extends Control

@export var PistolWeapon: WeaponResource
@export var SmgWeapon: WeaponResource
@export var ShotgunWeapon: WeaponResource
@export var SniperWeapon: WeaponResource

var _presets: Array[CharacterPreset] = []
var _selected_difficulty: int = 1
var _difficulty_buttons: Array[Button] = []
var _difficulty_desc_label: Label = null


func _ready() -> void:
	_presets = _build_presets()
	_selected_difficulty = clampi(GameManager.SelectedDifficulty, DifficultyConfig.MIN, DifficultyConfig.MAX)
	if _selected_difficulty > SaveData.HighestUnlockedDifficulty:
		_selected_difficulty = SaveData.HighestUnlockedDifficulty
	_build_ui()
	_update_difficulty_buttons()
	AudioManager.play_music("main_menu")


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.1, 0.1, 0.14)
	bg.anchor_right = 1
	bg.anchor_bottom = 1
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var margin := MarginContainer.new()
	margin.anchor_right = 1
	margin.anchor_bottom = 1
	margin.add_theme_constant_override("margin_left", 40)
	margin.add_theme_constant_override("margin_right", 40)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_bottom", 30)
	add_child(margin)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 18)
	margin.add_child(col)

	var title := Label.new()
	title.text = "ESCOLHA SEU PERSONAGEM"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 34)
	col.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Cada personagem começa com uma arma diferente — útil para testar build"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 15)
	subtitle.add_theme_color_override("font_color", Color(0.7, 0.75, 0.85))
	col.add_child(subtitle)

	var top_spacer := Control.new()
	top_spacer.size_flags_vertical = Control.SIZE_EXPAND
	col.add_child(top_spacer)

	var cards_row := HBoxContainer.new()
	cards_row.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	cards_row.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	cards_row.add_theme_constant_override("separation", 18)
	col.add_child(cards_row)

	for preset in _presets:
		cards_row.add_child(_build_card(preset))

	var bottom_spacer := Control.new()
	bottom_spacer.size_flags_vertical = Control.SIZE_EXPAND
	col.add_child(bottom_spacer)

	# DIFICULDADE row
	var diff_title := Label.new()
	diff_title.text = "DIFICULDADE"
	diff_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	diff_title.add_theme_font_size_override("font_size", 18)
	diff_title.add_theme_color_override("font_color", Color(1, 0.7, 0.4))
	col.add_child(diff_title)

	var diff_row := HBoxContainer.new()
	diff_row.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	diff_row.add_theme_constant_override("separation", 8)
	col.add_child(diff_row)

	for i in range(DifficultyConfig.MAX):
		var diff: int = i + 1
		var btn := Button.new()
		btn.text = "D%d" % diff
		btn.custom_minimum_size = Vector2(70, 50)
		btn.add_theme_font_size_override("font_size", 18)
		btn.pressed.connect(func(): _on_difficulty_click(diff))
		diff_row.add_child(btn)
		_difficulty_buttons.append(btn)

	_difficulty_desc_label = Label.new()
	_difficulty_desc_label.text = DifficultyConfig.get_description(_selected_difficulty)
	_difficulty_desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_difficulty_desc_label.add_theme_font_size_override("font_size", 13)
	_difficulty_desc_label.add_theme_color_override("font_color", Color(0.7, 0.75, 0.85))
	col.add_child(_difficulty_desc_label)

	var hint := Label.new()
	hint.text = "Vença a dificuldade atual para destravar a próxima."
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 12)
	hint.add_theme_color_override("font_color", Color(0.55, 0.6, 0.7))
	col.add_child(hint)


func _build_card(preset: CharacterPreset) -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(220, 320)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(preset.base_color.r * 0.18, preset.base_color.g * 0.18, preset.base_color.b * 0.18, 0.92)
	style.border_color = preset.base_color
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	panel.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	panel.add_child(vbox)

	var preview := Label.new()
	preview.text = "●"
	preview.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	preview.add_theme_font_size_override("font_size", 84)
	preview.add_theme_color_override("font_color", preset.base_color)
	vbox.add_child(preview)

	var name_label := Label.new()
	name_label.text = preset.name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 22)
	vbox.add_child(name_label)

	var weapon_name: String = "(sem arma)"
	if preset.starting_weapons.size() > 0:
		weapon_name = preset.starting_weapons[0].WeaponName
	var weapon_label := Label.new()
	weapon_label.text = "Arma: %s" % weapon_name
	weapon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	weapon_label.add_theme_font_size_override("font_size", 14)
	weapon_label.add_theme_color_override("font_color", Color(1, 0.95, 0.6))
	vbox.add_child(weapon_label)

	var desc := Label.new()
	desc.text = preset.description
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.custom_minimum_size = Vector2(0, 70)
	desc.add_theme_font_size_override("font_size", 13)
	desc.add_theme_color_override("font_color", Color(0.85, 0.88, 0.92))
	vbox.add_child(desc)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND
	vbox.add_child(spacer)

	var btn := Button.new()
	btn.text = "Escolher"
	btn.custom_minimum_size = Vector2(0, 44)
	btn.add_theme_font_size_override("font_size", 16)
	btn.pressed.connect(func(): _on_choose(preset))
	vbox.add_child(btn)

	return panel


func _on_choose(preset: CharacterPreset) -> void:
	GameManager.reset_run_state()
	GameManager.SelectedCharacter = preset
	GameManager.SelectedDifficulty = _selected_difficulty
	AdsManager.track_event("run_start", {"character": preset.name, "difficulty": _selected_difficulty})
	get_tree().change_scene_to_file("res://Scenes/Main.tscn")


func _on_difficulty_click(diff: int) -> void:
	if diff > SaveData.HighestUnlockedDifficulty:
		return
	_selected_difficulty = diff
	_update_difficulty_buttons()


func _update_difficulty_buttons() -> void:
	for i in range(DifficultyConfig.MAX):
		var diff: int = i + 1
		var btn: Button = _difficulty_buttons[i] if i < _difficulty_buttons.size() else null
		if btn == null:
			continue
		var unlocked: bool = diff <= SaveData.HighestUnlockedDifficulty
		var selected: bool = diff == _selected_difficulty
		btn.disabled = not unlocked
		btn.text = ("D%d" % diff) if unlocked else ("🔒 D%d" % diff)
		if selected:
			btn.modulate = Color(1, 0.85, 0.3)
		elif unlocked:
			btn.modulate = Color.WHITE
		else:
			btn.modulate = Color(0.45, 0.45, 0.5)
	if _difficulty_desc_label != null:
		_difficulty_desc_label.text = DifficultyConfig.get_description(_selected_difficulty)


func _build_presets() -> Array[CharacterPreset]:
	var list: Array[CharacterPreset] = []

	var p1 := CharacterPreset.new()
	p1.name = "Pistoleiro"
	p1.description = "Equilibrado. Pistol de dano médio e range médio."
	p1.base_color = Color(0.45, 0.85, 1)
	if PistolWeapon != null: p1.starting_weapons = [PistolWeapon]
	list.append(p1)

	var p2 := CharacterPreset.new()
	p2.name = "Metralhador"
	p2.description = "SMG rápida. Dano baixo por tiro mas DPS alto no curto/médio."
	p2.base_color = Color(0.55, 1, 0.65)
	if SmgWeapon != null: p2.starting_weapons = [SmgWeapon]
	list.append(p2)

	var p3 := CharacterPreset.new()
	p3.name = "Bombardeiro"
	p3.description = "Shotgun em leque. 5 pellets que devastam no curto alcance."
	p3.base_color = Color(1, 0.65, 0.3)
	if ShotgunWeapon != null: p3.starting_weapons = [ShotgunWeapon]
	list.append(p3)

	var p4 := CharacterPreset.new()
	p4.name = "Atirador"
	p4.description = "Sniper de longa distância. Dano altíssimo, recarga lenta."
	p4.base_color = Color(0.75, 0.5, 1)
	if SniperWeapon != null: p4.starting_weapons = [SniperWeapon]
	list.append(p4)

	return list
