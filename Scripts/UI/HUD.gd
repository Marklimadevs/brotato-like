extends CanvasLayer

var _hp_bar: ProgressBar
var _hp_label: Label
var _xp_bar: ProgressBar
var _xp_label: Label
var _wave_label: Label
var _timer_label: Label
var _materials_label: Label
var _boss_hp_bar: ProgressBar
var _boss_label: Label


func _ready() -> void:
	_build_ui()
	GameManager.xp_changed.connect(_update_xp)
	GameManager.materials_changed.connect(_update_materials)
	_update_xp()
	_update_materials()


func _exit_tree() -> void:
	if GameManager == null: return
	if GameManager.xp_changed.is_connected(_update_xp):
		GameManager.xp_changed.disconnect(_update_xp)
	if GameManager.materials_changed.is_connected(_update_materials):
		GameManager.materials_changed.disconnect(_update_materials)


func _build_ui() -> void:
	# HP bar — top left
	_hp_bar = ProgressBar.new()
	_hp_bar.custom_minimum_size = Vector2(280, 26)
	_hp_bar.show_percentage = false
	_hp_bar.position = Vector2(20, 20)
	_hp_bar.modulate = Color(1, 0.45, 0.45)
	add_child(_hp_bar)
	_hp_label = _make_label("HP", Vector2(28, 22), 14)
	add_child(_hp_label)

	# XP bar — top center
	_xp_bar = ProgressBar.new()
	_xp_bar.custom_minimum_size = Vector2(560, 16)
	_xp_bar.show_percentage = false
	_xp_bar.position = Vector2(330, 24)
	_xp_bar.modulate = Color(0.55, 1, 0.55)
	add_child(_xp_bar)
	_xp_label = _make_label("Lv 1", Vector2(330, 42), 13)
	add_child(_xp_label)

	# Wave + timer — top right
	_wave_label = _make_label("Wave 1 / 5", Vector2(940, 20), 18)
	add_child(_wave_label)
	_timer_label = _make_label("30.0s", Vector2(940, 44), 16)
	add_child(_timer_label)
	var diff_label: Label = _make_label(DifficultyConfig.get_label(GameManager.SelectedDifficulty), Vector2(1180, 20), 18)
	diff_label.add_theme_color_override("font_color", Color(1, 0.7, 0.4))
	add_child(diff_label)

	# Materials below HP bar
	_materials_label = _make_label("Mat: 0", Vector2(20, 56), 18)
	_materials_label.add_theme_color_override("font_color", Color(1, 0.85, 0.4))
	add_child(_materials_label)

	# Boss HP bar (centered, hidden until boss alive)
	_boss_label = _make_label("⚠  BOSS  ⚠", Vector2(540, 80), 20)
	_boss_label.add_theme_color_override("font_color", Color(0.95, 0.55, 1))
	_boss_label.visible = false
	add_child(_boss_label)

	_boss_hp_bar = ProgressBar.new()
	_boss_hp_bar.custom_minimum_size = Vector2(900, 26)
	_boss_hp_bar.show_percentage = false
	_boss_hp_bar.position = Vector2(190, 108)
	_boss_hp_bar.modulate = Color(0.85, 0.4, 1)
	_boss_hp_bar.visible = false
	add_child(_boss_hp_bar)


func _make_label(text: String, pos: Vector2, font_size: int) -> Label:
	var l := Label.new()
	l.text = text
	l.position = pos
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", Color.WHITE)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 5)
	return l


func _process(_delta: float) -> void:
	var p: Player = GameManager.Player
	if p != null and p.Stats != null and _hp_bar != null:
		var cur_hp: int = maxi(0, p.Stats.CurrentHp)
		_hp_bar.max_value = p.Stats.MaxHp
		_hp_bar.value = cur_hp
		_hp_label.text = "%d / %d" % [cur_hp, p.Stats.MaxHp]

	var wm: WaveManager = WaveManager.Instance
	if wm != null and _wave_label != null:
		var total: int = wm.get_total_waves()
		_wave_label.text = "Wave %d / %d" % [mini(wm.CurrentWaveIndex + 1, total), total]

		var boss: EnemyBase = wm.CurrentBoss
		var boss_alive: bool = boss != null and is_instance_valid(boss)

		if boss_alive:
			_timer_label.text = "Mate o Boss!"
			_boss_label.visible = true
			_boss_hp_bar.visible = true
			_boss_hp_bar.max_value = boss.get_scaled_max_hp() if boss.get_scaled_max_hp() > 0 else (boss.Data.MaxHp if boss.Data != null else 1)
			_boss_hp_bar.value = maxi(0, boss.get_current_hp())
		else:
			_boss_label.visible = false
			_boss_hp_bar.visible = false
			if wm.GameWon:
				_timer_label.text = "Fim"
			elif wm.BetweenWaves:
				_timer_label.text = "..."
			else:
				_timer_label.text = "%.1fs" % maxf(0.0, wm.WaveTimeRemaining)


func _update_xp() -> void:
	if _xp_bar == null:
		return
	_xp_bar.max_value = GameManager.XpForNextLevel
	_xp_bar.value = GameManager.Xp
	var pending: String = ""
	if GameManager.PendingLevelUps > 0:
		pending = "    ⬆ %d upgrade(s) ao fim da wave" % GameManager.PendingLevelUps
	_xp_label.text = "Lv %d    XP %d / %d%s" % [GameManager.Level, GameManager.Xp, GameManager.XpForNextLevel, pending]


func _update_materials() -> void:
	if _materials_label == null:
		return
	_materials_label.text = "Mat: %d" % GameManager.Materials
