namespace BrotatoLike;

public class Stats
{
	public int MaxHp = 30;
	public int CurrentHp = 30;
	public int BonusDamage = 0;
	public float AttackSpeedMult = 1f;
	public float MoveSpeed = 260f;
	public float PickupRadius = 80f;
	public float XpGainMult = 1f;

	// M10 — combat depth
	public float CritChance = 0f;
	public float CritMultiplier = 2f;
	public int Armor = 0;
	public float HpRegenPerSec = 0f;
	public float Knockback = 0f;
}
