extends CanvasLayer

const REROLL_COST := 3
const OFFER_SLOTS := 3

@export var ShopWeapon1: WeaponResource
@export var ShopWeapon2: WeaponResource
@export var ShopWeapon3: WeaponResource
@export var ShopWeapon4: WeaponResource

var _root: Control
var _title_label: Label
var _materials_label: Label
var _offer_buttons: Array[Button] = []
var _offer_rich_labels: Array[RichTextLabel] = []
var _lock_buttons: Array[Button] = []
var _reroll_button: Button
var _continue_button: Button
var _sell_list: VBoxContainer
var _sell_header: Label

var _weapon_catalog: Array[WeaponResource] = []
var _current_offers: Array = []  # Array of Dictionary { item, weapon } or null
var _purchased: Array[bool] = []
var _locked: Array[bool] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_weapon_catalog = _build_weapon_catalog()
	_current_offers.resize(OFFER_SLOTS)
	_purchased.resize(OFFER_SLOTS)
	_locked.resize(OFFER_SLOTS)
	for i in range(OFFER_SLOTS):
		_current_offers[i] = null
		_purchased[i] = false
		_locked[i] = false
	_build_ui()
	_root.visible = false

	GameManager.shop_opened.connect(_on_shop_opened)
	GameManager.materials_changed.connect(_update_ui)


func _exit_tree() -> void:
	if GameManager == null: return
	if GameManager.shop_opened.is_connected(_on_shop_opened):
		GameManager.shop_opened.disconnect(_on_shop_opened)
	if GameManager.materials_changed.is_connected(_update_ui):
		GameManager.materials_changed.disconnect(_update_ui)


func _on_shop_opened() -> void:
	_roll_offers()
	_root.visible = true
	get_tree().paused = true
	_update_ui()


func _on_continue() -> void:
	_root.visible = false
	get_tree().paused = false
	GameManager.notify_shop_closed()


func _on_buy(idx: int) -> void:
	if idx < 0 or idx >= OFFER_SLOTS:
		return
	var offer = _current_offers[idx]
	if offer == null or _purchased[idx]:
		return
	var player: Player = GameManager.Player
	if player == null:
		return

	var is_weapon: bool = offer["weapon"] != null
	var cost: int = offer["weapon"].Cost if is_weapon else offer["item"].Cost

	if is_weapon:
		if player.get_equipped_weapon_count() >= Player.MAX_WEAPON_SLOTS:
			return
		if not GameManager.spend_material(cost):
			return
		player.add_weapon(offer["weapon"])
	else:
		if not GameManager.spend_material(cost):
			return
		offer["item"].apply(player.Stats)
	_purchased[idx] = true
	_update_ui()


func _on_reroll() -> void:
	if not GameManager.spend_material(REROLL_COST):
		return
	_roll_offers()
	_update_ui()


func _on_lock_toggle(idx: int, pressed: bool) -> void:
	if idx < 0 or idx >= OFFER_SLOTS:
		return
	_locked[idx] = pressed
	_update_ui()


func _on_sell_weapon(weapon_index: int, sell_value: int) -> void:
	var player: Player = GameManager.Player
	if player == null:
		return
	if not player.remove_weapon_at(weapon_index):
		return
	GameManager.add_material(sell_value)
	_update_ui()


func _roll_offers() -> void:
	var rng: RandomNumberGenerator = GameManager.Rng
	var item_pool: Array[UpgradeResource] = UpgradeCatalog.all()
	var weapon_pool: Array[WeaponResource] = _weapon_catalog.duplicate()
	var wave_idx: int = 0
	if WaveManager.Instance != null:
		wave_idx = WaveManager.Instance.CurrentWaveIndex

	# Remove kept (locked, non-purchased) offers from pools
	for i in range(OFFER_SLOTS):
		if _keep_slot(i):
			var offer = _current_offers[i]
			if offer["weapon"] != null:
				weapon_pool.erase(offer["weapon"])
			else:
				item_pool.erase(offer["item"])

	for i in range(OFFER_SLOTS):
		if not _keep_slot(i):
			_current_offers[i] = _roll_single_offer(item_pool, weapon_pool, rng, wave_idx)
			_purchased[i] = false
			_locked[i] = false


func _keep_slot(i: int) -> bool:
	return _locked[i] and _current_offers[i] != null and not _purchased[i]


func _roll_single_offer(item_pool: Array[UpgradeResource], weapon_pool: Array[WeaponResource], rng: RandomNumberGenerator, wave_idx: int):
	var try_weapon: bool = weapon_pool.size() > 0 and rng.randf() < 0.35
	if try_weapon:
		var idx: int = rng.randi_range(0, weapon_pool.size() - 1)
		var w: WeaponResource = weapon_pool[idx]
		weapon_pool.remove_at(idx)
		return {"item": null, "weapon": w}
	if item_pool.size() > 0:
		var item: UpgradeResource = UpgradeCatalog.pick_from_pool(item_pool, rng, wave_idx)
		if item != null:
			return {"item": item, "weapon": null}
	if weapon_pool.size() > 0:
		var idx: int = rng.randi_range(0, weapon_pool.size() - 1)
		var w: WeaponResource = weapon_pool[idx]
		weapon_pool.remove_at(idx)
		return {"item": null, "weapon": w}
	return null


func _update_ui() -> void:
	var wave: int = 0
	var total_waves: int = 5
	if WaveManager.Instance != null:
		wave = WaveManager.Instance.CurrentWaveIndex + 1
		total_waves = WaveManager.Instance.get_total_waves()
	_title_label.text = "SHOP — Próxima: Wave %d / %d" % [wave + 1, total_waves]
	_materials_label.text = "Materiais: %d" % GameManager.Materials

	var player: Player = GameManager.Player
	var slots_used: int = player.get_equipped_weapon_count() if player != null else 0
	var slots_max: int = Player.MAX_WEAPON_SLOTS

	for i in range(OFFER_SLOTS):
		var btn: Button = _offer_buttons[i]
		var rich: RichTextLabel = _offer_rich_labels[i]
		var lock_btn: Button = _lock_buttons[i]
		var offer = _current_offers[i]

		if offer != null:
			btn.visible = true
			lock_btn.visible = true

			var is_weapon: bool = offer["weapon"] != null
			var cost: int = offer["weapon"].Cost if is_weapon else offer["item"].Cost
			var title: String = ("⚔ " + offer["weapon"].WeaponName) if is_weapon else offer["item"].Title

			if _purchased[i]:
				rich.text = ItemDisplay.format_purchased_bbcode(title)
				btn.disabled = true
				lock_btn.disabled = true
			else:
				if is_weapon:
					rich.text = ItemDisplay.format_shop_weapon_bbcode(offer["weapon"], slots_used, slots_max)
				else:
					rich.text = ItemDisplay.format_shop_item_bbcode(offer["item"])
				var no_mat: bool = GameManager.Materials < cost
				var no_slot: bool = is_weapon and slots_used >= slots_max
				btn.disabled = no_mat or no_slot
				lock_btn.disabled = false

			lock_btn.set_pressed_no_signal(_locked[i])
			lock_btn.modulate = Color(1, 0.85, 0.3) if _locked[i] else Color(0.6, 0.6, 0.65)
		else:
			btn.visible = false
			lock_btn.visible = false

	_reroll_button.text = "Reroll (%d mat)" % REROLL_COST
	_reroll_button.disabled = GameManager.Materials < REROLL_COST

	# Sell list
	for c in _sell_list.get_children():
		c.queue_free()
	if player != null:
		var idx: int = 0
		for w in player.get_active_weapons():
			if w == null or w.Data == null:
				idx += 1
				continue
			var sell_value: int = w.Data.SellValue
			var weapon_index: int = idx
			var sell_btn := RichTooltipButton.new()
			sell_btn.text = "Vender %s  +%d mat" % [w.Data.WeaponName, sell_value]
			sell_btn.custom_minimum_size = Vector2(260, 36)
			sell_btn.tooltip_text = ItemDisplay.format_weapon_tooltip_bbcode(w)
			sell_btn.add_theme_font_size_override("font_size", 14)
			sell_btn.pressed.connect(func(): _on_sell_weapon(weapon_index, sell_value))
			_sell_list.add_child(sell_btn)
			idx += 1
		_sell_header.text = "SUAS ARMAS (%d/%d)" % [slots_used, slots_max]


func _build_ui() -> void:
	_root = Control.new()
	_root.anchor_right = 1
	_root.anchor_bottom = 1
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)

	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.65)
	bg.anchor_right = 1
	bg.anchor_bottom = 1
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.add_child(bg)

	var panel := PanelContainer.new()
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -380
	panel.offset_top = -290
	panel.offset_right = 380
	panel.offset_bottom = 290
	_root.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	panel.add_child(margin)

	var root_col := VBoxContainer.new()
	root_col.add_theme_constant_override("separation", 10)
	margin.add_child(root_col)

	_title_label = Label.new()
	_title_label.text = "SHOP"
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.add_theme_font_size_override("font_size", 20)
	root_col.add_child(_title_label)

	_materials_label = Label.new()
	_materials_label.text = "Materiais: 0"
	_materials_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_materials_label.add_theme_font_size_override("font_size", 16)
	_materials_label.add_theme_color_override("font_color", Color(1, 0.85, 0.4))
	root_col.add_child(_materials_label)

	root_col.add_child(HSeparator.new())

	var two_cols := HBoxContainer.new()
	two_cols.add_theme_constant_override("separation", 16)
	two_cols.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root_col.add_child(two_cols)

	# LEFT — offers
	var left_col := VBoxContainer.new()
	left_col.add_theme_constant_override("separation", 8)
	left_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	two_cols.add_child(left_col)

	var offers_header := Label.new()
	offers_header.text = "À VENDA  (cadeado trava p/ próxima wave)"
	offers_header.add_theme_font_size_override("font_size", 13)
	offers_header.add_theme_color_override("font_color", Color(0.7, 0.85, 1))
	left_col.add_child(offers_header)

	for i in range(OFFER_SLOTS):
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 4)
		left_col.add_child(row)

		var btn := Button.new()
		btn.text = ""
		btn.custom_minimum_size = Vector2(0, 90)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var idx: int = i
		btn.pressed.connect(func(): _on_buy(idx))
		row.add_child(btn)
		_offer_buttons.append(btn)

		var rich := RichTextLabel.new()
		rich.bbcode_enabled = true
		rich.fit_content = true
		rich.scroll_active = false
		rich.anchor_right = 1
		rich.anchor_bottom = 1
		rich.offset_left = 8
		rich.offset_top = 6
		rich.offset_right = -8
		rich.offset_bottom = -6
		rich.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rich.add_theme_font_size_override("normal_font_size", 13)
		rich.add_theme_font_size_override("bold_font_size", 15)
		btn.add_child(rich)
		_offer_rich_labels.append(rich)

		var lock_btn := Button.new()
		lock_btn.text = "🔒"
		lock_btn.toggle_mode = true
		lock_btn.custom_minimum_size = Vector2(50, 90)
		lock_btn.tooltip_text = "Travar item — não vai re-rolar"
		lock_btn.add_theme_font_size_override("font_size", 22)
		var lock_idx: int = i
		lock_btn.toggled.connect(func(pressed: bool): _on_lock_toggle(lock_idx, pressed))
		row.add_child(lock_btn)
		_lock_buttons.append(lock_btn)

	_reroll_button = Button.new()
	_reroll_button.text = "Reroll (%d mat)" % REROLL_COST
	_reroll_button.custom_minimum_size = Vector2(380, 40)
	_reroll_button.add_theme_font_size_override("font_size", 14)
	_reroll_button.pressed.connect(_on_reroll)
	left_col.add_child(_reroll_button)

	# RIGHT — sell
	var right_col := VBoxContainer.new()
	right_col.add_theme_constant_override("separation", 8)
	right_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	two_cols.add_child(right_col)

	_sell_header = Label.new()
	_sell_header.text = "SUAS ARMAS"
	_sell_header.add_theme_font_size_override("font_size", 14)
	_sell_header.add_theme_color_override("font_color", Color(0.7, 0.85, 1))
	right_col.add_child(_sell_header)

	_sell_list = VBoxContainer.new()
	_sell_list.add_theme_constant_override("separation", 4)
	right_col.add_child(_sell_list)

	var sell_hint := Label.new()
	sell_hint.text = "Hover para ver stats  ·  metade do preço"
	sell_hint.add_theme_font_size_override("font_size", 11)
	sell_hint.add_theme_color_override("font_color", Color(0.65, 0.7, 0.78))
	right_col.add_child(sell_hint)

	# CONTINUE row
	root_col.add_child(HSeparator.new())
	_continue_button = Button.new()
	_continue_button.text = "Próxima Wave →"
	_continue_button.custom_minimum_size = Vector2(720, 48)
	_continue_button.add_theme_font_size_override("font_size", 16)
	_continue_button.pressed.connect(_on_continue)
	root_col.add_child(_continue_button)


func _build_weapon_catalog() -> Array[WeaponResource]:
	var list: Array[WeaponResource] = []
	if ShopWeapon1 != null: list.append(ShopWeapon1)
	if ShopWeapon2 != null: list.append(ShopWeapon2)
	if ShopWeapon3 != null: list.append(ShopWeapon3)
	if ShopWeapon4 != null: list.append(ShopWeapon4)
	return list
