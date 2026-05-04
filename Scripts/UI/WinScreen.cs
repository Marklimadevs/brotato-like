using Godot;

namespace BrotatoLike;

public partial class WinScreen : CanvasLayer
{
	private Control _root;

	public override void _Ready()
	{
		ProcessMode = ProcessModeEnum.Always;
		BuildUi();
		_root.Visible = false;
		// WaveManager pode não estar pronto no _Ready ainda — usa CallDeferred
		CallDeferred(nameof(SubscribeToWave));
	}

	private void SubscribeToWave()
	{
		if (WaveManager.Instance != null)
			WaveManager.Instance.GameWonEvent += OnGameWon;
	}

	public override void _ExitTree()
	{
		if (WaveManager.Instance != null)
			WaveManager.Instance.GameWonEvent -= OnGameWon;
	}

	public override void _Process(double delta)
	{
		if (_root.Visible && Input.IsActionJustPressed("restart"))
			OnRestart();
	}

	private void OnGameWon()
	{
		SaveData.NotifyDifficultyCompleted(GameManager.Instance.SelectedDifficulty);
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
			Color = new Color(0f, 0.1f, 0f, 0.7f),
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

		var title = new Label { Text = "VITÓRIA!", HorizontalAlignment = HorizontalAlignment.Center };
		title.AddThemeFontSizeOverride("font_size", 44);
		title.AddThemeColorOverride("font_color", new Color(0.5f, 1f, 0.5f));
		vbox.AddChild(title);

		var subtitle = new Label { Text = "Você sobreviveu às 5 waves", HorizontalAlignment = HorizontalAlignment.Center };
		subtitle.AddThemeFontSizeOverride("font_size", 16);
		vbox.AddChild(subtitle);

		var btn = new Button
		{
			Text = "Jogar de novo (R)",
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
