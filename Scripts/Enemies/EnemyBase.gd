class_name EnemyBase
extends CharacterBody2D

@export var Resource: EnemyResource
@export var XpGemScene: PackedScene

var _hp: int = 0
var _scaled_max_hp: int = 0
var _scaled_damage: int = 0
var _scaled_speed: float = 0.0
var _collision_shape: CollisionShape2D
var _shape: CircleShape2D
var _flash_timer: float = 0.0
var _dead: bool = false

var _knockback_velocity: Vector2 = Vector2.ZERO
var _knockback_timer: float = 0.0

# Charger state
var _charge_interval_timer: float = 0.0
var _charging_timer: float = 0.0
var _is_charging: bool = false
var _charge_dir: Vector2 = Vector2.ZERO


func get_current_hp() -> int:
	return _hp


func get_scaled_max_hp() -> int:
	return _scaled_max_hp


func get_scaled_damage() -> int:
	return _scaled_damage


func get_scaled_speed() -> float:
	return _scaled_speed


func is_boss() -> bool:
	return Resource != null and Resource.IsBoss


func _ready() -> void:
	_collision_shape = get_node("CollisionShape2D")
	_shape = _collision_shape.shape.duplicate() as CircleShape2D
	_collision_shape.shape = _shape

	if Resource != null:
		apply_resource(Resource)

	GameManager.register_enemy(self)

	if is_boss():
		_attach_boss_attack()
	elif Resource != null and Resource.HasRangedAttack:
		_attach_ranged_attack()

	if Resource != null and Resource.IsCharger:
		_charge_interval_timer = Resource.ChargeInterval


func _attach_boss_attack() -> void:
	var bullet_scene: PackedScene = load("res://Scenes/Bullets/EnemyBullet.tscn")
	if bullet_scene == null:
		return
	var attack: BossAttack = BossAttack.new()
	attack.EnemyBulletScene = bullet_scene
	add_child(attack)


func _attach_ranged_attack() -> void:
	var bullet_scene: PackedScene = load("res://Scenes/Bullets/EnemyBullet.tscn")
	if bullet_scene == null:
		return
	var attack: RangedAttack = RangedAttack.new()
	attack.EnemyBulletScene = bullet_scene
	attack.FireInterval = Resource.RangedFireInterval
	attack.Damage = Resource.RangedDamage
	attack.BulletSpeed = Resource.RangedBulletSpeed
	add_child(attack)


func apply_resource(res: EnemyResource) -> void:
	Resource = res
	var diff = DifficultyConfig.get_multipliers(GameManager.SelectedDifficulty)
	_scaled_max_hp = maxi(1, int(res.MaxHp * diff["hp_mult"]))
	_scaled_damage = maxi(1, int(res.Damage * diff["damage_mult"]))
	_scaled_speed = res.Speed * diff["speed_mult"]
	_hp = _scaled_max_hp
	if _shape != null:
		_shape.radius = res.Radius
	queue_redraw()


func _physics_process(delta: float) -> void:
	if _dead:
		return
	var player: Player = GameManager.Player
	if player == null or Resource == null:
		return

	var to_player: Vector2 = player.global_position - global_position
	var dist_to_player: float = to_player.length()
	var dir_to_player: Vector2 = to_player / dist_to_player if dist_to_player > 0.01 else Vector2.ZERO

	if _knockback_timer > 0.0:
		_knockback_timer -= delta
		velocity = _knockback_velocity
		_knockback_velocity = _knockback_velocity.lerp(Vector2.ZERO, delta * 8.0)
	elif Resource.IsCharger:
		_update_charger(delta, dir_to_player)
	elif Resource.HasRangedAttack:
		if dist_to_player < Resource.RangedStopDistance:
			velocity = Vector2.ZERO
		else:
			velocity = dir_to_player * _scaled_speed
	else:
		velocity = dir_to_player * _scaled_speed

	move_and_slide()


func _update_charger(delta: float, dir_to_player: Vector2) -> void:
	if _is_charging:
		_charging_timer -= delta
		if _charging_timer <= 0.0:
			_is_charging = false
			_charge_interval_timer = Resource.ChargeInterval
		else:
			velocity = _charge_dir * _scaled_speed * Resource.ChargeSpeedMult
		return

	_charge_interval_timer -= delta
	if _charge_interval_timer <= 0.0:
		_is_charging = true
		_charging_timer = Resource.ChargeDuration
		_charge_dir = dir_to_player
		velocity = _charge_dir * _scaled_speed * Resource.ChargeSpeedMult
	else:
		velocity = dir_to_player * _scaled_speed


func _process(delta: float) -> void:
	if _flash_timer > 0.0:
		_flash_timer -= delta
		if _flash_timer <= 0.0:
			modulate = Color.WHITE

	# Charger telegraph: pulse modulate while approaching charge
	if Resource != null and Resource.IsCharger and not _is_charging and _flash_timer <= 0.0:
		var remaining: float = _charge_interval_timer
		if remaining < 0.6:
			var t: float = 1.0 - (remaining / 0.6)
			var pulse: float = 1.0 + sin(t * TAU * 4.0) * 0.4
			modulate = Color(pulse, pulse * 0.7, pulse * 0.5)
		else:
			modulate = Color.WHITE


func take_damage(dmg: int, is_crit: bool = false) -> void:
	if _dead:
		return
	_hp -= dmg

	modulate = Color(3, 3, 3)
	_flash_timer = 0.06

	var color: Color = Color(1, 0.85, 0.2) if is_crit else Color(1, 1, 0.7)
	var pos_y: float = -(Resource.Radius if Resource != null else 12.0) - 2.0
	DamageNumber.spawn(get_tree().current_scene, global_position + Vector2(0, pos_y), dmg, color, is_crit)

	if _hp <= 0:
		_die()


func apply_knockback(force: Vector2) -> void:
	if is_boss():
		return
	_knockback_velocity = force
	_knockback_timer = 0.18


func _die() -> void:
	_dead = true
	_spawn_death_particles()
	_spawn_xp_gem()
	if Resource != null and Resource.SplitsOnDeath and Resource.SplitInto != null and Resource.SplitCount > 0:
		_spawn_splits()
	if is_boss() and WaveManager.Instance != null:
		WaveManager.Instance.notify_boss_killed()
	queue_free()


func _spawn_splits() -> void:
	var enemy_scene: PackedScene = load("res://Scenes/Enemies/EnemyBase.tscn")
	if enemy_scene == null:
		return
	var rng: RandomNumberGenerator = GameManager.Rng
	var parent: Node = get_parent()
	if parent == null or not is_instance_valid(parent):
		return
	for i in range(Resource.SplitCount):
		var split: EnemyBase = enemy_scene.instantiate()
		split.Resource = Resource.SplitInto
		var offset := Vector2(rng.randf_range(-20.0, 20.0), rng.randf_range(-20.0, 20.0))
		parent.add_child(split)
		split.global_position = global_position + offset


func _spawn_xp_gem() -> void:
	if XpGemScene == null or Resource == null or Resource.XpDrop <= 0:
		return
	var gem: XpGem = XpGemScene.instantiate()
	gem.Value = Resource.XpDrop
	gem.MaterialValue = Resource.MaterialDrop
	get_tree().current_scene.add_child(gem)
	gem.global_position = global_position


func _spawn_death_particles() -> void:
	var particles := CPUParticles2D.new()
	particles.emitting = true
	particles.one_shot = true
	particles.amount = 30 if is_boss() else 10
	particles.lifetime = 0.7 if is_boss() else 0.4
	particles.explosiveness = 1.0
	particles.direction = Vector2.UP
	particles.spread = 180.0
	particles.initial_velocity_min = 80.0
	particles.initial_velocity_max = 280.0 if is_boss() else 180.0
	particles.gravity = Vector2.ZERO
	particles.scale_amount_min = 3.0 if is_boss() else 2.0
	particles.scale_amount_max = 6.0 if is_boss() else 4.0
	particles.color = Resource.EnemyColor if Resource != null else Color.WHITE
	get_tree().current_scene.add_child(particles)
	particles.global_position = global_position
	particles.finished.connect(func():
		if is_instance_valid(particles):
			particles.queue_free())


func _draw() -> void:
	if Resource == null:
		return
	var c: Color = Resource.EnemyColor
	var r: float = Resource.Radius

	match Resource.Shape:
		EnemyResource.EnemyShape.TRIANGLE:
			draw_colored_polygon(PackedVector2Array([
				Vector2(0, -r * 1.3),
				Vector2(r * 1.05, r * 0.85),
				Vector2(-r * 1.05, r * 0.85),
			]), c)
		EnemyResource.EnemyShape.DIAMOND:
			draw_colored_polygon(PackedVector2Array([
				Vector2(0, -r * 1.2),
				Vector2(r * 1.2, 0),
				Vector2(0, r * 1.2),
				Vector2(-r * 1.2, 0),
			]), c)
		EnemyResource.EnemyShape.SPIKE:
			draw_colored_polygon(PackedVector2Array([
				Vector2(0, -r * 1.5),
				Vector2(r * 0.45, -r * 0.45),
				Vector2(r * 1.5, 0),
				Vector2(r * 0.45, r * 0.45),
				Vector2(0, r * 1.5),
				Vector2(-r * 0.45, r * 0.45),
				Vector2(-r * 1.5, 0),
				Vector2(-r * 0.45, -r * 0.45),
			]), c)
		EnemyResource.EnemyShape.BOSS_DIAMOND:
			# Outer translucent halo
			draw_colored_polygon(PackedVector2Array([
				Vector2(0, -r * 1.7),
				Vector2(r * 1.7, 0),
				Vector2(0, r * 1.7),
				Vector2(-r * 1.7, 0),
			]), Color(c.r, c.g, c.b, 0.25))
			# Mid layer
			draw_colored_polygon(PackedVector2Array([
				Vector2(0, -r * 1.35),
				Vector2(r * 1.35, 0),
				Vector2(0, r * 1.35),
				Vector2(-r * 1.35, 0),
			]), c)
			# Inner brighter core
			draw_colored_polygon(PackedVector2Array([
				Vector2(0, -r * 0.55),
				Vector2(r * 0.55, 0),
				Vector2(0, r * 0.55),
				Vector2(-r * 0.55, 0),
			]), Color(1, 1, 1, 0.45))


func _exit_tree() -> void:
	if GameManager != null:
		GameManager.unregister_enemy(self)
