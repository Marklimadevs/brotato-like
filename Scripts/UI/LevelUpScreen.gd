extends CanvasLayer

const REROLL_COST := 3

var _root: Control
var _bg: ColorRect
var _panel: PanelContainer
var _title_label: Label
var _materials_label: Label
var _reroll_button: Button
var _buttons: Array[Button] = []
var _rich_labels: Array[RichTextLabel] = []

var _current_choices: Array[UpgradeResource] = []
var _pending: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	_root.visible = false
	GameManager.level_up.connect(_on_level_up)


func _exit_tree() -> void:
	if GameManager != null and GameManager.level_up.is_connected(_on_level_up):
		GameManager.level_up.disconnect(_on_level_up)


func _build_ui() -> void:
	_root = Control.new()
	_root.anchor_right = 1
	_root.anchor_bottom = 1
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)

	_bg = ColorRect.new()
	_bg.color = Color(0, 0, 0, 0.65)
	_bg.anchor_right = 1
	_bg.anchor_bottom = 1
	_bg.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.add_child(_bg)

	_panel = PanelContainer.new()
	_panel.anchor_left = 0.5
	_panel.anchor_top = 0.5
	_panel.anchor_right = 0.5
	_panel.anchor_bottom = 0.5
	_panel.offset_left = -260
	_panel.offset_top = -240
	_panel.offset_right = 260
	_panel.offset_bottom = 240
	_root.add_child(_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	_panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	margin.add_child(vbox)

	_title_label = Label.new()
	_title_label.text = "Level Up!"
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.add_theme_font_size_override("font_size", 26)
	vbox.add_child(_title_label)

	_materials_label = Label.new()
	_materials_label.text = "Materiais: 0"
	_materials_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_materials_label.add_theme_font_size_override("font_size", 13)
	_materials_label.add_theme_color_override("font_color", Color(1, 0.85, 0.4))
	vbox.add_child(_materials_label)

	for i in range(3):
		var btn := Button.new()
		btn.text = ""
		btn.custom_minimum_size = Vector2(440, 80)
		var idx: int = i
		btn.pressed.connect(func(): _on_button_pressed(idx))
		vbox.add_child(btn)
		_buttons.append(btn)

		var rich := RichTextLabel.new()
		rich.bbcode_enabled = true
		rich.fit_content = true
		rich.scroll_active = false
		rich.anchor_right = 1
		rich.anchor_bottom = 1
		rich.offset_left = 10
		rich.offset_top = 8
		rich.offset_right = -10
		rich.offset_bottom = -8
		rich.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rich.add_theme_font_size_override("normal_font_size", 14)
		rich.add_theme_font_size_override("bold_font_size", 17)
		btn.add_child(rich)
		_rich_labels.append(rich)

	_reroll_button = Button.new()
	_reroll_button.text = "Reroll (%d mat)" % REROLL_COST
	_reroll_button.custom_minimum_size = Vector2(440, 38)
	_reroll_button.add_theme_font_size_override("font_size", 14)
	_reroll_button.pressed.connect(_on_reroll)
	vbox.add_child(_reroll_button)


func _on_level_up() -> void:
	_pending += 1
	if _root.visible:
		return
	_show_one()


func _show_one() -> void:
	_pending = maxi(0, _pending - 1)
	_roll_choices()
	_title_label.text = "Level %d  —  Escolha um upgrade" % GameManager.Level
	_refresh_materials_and_reroll()
	_root.visible = true
	get_tree().paused = true


func _roll_choices() -> void:
	_current_choices = []
	var pool: Array[UpgradeResource] = UpgradeCatalog.all()
	var rng: RandomNumberGenerator = GameManager.Rng
	var wave_idx: int = 0
	if WaveManager.Instance != null:
		wave_idx = WaveManager.Instance.CurrentWaveIndex

	for i in range(3):
		if pool.is_empty():
			break
		var choice: UpgradeResource = UpgradeCatalog.pick_from_pool(pool, rng, wave_idx)
		if choice == null:
			break
		_current_choices.append(choice)
		_rich_labels[i].text = ItemDisplay.format_item_bbcode(choice)
		_buttons[i].visible = true
	for i in range(_current_choices.size(), 3):
		_buttons[i].visible = false


func _refresh_materials_and_reroll() -> void:
	_materials_label.text = "Materiais: %d" % GameManager.Materials
	_reroll_button.text = "Reroll (%d mat)" % REROLL_COST
	_reroll_button.disabled = GameManager.Materials < REROLL_COST


func _on_reroll() -> void:
	if not GameManager.spend_material(REROLL_COST):
		return
	_roll_choices()
	_refresh_materials_and_reroll()


func _on_button_pressed(idx: int) -> void:
	if idx < _current_choices.size() and GameManager.Player != null and GameManager.Player.stats != null:
		_current_choices[idx].apply(GameManager.Player.stats)

	if _pending > 0:
		_show_one()
	else:
		_root.visible = false
		get_tree().paused = false
		GameManager.notify_level_up_closed()
