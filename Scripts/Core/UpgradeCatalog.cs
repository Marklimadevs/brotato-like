using System.Collections.Generic;
using Godot;

namespace BrotatoLike;

public static class UpgradeCatalog
{
	public static List<UpgradeResource> All() => BuildCatalog();

	public static ItemRarity RollRarity(RandomNumberGenerator rng, int waveIdx)
	{
		float r = rng.Randf();
		// Waves 1-2 (idx 0-1): mostly Common
		if (waveIdx <= 1)
		{
			if (r < 0.70f) return ItemRarity.Common;
			if (r < 0.95f) return ItemRarity.Uncommon;
			return ItemRarity.Rare;
		}
		// Wave 3 (idx 2): Legendary starts appearing
		if (waveIdx == 2)
		{
			if (r < 0.50f) return ItemRarity.Common;
			if (r < 0.85f) return ItemRarity.Uncommon;
			if (r < 0.97f) return ItemRarity.Rare;
			return ItemRarity.Legendary;
		}
		// Waves 4+: more Uncommon/Rare/Legendary
		if (r < 0.30f) return ItemRarity.Common;
		if (r < 0.65f) return ItemRarity.Uncommon;
		if (r < 0.90f) return ItemRarity.Rare;
		return ItemRarity.Legendary;
	}

	public static UpgradeResource PickFromPool(List<UpgradeResource> pool, RandomNumberGenerator rng, int waveIdx)
	{
		if (pool == null || pool.Count == 0) return null;
		var rarity = RollRarity(rng, waveIdx);
		var byRarity = pool.FindAll(u => u.Rarity == rarity);
		if (byRarity.Count == 0) byRarity = new List<UpgradeResource>(pool);
		var picked = byRarity[rng.RandiRange(0, byRarity.Count - 1)];
		pool.Remove(picked);
		return picked;
	}

	public static Color RarityColor(ItemRarity r) => r switch
	{
		ItemRarity.Common => new Color(0.92f, 0.92f, 0.95f),
		ItemRarity.Uncommon => new Color(0.45f, 1f, 0.55f),
		ItemRarity.Rare => new Color(0.5f, 0.7f, 1f),
		ItemRarity.Legendary => new Color(1f, 0.65f, 0.25f),
		_ => Colors.White,
	};

	public static string RarityLabel(ItemRarity r) => r switch
	{
		ItemRarity.Common => "Comum",
		ItemRarity.Uncommon => "Incomum",
		ItemRarity.Rare => "Raro",
		ItemRarity.Legendary => "Lendário",
		_ => "",
	};

	private static List<UpgradeResource> BuildCatalog()
	{
		return new List<UpgradeResource>
		{
			// ===== COMMON =====
			new UpgradeResource { Title = "+5 HP Máximo", Description = "Aumenta vida máxima e cura 5", Stat = UpgradeStat.MaxHp, Value = 5f, Cost = 5, Rarity = ItemRarity.Common },
			new UpgradeResource { Title = "+25 Velocidade", Description = "Movimentação mais rápida", Stat = UpgradeStat.MoveSpeed, Value = 25f, Cost = 5, Rarity = ItemRarity.Common },
			new UpgradeResource { Title = "+30 Raio de Coleta", Description = "Atrai gemas de mais longe", Stat = UpgradeStat.PickupRadius, Value = 30f, Cost = 5, Rarity = ItemRarity.Common },
			new UpgradeResource { Title = "+50 Knockback", Description = "Empurra inimigos atingidos", Stat = UpgradeStat.Knockback, Value = 50f, Cost = 5, Rarity = ItemRarity.Common },
			new UpgradeResource { Title = "+1 Armadura", Description = "Reduz dano recebido (mín 1)", Stat = UpgradeStat.Armor, Value = 1f, Cost = 7, Rarity = ItemRarity.Common },
			new UpgradeResource { Title = "+1 Dano", Description = "Bônus de dano em todas as armas", Stat = UpgradeStat.BonusDamage, Value = 1f, Cost = 8, Rarity = ItemRarity.Common },

			// ===== UNCOMMON =====
			new UpgradeResource { Title = "+15% Atk Speed", Description = "Atira mais rápido", Stat = UpgradeStat.AttackSpeedMult, Value = 0.15f, Cost = 8, Rarity = ItemRarity.Uncommon },
			new UpgradeResource { Title = "+25% XP", Description = "Mais XP por gema coletada", Stat = UpgradeStat.XpGainMult, Value = 0.25f, Cost = 8, Rarity = ItemRarity.Uncommon },
			new UpgradeResource { Title = "+5% Crítico", Description = "Chance de crítico (×2 dano)", Stat = UpgradeStat.CritChance, Value = 0.05f, Cost = 9, Rarity = ItemRarity.Uncommon },
			new UpgradeResource { Title = "+0.5 Regen HP/s", Description = "Recupera HP automaticamente", Stat = UpgradeStat.HpRegenPerSec, Value = 0.5f, Cost = 10, Rarity = ItemRarity.Uncommon },
			new UpgradeResource { Title = "+10 HP Máximo", Description = "Bônus maior de vida (cura 10)", Stat = UpgradeStat.MaxHp, Value = 10f, Cost = 12, Rarity = ItemRarity.Uncommon },
			new UpgradeResource { Title = "Pílula Vermelha", Description = "+15 HP, mas −20 Velocidade", Stat = UpgradeStat.MaxHp, Value = 15f, Cost = 8, Rarity = ItemRarity.Uncommon, HasSecondaryEffect = true, SecondaryStat = UpgradeStat.MoveSpeed, SecondaryValue = -20f },
			new UpgradeResource { Title = "Botas de Corrida", Description = "+30 Velocidade, mas −1 Dano", Stat = UpgradeStat.MoveSpeed, Value = 30f, Cost = 10, Rarity = ItemRarity.Uncommon, HasSecondaryEffect = true, SecondaryStat = UpgradeStat.BonusDamage, SecondaryValue = -1f },

			// ===== RARE =====
			new UpgradeResource { Title = "+25% Dano Crítico", Description = "Multiplicador maior em críticos", Stat = UpgradeStat.CritMultiplier, Value = 0.25f, Cost = 13, Rarity = ItemRarity.Rare },
			new UpgradeResource { Title = "+2 Dano", Description = "Bônus dobrado de dano", Stat = UpgradeStat.BonusDamage, Value = 2f, Cost = 14, Rarity = ItemRarity.Rare },
			new UpgradeResource { Title = "Adrenalina", Description = "+15% Atk Speed e +20 Velocidade", Stat = UpgradeStat.AttackSpeedMult, Value = 0.15f, Cost = 15, Rarity = ItemRarity.Rare, HasSecondaryEffect = true, SecondaryStat = UpgradeStat.MoveSpeed, SecondaryValue = 20f },
			new UpgradeResource { Title = "Capacete", Description = "+10 HP e +1 Armadura", Stat = UpgradeStat.MaxHp, Value = 10f, Cost = 15, Rarity = ItemRarity.Rare, HasSecondaryEffect = true, SecondaryStat = UpgradeStat.Armor, SecondaryValue = 1f },
			new UpgradeResource { Title = "Munição Pesada", Description = "+2 Dano, mas −10% Atk Speed", Stat = UpgradeStat.BonusDamage, Value = 2f, Cost = 16, Rarity = ItemRarity.Rare, HasSecondaryEffect = true, SecondaryStat = UpgradeStat.AttackSpeedMult, SecondaryValue = -0.1f },
			new UpgradeResource { Title = "Munição Leve", Description = "+20% Atk Speed, mas −1 Dano", Stat = UpgradeStat.AttackSpeedMult, Value = 0.20f, Cost = 12, Rarity = ItemRarity.Rare, HasSecondaryEffect = true, SecondaryStat = UpgradeStat.BonusDamage, SecondaryValue = -1f },

			// ===== LEGENDARY =====
			new UpgradeResource { Title = "Coração de Aço", Description = "+15 HP e +1 Regen HP/s", Stat = UpgradeStat.MaxHp, Value = 15f, Cost = 22, Rarity = ItemRarity.Legendary, HasSecondaryEffect = true, SecondaryStat = UpgradeStat.HpRegenPerSec, SecondaryValue = 1f },
			new UpgradeResource { Title = "Olho de Falcão", Description = "+10% Crítico e +50% Dano Crítico", Stat = UpgradeStat.CritChance, Value = 0.10f, Cost = 25, Rarity = ItemRarity.Legendary, HasSecondaryEffect = true, SecondaryStat = UpgradeStat.CritMultiplier, SecondaryValue = 0.5f },
			new UpgradeResource { Title = "Vingança", Description = "+3 Dano e +30 Knockback", Stat = UpgradeStat.BonusDamage, Value = 3f, Cost = 20, Rarity = ItemRarity.Legendary, HasSecondaryEffect = true, SecondaryStat = UpgradeStat.Knockback, SecondaryValue = 30f },
			new UpgradeResource { Title = "Aço Carmesim", Description = "+20 HP e +2 Armadura", Stat = UpgradeStat.MaxHp, Value = 20f, Cost = 24, Rarity = ItemRarity.Legendary, HasSecondaryEffect = true, SecondaryStat = UpgradeStat.Armor, SecondaryValue = 2f },
			new UpgradeResource { Title = "Berserker", Description = "+3 Dano e +25% Atk Speed", Stat = UpgradeStat.BonusDamage, Value = 3f, Cost = 28, Rarity = ItemRarity.Legendary, HasSecondaryEffect = true, SecondaryStat = UpgradeStat.AttackSpeedMult, SecondaryValue = 0.25f },
		};
	}
}
