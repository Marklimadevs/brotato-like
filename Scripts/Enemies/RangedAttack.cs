using Godot;

namespace BrotatoLike;

public partial class RangedAttack : Node
{
	public PackedScene EnemyBulletScene;
	public float FireInterval = 2f;
	public int Damage = 5;
	public float BulletSpeed = 300f;

	private EnemyBase _shooter;
	private Timer _timer;

	public override void _Ready()
	{
		_shooter = GetParent<EnemyBase>();
		_timer = new Timer { WaitTime = FireInterval, Autostart = true };
		_timer.Timeout += OnFire;
		AddChild(_timer);
	}

	private void OnFire()
	{
		if (_shooter == null || !IsInstanceValid(_shooter)) return;
		var player = GameManager.Instance.Player;
		if (player == null || !player.IsAlive) return;
		if (EnemyBulletScene == null) return;

		var aimDir = (player.GlobalPosition - _shooter.GlobalPosition).Normalized();
		var bullet = EnemyBulletScene.Instantiate<EnemyBullet>();
		bullet.Direction = aimDir;
		bullet.Speed = BulletSpeed;
		var diff = DifficultyConfig.GetMultipliers(GameManager.Instance.SelectedDifficulty);
		bullet.Damage = Mathf.Max(1, (int)(Damage * diff.DamageMult));
		_shooter.GetTree().CurrentScene.AddChild(bullet);
		bullet.GlobalPosition = _shooter.GlobalPosition;
	}
}
