using Godot;

namespace BrotatoLike;

public partial class EnemyBullet : Area2D
{
	public float Speed = 350f;
	public Vector2 Direction = Vector2.Right;
	public int Damage = 6;
	public float Lifetime = 2.5f;
	public float Radius = 5f;
	public Color SpikeColor = new(0.9f, 0.4f, 0.95f);

	private float _age;
	private bool _consumed;

	public override void _Ready()
	{
		BodyEntered += OnBodyEntered;
		Rotation = Direction.Angle() + Mathf.Pi / 2f;
		QueueRedraw();
	}

	public override void _PhysicsProcess(double delta)
	{
		if (_consumed) return;
		Position += Direction * Speed * (float)delta;
		_age += (float)delta;
		if (_age >= Lifetime) QueueFree();
	}

	public override void _Draw()
	{
		// Spike pointing "up" in local space (Direction is rotated to face +x via Rotation)
		DrawColoredPolygon(new[]
		{
			new Vector2(0, -Radius * 1.5f),
			new Vector2(Radius * 0.9f, Radius * 0.7f),
			new Vector2(-Radius * 0.9f, Radius * 0.7f),
		}, SpikeColor);
		DrawCircle(new Vector2(0, -Radius * 0.4f), Radius * 0.35f, new Color(1f, 1f, 1f, 0.55f));
	}

	private void OnBodyEntered(Node2D body)
	{
		if (_consumed) return;
		if (body is Player p)
		{
			_consumed = true;
			p.TakeDamage(Damage);
			QueueFree();
		}
		else
		{
			// Hit wall
			_consumed = true;
			QueueFree();
		}
	}
}
