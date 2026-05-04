extends Node

# Autoload singleton — accessed globally as GameManager.X

signal level_up
signal level_up_closed
signal xp_changed
signal materials_changed
signal player_died
signal shop_opened
signal shop_closed

var Rng: RandomNumberGenerator
var Player: Player = null
var Enemies: Array[EnemyBase] = []
var SelectedCharacter: CharacterPreset = null
var SelectedDifficulty: int = 1

var Xp: int = 0
var Level: int = 1
var XpForNextLevel: int = 5
var Materials: int = 0
var PendingLevelUps: int = 0
var ReviveUsedThisRun: bool = false
var WaveMaterialsEarned: int = 0  # reseta a cada wave_start; usado pra bonus mat ad


func _enter_tree() -> void:
	Rng = RandomNumberGenerator.new()
	Rng.randomize()
	SaveData.load_data()


func register_enemy(e: EnemyBase) -> void:
	if not Enemies.has(e):
		Enemies.append(e)


func unregister_enemy(e: EnemyBase) -> void:
	Enemies.erase(e)


func add_xp(amount: int) -> void:
	var mult: float = 1.0
	if Player != null and Player.stats != null:
		mult = Player.stats.XpGainMult
	Xp += maxi(1, int(amount * mult))
	xp_changed.emit()
	while Xp >= XpForNextLevel:
		Xp -= XpForNextLevel
		Level += 1
		XpForNextLevel = 5 + Level * 3
		PendingLevelUps += 1
		# Don't fire LevelUp here — accumulate until wave end
	xp_changed.emit()


func drain_pending_level_ups() -> void:
	var pending: int = PendingLevelUps
	PendingLevelUps = 0
	for i in range(pending):
		level_up.emit()
	xp_changed.emit()


func force_level_up() -> void:
	Level += 1
	XpForNextLevel = 5 + Level * 3
	level_up.emit()
	xp_changed.emit()


func notify_level_up_closed() -> void:
	level_up_closed.emit()


func notify_player_died() -> void:
	player_died.emit()


func add_material(amount: int) -> void:
	if amount <= 0:
		return
	Materials += amount
	WaveMaterialsEarned += amount
	materials_changed.emit()


func spend_material(amount: int) -> bool:
	if amount <= 0:
		return true
	if Materials < amount:
		return false
	Materials -= amount
	materials_changed.emit()
	return true


func open_shop() -> void:
	shop_opened.emit()


func notify_shop_closed() -> void:
	shop_closed.emit()


func reset_run_state() -> void:
	Xp = 0
	Level = 1
	XpForNextLevel = 5
	Materials = 0
	PendingLevelUps = 0
	ReviveUsedThisRun = false
	WaveMaterialsEarned = 0
	Enemies.clear()
	Player = null


func clear_all_enemies() -> void:
	var snapshot: Array = Enemies.duplicate()
	for e in snapshot:
		if is_instance_valid(e):
			e.queue_free()
	Enemies.clear()
