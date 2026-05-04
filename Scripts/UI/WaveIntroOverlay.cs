using Godot;

namespace BrotatoLike;

public partial class WaveIntroOverlay : CanvasLayer
{
	private Label _label;
	private Tween _currentTween;

	public override void _Ready()
	{
		Layer = 4;
		BuildUi();
		CallDeferred(nameof(SubscribeToWaveManager));
	}

	private void SubscribeToWaveManager()
	{
		if (WaveManager.Instance == null) return;
		WaveManager.Instance.WaveStarted += OnWaveStarted;
		WaveManager.Instance.BossSpawned += OnBossSpawned;
	}

	public override void _ExitTree()
	{
		if (WaveManager.Instance != null)
		{
			WaveManager.Instance.WaveStarted -= OnWaveStarted;
			WaveManager.Instance.BossSpawned -= OnBossSpawned;
		}
	}

	private void OnWaveStarted()
	{
		var wm = WaveManager.Instance;
		if (wm == null) return;
		bool isLast = wm.CurrentWaveIndex == wm.TotalWaves - 1;
		string text = isLast ? "WAVE FINAL" : $"WAVE {wm.CurrentWaveIndex + 1}";
		ShowText(text, new Color(1f, 1f, 1f), 56, 1.0);
	}

	private void OnBossSpawned()
	{
		ShowText("⚠  BOSS  ⚠", new Color(1f, 0.45f, 0.85f), 70, 1.4);
		var player = GameManager.Instance.Player;
		if (player != null && IsInstanceValid(player))
		{
			var cam = player.GetNodeOrNull<CameraShake>("Camera2D");
			cam?.Shake(28f);
		}
	}

	private void ShowText(string text, Color color, int fontSize, double holdSeconds)
	{
		_label.Text = text;
		_label.AddThemeFontSizeOverride("font_size", fontSize);
		_label.AddThemeColorOverride("font_color", color);
		_label.Modulate = new Color(1f, 1f, 1f, 0f);
		_label.Visible = true;

		if (_currentTween != null && _currentTween.IsValid())
			_currentTween.Kill();

		_currentTween = CreateTween();
		_currentTween.TweenProperty(_label, "modulate:a", 1f, 0.3);
		_currentTween.TweenInterval(holdSeconds);
		_currentTween.TweenProperty(_label, "modulate:a", 0f, 0.5);
		_currentTween.TweenCallback(Callable.From(HideLabel));
	}

	private void HideLabel()
	{
		if (_label != null && IsInstanceValid(_label))
			_label.Visible = false;
	}

	private void BuildUi()
	{
		_label = new Label
		{
			HorizontalAlignment = HorizontalAlignment.Center,
			VerticalAlignment = VerticalAlignment.Center,
			AnchorLeft = 0.5f,
			AnchorTop = 0.5f,
			AnchorRight = 0.5f,
			AnchorBottom = 0.5f,
			OffsetLeft = -360f,
			OffsetTop = -80f,
			OffsetRight = 360f,
			OffsetBottom = 80f,
			Visible = false,
			MouseFilter = Control.MouseFilterEnum.Ignore,
		};
		_label.AddThemeColorOverride("font_outline_color", Colors.Black);
		_label.AddThemeConstantOverride("outline_size", 10);
		AddChild(_label);
	}
}
