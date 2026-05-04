class_name Player
extends CharacterBody2D

const MAX_WEAPON_SLOTS := 4

@export var Radius: float = 16.0
@export var BaseColor: Color = Color(0.45, 0.85, 1)
@export var Weapon1: WeaponResource
@export var Weapon2: WeaponResource
@export var WeaponScene: PackedScene

var stats: Stats
var _weapon_mount: Node2D
var _hurt_box: Area2D
var _camera: CameraShake
var _iframe_timer: float = 0.0
var _hit_flash_timer: float = 0.0
var _regen_accumulator: float = 0.0
var _alive: bool = true


func is_alive() -> bool:
	return _alive


func get_equipped_weapon_count() -> int:
	var c: int = 0
	for w in get_active_weapons():
		c += 1
	return c


func _ready() -> void:
	stats = Stats.new()
	GameManager.Player = self

	_weapon_mount = get_node("WeaponMount")
	_hurt_box = get_node("HurtBox")
	_camera = get_node("Camera2D")

	var preset: CharacterPreset = GameManager.SelectedCharacter
	if preset != null and preset.starting_weapons != null and preset.starting_weapons.size() > 0:
		BaseColor = preset.base_color
		for w in preset.starting_weapons:
			add_weapon(w)
	else:
		# Fallback for running Main.tscn directly in editor
		add_weapon(Weapon1)
		add_weapon(Weapon2)

	queue_redraw()


func _physics_process(delta: float) -> void:
	if not _alive:
		return

	if _iframe_timer > 0.0:
		_iframe_timer -= delta

	var dir: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = dir * stats.MoveSpeed
	move_and_slide()

	if _iframe_timer <= 0.0:
		_check_enemy_contact()


func _check_enemy_contact() -> void:
	if _hurt_box == null:
		return
	for body in _hurt_box.get_overlapping_bodies():
		if body is EnemyBase and body.Data != null:
			take_damage(body.get_scaled_damage())
			return


func _process(delta: float) -> void:
	if _hit_flash_timer > 0.0:
		_hit_flash_timer -= delta
		if _hit_flash_timer <= 0.0:
			modulate = Color.WHITE

	# HP regen
	if _alive and stats != null and stats.HpRegenPerSec > 0.0 and stats.CurrentHp < stats.MaxHp:
		_regen_accumulator += stats.HpRegenPerSec * delta
		if _regen_accumulator >= 1.0:
			var amount: int = int(floor(_regen_accumulator))
			_regen_accumulator -= amount
			var old_hp: int = stats.CurrentHp
			stats.CurrentHp = mini(stats.MaxHp, stats.CurrentHp + amount)
			var gained: int = stats.CurrentHp - old_hp
			if gained > 0:
				DamageNumber.spawn_text(get_tree().current_scene, global_position + Vector2(0, -Radius - 4), "+%d" % gained, Color(0.5, 1, 0.55))


func add_weapon(res: WeaponResource) -> bool:
	if res == null or WeaponScene == null:
		return false
	if get_equipped_weapon_count() >= MAX_WEAPON_SLOTS:
		return false
	var w: Weapon = WeaponScene.instantiate()
	w.Data = res
	_weapon_mount.add_child(w)
	_layout_weapons()
	return true


func remove_weapon_at(index: int) -> bool:
	var weapons: Array = get_active_weapons()
	if index < 0 or index >= weapons.size():
		return false
	var w: Weapon = weapons[index]
	_weapon_mount.remove_child(w)
	w.queue_free()
	_layout_weapons()
	return true


func get_active_weapons() -> Array:
	var result: Array = []
	if _weapon_mount == null or not is_instance_valid(_weapon_mount):
		return result
	for c in _weapon_mount.get_children():
		if c is Weapon:
			result.append(c)
	return result


func _layout_weapons() -> void:
	var weapons: Array = []
	for w in get_active_weapons():
		if is_instance_valid(w):
			weapons.append(w)
	var n: int = weapons.size()
	var radius: float = 0.0 if n <= 1 else 24.0
	for i in range(n):
		var angle: float = (float(i) / float(n)) * TAU - PI / 2.0
		weapons[i].position = Vector2(cos(angle), sin(angle)) * radius


func take_damage(dmg: int) -> void:
	if not _alive or _iframe_timer > 0.0:
		return
	# Apply armor (always at least 1 dmg)
	var actual_dmg: int = maxi(1, dmg - stats.Armor)
	stats.CurrentHp -= actual_dmg
	_iframe_timer = 0.45
	modulate = Color(3, 1.4, 1.4)
	_hit_flash_timer = 0.08

	DamageNumber.spawn(get_tree().current_scene, global_position + Vector2(0, -Radius - 4), actual_dmg, Color(1, 0.55, 0.55))
	if _camera != null:
		_camera.shake(11.0)

	if stats.CurrentHp <= 0:
		_die()


func _die() -> void:
	if not _alive:
		return
	_alive = false
	visible = false

	set_physics_process(false)
	collision_layer = 0
	collision_mask = 0
	if _hurt_box != null:
		_hurt_box.monitoring = false

	if _weapon_mount != null and is_instance_valid(_weapon_mount):
		for child in _weapon_mount.get_children():
			child.queue_free()

	print("Player died!")
	GameManager.notify_player_died()


func _draw() -> void:
	draw_circle(Vector2.ZERO, Radius, BaseColor)
	draw_circle(Vector2(-Radius * 0.3, -Radius * 0.3), Radius * 0.28, Color(1, 1, 1, 0.35))
	draw_arc(Vector2.ZERO, Radius - 1.5, 0.0, TAU, 32, Color(0.1, 0.2, 0.3), 2.0, true)
