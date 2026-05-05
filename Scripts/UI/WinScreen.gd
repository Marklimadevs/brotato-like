extends CanvasLayer

var _root: Control
var _share_btn: Button
var _share_status: Label


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
	AdsManager.notify_happytime()  # vencer a run = pico de momento positivo
	AudioManager.play_music("victory")


func _on_restart() -> void:
	get_tree().paused = false
	GameManager.reset_run_state()
	get_tree().reload_current_scene()


func _on_menu() -> void:
	get_tree().paused = false
	GameManager.reset_run_state()
	get_tree().change_scene_to_file("res://Scenes/CharacterSelect.tscn")


func _on_share_pressed() -> void:
	if _share_btn == null: return
	_share_btn.disabled = true
	_share_btn.text = "Gerando link..."
	var char_name: String = ""
	if GameManager.SelectedCharacter != null:
		char_name = GameManager.SelectedCharacter.name
	var params: Dictionary = {
		"character": char_name,
		"difficulty": DifficultyConfig.get_label(GameManager.SelectedDifficulty),
	}
	AdsManager.get_invite_link(params, _on_invite_link_received)


func _on_invite_link_received(url: String) -> void:
	if _share_btn == null: return
	_share_btn.disabled = false
	if url.is_empty():
		_share_btn.text = "Compartilhar"
		_share_status.text = "Não foi possível gerar o link."
		return

	# Copia para clipboard via JS API (funciona dentro do iframe do CrazyGames)
	if OS.has_feature("web") and Engine.has_singleton("JavaScriptBridge"):
		var safe_url: String = JSON.stringify(url)
		JavaScriptBridge.eval("""
			try {
				navigator.clipboard.writeText(%s);
			} catch(e) { console.warn('clipboard failed:', e); }
		""" % safe_url, true)
	else:
		print("Invite link: ", url)

	_share_btn.text = "✓ Link copiado!"
	_share_status.text = url


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
	panel.offset_left = -260
	panel.offset_top = -200
	panel.offset_right = 260
	panel.offset_bottom = 200
	_root.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_top", 22)
	margin.add_theme_constant_override("margin_bottom", 22)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
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

	# Share button (CrazyGames inviteLink)
	_share_btn = Button.new()
	_share_btn.text = "Compartilhar"
	_share_btn.custom_minimum_size = Vector2(380, 42)
	_share_btn.add_theme_font_size_override("font_size", 14)
	_share_btn.add_theme_color_override("font_color", Color(0.6, 0.85, 1))
	_share_btn.add_theme_color_override("font_hover_color", Color(0.7, 0.95, 1))
	_share_btn.pressed.connect(_on_share_pressed)
	vbox.add_child(_share_btn)

	_share_status = Label.new()
	_share_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_share_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_share_status.add_theme_font_size_override("font_size", 11)
	_share_status.add_theme_color_override("font_color", Color(0.7, 0.75, 0.85))
	_share_status.custom_minimum_size = Vector2(380, 30)
	vbox.add_child(_share_status)

	var btn := Button.new()
	btn.text = "Jogar de novo (R)"
	btn.custom_minimum_size = Vector2(380, 48)
	btn.add_theme_font_size_override("font_size", 18)
	btn.pressed.connect(_on_restart)
	vbox.add_child(btn)

	var menu_btn := Button.new()
	menu_btn.text = "Trocar personagem"
	menu_btn.custom_minimum_size = Vector2(380, 40)
	menu_btn.add_theme_font_size_override("font_size", 14)
	menu_btn.pressed.connect(_on_menu)
	vbox.add_child(menu_btn)
