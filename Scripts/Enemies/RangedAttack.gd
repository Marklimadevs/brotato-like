class_name RangedAttack
extends Node

var EnemyBulletScene: PackedScene
var FireInterval: float = 2.0
var Damage: int = 5
var BulletSpeed: float = 300.0

var _shooter: EnemyBase = null
var _timer: Timer = null


func _ready() -> void:
	_shooter = get_parent() as EnemyBase
	_timer = Timer.new()
	_timer.wait_time = FireInterval
	_timer.autostart = true
	_timer.timeout.connect(_on_fire)
	add_child(_timer)


func _on_fire() -> void:
	if _shooter == null or not is_instance_valid(_shooter):
		return
	var player: Player = GameManager.Player
	if player == null or not player.is_alive():
		return
	if EnemyBulletScene == null:
		return

	var aim_dir: Vector2 = (player.global_position - _shooter.global_position).normalized()
	var bullet: EnemyBullet = EnemyBulletScene.instantiate()
	bullet.Direction = aim_dir
	bullet.Speed = BulletSpeed
	var diff = DifficultyConfig.get_multipliers(GameManager.SelectedDifficulty)
	bullet.Damage = maxi(1, int(Damage * diff["damage_mult"]))
	_shooter.get_tree().current_scene.add_child(bullet)
	bullet.global_position = _shooter.global_position
