class_name ItemDisplay
extends RefCounted

const _SIGNED_NUMBER_REGEX_PATTERN := r"([+\-−])(\d+(?:\.\d+)?%?)"
static var _signed_number_regex: RegEx


static func _ensure_regex() -> void:
	if _signed_number_regex == null:
		_signed_number_regex = RegEx.new()
		_signed_number_regex.compile(_SIGNED_NUMBER_REGEX_PATTERN)


static func format_item_bbcode(item: UpgradeResource) -> String:
	var rarity_hex: String = _to_hex(UpgradeCatalog.rarity_color(item.Rarity))
	var rarity_label: String = UpgradeCatalog.rarity_label(item.Rarity)
	var desc: String = colorize_description(item.Description)
	return "[center][color=#%s][b]%s[/b]   ·   %s[/color]\n[color=#dddddd]%s[/color][/center]" % [rarity_hex, item.Title, rarity_label, desc]


static func format_shop_item_bbcode(item: UpgradeResource) -> String:
	var rarity_hex: String = _to_hex(UpgradeCatalog.rarity_color(item.Rarity))
	var rarity_label: String = UpgradeCatalog.rarity_label(item.Rarity)
	var desc: String = colorize_description(item.Description)
	return "[center][color=#%s][b]%s[/b]   ·   %s[/color]\n[color=#dddddd]%s[/color]\n[color=#ffd84a]%d mat[/color][/center]" % [rarity_hex, item.Title, rarity_label, desc, item.Cost]


static func format_shop_weapon_bbcode(w: WeaponResource, slots_used: int, slots_max: int) -> String:
	var rarity_hex: String = _to_hex(UpgradeCatalog.rarity_color(UpgradeResource.ItemRarity.RARE))
	var dmg_str: String = "%d×%d" % [w.Damage, w.Pellets] if w.Pellets > 1 else "%d" % w.Damage
	var extra: String = ", Penetra %d" % (w.Pierce + 1) if w.Pierce > 0 else ""
	return "[center][color=#%s][b]⚔ %s[/b]   ·   Arma[/color]\n[color=#dddddd]Dmg [color=#8aff8a]%s[/color], CD %.2fs, Range %d%s[/color]\n[color=#ffd84a]%d mat[/color]   [color=#888888](%d/%d slots)[/color][/center]" % [
		rarity_hex, w.WeaponName, dmg_str, w.Cooldown, int(w.Reach), extra, w.Cost, slots_used, slots_max
	]


static func format_purchased_bbcode(title: String) -> String:
	return "[center][color=#888888]✓ %s — comprado[/color][/center]" % title


static func format_weapon_tooltip_bbcode(w: Weapon) -> String:
	if w == null or w.Data == null:
		return ""
	var res: WeaponResource = w.Data
	var sb := ""
	sb += "[b][color=#8acaff]⚔ %s[/color][/b]\n" % res.WeaponName
	sb += "[color=#555555]─────────────────[/color]\n"

	var total_dmg: int = w.get_effective_damage()
	if res.Pellets > 1:
		sb += "Dano: [color=#8aff8a]%d × %d[/color]  (max %d)\n" % [total_dmg, res.Pellets, total_dmg * res.Pellets]
	else:
		sb += "Dano: [color=#8aff8a]%d[/color]\n" % total_dmg

	sb += "Fire rate: [color=#8aff8a]%.2f/s[/color]  (CD %.2fs)\n" % [w.get_effective_fire_rate(), res.Cooldown]
	sb += "Range: [color=#8aff8a]%d[/color]\n" % int(res.Reach)
	sb += "Vel. bullet: %d\n" % int(res.BulletSpeed)

	if res.Pellets > 1 and res.SpreadAngleDeg > 0:
		sb += "Spread: %d°\n" % int(res.SpreadAngleDeg)

	if res.Pierce > 0:
		sb += "Penetração: [color=#8aff8a]%d inimigos[/color]\n" % (res.Pierce + 1)

	sb += "[color=#555555]─────────────────[/color]\n"
	sb += "Comprou por [color=#ffd84a]%d mat[/color]   ·   Vende por [color=#ffd84a]%d mat[/color]" % [res.Cost, res.SellValue]
	return sb


static func colorize_description(desc: String) -> String:
	if desc.is_empty():
		return desc
	_ensure_regex()
	var result := ""
	var pos: int = 0
	var matches := _signed_number_regex.search_all(desc)
	for m in matches:
		var start: int = m.get_start()
		var end: int = m.get_end()
		result += desc.substr(pos, start - pos)
		var sign_str: String = m.get_string(1)
		var value_str: String = m.get_string(2)
		var negative: bool = sign_str == "-" or sign_str == "−"
		var color_hex: String = "ff5050" if negative else "8aff8a"
		result += "[color=#%s]%s%s[/color]" % [color_hex, sign_str, value_str]
		pos = end
	result += desc.substr(pos)
	return result


static func _to_hex(c: Color) -> String:
	var r: int = clampi(int(c.r * 255.0), 0, 255)
	var g: int = clampi(int(c.g * 255.0), 0, 255)
	var b: int = clampi(int(c.b * 255.0), 0, 255)
	return "%02X%02X%02X" % [r, g, b]
