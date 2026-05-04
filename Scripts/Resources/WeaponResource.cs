using Godot;

namespace BrotatoLike;

[GlobalClass]
public partial class WeaponResource : Resource
{
	[Export] public string WeaponName { get; set; } = "Pistol";
	[Export] public int Cost { get; set; } = 10;
	[Export] public int Damage { get; set; } = 4;
	[Export] public float Cooldown { get; set; } = 0.55f;
	[Export] public float Range { get; set; } = 380f;
	[Export] public float BulletSpeed { get; set; } = 700f;
	[Export] public float BulletRadius { get; set; } = 5f;
	[Export] public Color ProjectileColor { get; set; } = new(1f, 0.95f, 0.5f);
	[Export] public PackedScene BulletScene { get; set; }
	[Export] public Color BarrelColor { get; set; } = new(0.55f, 0.55f, 0.6f);
	[Export] public float BarrelLength { get; set; } = 18f;
	[Export] public float BarrelWidth { get; set; } = 6f;
	[Export] public int Pellets { get; set; } = 1;
	[Export] public float SpreadAngleDeg { get; set; } = 0f;
	[Export] public int Pierce { get; set; } = 0; // bullet passes through N extra enemies

	public int SellValue => Mathf.Max(1, Cost / 2);
}
