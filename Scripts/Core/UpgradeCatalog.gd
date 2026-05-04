class_name UpgradeCatalog
extends RefCounted


static func all() -> Array[UpgradeResource]:
	return _build_catalog()


static func roll_rarity(rng: RandomNumberGenerator, wave_idx: int) -> int:
	var r: float = rng.randf()
	# Waves 1-2 (idx 0-1): mostly Common
	if wave_idx <= 1:
		if r < 0.70:
			return UpgradeResource.ItemRarity.COMMON
		if r < 0.95:
			return UpgradeResource.ItemRarity.UNCOMMON
		return UpgradeResource.ItemRarity.RARE
	# Wave 3 (idx 2): Legendary starts appearing
	if wave_idx == 2:
		if r < 0.50:
			return UpgradeResource.ItemRarity.COMMON
		if r < 0.85:
			return UpgradeResource.ItemRarity.UNCOMMON
		if r < 0.97:
			return UpgradeResource.ItemRarity.RARE
		return UpgradeResource.ItemRarity.LEGENDARY
	# Waves 4+: more Uncommon/Rare/Legendary
	if r < 0.30:
		return UpgradeResource.ItemRarity.COMMON
	if r < 0.65:
		return UpgradeResource.ItemRarity.UNCOMMON
	if r < 0.90:
		return UpgradeResource.ItemRarity.RARE
	return UpgradeResource.ItemRarity.LEGENDARY


static func pick_from_pool(pool: Array[UpgradeResource], rng: RandomNumberGenerator, wave_idx: int) -> UpgradeResource:
	if pool == null or pool.is_empty():
		return null
	var rarity: int = roll_rarity(rng, wave_idx)
	var by_rarity: Array[UpgradeResource] = []
	for u in pool:
		if u.Rarity == rarity:
			by_rarity.append(u)
	if by_rarity.is_empty():
		by_rarity = pool.duplicate()
	var picked: UpgradeResource = by_rarity[rng.randi_range(0, by_rarity.size() - 1)]
	pool.erase(picked)
	return picked


static func rarity_color(r: int) -> Color:
	match r:
		UpgradeResource.ItemRarity.COMMON: return Color(0.92, 0.92, 0.95)
		UpgradeResource.ItemRarity.UNCOMMON: return Color(0.45, 1, 0.55)
		UpgradeResource.ItemRarity.RARE: return Color(0.5, 0.7, 1)
		UpgradeResource.ItemRarity.LEGENDARY: return Color(1, 0.65, 0.25)
	return Color.WHITE


static func rarity_label(r: int) -> String:
	match r:
		UpgradeResource.ItemRarity.COMMON: return "Comum"
		UpgradeResource.ItemRarity.UNCOMMON: return "Incomum"
		UpgradeResource.ItemRarity.RARE: return "Raro"
		UpgradeResource.ItemRarity.LEGENDARY: return "Lendário"
	return ""


static func _make(title: String, desc: String, stat: int, value: float, cost: int, rarity: int,
		secondary_stat: int = -1, secondary_value: float = 0.0) -> UpgradeResource:
	var u := UpgradeResource.new()
	u.Title = title
	u.Description = desc
	u.Stat = stat
	u.Value = value
	u.Cost = cost
	u.Rarity = rarity
	if secondary_stat >= 0:
		u.HasSecondaryEffect = true
		u.SecondaryStat = secondary_stat
		u.SecondaryValue = secondary_value
	return u


static func _build_catalog() -> Array[UpgradeResource]:
	var US := UpgradeResource.UpgradeStat
	var IR := UpgradeResource.ItemRarity
	var list: Array[UpgradeResource] = [
		# COMMON
		_make("+5 HP Máximo", "Aumenta vida máxima e cura 5", US.MAX_HP, 5.0, 5, IR.COMMON),
		_make("+25 Velocidade", "Movimentação mais rápida", US.MOVE_SPEED, 25.0, 5, IR.COMMON),
		_make("+30 Raio de Coleta", "Atrai gemas de mais longe", US.PICKUP_RADIUS, 30.0, 5, IR.COMMON),
		_make("+50 Knockback", "Empurra inimigos atingidos", US.KNOCKBACK, 50.0, 5, IR.COMMON),
		_make("+1 Armadura", "Reduz dano recebido (mín 1)", US.ARMOR, 1.0, 7, IR.COMMON),
		_make("+1 Dano", "Bônus de dano em todas as armas", US.BONUS_DAMAGE, 1.0, 8, IR.COMMON),

		# UNCOMMON
		_make("+15% Atk Speed", "Atira mais rápido", US.ATTACK_SPEED_MULT, 0.15, 8, IR.UNCOMMON),
		_make("+25% XP", "Mais XP por gema coletada", US.XP_GAIN_MULT, 0.25, 8, IR.UNCOMMON),
		_make("+5% Crítico", "Chance de crítico (×2 dano)", US.CRIT_CHANCE, 0.05, 9, IR.UNCOMMON),
		_make("+0.5 Regen HP/s", "Recupera HP automaticamente", US.HP_REGEN_PER_SEC, 0.5, 10, IR.UNCOMMON),
		_make("+10 HP Máximo", "Bônus maior de vida (cura 10)", US.MAX_HP, 10.0, 12, IR.UNCOMMON),
		_make("Pílula Vermelha", "+15 HP, mas −20 Velocidade", US.MAX_HP, 15.0, 8, IR.UNCOMMON, US.MOVE_SPEED, -20.0),
		_make("Botas de Corrida", "+30 Velocidade, mas −1 Dano", US.MOVE_SPEED, 30.0, 10, IR.UNCOMMON, US.BONUS_DAMAGE, -1.0),

		# RARE
		_make("+25% Dano Crítico", "Multiplicador maior em críticos", US.CRIT_MULTIPLIER, 0.25, 13, IR.RARE),
		_make("+2 Dano", "Bônus dobrado de dano", US.BONUS_DAMAGE, 2.0, 14, IR.RARE),
		_make("Adrenalina", "+15% Atk Speed e +20 Velocidade", US.ATTACK_SPEED_MULT, 0.15, 15, IR.RARE, US.MOVE_SPEED, 20.0),
		_make("Capacete", "+10 HP e +1 Armadura", US.MAX_HP, 10.0, 15, IR.RARE, US.ARMOR, 1.0),
		_make("Munição Pesada", "+2 Dano, mas −10% Atk Speed", US.BONUS_DAMAGE, 2.0, 16, IR.RARE, US.ATTACK_SPEED_MULT, -0.1),
		_make("Munição Leve", "+20% Atk Speed, mas −1 Dano", US.ATTACK_SPEED_MULT, 0.20, 12, IR.RARE, US.BONUS_DAMAGE, -1.0),

		# LEGENDARY
		_make("Coração de Aço", "+15 HP e +1 Regen HP/s", US.MAX_HP, 15.0, 22, IR.LEGENDARY, US.HP_REGEN_PER_SEC, 1.0),
		_make("Olho de Falcão", "+10% Crítico e +50% Dano Crítico", US.CRIT_CHANCE, 0.10, 25, IR.LEGENDARY, US.CRIT_MULTIPLIER, 0.5),
		_make("Vingança", "+3 Dano e +30 Knockback", US.BONUS_DAMAGE, 3.0, 20, IR.LEGENDARY, US.KNOCKBACK, 30.0),
		_make("Aço Carmesim", "+20 HP e +2 Armadura", US.MAX_HP, 20.0, 24, IR.LEGENDARY, US.ARMOR, 2.0),
		_make("Berserker", "+3 Dano e +25% Atk Speed", US.BONUS_DAMAGE, 3.0, 28, IR.LEGENDARY, US.ATTACK_SPEED_MULT, 0.25),
	]
	return list
