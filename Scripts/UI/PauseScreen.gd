extends CanvasLayer

var _root: Control
var _is_paused: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	_root.visible = false


func _input(event: InputEvent) -> void:
	if not event.is_action_pressed("pause"):
		return
	if _is_paused:
		_resume()
		get_viewport().set_input_as_handled()
	elif not get_tree().paused:
		_pause()
		get_viewport().set_input_as_handled()


func _pause() -> void:
	_is_paused = true
	get_tree().paused = true
	_root.visible = true


func _resume() -> void:
	_is_paused = false
	get_tree().paused = false
	_root.visible = false


func _on_menu() -> void:
	_is_paused = false
	get_tree().paused = false
	GameManager.reset_run_state()
	get_tree().change_scene_to_file("res://Scenes/CharacterSelect.tscn")


func _build_ui() -> void:
	_root = Control.new()
	_root.anchor_right = 1
	_root.anchor_bottom = 1
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)

	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.7)
	bg.anchor_right = 1
	bg.anchor_bottom = 1
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.add_child(bg)

	var panel := PanelContainer.new()
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -220
	panel.offset_top = -160
	panel.offset_right = 220
	panel.offset_bottom = 160
	_root.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 22)
	margin.add_theme_constant_override("margin_bottom", 22)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	margin.add_child(vbox)

	var title := Label.new()
	title.text = "PAUSADO"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 36)
	vbox.add_child(title)

	var hint := Label.new()
	hint.text = "Esc para continuar  ·  Tab para ver stats"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 13)
	hint.add_theme_color_override("font_color", Color(0.7, 0.75, 0.85))
	vbox.add_child(hint)

	var resume_btn := Button.new()
	resume_btn.text = "Continuar (Esc)"
	resume_btn.custom_minimum_size = Vector2(340, 48)
	resume_btn.add_theme_font_size_override("font_size", 16)
	resume_btn.pressed.connect(_resume)
	vbox.add_child(resume_btn)

	var menu_btn := Button.new()
	menu_btn.text = "Trocar personagem"
	menu_btn.custom_minimum_size = Vector2(340, 40)
	menu_btn.add_theme_font_size_override("font_size", 14)
	menu_btn.pressed.connect(_on_menu)
	vbox.add_child(menu_btn)

	# Separator + título de áudio
	vbox.add_child(HSeparator.new())
	var audio_title := Label.new()
	audio_title.text = "ÁUDIO"
	audio_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	audio_title.add_theme_font_size_override("font_size", 14)
	audio_title.add_theme_color_override("font_color", Color(0.7, 0.85, 1))
	vbox.add_child(audio_title)

	_add_volume_slider(vbox, "Master", AudioManager.master_volume, AudioManager.set_master_volume)
	_add_volume_slider(vbox, "Música", AudioManager.music_volume, AudioManager.set_music_volume)
	_add_volume_slider(vbox, "Efeitos", AudioManager.sfx_volume, AudioManager.set_sfx_volume)


func _add_volume_slider(parent: VBoxContainer, label_text: String, initial_value: float, on_change: Callable) -> void:
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	parent.add_child(hbox)

	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(80, 0)
	label.add_theme_font_size_override("font_size", 13)
	hbox.add_child(label)

	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.01
	slider.value = initial_value
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.custom_minimum_size = Vector2(180, 24)
	hbox.add_child(slider)

	var value_label := Label.new()
	value_label.text = "%d%%" % int(initial_value * 100)
	value_label.custom_minimum_size = Vector2(50, 0)
	value_label.add_theme_font_size_override("font_size", 12)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hbox.add_child(value_label)

	slider.value_changed.connect(func(v: float):
		on_change.call(v)
		value_label.text = "%d%%" % int(v * 100))
