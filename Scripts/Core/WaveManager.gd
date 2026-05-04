class_name WaveManager
extends Node

@export var EnemyScene: PackedScene
@export var RunnerEnemy: EnemyResource
@export var SwarmerEnemy: EnemyResource
@export var TankEnemy: EnemyResource
@export var SplitterEnemy: EnemyResource
@export var ChargerEnemy: EnemyResource
@export var RangedEnemy: EnemyResource
@export var BossEnemy: EnemyResource
@export var SpawnRootPath: NodePath
@export var ArenaSize: Vector2 = Vector2(1600, 900)
@export var SpawnMargin: float = 60.0
@export var BossSpawnDelay: float = 5.0

static var Instance: WaveManager = null

signal wave_started
signal wave_ended
signal game_won_event
signal boss_spawned

var CurrentWaveIndex: int = 0
var WaveTimeRemaining: float = 0.0
var BetweenWaves: bool = false
var GameWon: bool = false
var CurrentBoss: EnemyBase = null

var _waves: Array = []
var _spawn_root: Node = null
var _spawn_timer: float = 0.0
var _boss_spawned: bool = false


func get_total_waves() -> int:
	return _waves.size()


func is_boss_wave() -> bool:
	return _waves.size() > 0 and CurrentWaveIndex == _waves.size() - 1


func _enter_tree() -> void:
	Instance = self


func _exit_tree() -> void:
	if Instance == self:
		Instance = null
	if GameManager != null:
		if GameManager.level_up_closed.is_connected(_on_after_level_up_between_waves):
			GameManager.level_up_closed.disconnect(_on_after_level_up_between_waves)
		if GameManager.shop_closed.is_connected(_on_shop_closed_between_waves):
			GameManager.shop_closed.disconnect(_on_shop_closed_between_waves)


func _ready() -> void:
	if SpawnRootPath != NodePath() and not SpawnRootPath.is_empty():
		_spawn_root = get_node(SpawnRootPath)
	else:
		_spawn_root = get_parent()

	_waves = [
		{"duration": 30.0, "batch": 4, "interval": 2.2, "pool": [RunnerEnemy]},
		{"duration": 30.0, "batch": 5, "interval": 2.0, "pool": [RunnerEnemy, RunnerEnemy, SwarmerEnemy, SplitterEnemy]},
		{"duration": 30.0, "batch": 6, "interval": 1.7, "pool": [RunnerEnemy, SwarmerEnemy, TankEnemy, SplitterEnemy, ChargerEnemy]},
		{"duration": 30.0, "batch": 7, "interval": 1.5, "pool": [RunnerEnemy, SwarmerEnemy, TankEnemy, ChargerEnemy, RangedEnemy]},
		{"duration": 9999.0, "batch": 2, "interval": 4.0, "pool": [SwarmerEnemy, SwarmerEnemy, RunnerEnemy, RangedEnemy]},
	]

	_start_wave(0)


func _process(delta: float) -> void:
	if GameWon or BetweenWaves:
		return
	if CurrentWaveIndex >= _waves.size():
		return
	if GameManager.Player != null and not GameManager.Player.is_alive():
		return

	WaveTimeRemaining -= delta

	# Boss spawn check
	if is_boss_wave() and not _boss_spawned:
		var elapsed: float = _waves[CurrentWaveIndex]["duration"] - WaveTimeRemaining
		if elapsed >= BossSpawnDelay:
			_spawn_boss()

	_spawn_timer -= delta
	if _spawn_timer <= 0.0:
		_spawn_batch(_waves[CurrentWaveIndex])
		_spawn_timer = _waves[CurrentWaveIndex]["interval"]

	if WaveTimeRemaining <= 0.0 and not is_boss_wave():
		_end_current_wave()


func _start_wave(idx: int) -> void:
	CurrentWaveIndex = idx
	WaveTimeRemaining = _waves[idx]["duration"]
	BetweenWaves = false
	_spawn_timer = 0.5
	_boss_spawned = false
	CurrentBoss = null
	wave_started.emit()
	print("Wave %d iniciada" % (idx + 1))


func _end_current_wave() -> void:
	BetweenWaves = true
	WaveTimeRemaining = 0.0
	_clear_enemies()
	wave_ended.emit()
	print("Wave %d terminada" % (CurrentWaveIndex + 1))

	if GameManager.Player != null and not GameManager.Player.is_alive():
		return

	GameManager.level_up_closed.connect(_on_after_level_up_between_waves)
	GameManager.force_level_up()
	GameManager.drain_pending_level_ups()


func _on_after_level_up_between_waves() -> void:
	if GameManager.level_up_closed.is_connected(_on_after_level_up_between_waves):
		GameManager.level_up_closed.disconnect(_on_after_level_up_between_waves)

	if GameManager.Player != null and not GameManager.Player.is_alive():
		return

	var next: int = CurrentWaveIndex + 1
	if next >= _waves.size():
		GameWon = true
		game_won_event.emit()
		print("VITÓRIA! Todas as 5 waves completas.")
		return

	GameManager.shop_closed.connect(_on_shop_closed_between_waves)
	GameManager.open_shop()


func _on_shop_closed_between_waves() -> void:
	if GameManager.shop_closed.is_connected(_on_shop_closed_between_waves):
		GameManager.shop_closed.disconnect(_on_shop_closed_between_waves)

	if GameManager.Player != null and not GameManager.Player.is_alive():
		return

	_start_wave(CurrentWaveIndex + 1)


func _spawn_boss() -> void:
	if BossEnemy == null or EnemyScene == null:
		return
	_boss_spawned = true
	var enemy: EnemyBase = EnemyScene.instantiate()
	enemy.Resource = BossEnemy
	enemy.position = Vector2(0.0, -ArenaSize.y / 2.0 + SpawnMargin)
	_spawn_root.add_child(enemy)
	CurrentBoss = enemy
	print("BOSS apareceu!")
	boss_spawned.emit()


func notify_boss_killed() -> void:
	if BetweenWaves or GameWon:
		return
	CurrentBoss = null
	if is_boss_wave():
		print("Boss derrotado — terminando wave 5")
		_end_current_wave()


func _spawn_batch(wave: Dictionary) -> void:
	if EnemyScene == null:
		return
	var pool: Array = wave["pool"]
	if pool == null or pool.is_empty():
		return
	var rng: RandomNumberGenerator = GameManager.Rng
	for i in range(wave["batch"]):
		var res: EnemyResource = pool[rng.randi_range(0, pool.size() - 1)]
		if res == null:
			continue
		_spawn_one(res)


func _spawn_one(res: EnemyResource) -> void:
	var enemy: EnemyBase = EnemyScene.instantiate()
	enemy.Resource = res
	enemy.position = _random_edge_position()
	_spawn_root.add_child(enemy)


func _clear_enemies() -> void:
	var snapshot: Array = GameManager.Enemies.duplicate()
	for e in snapshot:
		if is_instance_valid(e):
			e.queue_free()
	CurrentBoss = null


func _random_edge_position() -> Vector2:
	var rng: RandomNumberGenerator = GameManager.Rng
	var half_w: float = ArenaSize.x / 2.0 - SpawnMargin
	var half_h: float = ArenaSize.y / 2.0 - SpawnMargin
	var side: int = rng.randi_range(0, 3)
	match side:
		0: return Vector2(rng.randf_range(-half_w, half_w), -half_h)
		1: return Vector2(rng.randf_range(-half_w, half_w), half_h)
		2: return Vector2(-half_w, rng.randf_range(-half_h, half_h))
		_: return Vector2(half_w, rng.randf_range(-half_h, half_h))
