extends CanvasLayer

var _root: Control


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	_root.visible = false
	# WaveManager pode não estar pronto no _ready ainda — usa CallDeferred
	call_deferred("_subscribe_to_wave")


func _subscribe_to_wave() -> void:
	if WaveManager.Instance != null:
		WaveManager.Instance.game_won_event.connect(_on_game_won)


func _exit_tree() -> void:
	if WaveManager.Instance != null and WaveManager.Instance.game_won_event.is_connected(_on_game_won):
		WaveManager.Instance.game_won_event.disconnect(_on_game_won)


func _process(_delta: float) -> void:
	if _root.visible and Input.is_action_just_pressed("restart"):
		_on_restart()


func _on_game_won() -> void:
	SaveData.notify_difficulty_completed(GameManager.SelectedDifficulty)
	_root.visible = true
	get_tree().paused = true
	AdsManager.notify_gameplay_stop()


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
	bg.color = Color(0, 0.1, 0, 0.7)
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

	var title := Label.new()
	title.text = "VITÓRIA!"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 44)
	title.add_theme_color_override("font_color", Color(0.5, 1, 0.5))
	vbox.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Você sobreviveu às 5 waves"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 16)
	vbox.add_child(subtitle)

	var btn := Button.new()
	btn.text = "Jogar de novo (R)"
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
