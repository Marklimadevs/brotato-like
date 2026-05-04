using Godot;

namespace BrotatoLike;

public partial class HUD : CanvasLayer
{
	private ProgressBar _hpBar;
	private Label _hpLabel;
	private ProgressBar _xpBar;
	private Label _xpLabel;
	private Label _waveLabel;
	private Label _timerLabel;
	private Label _materialsLabel;
	private ProgressBar _bossHpBar;
	private Label _bossLabel;

	public override void _Ready()
	{
		BuildUi();
		GameManager.Instance.XpChanged += UpdateXp;
		GameManager.Instance.MaterialsChanged += UpdateMaterials;
		UpdateXp();
		UpdateMaterials();
	}

	public override void _ExitTree()
	{
		if (GameManager.Instance == null) return;
		GameManager.Instance.XpChanged -= UpdateXp;
		GameManager.Instance.MaterialsChanged -= UpdateMaterials;
	}

	private void BuildUi()
	{
		// HP bar - top left
		_hpBar = new ProgressBar
		{
			CustomMinimumSize = new Vector2(280f, 26f),
			ShowPercentage = false,
			Position = new Vector2(20f, 20f),
			Modulate = new Color(1f, 0.45f, 0.45f),
		};
		AddChild(_hpBar);
		_hpLabel = MakeLabel("HP", new Vector2(28f, 22f), 14);
		AddChild(_hpLabel);

		// XP bar - top center
		_xpBar = new ProgressBar
		{
			CustomMinimumSize = new Vector2(560f, 16f),
			ShowPercentage = false,
			Position = new Vector2(330f, 24f),
			Modulate = new Color(0.55f, 1f, 0.55f),
		};
		AddChild(_xpBar);
		_xpLabel = MakeLabel("Lv 1", new Vector2(330f, 42f), 13);
		AddChild(_xpLabel);

		// Wave + timer - top right
		_waveLabel = MakeLabel("Wave 1 / 5", new Vector2(940f, 20f), 18);
		AddChild(_waveLabel);
		_timerLabel = MakeLabel("30.0s", new Vector2(940f, 44f), 16);
		AddChild(_timerLabel);
		var diffLabel = MakeLabel(DifficultyConfig.GetLabel(GameManager.Instance.SelectedDifficulty), new Vector2(1180f, 20f), 18);
		diffLabel.AddThemeColorOverride("font_color", new Color(1f, 0.7f, 0.4f));
		AddChild(diffLabel);

		// Materials below HP bar
		_materialsLabel = MakeLabel("Mat: 0", new Vector2(20f, 56f), 18);
		_materialsLabel.AddThemeColorOverride("font_color", new Color(1f, 0.85f, 0.4f));
		AddChild(_materialsLabel);

		// Boss HP bar (centered, hidden until boss alive)
		_bossLabel = MakeLabel("⚠  BOSS  ⚠", new Vector2(540f, 80f), 20);
		_bossLabel.AddThemeColorOverride("font_color", new Color(0.95f, 0.55f, 1f));
		_bossLabel.Visible = false;
		AddChild(_bossLabel);

		_bossHpBar = new ProgressBar
		{
			CustomMinimumSize = new Vector2(900f, 26f),
			ShowPercentage = false,
			Position = new Vector2(190f, 108f),
			Modulate = new Color(0.85f, 0.4f, 1f),
			Visible = false,
		};
		AddChild(_bossHpBar);
	}

	private static Label MakeLabel(string text, Vector2 pos, int fontSize)
	{
		var l = new Label { Text = text, Position = pos };
		l.AddThemeFontSizeOverride("font_size", fontSize);
		l.AddThemeColorOverride("font_color", Colors.White);
		l.AddThemeColorOverride("font_outline_color", Colors.Black);
		l.AddThemeConstantOverride("outline_size", 5);
		return l;
	}

	public override void _Process(double delta)
	{
		var p = GameManager.Instance.Player;
		if (p?.Stats != null && _hpBar != null)
		{
			int curHp = Mathf.Max(0, p.Stats.CurrentHp);
			_hpBar.MaxValue = p.Stats.MaxHp;
			_hpBar.Value = curHp;
			_hpLabel.Text = $"{curHp} / {p.Stats.MaxHp}";
		}

		var wm = WaveManager.Instance;
		if (wm != null && _waveLabel != null)
		{
			_waveLabel.Text = $"Wave {Mathf.Min(wm.CurrentWaveIndex + 1, wm.TotalWaves)} / {wm.TotalWaves}";

			var boss = wm.CurrentBoss;
			bool bossAlive = boss != null && IsInstanceValid(boss);

			if (bossAlive)
			{
				_timerLabel.Text = "Mate o Boss!";
				_bossLabel.Visible = true;
				_bossHpBar.Visible = true;
				_bossHpBar.MaxValue = boss.ScaledMaxHp > 0 ? boss.ScaledMaxHp : (boss.Resource?.MaxHp ?? 1);
				_bossHpBar.Value = Mathf.Max(0, boss.CurrentHp);
			}
			else
			{
				_bossLabel.Visible = false;
				_bossHpBar.Visible = false;
				_timerLabel.Text = wm.GameWon
					? "Fim"
					: wm.BetweenWaves ? "..." : $"{Mathf.Max(0f, wm.WaveTimeRemaining):F1}s";
			}
		}
	}

	private void UpdateXp()
	{
		if (_xpBar == null) return;
		var gm = GameManager.Instance;
		_xpBar.MaxValue = gm.XpForNextLevel;
		_xpBar.Value = gm.Xp;
		string pending = gm.PendingLevelUps > 0
			? $"    ⬆ {gm.PendingLevelUps} upgrade(s) ao fim da wave"
			: "";
		_xpLabel.Text = $"Lv {gm.Level}    XP {gm.Xp} / {gm.XpForNextLevel}{pending}";
	}

	private void UpdateMaterials()
	{
		if (_materialsLabel == null) return;
		_materialsLabel.Text = $"Mat: {GameManager.Instance.Materials}";
	}
}
