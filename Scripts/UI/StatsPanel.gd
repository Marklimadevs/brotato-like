extends CanvasLayer

var _root: Control
var _stats_list: VBoxContainer
var _weapons_list: VBoxContainer
var _hint: Label

var _hp_val: Label
var _dmg_val: Label
var _atk_spd_val: Label
var _move_val: Label
var _pickup_val: Label
var _xp_val: Label
var _crit_val: Label
var _crit_dmg_val: Label
var _armor_val: Label
var _regen_val: Label
var _knock_val: Label

var _weapon_rows: Array = []  # Array of Dictionary { box, name, damage, fire_rate, range, bullet_speed }
var _user_toggled: bool = false
var _forced_visible: bool = false
var _refresh_timer: float = 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	_root.visible = false

	GameManager.level_up.connect(_on_force_show)
	GameManager.level_up_closed.connect(_on_force_hide)
	GameManager.shop_opened.connect(_on_force_show)
	GameManager.shop_closed.connect(_on_force_hide)
	GameManager.player_died.connect(_on_player_died)


func _exit_tree() -> void:
	if GameManager == null: return
	for sig_name_pair in [
		["level_up", _on_force_show], ["level_up_closed", _on_force_hide],
		["shop_opened", _on_force_show], ["shop_closed", _on_force_hide],
		["player_died", _on_player_died],
	]:
		var sig_name: String = sig_name_pair[0]
		var handler: Callable = sig_name_pair[1]
		var sig: Signal = GameManager.get(sig_name)
		if sig.is_connected(handler):
			sig.disconnect(handler)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("stats_toggle"):
		_user_toggled = not _user_toggled
		_update_visibility()
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if not _root.visible:
		return
	_refresh_timer -= delta
	if _refresh_timer <= 0.0:
		_refresh_timer = 0.15
		_refresh()


func _on_force_show() -> void:
	_forced_visible = true
	_update_visibility()
	_refresh()


func _on_force_hide() -> void:
	_forced_visible = false
	_update_visibility()


func _on_player_died() -> void:
	_user_toggled = false
	_forced_visible = false
	_update_visibility()


func _update_visibility() -> void:
	_root.visible = _user_toggled or _forced_visible
	if _hint != null:
		_hint.visible = not _forced_visible


func _refresh() -> void:
	var p: Player = GameManager.Player
	if p == null or not p.is_alive() or p.Stats == null:
		return

	_hp_val.text = "%d / %d" % [maxi(0, p.Stats.CurrentHp), p.Stats.MaxHp]
	_dmg_val.text = "+%d" % p.Stats.BonusDamage
	_atk_spd_val.text = "%d%%" % int(round(p.Stats.AttackSpeedMult * 100.0))
	_move_val.text = "%d" % int(p.Stats.MoveSpeed)
	_pickup_val.text = "%d" % int(p.Stats.PickupRadius)
	_xp_val.text = "%d%%" % int(round(p.Stats.XpGainMult * 100.0))
	_crit_val.text = "%d%%" % int(round(p.Stats.CritChance * 100.0))
	_crit_dmg_val.text = "×%.2f" % p.Stats.CritMultiplier
	_armor_val.text = "%d" % p.Stats.Armor
	_regen_val.text = "%.1f/s" % p.Stats.HpRegenPerSec
	_knock_val.text = "%d" % int(p.Stats.Knockback)

	var idx: int = 0
	for w in p.get_active_weapons():
		if w == null or w.Data == null:
			continue
		while _weapon_rows.size() <= idx:
			_weapon_rows.append(_build_weapon_row())

		var row: Dictionary = _weapon_rows[idx]
		row["box"].visible = true
		row["name"].text = w.Data.WeaponName
		if w.Data.Pellets > 1:
			row["damage"].text = "%d × %d" % [w.get_effective_damage(), w.Data.Pellets]
		else:
			row["damage"].text = "%d" % w.get_effective_damage()
		row["fire_rate"].text = "%.2f/s" % w.get_effective_fire_rate()
		row["range"].text = "%d" % int(w.Data.Reach)
		row["bullet_speed"].text = "%d" % int(w.Data.BulletSpeed)
		idx += 1
	for i in range(idx, _weapon_rows.size()):
		_weapon_rows[i]["box"].visible = false


func _build_ui() -> void:
	_root = Control.new()
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.anchor_right = 1
	_root.anchor_bottom = 1
	add_child(_root)

	var panel := PanelContainer.new()
	panel.anchor_left = 1.0
	panel.anchor_top = 0.0
	panel.anchor_right = 1.0
	panel.anchor_bottom = 1.0
	panel.offset_left = -310
	panel.offset_top = 80
	panel.offset_right = -14
	panel.offset_bottom = -100
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(margin)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	margin.add_child(col)

	col.add_child(_make_title("PLAYER"))
	_stats_list = VBoxContainer.new()
	_stats_list.add_theme_constant_override("separation", 2)
	col.add_child(_stats_list)

	_hp_val = _add_row(_stats_list, "HP")
	_dmg_val = _add_row(_stats_list, "Bonus Damage")
	_atk_spd_val = _add_row(_stats_list, "Attack Speed")
	_move_val = _add_row(_stats_list, "Move Speed")
	_pickup_val = _add_row(_stats_list, "Pickup Radius")
	_xp_val = _add_row(_stats_list, "XP Gain")
	_crit_val = _add_row(_stats_list, "Crit Chance")
	_crit_dmg_val = _add_row(_stats_list, "Crit Damage")
	_armor_val = _add_row(_stats_list, "Armor")
	_regen_val = _add_row(_stats_list, "HP Regen")
	_knock_val = _add_row(_stats_list, "Knockback")

	col.add_child(HSeparator.new())
	col.add_child(_make_title("ARMAS"))
	_weapons_list = VBoxContainer.new()
	_weapons_list.add_theme_constant_override("separation", 6)
	col.add_child(_weapons_list)

	_hint = _make_muted_label("Tab para fechar", 11)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(_hint)


func _build_weapon_row() -> Dictionary:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 1)
	_weapons_list.add_child(box)

	var name_label := _make_label("Weapon", 15, true)
	box.add_child(name_label)

	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 1)
	box.add_child(inner)
	var damage := _add_row(inner, "Damage")
	var fire_rate := _add_row(inner, "Fire rate")
	var range_v := _add_row(inner, "Range")
	var bullet_speed := _add_row(inner, "Bullet spd")
	return {
		"box": box,
		"name": name_label,
		"damage": damage,
		"fire_rate": fire_rate,
		"range": range_v,
		"bullet_speed": bullet_speed,
	}


func _add_row(parent: Container, name: String) -> Label:
	var hbox := HBoxContainer.new()
	parent.add_child(hbox)
	var name_label := _make_muted_label(name + ":", 13)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(name_label)
	var value_label := _make_label("0", 13, false)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hbox.add_child(value_label)
	return value_label


func _make_title(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 14)
	l.add_theme_color_override("font_color", Color(0.7, 0.85, 1))
	return l


func _make_label(text: String, font_size: int, bold: bool) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", Color.WHITE if bold else Color(0.95, 0.95, 0.95))
	return l


func _make_muted_label(text: String, font_size: int) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", Color(0.65, 0.7, 0.78))
	return l
