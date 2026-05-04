using Godot;

namespace BrotatoLike;

public partial class CameraShake : Camera2D
{
	[Export] public float Decay = 7f;
	private float _strength;

	public override void _Process(double delta)
	{
		if (_strength > 0.05f)
		{
			var rng = GameManager.Instance.Rng;
			Offset = new Vector2(rng.RandfRange(-1f, 1f), rng.RandfRange(-1f, 1f)) * _strength;
			_strength = Mathf.Lerp(_strength, 0f, (float)delta * Decay);
		}
		else if (_strength > 0f)
		{
			_strength = 0f;
			Offset = Vector2.Zero;
		}
	}

	public void Shake(float amount)
	{
		if (amount > _strength)
			_strength = amount;
	}
}
