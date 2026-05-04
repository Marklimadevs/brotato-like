using System.Collections.Generic;
using Godot;

namespace BrotatoLike;

public partial class CharacterSelectScreen : Control
{
	[Export] public WeaponResource PistolWeapon;
	[Export] public WeaponResource SmgWeapon;
	[Export] public WeaponResource ShotgunWeapon;
	[Export] public WeaponResource SniperWeapon;

	private List<CharacterPreset> _presets;
	private int _selectedDifficulty = 1;
	private readonly Button[] _difficultyButtons = new Button[DifficultyConfig.Max];
	private Label _difficultyDescLabel;

	public override void _Ready()
	{
		_presets = BuildPresets();
		_selectedDifficulty = Mathf.Clamp(GameManager.Instance.SelectedDifficulty, DifficultyConfig.Min, DifficultyConfig.Max);
		if (_selectedDifficulty > SaveData.HighestUnlockedDifficulty)
			_selectedDifficulty = SaveData.HighestUnlockedDifficulty;
		BuildUi();
		UpdateDifficultyButtons();
	}

	private void BuildUi()
	{
		var bg = new ColorRect
		{
			Color = new Color(0.1f, 0.1f, 0.14f),
			AnchorRight = 1f,
			AnchorBottom = 1f,
			MouseFilter = Control.MouseFilterEnum.Ignore,
		};
		AddChild(bg);

		var margin = new MarginContainer
		{
			AnchorRight = 1f,
			AnchorBottom = 1f,
		};
		margin.AddThemeConstantOverride("margin_left", 40);
		margin.AddThemeConstantOverride("margin_right", 40);
		margin.AddThemeConstantOverride("margin_top", 30);
		margin.AddThemeConstantOverride("margin_bottom", 30);
		AddChild(margin);

		var col = new VBoxContainer();
		col.AddThemeConstantOverride("separation", 18);
		margin.AddChild(col);

		var title = new Label
		{
			Text = "ESCOLHA SEU PERSONAGEM",
			HorizontalAlignment = HorizontalAlignment.Center,
		};
		title.AddThemeFontSizeOverride("font_size", 34);
		col.AddChild(title);

		var subtitle = new Label
		{
			Text = "Cada personagem começa com uma arma diferente — útil para testar build",
			HorizontalAlignment = HorizontalAlignment.Center,
		};
		subtitle.AddThemeFontSizeOverride("font_size", 15);
		subtitle.AddThemeColorOverride("font_color", new Color(0.7f, 0.75f, 0.85f));
		col.AddChild(subtitle);

		// Spacer
		var topSpacer = new Control { SizeFlagsVertical = SizeFlags.Expand };
		col.AddChild(topSpacer);

		// Cards row, centered
		var cardsRow = new HBoxContainer
		{
			SizeFlagsHorizontal = SizeFlags.ShrinkCenter,
			SizeFlagsVertical = SizeFlags.ShrinkCenter,
		};
		cardsRow.AddThemeConstantOverride("separation", 18);
		col.AddChild(cardsRow);

		foreach (var preset in _presets)
			cardsRow.AddChild(BuildCard(preset));

		var bottomSpacer = new Control { SizeFlagsVertical = SizeFlags.Expand };
		col.AddChild(bottomSpacer);

		// DIFICULDADE row
		var diffTitle = new Label
		{
			Text = "DIFICULDADE",
			HorizontalAlignment = HorizontalAlignment.Center,
		};
		diffTitle.AddThemeFontSizeOverride("font_size", 18);
		diffTitle.AddThemeColorOverride("font_color", new Color(1f, 0.7f, 0.4f));
		col.AddChild(diffTitle);

		var diffRow = new HBoxContainer
		{
			SizeFlagsHorizontal = SizeFlags.ShrinkCenter,
		};
		diffRow.AddThemeConstantOverride("separation", 8);
		col.AddChild(diffRow);

		for (int i = 0; i < DifficultyConfig.Max; i++)
		{
			int diff = i + 1;
			var btn = new Button
			{
				Text = $"D{diff}",
				CustomMinimumSize = new Vector2(70f, 50f),
			};
			btn.AddThemeFontSizeOverride("font_size", 18);
			btn.Pressed += () => OnDifficultyClick(diff);
			diffRow.AddChild(btn);
			_difficultyButtons[i] = btn;
		}

		_difficultyDescLabel = new Label
		{
			Text = DifficultyConfig.GetDescription(_selectedDifficulty),
			HorizontalAlignment = HorizontalAlignment.Center,
		};
		_difficultyDescLabel.AddThemeFontSizeOverride("font_size", 13);
		_difficultyDescLabel.AddThemeColorOverride("font_color", new Color(0.7f, 0.75f, 0.85f));
		col.AddChild(_difficultyDescLabel);

		var hint = new Label
		{
			Text = "Vença a dificuldade atual para destravar a próxima.",
			HorizontalAlignment = HorizontalAlignment.Center,
		};
		hint.AddThemeFontSizeOverride("font_size", 12);
		hint.AddThemeColorOverride("font_color", new Color(0.55f, 0.6f, 0.7f));
		col.AddChild(hint);
	}

	private Control BuildCard(CharacterPreset preset)
	{
		var panel = new PanelContainer
		{
			CustomMinimumSize = new Vector2(220f, 320f),
		};

		var styleBox = new StyleBoxFlat
		{
			BgColor = new Color(preset.BaseColor.R * 0.18f, preset.BaseColor.G * 0.18f, preset.BaseColor.B * 0.18f, 0.92f),
			BorderColor = preset.BaseColor,
			BorderWidthLeft = 2,
			BorderWidthRight = 2,
			BorderWidthTop = 2,
			BorderWidthBottom = 2,
			CornerRadiusTopLeft = 8,
			CornerRadiusTopRight = 8,
			CornerRadiusBottomLeft = 8,
			CornerRadiusBottomRight = 8,
			ContentMarginLeft = 14,
			ContentMarginRight = 14,
			ContentMarginTop = 14,
			ContentMarginBottom = 14,
		};
		panel.AddThemeStyleboxOverride("panel", styleBox);

		var vbox = new VBoxContainer();
		vbox.AddThemeConstantOverride("separation", 10);
		panel.AddChild(vbox);

		// Big colored disc preview
		var preview = new Label
		{
			Text = "●",
			HorizontalAlignment = HorizontalAlignment.Center,
		};
		preview.AddThemeFontSizeOverride("font_size", 84);
		preview.AddThemeColorOverride("font_color", preset.BaseColor);
		vbox.AddChild(preview);

		var name = new Label
		{
			Text = preset.Name,
			HorizontalAlignment = HorizontalAlignment.Center,
		};
		name.AddThemeFontSizeOverride("font_size", 22);
		vbox.AddChild(name);

		string weaponName = preset.StartingWeapons.Count > 0
			? preset.StartingWeapons[0].WeaponName
			: "(sem arma)";
		var weaponLabel = new Label
		{
			Text = $"Arma: {weaponName}",
			HorizontalAlignment = HorizontalAlignment.Center,
		};
		weaponLabel.AddThemeFontSizeOverride("font_size", 14);
		weaponLabel.AddThemeColorOverride("font_color", new Color(1f, 0.95f, 0.6f));
		vbox.AddChild(weaponLabel);

		var desc = new Label
		{
			Text = preset.Description,
			HorizontalAlignment = HorizontalAlignment.Center,
			AutowrapMode = TextServer.AutowrapMode.WordSmart,
			CustomMinimumSize = new Vector2(0f, 70f),
		};
		desc.AddThemeFontSizeOverride("font_size", 13);
		desc.AddThemeColorOverride("font_color", new Color(0.85f, 0.88f, 0.92f));
		vbox.AddChild(desc);

		var spacer = new Control { SizeFlagsVertical = SizeFlags.Expand };
		vbox.AddChild(spacer);

		var btn = new Button
		{
			Text = "Escolher",
			CustomMinimumSize = new Vector2(0f, 44f),
		};
		btn.AddThemeFontSizeOverride("font_size", 16);
		btn.Pressed += () => OnChoose(preset);
		vbox.AddChild(btn);

		return panel;
	}

	private void OnChoose(CharacterPreset preset)
	{
		GameManager.Instance.ResetRunState();
		GameManager.Instance.SelectedCharacter = preset;
		GameManager.Instance.SelectedDifficulty = _selectedDifficulty;
		GetTree().ChangeSceneToFile("res://Scenes/Main.tscn");
	}

	private void OnDifficultyClick(int diff)
	{
		if (diff > SaveData.HighestUnlockedDifficulty) return;
		_selectedDifficulty = diff;
		UpdateDifficultyButtons();
	}

	private void UpdateDifficultyButtons()
	{
		for (int i = 0; i < DifficultyConfig.Max; i++)
		{
			int diff = i + 1;
			var btn = _difficultyButtons[i];
			if (btn == null) continue;
			bool unlocked = diff <= SaveData.HighestUnlockedDifficulty;
			bool selected = diff == _selectedDifficulty;
			btn.Disabled = !unlocked;
			btn.Text = unlocked ? $"D{diff}" : $"🔒 D{diff}";
			btn.Modulate = selected
				? new Color(1f, 0.85f, 0.3f)
				: (unlocked ? Colors.White : new Color(0.45f, 0.45f, 0.5f));
		}
		if (_difficultyDescLabel != null)
			_difficultyDescLabel.Text = DifficultyConfig.GetDescription(_selectedDifficulty);
	}

	private List<CharacterPreset> BuildPresets()
	{
		return new List<CharacterPreset>
		{
			new CharacterPreset
			{
				Name = "Pistoleiro",
				Description = "Equilibrado. Pistol de dano médio e range médio.",
				BaseColor = new Color(0.45f, 0.85f, 1f),
				StartingWeapons = PistolWeapon != null ? new List<WeaponResource> { PistolWeapon } : new(),
			},
			new CharacterPreset
			{
				Name = "Metralhador",
				Description = "SMG rápida. Dano baixo por tiro mas DPS alto no curto/médio.",
				BaseColor = new Color(0.55f, 1f, 0.65f),
				StartingWeapons = SmgWeapon != null ? new List<WeaponResource> { SmgWeapon } : new(),
			},
			new CharacterPreset
			{
				Name = "Bombardeiro",
				Description = "Shotgun em leque. 5 pellets que devastam no curto alcance.",
				BaseColor = new Color(1f, 0.65f, 0.3f),
				StartingWeapons = ShotgunWeapon != null ? new List<WeaponResource> { ShotgunWeapon } : new(),
			},
			new CharacterPreset
			{
				Name = "Atirador",
				Description = "Sniper de longa distância. Dano altíssimo, recarga lenta.",
				BaseColor = new Color(0.75f, 0.5f, 1f),
				StartingWeapons = SniperWeapon != null ? new List<WeaponResource> { SniperWeapon } : new(),
			},
		};
	}
}
