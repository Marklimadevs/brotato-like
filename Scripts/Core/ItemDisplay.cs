using System.Text;
using System.Text.RegularExpressions;
using Godot;

namespace BrotatoLike;

public static class ItemDisplay
{
	private static readonly Regex SignedNumberRegex = new(@"([+\-−])(\d+(?:\.\d+)?%?)", RegexOptions.Compiled);

	public static string FormatItemBBCode(UpgradeResource item)
	{
		var rarityHex = ToHex(UpgradeCatalog.RarityColor(item.Rarity));
		var rarityLabel = UpgradeCatalog.RarityLabel(item.Rarity);
		var desc = ColorizeDescription(item.Description);

		var sb = new StringBuilder();
		sb.Append($"[center][color=#{rarityHex}][b]{item.Title}[/b]   ·   {rarityLabel}[/color]\n");
		sb.Append($"[color=#dddddd]{desc}[/color][/center]");
		return sb.ToString();
	}

	public static string FormatShopItemBBCode(UpgradeResource item)
	{
		var rarityHex = ToHex(UpgradeCatalog.RarityColor(item.Rarity));
		var rarityLabel = UpgradeCatalog.RarityLabel(item.Rarity);
		var desc = ColorizeDescription(item.Description);

		var sb = new StringBuilder();
		sb.Append($"[center][color=#{rarityHex}][b]{item.Title}[/b]   ·   {rarityLabel}[/color]\n");
		sb.Append($"[color=#dddddd]{desc}[/color]\n");
		sb.Append($"[color=#ffd84a]{item.Cost} mat[/color][/center]");
		return sb.ToString();
	}

	public static string FormatShopWeaponBBCode(WeaponResource w, int slotsUsed, int slotsMax)
	{
		var rarityHex = ToHex(UpgradeCatalog.RarityColor(ItemRarity.Rare));
		string dmg = w.Pellets > 1 ? $"{w.Damage}×{w.Pellets}" : $"{w.Damage}";
		string extra = w.Pierce > 0 ? $", Penetra {w.Pierce + 1}" : "";
		var sb = new StringBuilder();
		sb.Append($"[center][color=#{rarityHex}][b]⚔ {w.WeaponName}[/b]   ·   Arma[/color]\n");
		sb.Append($"[color=#dddddd]Dmg [color=#8aff8a]{dmg}[/color], CD {w.Cooldown:F2}s, Range {w.Range:F0}{extra}[/color]\n");
		sb.Append($"[color=#ffd84a]{w.Cost} mat[/color]   [color=#888888]({slotsUsed}/{slotsMax} slots)[/color][/center]");
		return sb.ToString();
	}

	public static string FormatPurchasedBBCode(string title)
	{
		return $"[center][color=#888888]✓ {title} — comprado[/color][/center]";
	}

	public static string FormatWeaponTooltipBBCode(Weapon w)
	{
		if (w?.Resource == null) return "";
		var res = w.Resource;
		var sb = new StringBuilder();
		sb.Append($"[b][color=#8acaff]⚔ {res.WeaponName}[/color][/b]\n");
		sb.Append("[color=#555555]─────────────────[/color]\n");

		string dmgLine;
		int totalDmg = w.EffectiveDamage;
		if (res.Pellets > 1)
			dmgLine = $"Dano: [color=#8aff8a]{totalDmg} × {res.Pellets}[/color]  (max {totalDmg * res.Pellets})";
		else
			dmgLine = $"Dano: [color=#8aff8a]{totalDmg}[/color]";
		sb.Append(dmgLine + "\n");

		sb.Append($"Fire rate: [color=#8aff8a]{w.EffectiveFireRate:F2}/s[/color]  (CD {res.Cooldown:F2}s)\n");
		sb.Append($"Range: [color=#8aff8a]{res.Range:F0}[/color]\n");
		sb.Append($"Vel. bullet: {res.BulletSpeed:F0}\n");

		if (res.Pellets > 1 && res.SpreadAngleDeg > 0)
			sb.Append($"Spread: {res.SpreadAngleDeg:F0}°\n");

		if (res.Pierce > 0)
			sb.Append($"Penetração: [color=#8aff8a]{res.Pierce + 1} inimigos[/color]\n");

		sb.Append("[color=#555555]─────────────────[/color]\n");
		sb.Append($"Comprou por [color=#ffd84a]{res.Cost} mat[/color]   ·   Vende por [color=#ffd84a]{res.SellValue} mat[/color]");
		return sb.ToString();
	}

	public static string ColorizeDescription(string desc)
	{
		if (string.IsNullOrEmpty(desc)) return desc;
		return SignedNumberRegex.Replace(desc, m =>
		{
			var sign = m.Groups[1].Value;
			var value = m.Groups[2].Value;
			bool negative = sign == "-" || sign == "−";
			string colorHex = negative ? "ff5050" : "8aff8a";
			return $"[color=#{colorHex}]{sign}{value}[/color]";
		});
	}

	private static string ToHex(Color c)
	{
		int r = Mathf.Clamp((int)(c.R * 255f), 0, 255);
		int g = Mathf.Clamp((int)(c.G * 255f), 0, 255);
		int b = Mathf.Clamp((int)(c.B * 255f), 0, 255);
		return $"{r:X2}{g:X2}{b:X2}";
	}
}
