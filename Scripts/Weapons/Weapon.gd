class_name Weapon
extends Node2D

@export var Data: WeaponResource

var _player: Player = null
var _timer: Timer = null
var _current_target: EnemyBase = null


func get_effective_damage() -> int:
	if Data == null:
		return 0
	var bonus: int = 0
	if _player != null and _player.stats != null:
		bonus = _player.stats.BonusDamage
	return Data.Damage + bonus


func get_effective_fire_rate() -> float:
	if Data == null or Data.Cooldown <= 0.0:
		return 0.0
	var mult: float = 1.0
	if _player != null and _player.stats != null:
		mult = _player.stats.AttackSpeedMult
	return mult / Data.Cooldown


func _ready() -> void:
	if get_parent() != null:
		_player = get_parent().get_parent() as Player
	_timer = Timer.new()
	_timer.one_shot = false
	_timer.timeout.connect(_on_timeout)
	add_child(_timer)
	_update_cooldown()
	_timer.start()
	queue_redraw()


func _process(_delta: float) -> void:
	_current_target = _find_nearest_enemy()
	if _current_target != null:
		var dir: Vector2 = _current_target.global_position - global_position
		if dir.length_squared() > 0.01:
			rotation = dir.angle()


func _draw() -> void:
	if Data == null:
		return
	var l: float = Data.BarrelLength
	var w: float = Data.BarrelWidth
	# Barrel pointing right at origin (+X). Rotation orients it toward target.
	var rect := Rect2(4.0, -w / 2.0, l, w)
	draw_rect(rect, Data.BarrelColor)
	draw_rect(rect, Color(0, 0, 0, 0.7), false, 1.0)
	# Tip highlight
	draw_rect(Rect2(4.0 + l - 3.0, -w / 2.0, 3.0, w), Color(1, 1, 1, 0.4))


func _update_cooldown() -> void:
	if Data == null:
		return
	var mult: float = 1.0
	if _player != null and _player.stats != null:
		mult = _player.stats.AttackSpeedMult
	_timer.wait_time = maxf(0.05, Data.Cooldown / mult)


func _on_timeout() -> void:
	if Data == null or Data.BulletScene == null:
		return
	_update_cooldown()
	if _current_target == null or not is_instance_valid(_current_target):
		_current_target = _find_nearest_enemy()
	if _current_target == null:
		return
	_fire_at(_current_target)


func _find_nearest_enemy() -> EnemyBase:
	if Data == null:
		return null
	var nearest: EnemyBase = null
	var best_sq: float = Data.Reach * Data.Reach
	for e in GameManager.Enemies:
		if not is_instance_valid(e):
			continue
		var d_sq: float = (e.global_position - global_position).length_squared()
		if d_sq < best_sq:
			best_sq = d_sq
			nearest = e
	return nearest


func _fire_at(target: EnemyBase) -> void:
	var aim_dir: Vector2 = (target.global_position - global_position).normalized()
	var pellets: int = maxi(1, Data.Pellets)
	var spread: float = deg_to_rad(Data.SpreadAngleDeg)

	for i in range(pellets):
		var dir: Vector2
		if pellets == 1 or spread <= 0.0:
			dir = aim_dir
		else:
			# Distribute pellets evenly across spread cone, centered on aim
			var t: float = (float(i) / float(pellets - 1)) - 0.5
			dir = aim_dir.rotated(t * spread)
		_spawn_pellet(dir)


func _spawn_pellet(dir: Vector2) -> void:
	var bullet: Bullet = Data.BulletScene.instantiate()
	bullet.Direction = dir
	bullet.Speed = Data.BulletSpeed
	var bonus: int = 0
	if _player != null and _player.stats != null:
		bonus = _player.stats.BonusDamage
	bullet.Damage = Data.Damage + bonus
	bullet.BulletColor = Data.ProjectileColor
	bullet.Radius = Data.BulletRadius
	bullet.Pierce = Data.Pierce
	get_tree().current_scene.add_child(bullet)
	bullet.global_position = global_position
