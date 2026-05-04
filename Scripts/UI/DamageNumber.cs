using Godot;

namespace BrotatoLike;

public partial class DamageNumber : Node2D
{
	private const float Lifetime = 0.55f;
	private const int FontSize = 22;
	private const int CritFontSize = 32;

	private string _text = "0";
	private Color _color = Colors.White;
	private bool _isCrit;
	private float _age;
	private Vector2 _velocity = new(0f, -55f);
	private static Font _font;

	public override void _Ready()
	{
		ZIndex = 100;
		if (_font == null)
			_font = ThemeDB.FallbackFont;
	}

	public override void _Process(double delta)
	{
		float dt = (float)delta;
		_age += dt;
		Position += _velocity * dt;
		_velocity = _velocity.Lerp(Vector2.Zero, dt * 4f);
		QueueRedraw();
		if (_age >= Lifetime)
			QueueFree();
	}

	public override void _Draw()
	{
		if (_font == null) return;
		float alpha = Mathf.Clamp(1f - (_age / Lifetime), 0f, 1f);
		var color = _color;
		color.A = alpha;
		var outline = new Color(0f, 0f, 0f, alpha * 0.85f);
		int fontSize = _isCrit ? CritFontSize : FontSize;

		var size = _font.GetStringSize(_text, HorizontalAlignment.Left, -1, fontSize);
		var origin = new Vector2(-size.X / 2f, size.Y / 2f);

		foreach (var off in new[] { new Vector2(1, 0), new Vector2(-1, 0), new Vector2(0, 1), new Vector2(0, -1) })
			DrawString(_font, origin + off, _text, HorizontalAlignment.Left, -1, fontSize, outline);
		DrawString(_font, origin, _text, HorizontalAlignment.Left, -1, fontSize, color);
	}

	public static void Spawn(Node parent, Vector2 worldPos, int amount, Color color, bool isCrit = false)
	{
		string text = isCrit ? $"{amount}!" : amount.ToString();
		SpawnText(parent, worldPos, text, color, isCrit);
	}

	public static void SpawnText(Node parent, Vector2 worldPos, string text, Color color, bool isCrit = false)
	{
		if (parent == null) return;
		var dn = new DamageNumber
		{
			_text = text,
			_color = color,
			_isCrit = isCrit,
		};
		parent.AddChild(dn);
		var jitter = new Vector2(GameManager.Instance.Rng.RandfRange(-6f, 6f), -8f);
		dn.GlobalPosition = worldPos + jitter;
	}
}
