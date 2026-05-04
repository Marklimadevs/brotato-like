using System.Collections.Generic;
using Godot;

namespace BrotatoLike;

public partial class LevelUpScreen : CanvasLayer
{
	private const int RerollCost = 3;

	private Control _root;
	private ColorRect _bg;
	private PanelContainer _panel;
	private Label _titleLabel;
	private Label _materialsLabel;
	private Button _rerollButton;
	private readonly Button[] _buttons = new Button[3];
	private readonly RichTextLabel[] _richLabels = new RichTextLabel[3];

	private List<UpgradeResource> _currentChoices = new();
	private int _pending;

	public override void _Ready()
	{
		ProcessMode = ProcessModeEnum.Always;
		BuildUi();
		_root.Visible = false;
		GameManager.Instance.LevelUp += OnLevelUp;
	}

	public override void _ExitTree()
	{
		if (GameManager.Instance != null)
			GameManager.Instance.LevelUp -= OnLevelUp;
	}

	private void BuildUi()
	{
		_root = new Control { AnchorRight = 1, AnchorBottom = 1, MouseFilter = Control.MouseFilterEnum.Stop };
		AddChild(_root);

		_bg = new ColorRect
		{
			Color = new Color(0f, 0f, 0f, 0.65f),
			AnchorRight = 1,
			AnchorBottom = 1,
			MouseFilter = Control.MouseFilterEnum.Stop,
		};
		_root.AddChild(_bg);

		_panel = new PanelContainer
		{
			AnchorLeft = 0.5f,
			AnchorTop = 0.5f,
			AnchorRight = 0.5f,
			AnchorBottom = 0.5f,
			OffsetLeft = -260f,
			OffsetTop = -240f,
			OffsetRight = 260f,
			OffsetBottom = 240f,
		};
		_root.AddChild(_panel);

		var margin = new MarginContainer();
		margin.AddThemeConstantOverride("margin_left", 18);
		margin.AddThemeConstantOverride("margin_right", 18);
		margin.AddThemeConstantOverride("margin_top", 18);
		margin.AddThemeConstantOverride("margin_bottom", 18);
		_panel.AddChild(margin);

		var vbox = new VBoxContainer();
		vbox.AddThemeConstantOverride("separation", 12);
		margin.AddChild(vbox);

		_titleLabel = new Label
		{
			Text = "Level Up!",
			HorizontalAlignment = HorizontalAlignment.Center,
		};
		_titleLabel.AddThemeFontSizeOverride("font_size", 26);
		vbox.AddChild(_titleLabel);

		_materialsLabel = new Label
		{
			Text = "Materiais: 0",
			HorizontalAlignment = HorizontalAlignment.Center,
		};
		_materialsLabel.AddThemeFontSizeOverride("font_size", 13);
		_materialsLabel.AddThemeColorOverride("font_color", new Color(1f, 0.85f, 0.4f));
		vbox.AddChild(_materialsLabel);

		for (int i = 0; i < 3; i++)
		{
			var btn = new Button
			{
				Text = "",
				CustomMinimumSize = new Vector2(440f, 80f),
			};
			int idx = i;
			btn.Pressed += () => OnButtonPressed(idx);
			vbox.AddChild(btn);
			_buttons[i] = btn;

			var rich = new RichTextLabel
			{
				BbcodeEnabled = true,
				FitContent = true,
				ScrollActive = false,
				AnchorRight = 1f,
				AnchorBottom = 1f,
				OffsetLeft = 10f,
				OffsetTop = 8f,
				OffsetRight = -10f,
				OffsetBottom = -8f,
				MouseFilter = Control.MouseFilterEnum.Ignore,
			};
			rich.AddThemeFontSizeOverride("normal_font_size", 14);
			rich.AddThemeFontSizeOverride("bold_font_size", 17);
			btn.AddChild(rich);
			_richLabels[i] = rich;
		}

		_rerollButton = new Button
		{
			Text = $"Reroll ({RerollCost} mat)",
			CustomMinimumSize = new Vector2(440f, 38f),
		};
		_rerollButton.AddThemeFontSizeOverride("font_size", 14);
		_rerollButton.Pressed += OnReroll;
		vbox.AddChild(_rerollButton);
	}

	private void OnLevelUp()
	{
		_pending++;
		if (_root.Visible) return;
		ShowOne();
	}

	private void ShowOne()
	{
		_pending = Mathf.Max(0, _pending - 1);
		RollChoices();
		_titleLabel.Text = $"Level {GameManager.Instance.Level}  —  Escolha um upgrade";
		RefreshMaterialsAndReroll();
		_root.Visible = true;
		GetTree().Paused = true;
	}

	private void RollChoices()
	{
		_currentChoices = new List<UpgradeResource>();
		var pool = UpgradeCatalog.All();
		var rng = GameManager.Instance.Rng;
		int waveIdx = WaveManager.Instance?.CurrentWaveIndex ?? 0;

		for (int i = 0; i < 3 && pool.Count > 0; i++)
		{
			var choice = UpgradeCatalog.PickFromPool(pool, rng, waveIdx);
			if (choice == null) break;
			_currentChoices.Add(choice);
			_richLabels[i].Text = ItemDisplay.FormatItemBBCode(choice);
			_buttons[i].Visible = true;
		}
		for (int i = _currentChoices.Count; i < 3; i++)
			_buttons[i].Visible = false;
	}

	private void RefreshMaterialsAndReroll()
	{
		var gm = GameManager.Instance;
		_materialsLabel.Text = $"Materiais: {gm.Materials}";
		_rerollButton.Text = $"Reroll ({RerollCost} mat)";
		_rerollButton.Disabled = gm.Materials < RerollCost;
	}

	private void OnReroll()
	{
		if (!GameManager.Instance.SpendMaterial(RerollCost)) return;
		RollChoices();
		RefreshMaterialsAndReroll();
	}

	private void OnButtonPressed(int idx)
	{
		if (idx < _currentChoices.Count && GameManager.Instance.Player?.Stats != null)
			_currentChoices[idx].Apply(GameManager.Instance.Player.Stats);

		if (_pending > 0)
		{
			ShowOne();
		}
		else
		{
			_root.Visible = false;
			GetTree().Paused = false;
			GameManager.Instance.NotifyLevelUpClosed();
		}
	}
}
