using Godot;

namespace BrotatoLike;

public partial class EnemyBase : CharacterBody2D
{
	[Export] public EnemyResource Resource;
	[Export] public PackedScene XpGemScene;

	private int _hp;
	private int _scaledMaxHp;
	private int _scaledDamage;
	private float _scaledSpeed;
	private CollisionShape2D _collisionShape;
	private CircleShape2D _shape;
	private float _flashTimer;
	private bool _dead;

	public int ScaledMaxHp => _scaledMaxHp;
	public int ScaledDamage => _scaledDamage;
	public float ScaledSpeed => _scaledSpeed;

	private Vector2 _knockbackVelocity;
	private float _knockbackTimer;

	// Charger state
	private float _chargeIntervalTimer;
	private float _chargingTimer;
	private bool _isCharging;
	private Vector2 _chargeDir;

	public int CurrentHp => _hp;
	public bool IsBoss => Resource?.IsBoss == true;

	public override void _Ready()
	{
		_collisionShape = GetNode<CollisionShape2D>("CollisionShape2D");
		_shape = (CircleShape2D)_collisionShape.Shape.Duplicate();
		_collisionShape.Shape = _shape;

		if (Resource != null)
			ApplyResource(Resource);

		GameManager.Instance.RegisterEnemy(this);

		if (IsBoss)
			AttachBossAttack();
		else if (Resource?.HasRangedAttack == true)
			AttachRangedAttack();

		if (Resource != null && Resource.IsCharger)
			_chargeIntervalTimer = Resource.ChargeInterval;
	}

	private void AttachBossAttack()
	{
		var bulletScene = GD.Load<PackedScene>("res://Scenes/Bullets/EnemyBullet.tscn");
		if (bulletScene == null) return;
		var attack = new BossAttack { EnemyBulletScene = bulletScene };
		AddChild(attack);
	}

	private void AttachRangedAttack()
	{
		var bulletScene = GD.Load<PackedScene>("res://Scenes/Bullets/EnemyBullet.tscn");
		if (bulletScene == null) return;
		var attack = new RangedAttack
		{
			EnemyBulletScene = bulletScene,
			FireInterval = Resource.RangedFireInterval,
			Damage = Resource.RangedDamage,
			BulletSpeed = Resource.RangedBulletSpeed,
		};
		AddChild(attack);
	}

	public void ApplyResource(EnemyResource res)
	{
		Resource = res;
		var diff = DifficultyConfig.GetMultipliers(GameManager.Instance.SelectedDifficulty);
		_scaledMaxHp = Mathf.Max(1, (int)(res.MaxHp * diff.HpMult));
		_scaledDamage = Mathf.Max(1, (int)(res.Damage * diff.DamageMult));
		_scaledSpeed = res.Speed * diff.SpeedMult;
		_hp = _scaledMaxHp;
		if (_shape != null)
			_shape.Radius = res.Radius;
		QueueRedraw();
	}

	public override void _PhysicsProcess(double delta)
	{
		if (_dead) return;
		var player = GameManager.Instance.Player;
		if (player == null || Resource == null) return;

		float dt = (float)delta;
		Vector2 toPlayer = player.GlobalPosition - GlobalPosition;
		float distToPlayer = toPlayer.Length();
		Vector2 dirToPlayer = distToPlayer > 0.01f ? toPlayer / distToPlayer : Vector2.Zero;

		if (_knockbackTimer > 0f)
		{
			_knockbackTimer -= dt;
			Velocity = _knockbackVelocity;
			_knockbackVelocity = _knockbackVelocity.Lerp(Vector2.Zero, dt * 8f);
		}
		else if (Resource.IsCharger)
		{
			UpdateCharger(dt, dirToPlayer);
		}
		else if (Resource.HasRangedAttack)
		{
			Velocity = distToPlayer < Resource.RangedStopDistance
				? Vector2.Zero
				: dirToPlayer * _scaledSpeed;
		}
		else
		{
			Velocity = dirToPlayer * _scaledSpeed;
		}

		MoveAndSlide();
	}

	private void UpdateCharger(float dt, Vector2 dirToPlayer)
	{
		if (_isCharging)
		{
			_chargingTimer -= dt;
			if (_chargingTimer <= 0f)
			{
				_isCharging = false;
				_chargeIntervalTimer = Resource.ChargeInterval;
			}
			else
			{
				Velocity = _chargeDir * _scaledSpeed * Resource.ChargeSpeedMult;
			}
			return;
		}

		_chargeIntervalTimer -= dt;
		if (_chargeIntervalTimer <= 0f)
		{
			_isCharging = true;
			_chargingTimer = Resource.ChargeDuration;
			_chargeDir = dirToPlayer;
			Velocity = _chargeDir * _scaledSpeed * Resource.ChargeSpeedMult;
		}
		else
		{
			Velocity = dirToPlayer * _scaledSpeed;
		}
	}

	public override void _Process(double delta)
	{
		if (_flashTimer > 0f)
		{
			_flashTimer -= (float)delta;
			if (_flashTimer <= 0f)
				Modulate = Colors.White;
		}

		// Charger telegraph: pulse modulate while approaching charge
		if (Resource != null && Resource.IsCharger && !_isCharging && _flashTimer <= 0f)
		{
			float remaining = _chargeIntervalTimer;
			if (remaining < 0.6f)
			{
				float t = 1f - (remaining / 0.6f); // 0..1
				float pulse = 1f + Mathf.Sin(t * Mathf.Tau * 4f) * 0.4f;
				Modulate = new Color(pulse, pulse * 0.7f, pulse * 0.5f);
			}
			else
			{
				Modulate = Colors.White;
			}
		}
	}

	public void TakeDamage(int dmg, bool isCrit = false)
	{
		if (_dead) return;
		_hp -= dmg;

		Modulate = new Color(3f, 3f, 3f);
		_flashTimer = 0.06f;

		Color color = isCrit
			? new Color(1f, 0.85f, 0.2f)
			: new Color(1f, 1f, 0.7f);
		DamageNumber.Spawn(GetTree().CurrentScene, GlobalPosition + new Vector2(0f, -(Resource?.Radius ?? 12f) - 2f), dmg, color, isCrit);

		if (_hp <= 0)
			Die();
	}

	public void ApplyKnockback(Vector2 force)
	{
		if (IsBoss) return;
		_knockbackVelocity = force;
		_knockbackTimer = 0.18f;
	}

	private void Die()
	{
		_dead = true;
		SpawnDeathParticles();
		SpawnXpGem();
		if (Resource?.SplitsOnDeath == true && Resource.SplitInto != null && Resource.SplitCount > 0)
			SpawnSplits();
		if (IsBoss)
			WaveManager.Instance?.NotifyBossKilled();
		QueueFree();
	}

	private void SpawnSplits()
	{
		var enemyScene = GD.Load<PackedScene>("res://Scenes/Enemies/EnemyBase.tscn");
		if (enemyScene == null) return;
		var rng = GameManager.Instance.Rng;
		var parent = GetParent();
		if (parent == null || !IsInstanceValid(parent)) return;
		for (int i = 0; i < Resource.SplitCount; i++)
		{
			var split = enemyScene.Instantiate<EnemyBase>();
			split.Resource = Resource.SplitInto;
			var offset = new Vector2(rng.RandfRange(-20f, 20f), rng.RandfRange(-20f, 20f));
			parent.AddChild(split);
			split.GlobalPosition = GlobalPosition + offset;
		}
	}

	private void SpawnXpGem()
	{
		if (XpGemScene == null || Resource == null || Resource.XpDrop <= 0) return;
		var gem = XpGemScene.Instantiate<XpGem>();
		gem.Value = Resource.XpDrop;
		gem.MaterialValue = Resource.MaterialDrop;
		GetTree().CurrentScene.AddChild(gem);
		gem.GlobalPosition = GlobalPosition;
	}

	private void SpawnDeathParticles()
	{
		var particles = new CpuParticles2D
		{
			Emitting = true,
			OneShot = true,
			Amount = IsBoss ? 30 : 10,
			Lifetime = IsBoss ? 0.7f : 0.4f,
			Explosiveness = 1f,
			Direction = Vector2.Up,
			Spread = 180f,
			InitialVelocityMin = 80f,
			InitialVelocityMax = IsBoss ? 280f : 180f,
			Gravity = Vector2.Zero,
			ScaleAmountMin = IsBoss ? 3f : 2f,
			ScaleAmountMax = IsBoss ? 6f : 4f,
			Color = Resource?.EnemyColor ?? Colors.White,
		};
		GetTree().CurrentScene.AddChild(particles);
		particles.GlobalPosition = GlobalPosition;
		particles.Finished += () =>
		{
			if (IsInstanceValid(particles)) particles.QueueFree();
		};
	}

	public override void _Draw()
	{
		if (Resource == null) return;
		Color c = Resource.EnemyColor;
		float r = Resource.Radius;

		switch (Resource.Shape)
		{
			case EnemyShape.Triangle:
				DrawColoredPolygon(new[]
				{
					new Vector2(0, -r * 1.3f),
					new Vector2(r * 1.05f, r * 0.85f),
					new Vector2(-r * 1.05f, r * 0.85f),
				}, c);
				break;
			case EnemyShape.Diamond:
				DrawColoredPolygon(new[]
				{
					new Vector2(0, -r * 1.2f),
					new Vector2(r * 1.2f, 0),
					new Vector2(0, r * 1.2f),
					new Vector2(-r * 1.2f, 0),
				}, c);
				break;
			case EnemyShape.Spike:
				DrawColoredPolygon(new[]
				{
					new Vector2(0, -r * 1.5f),
					new Vector2(r * 0.45f, -r * 0.45f),
					new Vector2(r * 1.5f, 0),
					new Vector2(r * 0.45f, r * 0.45f),
					new Vector2(0, r * 1.5f),
					new Vector2(-r * 0.45f, r * 0.45f),
					new Vector2(-r * 1.5f, 0),
					new Vector2(-r * 0.45f, -r * 0.45f),
				}, c);
				break;
			case EnemyShape.BossDiamond:
				DrawColoredPolygon(new[]
				{
					new Vector2(0, -r * 1.7f),
					new Vector2(r * 1.7f, 0),
					new Vector2(0, r * 1.7f),
					new Vector2(-r * 1.7f, 0),
				}, new Color(c.R, c.G, c.B, 0.25f));
				DrawColoredPolygon(new[]
				{
					new Vector2(0, -r * 1.35f),
					new Vector2(r * 1.35f, 0),
					new Vector2(0, r * 1.35f),
					new Vector2(-r * 1.35f, 0),
				}, c);
				DrawColoredPolygon(new[]
				{
					new Vector2(0, -r * 0.55f),
					new Vector2(r * 0.55f, 0),
					new Vector2(0, r * 0.55f),
					new Vector2(-r * 0.55f, 0),
				}, new Color(1f, 1f, 1f, 0.45f));
				break;
		}
	}

	public override void _ExitTree()
	{
		GameManager.Instance?.UnregisterEnemy(this);
	}
}
