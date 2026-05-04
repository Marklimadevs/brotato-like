extends CanvasLayer

var _root: Control
var _title: Label
var _subtitle: Label


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	_root.visible = false
	GameManager.player_died.connect(_on_died)


func _exit_tree() -> void:
	if GameManager != null and GameManager.player_died.is_connected(_on_died):
		GameManager.player_died.disconnect(_on_died)


func _process(_delta: float) -> void:
	if _root.visible and Input.is_action_just_pressed("restart"):
		_on_restart()


func _on_died() -> void:
	var wave: int = 0
	var total_waves: int = 5
	if WaveManager.Instance != null:
		wave = WaveManager.Instance.CurrentWaveIndex + 1
		total_waves = WaveManager.Instance.get_total_waves()
	_subtitle.text = "Você caiu na wave %d de %d" % [wave, total_waves]
	_root.visible = true
	get_tree().paused = true


func _on_restart() -> void:
	get_tree().paused = false
	GameManager.reset_run_state()
	get_tree().reload_current_scene()


func _on_menu() -> void:
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
	bg.color = Color(0.1, 0, 0, 0.7)
	bg.anchor_right = 1
	bg.anchor_bottom = 1
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.add_child(bg)

	var panel := PanelContainer.new()
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -240
	panel.offset_top = -150
	panel.offset_right = 240
	panel.offset_bottom = 150
	_root.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_top", 22)
	margin.add_theme_constant_override("margin_bottom", 22)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	margin.add_child(vbox)

	_title = Label.new()
	_title.text = "GAME OVER"
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override("font_size", 38)
	_title.add_theme_color_override("font_color", Color(1, 0.5, 0.5))
	vbox.add_child(_title)

	_subtitle = Label.new()
	_subtitle.text = "Você caiu"
	_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_subtitle.add_theme_font_size_override("font_size", 16)
	vbox.add_child(_subtitle)

	var btn := Button.new()
	btn.text = "Reiniciar (R)"
	btn.custom_minimum_size = Vector2(380, 52)
	btn.add_theme_font_size_override("font_size", 18)
	btn.pressed.connect(_on_restart)
	vbox.add_child(btn)

	var menu_btn := Button.new()
	menu_btn.text = "Trocar personagem"
	menu_btn.custom_minimum_size = Vector2(380, 40)
	menu_btn.add_theme_font_size_override("font_size", 14)
	menu_btn.pressed.connect(_on_menu)
	vbox.add_child(menu_btn)
