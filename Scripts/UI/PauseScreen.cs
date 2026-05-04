using Godot;

namespace BrotatoLike;

public partial class PauseScreen : CanvasLayer
{
	private Control _root;
	private bool _isPaused;

	public override void _Ready()
	{
		ProcessMode = ProcessModeEnum.Always;
		BuildUi();
		_root.Visible = false;
	}

	public override void _Input(InputEvent @event)
	{
		if (!@event.IsActionPressed("pause")) return;

		if (_isPaused)
		{
			Resume();
			GetViewport().SetInputAsHandled();
		}
		else if (!GetTree().Paused)
		{
			// Only allow pause when no other modal owns the pause state
			Pause();
			GetViewport().SetInputAsHandled();
		}
		// else: another screen (level-up, shop, death, win) owns pause — ignore
	}

	private void Pause()
	{
		_isPaused = true;
		GetTree().Paused = true;
		_root.Visible = true;
	}

	private void Resume()
	{
		_isPaused = false;
		GetTree().Paused = false;
		_root.Visible = false;
	}

	private void OnMenu()
	{
		_isPaused = false;
		GetTree().Paused = false;
		GameManager.Instance.ResetRunState();
		GetTree().ChangeSceneToFile("res://Scenes/CharacterSelect.tscn");
	}

	private void BuildUi()
	{
		_root = new Control { AnchorRight = 1, AnchorBottom = 1, MouseFilter = Control.MouseFilterEnum.Stop };
		AddChild(_root);

		var bg = new ColorRect
		{
			Color = new Color(0f, 0f, 0f, 0.7f),
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
			OffsetLeft = -220f,
			OffsetTop = -160f,
			OffsetRight = 220f,
			OffsetBottom = 160f,
		};
		_root.AddChild(panel);

		var margin = new MarginContainer();
		margin.AddThemeConstantOverride("margin_left", 24);
		margin.AddThemeConstantOverride("margin_right", 24);
		margin.AddThemeConstantOverride("margin_top", 22);
		margin.AddThemeConstantOverride("margin_bottom", 22);
		panel.AddChild(margin);

		var vbox = new VBoxContainer();
		vbox.AddThemeConstantOverride("separation", 14);
		margin.AddChild(vbox);

		var title = new Label { Text = "PAUSADO", HorizontalAlignment = HorizontalAlignment.Center };
		title.AddThemeFontSizeOverride("font_size", 36);
		vbox.AddChild(title);

		var hint = new Label { Text = "Esc para continuar  ·  Tab para ver stats", HorizontalAlignment = HorizontalAlignment.Center };
		hint.AddThemeFontSizeOverride("font_size", 13);
		hint.AddThemeColorOverride("font_color", new Color(0.7f, 0.75f, 0.85f));
		vbox.AddChild(hint);

		var resumeBtn = new Button { Text = "Continuar (Esc)", CustomMinimumSize = new Vector2(340f, 48f) };
		resumeBtn.AddThemeFontSizeOverride("font_size", 16);
		resumeBtn.Pressed += Resume;
		vbox.AddChild(resumeBtn);

		var menuBtn = new Button { Text = "Trocar personagem", CustomMinimumSize = new Vector2(340f, 40f) };
		menuBtn.AddThemeFontSizeOverride("font_size", 14);
		menuBtn.Pressed += OnMenu;
		vbox.AddChild(menuBtn);
	}
}
