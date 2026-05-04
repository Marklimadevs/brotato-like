using Godot;

namespace BrotatoLike;

public partial class Bullet : Area2D
{
	public float Speed = 600f;
	public Vector2 Direction = Vector2.Right;
	public int Damage = 4;
	public Color BulletColor = new(1f, 0.95f, 0.5f);
	public float Radius = 5f;
	public float Lifetime = 1.5f;
	public int Pierce = 0; // additional enemies the bullet can pass through

	private float _age;
	private int _hitsRemaining = 1;
	private bool _consumed;
	private readonly System.Collections.Generic.HashSet<EnemyBase> _alreadyHit = new();

	public override void _Ready()
	{
		BodyEntered += OnBodyEntered;
		_hitsRemaining = 1 + Pierce;

		var shape = GetNode<CollisionShape2D>("CollisionShape2D");
		var circle = (CircleShape2D)shape.Shape.Duplicate();
		circle.Radius = Radius;
		shape.Shape = circle;

		QueueRedraw();
	}

	public override void _PhysicsProcess(double delta)
	{
		if (_consumed) return;
		Position += Direction * Speed * (float)delta;
		_age += (float)delta;
		if (_age >= Lifetime)
			QueueFree();
	}

	public override void _Draw()
	{
		DrawCircle(Vector2.Zero, Radius, BulletColor);
		DrawCircle(Vector2.Zero, Radius * 0.5f, new Color(1f, 1f, 1f, 0.6f));
	}

	private void OnBodyEntered(Node2D body)
	{
		if (_consumed) return;
		if (body is EnemyBase enemy)
		{
			if (_alreadyHit.Contains(enemy)) return;
			_alreadyHit.Add(enemy);

			var player = GameManager.Instance.Player;
			bool isCrit = false;
			int finalDmg = Damage;

			if (player?.Stats != null)
			{
				if (GameManager.Instance.Rng.Randf() < player.Stats.CritChance)
				{
					isCrit = true;
					finalDmg = Mathf.Max(1, (int)(Damage * player.Stats.CritMultiplier));
				}
			}

			enemy.TakeDamage(finalDmg, isCrit);

			if (player?.Stats != null && player.Stats.Knockback > 0f)
				enemy.ApplyKnockback(Direction * player.Stats.Knockback);

			_hitsRemaining--;
			if (_hitsRemaining <= 0)
			{
				_consumed = true;
				QueueFree();
			}
		}
		else
		{
			// Hit wall — always despawn
			_consumed = true;
			QueueFree();
		}
	}
}
