using Godot;

namespace BrotatoLike;

public partial class Weapon : Node2D
{
	[Export] public WeaponResource Resource;

	private Player _player;
	private Timer _timer;
	private EnemyBase _currentTarget;

	public int EffectiveDamage =>
		Resource == null ? 0 : Resource.Damage + (_player?.Stats?.BonusDamage ?? 0);

	public float EffectiveFireRate
	{
		get
		{
			if (Resource == null || Resource.Cooldown <= 0f) return 0f;
			float mult = _player?.Stats?.AttackSpeedMult ?? 1f;
			return mult / Resource.Cooldown;
		}
	}

	public override void _Ready()
	{
		_player = GetParent()?.GetParent<Player>();
		_timer = new Timer { OneShot = false };
		_timer.Timeout += OnTimeout;
		AddChild(_timer);
		UpdateCooldown();
		_timer.Start();
		QueueRedraw();
	}

	public override void _Process(double delta)
	{
		_currentTarget = FindNearestEnemy();
		if (_currentTarget != null)
		{
			var dir = _currentTarget.GlobalPosition - GlobalPosition;
			if (dir.LengthSquared() > 0.01f)
				Rotation = dir.Angle();
		}
	}

	public override void _Draw()
	{
		if (Resource == null) return;
		float l = Resource.BarrelLength;
		float w = Resource.BarrelWidth;
		// Barrel pointing right at origin (+X). Player rotation orients it toward target.
		var rect = new Rect2(4f, -w / 2f, l, w);
		DrawRect(rect, Resource.BarrelColor);
		DrawRect(rect, new Color(0f, 0f, 0f, 0.7f), false, 1f);
		// Tip highlight
		DrawRect(new Rect2(4f + l - 3f, -w / 2f, 3f, w), new Color(1f, 1f, 1f, 0.4f));
	}

	private void UpdateCooldown()
	{
		if (Resource == null) return;
		float mult = _player?.Stats?.AttackSpeedMult ?? 1f;
		_timer.WaitTime = Mathf.Max(0.05f, Resource.Cooldown / mult);
	}

	private void OnTimeout()
	{
		if (Resource == null || Resource.BulletScene == null) return;
		UpdateCooldown();
		if (_currentTarget == null || !IsInstanceValid(_currentTarget))
			_currentTarget = FindNearestEnemy();
		if (_currentTarget == null) return;
		FireAt(_currentTarget);
	}

	private EnemyBase FindNearestEnemy()
	{
		if (Resource == null) return null;
		EnemyBase nearest = null;
		float bestSq = Resource.Range * Resource.Range;
		foreach (var e in GameManager.Instance.Enemies)
		{
			if (!IsInstanceValid(e)) continue;
			float dSq = (e.GlobalPosition - GlobalPosition).LengthSquared();
			if (dSq < bestSq)
			{
				bestSq = dSq;
				nearest = e;
			}
		}
		return nearest;
	}

	private void FireAt(EnemyBase target)
	{
		var aimDir = (target.GlobalPosition - GlobalPosition).Normalized();
		int pellets = Mathf.Max(1, Resource.Pellets);
		float spread = Mathf.DegToRad(Resource.SpreadAngleDeg);

		for (int i = 0; i < pellets; i++)
		{
			Vector2 dir;
			if (pellets == 1 || spread <= 0f)
			{
				dir = aimDir;
			}
			else
			{
				// Distribute pellets evenly across spread cone, centered on aim
				float t = (i / (float)(pellets - 1)) - 0.5f; // -0.5 .. 0.5
				dir = aimDir.Rotated(t * spread);
			}
			SpawnPellet(dir);
		}
	}

	private void SpawnPellet(Vector2 dir)
	{
		var bullet = Resource.BulletScene.Instantiate<Bullet>();
		bullet.Direction = dir;
		bullet.Speed = Resource.BulletSpeed;
		bullet.Damage = Resource.Damage + (_player?.Stats?.BonusDamage ?? 0);
		bullet.BulletColor = Resource.ProjectileColor;
		bullet.Radius = Resource.BulletRadius;
		bullet.Pierce = Resource.Pierce;
		GetTree().CurrentScene.AddChild(bullet);
		bullet.GlobalPosition = GlobalPosition;
	}
}
