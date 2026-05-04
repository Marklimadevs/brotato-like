using System.Collections.Generic;
using Godot;

namespace BrotatoLike;

public partial class StatsPanel : CanvasLayer
{
	private Control _root;
	private VBoxContainer _statsList;
	private VBoxContainer _weaponsList;
	private Label _hint;

	private Label _hpVal, _dmgVal, _atkSpdVal, _moveVal, _pickupVal, _xpVal;
	private Label _critVal, _critDmgVal, _armorVal, _regenVal, _knockVal;
	private readonly List<WeaponRow> _weaponRows = new();

	private bool _userToggled;
	private bool _forcedVisible;
	private float _refreshTimer;

	private class WeaponRow
	{
		public VBoxContainer Box;
		public Label Name;
		public Label Damage;
		public Label FireRate;
		public Label Range;
		public Label BulletSpeed;
	}

	public override void _Ready()
	{
		ProcessMode = ProcessModeEnum.Always;
		BuildUi();
		_root.Visible = false;

		GameManager.Instance.LevelUp += OnForceShow;
		GameManager.Instance.LevelUpClosed += OnForceHide;
		GameManager.Instance.ShopOpened += OnForceShow;
		GameManager.Instance.ShopClosed += OnForceHide;
		GameManager.Instance.PlayerDied += OnPlayerDied;
	}

	public override void _ExitTree()
	{
		if (GameManager.Instance == null) return;
		GameManager.Instance.LevelUp -= OnForceShow;
		GameManager.Instance.LevelUpClosed -= OnForceHide;
		GameManager.Instance.ShopOpened -= OnForceShow;
		GameManager.Instance.ShopClosed -= OnForceHide;
		GameManager.Instance.PlayerDied -= OnPlayerDied;
	}

	public override void _Input(InputEvent @event)
	{
		if (@event.IsActionPressed("stats_toggle"))
		{
			_userToggled = !_userToggled;
			UpdateVisibility();
			GetViewport().SetInputAsHandled();
		}
	}

	public override void _Process(double delta)
	{
		if (!_root.Visible) return;
		_refreshTimer -= (float)delta;
		if (_refreshTimer <= 0f)
		{
			_refreshTimer = 0.15f;
			Refresh();
		}
	}

	private void OnForceShow()
	{
		_forcedVisible = true;
		UpdateVisibility();
		Refresh();
	}

	private void OnForceHide()
	{
		_forcedVisible = false;
		UpdateVisibility();
	}

	private void OnPlayerDied()
	{
		_userToggled = false;
		_forcedVisible = false;
		UpdateVisibility();
	}

	private void UpdateVisibility()
	{
		_root.Visible = _userToggled || _forcedVisible;
		if (_hint != null)
			_hint.Visible = !_forcedVisible;
	}

	private void Refresh()
	{
		var p = GameManager.Instance.Player;
		if (p == null || !p.IsAlive || p.Stats == null) return;

		_hpVal.Text = $"{Mathf.Max(0, p.Stats.CurrentHp)} / {p.Stats.MaxHp}";
		_dmgVal.Text = $"+{p.Stats.BonusDamage}";
		_atkSpdVal.Text = $"{p.Stats.AttackSpeedMult * 100f:F0}%";
		_moveVal.Text = $"{p.Stats.MoveSpeed:F0}";
		_pickupVal.Text = $"{p.Stats.PickupRadius:F0}";
		_xpVal.Text = $"{p.Stats.XpGainMult * 100f:F0}%";
		_critVal.Text = $"{p.Stats.CritChance * 100f:F0}%";
		_critDmgVal.Text = $"×{p.Stats.CritMultiplier:F2}";
		_armorVal.Text = $"{p.Stats.Armor}";
		_regenVal.Text = $"{p.Stats.HpRegenPerSec:F1}/s";
		_knockVal.Text = $"{p.Stats.Knockback:F0}";

		int idx = 0;
		foreach (var w in p.GetActiveWeapons())
		{
			if (w?.Resource == null) continue;
			while (_weaponRows.Count <= idx)
				_weaponRows.Add(BuildWeaponRow());

			var row = _weaponRows[idx];
			row.Box.Visible = true;
			row.Name.Text = w.Resource.WeaponName;
			row.Damage.Text = w.Resource.Pellets > 1
				? $"{w.EffectiveDamage} × {w.Resource.Pellets}"
				: $"{w.EffectiveDamage}";
			row.FireRate.Text = $"{w.EffectiveFireRate:F2}/s";
			row.Range.Text = $"{w.Resource.Range:F0}";
			row.BulletSpeed.Text = $"{w.Resource.BulletSpeed:F0}";
			idx++;
		}
		for (int i = idx; i < _weaponRows.Count; i++)
			_weaponRows[i].Box.Visible = false;
	}

	private void BuildUi()
	{
		_root = new Control { MouseFilter = Control.MouseFilterEnum.Ignore };
		_root.AnchorRight = 1;
		_root.AnchorBottom = 1;
		AddChild(_root);

		var panel = new PanelContainer
		{
			AnchorLeft = 1f,
			AnchorTop = 0f,
			AnchorRight = 1f,
			AnchorBottom = 1f,
			OffsetLeft = -310f,
			OffsetTop = 80f,
			OffsetRight = -14f,
			OffsetBottom = -100f,
			MouseFilter = Control.MouseFilterEnum.Ignore,
		};
		_root.AddChild(panel);

		var margin = new MarginContainer();
		margin.AddThemeConstantOverride("margin_left", 14);
		margin.AddThemeConstantOverride("margin_right", 14);
		margin.AddThemeConstantOverride("margin_top", 12);
		margin.AddThemeConstantOverride("margin_bottom", 12);
		panel.AddChild(margin);

		var col = new VBoxContainer();
		col.AddThemeConstantOverride("separation", 8);
		margin.AddChild(col);

		col.AddChild(MakeTitle("PLAYER"));
		_statsList = new VBoxContainer();
		_statsList.AddThemeConstantOverride("separation", 2);
		col.AddChild(_statsList);

		_hpVal = AddRow(_statsList, "HP");
		_dmgVal = AddRow(_statsList, "Bonus Damage");
		_atkSpdVal = AddRow(_statsList, "Attack Speed");
		_moveVal = AddRow(_statsList, "Move Speed");
		_pickupVal = AddRow(_statsList, "Pickup Radius");
		_xpVal = AddRow(_statsList, "XP Gain");
		_critVal = AddRow(_statsList, "Crit Chance");
		_critDmgVal = AddRow(_statsList, "Crit Damage");
		_armorVal = AddRow(_statsList, "Armor");
		_regenVal = AddRow(_statsList, "HP Regen");
		_knockVal = AddRow(_statsList, "Knockback");

		col.AddChild(new HSeparator());
		col.AddChild(MakeTitle("ARMAS"));
		_weaponsList = new VBoxContainer();
		_weaponsList.AddThemeConstantOverride("separation", 6);
		col.AddChild(_weaponsList);

		_hint = MakeMutedLabel("Tab para fechar", 11);
		_hint.HorizontalAlignment = HorizontalAlignment.Center;
		col.AddChild(_hint);
	}

	private WeaponRow BuildWeaponRow()
	{
		var row = new WeaponRow();
		row.Box = new VBoxContainer();
		row.Box.AddThemeConstantOverride("separation", 1);
		_weaponsList.AddChild(row.Box);

		row.Name = MakeLabel("Weapon", 15, true);
		row.Box.AddChild(row.Name);

		var inner = new VBoxContainer();
		inner.AddThemeConstantOverride("separation", 1);
		row.Box.AddChild(inner);
		row.Damage = AddRow(inner, "Damage");
		row.FireRate = AddRow(inner, "Fire rate");
		row.Range = AddRow(inner, "Range");
		row.BulletSpeed = AddRow(inner, "Bullet spd");
		return row;
	}

	private static Label AddRow(Container parent, string name)
	{
		var hbox = new HBoxContainer();
		parent.AddChild(hbox);
		var nameLabel = MakeMutedLabel(name + ":", 13);
		nameLabel.SizeFlagsHorizontal = Control.SizeFlags.ExpandFill;
		hbox.AddChild(nameLabel);
		var valueLabel = MakeLabel("0", 13, false);
		valueLabel.HorizontalAlignment = HorizontalAlignment.Right;
		hbox.AddChild(valueLabel);
		return valueLabel;
	}

	private static Label MakeTitle(string text)
	{
		var l = new Label { Text = text };
		l.AddThemeFontSizeOverride("font_size", 14);
		l.AddThemeColorOverride("font_color", new Color(0.7f, 0.85f, 1f));
		return l;
	}

	private static Label MakeLabel(string text, int fontSize, bool bold)
	{
		var l = new Label { Text = text };
		l.AddThemeFontSizeOverride("font_size", fontSize);
		l.AddThemeColorOverride("font_color", bold ? Colors.White : new Color(0.95f, 0.95f, 0.95f));
		return l;
	}

	private static Label MakeMutedLabel(string text, int fontSize)
	{
		var l = new Label { Text = text };
		l.AddThemeFontSizeOverride("font_size", fontSize);
		l.AddThemeColorOverride("font_color", new Color(0.65f, 0.7f, 0.78f));
		return l;
	}
}
