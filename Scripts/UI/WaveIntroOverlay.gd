extends CanvasLayer

var _label: Label
var _current_tween: Tween = null


func _ready() -> void:
	layer = 4
	_build_ui()
	call_deferred("_subscribe_to_wave_manager")


func _subscribe_to_wave_manager() -> void:
	if WaveManager.Instance == null:
		return
	WaveManager.Instance.wave_started.connect(_on_wave_started)
	WaveManager.Instance.boss_spawned.connect(_on_boss_spawned)


func _exit_tree() -> void:
	if WaveManager.Instance != null:
		if WaveManager.Instance.wave_started.is_connected(_on_wave_started):
			WaveManager.Instance.wave_started.disconnect(_on_wave_started)
		if WaveManager.Instance.boss_spawned.is_connected(_on_boss_spawned):
			WaveManager.Instance.boss_spawned.disconnect(_on_boss_spawned)


func _on_wave_started() -> void:
	var wm: WaveManager = WaveManager.Instance
	if wm == null:
		return
	var is_last: bool = wm.CurrentWaveIndex == wm.get_total_waves() - 1
	var text: String = "WAVE FINAL" if is_last else "WAVE %d" % (wm.CurrentWaveIndex + 1)
	_show_text(text, Color(1, 1, 1), 56, 1.0)


func _on_boss_spawned() -> void:
	_show_text("⚠  BOSS  ⚠", Color(1, 0.45, 0.85), 70, 1.4)
	var player: Player = GameManager.Player
	if player != null and is_instance_valid(player):
		var cam: CameraShake = player.get_node_or_null("Camera2D") as CameraShake
		if cam != null:
			cam.shake(28.0)


func _show_text(text: String, color: Color, font_size: int, hold_seconds: float) -> void:
	_label.text = text
	_label.add_theme_font_size_override("font_size", font_size)
	_label.add_theme_color_override("font_color", color)
	_label.modulate = Color(1, 1, 1, 0)
	_label.visible = true

	if _current_tween != null and _current_tween.is_valid():
		_current_tween.kill()

	_current_tween = create_tween()
	_current_tween.tween_property(_label, "modulate:a", 1.0, 0.3)
	_current_tween.tween_interval(hold_seconds)
	_current_tween.tween_property(_label, "modulate:a", 0.0, 0.5)
	_current_tween.tween_callback(_hide_label)


func _hide_label() -> void:
	if _label != null and is_instance_valid(_label):
		_label.visible = false


func _build_ui() -> void:
	_label = Label.new()
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.anchor_left = 0.5
	_label.anchor_top = 0.5
	_label.anchor_right = 0.5
	_label.anchor_bottom = 0.5
	_label.offset_left = -360
	_label.offset_top = -80
	_label.offset_right = 360
	_label.offset_bottom = 80
	_label.visible = false
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_label.add_theme_constant_override("outline_size", 10)
	add_child(_label)
