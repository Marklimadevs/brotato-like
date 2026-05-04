class_name UpgradeResource
extends Resource

enum UpgradeStat {
	MAX_HP,
	BONUS_DAMAGE,
	ATTACK_SPEED_MULT,
	MOVE_SPEED,
	PICKUP_RADIUS,
	XP_GAIN_MULT,
	CRIT_CHANCE,
	CRIT_MULTIPLIER,
	ARMOR,
	HP_REGEN_PER_SEC,
	KNOCKBACK,
}

enum ItemRarity {
	COMMON,
	UNCOMMON,
	RARE,
	LEGENDARY,
}

@export var Title: String = "Upgrade"
@export_multiline var Description: String = ""
@export var Stat: UpgradeStat = UpgradeStat.MAX_HP
@export var Value: float = 1.0
@export var Cost: int = 5
@export var Rarity: ItemRarity = ItemRarity.COMMON
@export var HasSecondaryEffect: bool = false
@export var SecondaryStat: UpgradeStat = UpgradeStat.MAX_HP
@export var SecondaryValue: float = 0.0


func apply(stats: Stats) -> void:
	_apply_stat(stats, Stat, Value)
	if HasSecondaryEffect:
		_apply_stat(stats, SecondaryStat, SecondaryValue)


static func _apply_stat(stats: Stats, key: UpgradeStat, value: float) -> void:
	match key:
		UpgradeStat.MAX_HP:
			var amt: int = int(value)
			stats.MaxHp = maxi(1, stats.MaxHp + amt)
			if amt > 0:
				stats.CurrentHp = mini(stats.MaxHp, stats.CurrentHp + amt)
			else:
				stats.CurrentHp = mini(stats.MaxHp, stats.CurrentHp)
		UpgradeStat.BONUS_DAMAGE:
			stats.BonusDamage += int(value)
		UpgradeStat.ATTACK_SPEED_MULT:
			stats.AttackSpeedMult = maxf(0.1, stats.AttackSpeedMult + value)
		UpgradeStat.MOVE_SPEED:
			stats.MoveSpeed = maxf(40.0, stats.MoveSpeed + value)
		UpgradeStat.PICKUP_RADIUS:
			stats.PickupRadius += value
		UpgradeStat.XP_GAIN_MULT:
			stats.XpGainMult += value
		UpgradeStat.CRIT_CHANCE:
			stats.CritChance = clampf(stats.CritChance + value, 0.0, 1.0)
		UpgradeStat.CRIT_MULTIPLIER:
			stats.CritMultiplier += value
		UpgradeStat.ARMOR:
			stats.Armor += int(value)
		UpgradeStat.HP_REGEN_PER_SEC:
			stats.HpRegenPerSec += value
		UpgradeStat.KNOCKBACK:
			stats.Knockback += value
