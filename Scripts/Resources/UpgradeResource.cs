using Godot;

namespace BrotatoLike;

public enum UpgradeStat
{
	MaxHp,
	BonusDamage,
	AttackSpeedMult,
	MoveSpeed,
	PickupRadius,
	XpGainMult,
	CritChance,
	CritMultiplier,
	Armor,
	HpRegenPerSec,
	Knockback,
}

public enum ItemRarity
{
	Common,
	Uncommon,
	Rare,
	Legendary,
}

[GlobalClass]
public partial class UpgradeResource : Resource
{
	[Export] public string Title { get; set; } = "Upgrade";
	[Export(PropertyHint.MultilineText)] public string Description { get; set; } = "";
	[Export] public UpgradeStat Stat { get; set; } = UpgradeStat.MaxHp;
	[Export] public float Value { get; set; } = 1f;
	[Export] public int Cost { get; set; } = 5;
	[Export] public ItemRarity Rarity { get; set; } = ItemRarity.Common;
	[Export] public bool HasSecondaryEffect { get; set; } = false;
	[Export] public UpgradeStat SecondaryStat { get; set; } = UpgradeStat.MaxHp;
	[Export] public float SecondaryValue { get; set; } = 0f;

	public void Apply(Stats stats)
	{
		ApplyStat(stats, Stat, Value);
		if (HasSecondaryEffect)
			ApplyStat(stats, SecondaryStat, SecondaryValue);
	}

	private static void ApplyStat(Stats stats, UpgradeStat stat, float value)
	{
		switch (stat)
		{
			case UpgradeStat.MaxHp:
				int amt = (int)value;
				stats.MaxHp = Mathf.Max(1, stats.MaxHp + amt);
				if (amt > 0)
					stats.CurrentHp = Mathf.Min(stats.MaxHp, stats.CurrentHp + amt);
				else
					stats.CurrentHp = Mathf.Min(stats.MaxHp, stats.CurrentHp);
				break;
			case UpgradeStat.BonusDamage:
				stats.BonusDamage += (int)value;
				break;
			case UpgradeStat.AttackSpeedMult:
				stats.AttackSpeedMult = Mathf.Max(0.1f, stats.AttackSpeedMult + value);
				break;
			case UpgradeStat.MoveSpeed:
				stats.MoveSpeed = Mathf.Max(40f, stats.MoveSpeed + value);
				break;
			case UpgradeStat.PickupRadius:
				stats.PickupRadius += value;
				break;
			case UpgradeStat.XpGainMult:
				stats.XpGainMult += value;
				break;
			case UpgradeStat.CritChance:
				stats.CritChance = Mathf.Clamp(stats.CritChance + value, 0f, 1f);
				break;
			case UpgradeStat.CritMultiplier:
				stats.CritMultiplier += value;
				break;
			case UpgradeStat.Armor:
				stats.Armor += (int)value;
				break;
			case UpgradeStat.HpRegenPerSec:
				stats.HpRegenPerSec += value;
				break;
			case UpgradeStat.Knockback:
				stats.Knockback += value;
				break;
		}
	}
}
