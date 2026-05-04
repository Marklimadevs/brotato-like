class_name BossAttack
extends Node

var EnemyBulletScene: PackedScene
var FireInterval: float = 3.5
var PelletsPerBurst: int = 4
var SpreadAngleDeg: float = 40.0
var BulletDamage: int = 6
var BulletSpeed: float = 360.0

var _boss: EnemyBase = null
var _timer: Timer = null


func _ready() -> void:
	_boss = get_parent() as EnemyBase
	_timer = Timer.new()
	_timer.wait_time = FireInterval
	_timer.autostart = true
	_timer.timeout.connect(_on_fire)
	add_child(_timer)


func _on_fire() -> void:
	if _boss == null or not is_instance_valid(_boss):
		return
	var player: Player = GameManager.Player
	if player == null or not player.is_alive():
		return
	if EnemyBulletScene == null:
		return

	var aim_dir: Vector2 = (player.global_position - _boss.global_position).normalized()
	var spread: float = deg_to_rad(SpreadAngleDeg)

	for i in range(PelletsPerBurst):
		var t: float
		if PelletsPerBurst == 1:
			t = 0.0
		else:
			t = (float(i) / float(PelletsPerBurst - 1)) - 0.5
		var dir: Vector2 = aim_dir.rotated(t * spread)
		_spawn_bullet(dir)


func _spawn_bullet(dir: Vector2) -> void:
	var bullet: EnemyBullet = EnemyBulletScene.instantiate()
	bullet.Direction = dir
	bullet.Speed = BulletSpeed
	var diff = DifficultyConfig.get_multipliers(GameManager.SelectedDifficulty)
	bullet.Damage = maxi(1, int(BulletDamage * diff["damage_mult"]))
	_boss.get_tree().current_scene.add_child(bullet)
	bullet.global_position = _boss.global_position
