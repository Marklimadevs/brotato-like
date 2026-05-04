using Godot;

namespace BrotatoLike;

public partial class XpGem : Area2D
{
	[Export] public float Radius = 6f;
	[Export] public Color GemColor = new(0.45f, 1f, 0.55f);

	public int Value = 1;
	public int MaterialValue = 0;

	private Player _player;
	private bool _attracting;
	private float _attractSpeed = 60f;
	private bool _consumed;

	public override void _Ready()
	{
		BodyEntered += OnBodyEntered;
		QueueRedraw();
	}

	public override void _PhysicsProcess(double delta)
	{
		if (_consumed) return;
		_player ??= GameManager.Instance.Player;
		if (_player == null) return;

		var toPlayer = _player.GlobalPosition - GlobalPosition;
		float dist = toPlayer.Length();
		float magnetR = _player.Stats?.PickupRadius ?? 80f;

		if (_attracting || dist < magnetR)
		{
			_attracting = true;
			_attractSpeed += 700f * (float)delta;
			GlobalPosition += toPlayer.Normalized() * _attractSpeed * (float)delta;
		}
	}

	public override void _Draw()
	{
		DrawColoredPolygon(new[]
		{
			new Vector2(0, -Radius),
			new Vector2(Radius, 0),
			new Vector2(0, Radius),
			new Vector2(-Radius, 0),
		}, GemColor);
		DrawColoredPolygon(new[]
		{
			new Vector2(0, -Radius * 0.4f),
			new Vector2(Radius * 0.4f, 0),
			new Vector2(0, Radius * 0.4f),
			new Vector2(-Radius * 0.4f, 0),
		}, new Color(1f, 1f, 1f, 0.7f));
	}

	private void OnBodyEntered(Node2D body)
	{
		if (_consumed) return;
		if (body is Player)
		{
			_consumed = true;
			GameManager.Instance.AddXp(Value);
			if (MaterialValue > 0)
				GameManager.Instance.AddMaterial(MaterialValue);
			QueueFree();
		}
	}
}
