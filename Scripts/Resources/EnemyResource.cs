using Godot;

namespace BrotatoLike;

public enum EnemyShape
{
	Triangle,
	Diamond,
	Spike,
	BossDiamond,
}

[GlobalClass]
public partial class EnemyResource : Resource
{
	[Export] public int MaxHp { get; set; } = 10;
	[Export] public int Damage { get; set; } = 5;
	[Export] public float Speed { get; set; } = 90f;
	[Export] public Color EnemyColor { get; set; } = new(0.9f, 0.4f, 0.3f);
	[Export] public EnemyShape Shape { get; set; } = EnemyShape.Triangle;
	[Export] public int XpDrop { get; set; } = 1;
	[Export] public int MaterialDrop { get; set; } = 1;
	[Export] public float Radius { get; set; } = 12f;
	[Export] public bool IsBoss { get; set; } = false;

	// Splitter
	[Export] public bool SplitsOnDeath { get; set; } = false;
	[Export] public EnemyResource SplitInto { get; set; }
	[Export] public int SplitCount { get; set; } = 2;

	// Charger (periodic dash)
	[Export] public bool IsCharger { get; set; } = false;
	[Export] public float ChargeInterval { get; set; } = 2.5f;
	[Export] public float ChargeDuration { get; set; } = 0.5f;
	[Export] public float ChargeSpeedMult { get; set; } = 4f;

	// Ranged (stops and shoots)
	[Export] public bool HasRangedAttack { get; set; } = false;
	[Export] public float RangedStopDistance { get; set; } = 280f;
	[Export] public float RangedFireInterval { get; set; } = 2f;
	[Export] public int RangedDamage { get; set; } = 5;
	[Export] public float RangedBulletSpeed { get; set; } = 300f;
}
