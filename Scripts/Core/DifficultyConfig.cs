using Godot;

namespace BrotatoLike;

public static class DifficultyConfig
{
	public const int Min = 1;
	public const int Max = 5;

	public struct Multipliers
	{
		public float HpMult;
		public float DamageMult;
		public float SpeedMult;
	}

	public static Multipliers GetMultipliers(int difficulty)
	{
		return Mathf.Clamp(difficulty, Min, Max) switch
		{
			1 => new Multipliers { HpMult = 1.00f, DamageMult = 1.00f, SpeedMult = 1.00f },
			2 => new Multipliers { HpMult = 1.25f, DamageMult = 1.15f, SpeedMult = 1.05f },
			3 => new Multipliers { HpMult = 1.50f, DamageMult = 1.30f, SpeedMult = 1.10f },
			4 => new Multipliers { HpMult = 1.75f, DamageMult = 1.50f, SpeedMult = 1.15f },
			5 => new Multipliers { HpMult = 2.00f, DamageMult = 1.75f, SpeedMult = 1.20f },
			_ => new Multipliers { HpMult = 1.00f, DamageMult = 1.00f, SpeedMult = 1.00f },
		};
	}

	public static string GetLabel(int difficulty) => $"D{Mathf.Clamp(difficulty, Min, Max)}";

	public static string GetDescription(int difficulty)
	{
		var m = GetMultipliers(difficulty);
		if (difficulty == 1) return "Padrão — sem modificadores";
		return $"+{(m.HpMult - 1f) * 100f:F0}% HP  ·  +{(m.DamageMult - 1f) * 100f:F0}% Dano  ·  +{(m.SpeedMult - 1f) * 100f:F0}% Velocidade";
	}
}
