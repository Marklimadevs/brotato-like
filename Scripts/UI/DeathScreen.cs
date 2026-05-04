using Godot;

namespace BrotatoLike;

public partial class DeathScreen : CanvasLayer
{
	private Control _root;
	private Label _title;
	private Label _subtitle;

	public override void _Ready()
	{
		ProcessMode = ProcessModeEnum.Always;
		BuildUi();
		_root.Visible = false;
		GameManager.Instance.PlayerDied += OnDied;
	}

	public override void _ExitTree()
	{
		if (GameManager.Instance != null)
			GameManager.Instance.PlayerDied -= OnDied;
	}

	public override void _Process(double delta)
	{
		if (_root.Visible && Input.IsActionJustPressed("restart"))
			OnRestart();
	}

	private void OnDied()
	{
		int wave = (WaveManager.Instance?.CurrentWaveIndex ?? 0) + 1;
		_subtitle.Text = $"Você caiu na wave {wave} de {WaveManager.Instance?.TotalWaves ?? 5}";
		_root.Visible = true;
		GetTree().Paused = true;
	}

	private void OnRestart()
	{
		GetTree().Paused = false;
		GameManager.Instance.ResetRunState();
		GetTree().ReloadCurrentScene();
	}

	private void BuildUi()
	{
		_root = new Control { AnchorRight = 1, AnchorBottom = 1, MouseFilter = Control.MouseFilterEnum.Stop };
		AddChild(_root);

		var bg = new ColorRect
		{
			Color = new Color(0.1f, 0f, 0f, 0.7f),
			AnchorRight = 1,
			AnchorBottom = 1,
			MouseFilter = Control.MouseFilterEnum.Stop,
		};
		_root.AddChild(bg);

		var panel = new PanelContainer
		{
			AnchorLeft = 0.5f,
			AnchorTop = 0.5f,
			AnchorRight = 0.5f,
			AnchorBottom = 0.5f,
			OffsetLeft = -240f,
			OffsetTop = -150f,
			OffsetRight = 240f,
			OffsetBottom = 150f,
		};
		_root.AddChild(panel);

		var margin = new MarginContainer();
		margin.AddThemeConstantOverride("margin_left", 22);
		margin.AddThemeConstantOverride("margin_right", 22);
		margin.AddThemeConstantOverride("margin_top", 22);
		margin.AddThemeConstantOverride("margin_bottom", 22);
		panel.AddChild(margin);

		var vbox = new VBoxContainer();
		vbox.AddThemeConstantOverride("separation", 16);
		margin.AddChild(vbox);

		_title = new Label { Text = "GAME OVER", HorizontalAlignment = HorizontalAlignment.Center };
		_title.AddThemeFontSizeOverride("font_size", 38);
		_title.AddThemeColorOverride("font_color", new Color(1f, 0.5f, 0.5f));
		vbox.AddChild(_title);

		_subtitle = new Label { Text = "Você caiu", HorizontalAlignment = HorizontalAlignment.Center };
		_subtitle.AddThemeFontSizeOverride("font_size", 16);
		vbox.AddChild(_subtitle);

		var btn = new Button
		{
			Text = "Reiniciar (R)",
			CustomMinimumSize = new Vector2(380f, 52f),
		};
		btn.AddThemeFontSizeOverride("font_size", 18);
		btn.Pressed += OnRestart;
		vbox.AddChild(btn);

		var menuBtn = new Button
		{
			Text = "Trocar personagem",
			CustomMinimumSize = new Vector2(380f, 40f),
		};
		menuBtn.AddThemeFontSizeOverride("font_size", 14);
		menuBtn.Pressed += OnMenu;
		vbox.AddChild(menuBtn);
	}

	private void OnMenu()
	{
		GetTree().Paused = false;
		GameManager.Instance.ResetRunState();
		GetTree().ChangeSceneToFile("res://Scenes/CharacterSelect.tscn");
	}
}
