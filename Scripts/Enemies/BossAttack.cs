using Godot;

namespace BrotatoLike;

public partial class BossAttack : Node
{
	public PackedScene EnemyBulletScene;
	public float FireInterval = 3.5f;
	public int PelletsPerBurst = 4;
	public float SpreadAngleDeg = 40f;
	public int BulletDamage = 6;
	public float BulletSpeed = 360f;

	private EnemyBase _boss;
	private Timer _timer;

	public override void _Ready()
	{
		_boss = GetParent<EnemyBase>();
		_timer = new Timer { WaitTime = FireInterval, Autostart = true };
		_timer.Timeout += OnFire;
		AddChild(_timer);
	}

	private void OnFire()
	{
		if (_boss == null || !IsInstanceValid(_boss)) return;
		var player = GameManager.Instance.Player;
		if (player == null || !player.IsAlive) return;
		if (EnemyBulletScene == null) return;

		var aimDir = (player.GlobalPosition - _boss.GlobalPosition).Normalized();
		float spread = Mathf.DegToRad(SpreadAngleDeg);

		for (int i = 0; i < PelletsPerBurst; i++)
		{
			float t = PelletsPerBurst == 1
				? 0f
				: (i / (float)(PelletsPerBurst - 1)) - 0.5f;
			var dir = aimDir.Rotated(t * spread);
			SpawnBullet(dir);
		}
	}

	private void SpawnBullet(Vector2 dir)
	{
		var bullet = EnemyBulletScene.Instantiate<EnemyBullet>();
		bullet.Direction = dir;
		bullet.Speed = BulletSpeed;
		var diff = DifficultyConfig.GetMultipliers(GameManager.Instance.SelectedDifficulty);
		bullet.Damage = Mathf.Max(1, (int)(BulletDamage * diff.DamageMult));
		_boss.GetTree().CurrentScene.AddChild(bullet);
		bullet.GlobalPosition = _boss.GlobalPosition;
	}
}
