using System.Collections.Generic;
using Godot;

namespace BrotatoLike;

public partial class ShopScreen : CanvasLayer
{
	private const int RerollCost = 3;
	private const int OfferSlots = 3;

	[Export] public WeaponResource ShopWeapon1;
	[Export] public WeaponResource ShopWeapon2;
	[Export] public WeaponResource ShopWeapon3;
	[Export] public WeaponResource ShopWeapon4;

	private Control _root;
	private Label _titleLabel;
	private Label _materialsLabel;
	private readonly Button[] _offerButtons = new Button[OfferSlots];
	private readonly RichTextLabel[] _offerRichLabels = new RichTextLabel[OfferSlots];
	private readonly Button[] _lockButtons = new Button[OfferSlots];
	private Button _rerollButton;
	private Button _continueButton;
	private VBoxContainer _sellList;
	private Label _sellHeader;

	private List<WeaponResource> _weaponCatalog;
	private readonly ShopOffer[] _currentOffers = new ShopOffer[OfferSlots];
	private readonly bool[] _purchased = new bool[OfferSlots];
	private readonly bool[] _locked = new bool[OfferSlots];

	private class ShopOffer
	{
		public UpgradeResource Item;
		public WeaponResource Weapon;
		public bool IsWeapon => Weapon != null;
		public int Cost => IsWeapon ? Weapon.Cost : Item.Cost;
		public string Title => IsWeapon ? $"⚔ {Weapon.WeaponName}" : Item.Title;
		public ItemRarity Rarity => IsWeapon ? ItemRarity.Rare : Item.Rarity;
	}

	public override void _Ready()
	{
		ProcessMode = ProcessModeEnum.Always;
		_weaponCatalog = BuildWeaponCatalog();
		BuildUi();
		_root.Visible = false;

		GameManager.Instance.ShopOpened += OnShopOpened;
		GameManager.Instance.MaterialsChanged += UpdateUi;
	}

	public override void _ExitTree()
	{
		if (GameManager.Instance == null) return;
		GameManager.Instance.ShopOpened -= OnShopOpened;
		GameManager.Instance.MaterialsChanged -= UpdateUi;
	}

	private void OnShopOpened()
	{
		RollOffers();
		_root.Visible = true;
		GetTree().Paused = true;
		UpdateUi();
	}

	private void OnContinue()
	{
		_root.Visible = false;
		GetTree().Paused = false;
		GameManager.Instance.NotifyShopClosed();
	}

	private void OnBuy(int idx)
	{
		if (idx < 0 || idx >= OfferSlots) return;
		var offer = _currentOffers[idx];
		if (offer == null || _purchased[idx]) return;

		var player = GameManager.Instance.Player;
		if (player == null) return;

		if (offer.IsWeapon)
		{
			if (player.EquippedWeaponCount >= Player.MaxWeaponSlots) return;
			if (!GameManager.Instance.SpendMaterial(offer.Cost)) return;
			player.AddWeapon(offer.Weapon);
		}
		else
		{
			if (!GameManager.Instance.SpendMaterial(offer.Cost)) return;
			offer.Item.Apply(player.Stats);
		}
		_purchased[idx] = true;
		UpdateUi();
	}

	private void OnReroll()
	{
		if (!GameManager.Instance.SpendMaterial(RerollCost)) return;
		RollOffers();
		UpdateUi();
	}

	private void OnLockToggle(int idx, bool pressed)
	{
		if (idx < 0 || idx >= OfferSlots) return;
		_locked[idx] = pressed;
		UpdateUi();
	}

	private void OnSellWeapon(int playerWeaponIndex, int sellValue)
	{
		var player = GameManager.Instance.Player;
		if (player == null) return;
		if (!player.RemoveWeaponAt(playerWeaponIndex)) return;
		GameManager.Instance.AddMaterial(sellValue);
		UpdateUi();
	}

	private void RollOffers()
	{
		var rng = GameManager.Instance.Rng;
		var itemPool = UpgradeCatalog.All();
		var weaponPool = new List<WeaponResource>(_weaponCatalog);
		int waveIdx = WaveManager.Instance?.CurrentWaveIndex ?? 0;

		// Remove kept (locked, non-purchased) offers from pools to avoid duplicates
		for (int i = 0; i < OfferSlots; i++)
		{
			if (KeepSlot(i))
			{
				if (_currentOffers[i].IsWeapon)
					weaponPool.Remove(_currentOffers[i].Weapon);
				else
					itemPool.Remove(_currentOffers[i].Item);
			}
		}

		// Re-roll non-kept slots
		for (int i = 0; i < OfferSlots; i++)
		{
			if (!KeepSlot(i))
			{
				_currentOffers[i] = RollSingleOffer(itemPool, weaponPool, rng, waveIdx);
				_purchased[i] = false;
				_locked[i] = false;
			}
		}
	}

	private bool KeepSlot(int i)
	{
		return _locked[i] && _currentOffers[i] != null && !_purchased[i];
	}

	private ShopOffer RollSingleOffer(List<UpgradeResource> itemPool, List<WeaponResource> weaponPool, RandomNumberGenerator rng, int waveIdx)
	{
		bool tryWeapon = weaponPool.Count > 0 && rng.Randf() < 0.35f;
		if (tryWeapon)
		{
			int idx = rng.RandiRange(0, weaponPool.Count - 1);
			var w = weaponPool[idx];
			weaponPool.RemoveAt(idx);
			return new ShopOffer { Weapon = w };
		}
		if (itemPool.Count > 0)
		{
			var item = UpgradeCatalog.PickFromPool(itemPool, rng, waveIdx);
			if (item != null) return new ShopOffer { Item = item };
		}
		if (weaponPool.Count > 0)
		{
			int idx = rng.RandiRange(0, weaponPool.Count - 1);
			var w = weaponPool[idx];
			weaponPool.RemoveAt(idx);
			return new ShopOffer { Weapon = w };
		}
		return null;
	}

	private void UpdateUi()
	{
		var gm = GameManager.Instance;
		int wave = WaveManager.Instance != null ? WaveManager.Instance.CurrentWaveIndex + 1 : 0;
		int totalWaves = WaveManager.Instance?.TotalWaves ?? 5;
		_titleLabel.Text = $"SHOP — Próxima: Wave {wave + 1} / {totalWaves}";
		_materialsLabel.Text = $"Materiais: {gm.Materials}";

		var player = gm.Player;
		int slotsUsed = player?.EquippedWeaponCount ?? 0;
		int slotsMax = Player.MaxWeaponSlots;

		// Offers + lock buttons
		for (int i = 0; i < OfferSlots; i++)
		{
			var btn = _offerButtons[i];
			var rich = _offerRichLabels[i];
			var lockBtn = _lockButtons[i];
			var offer = _currentOffers[i];

			if (offer != null)
			{
				btn.Visible = true;
				lockBtn.Visible = true;

				if (_purchased[i])
				{
					rich.Text = ItemDisplay.FormatPurchasedBBCode(offer.Title);
					btn.Disabled = true;
					lockBtn.Disabled = true;
				}
				else
				{
					rich.Text = offer.IsWeapon
						? ItemDisplay.FormatShopWeaponBBCode(offer.Weapon, slotsUsed, slotsMax)
						: ItemDisplay.FormatShopItemBBCode(offer.Item);
					bool noMat = gm.Materials < offer.Cost;
					bool noSlot = offer.IsWeapon && slotsUsed >= slotsMax;
					btn.Disabled = noMat || noSlot;
					lockBtn.Disabled = false;
				}

				lockBtn.SetPressedNoSignal(_locked[i]);
				lockBtn.Modulate = _locked[i]
					? new Color(1f, 0.85f, 0.3f)
					: new Color(0.6f, 0.6f, 0.65f);
			}
			else
			{
				btn.Visible = false;
				lockBtn.Visible = false;
			}
		}

		_rerollButton.Text = $"Reroll ({RerollCost} mat)";
		_rerollButton.Disabled = gm.Materials < RerollCost;

		// Sell list — recreate each call
		foreach (var c in _sellList.GetChildren()) c.QueueFree();
		if (player != null)
		{
			int idx = 0;
			foreach (var w in player.GetActiveWeapons())
			{
				if (w?.Resource == null) { idx++; continue; }
				int sellValue = w.Resource.SellValue;
				int weaponIndex = idx;
				var sellBtn = new RichTooltipButton
				{
					Text = $"Vender {w.Resource.WeaponName}  +{sellValue} mat",
					CustomMinimumSize = new Vector2(260f, 36f),
					TooltipText = ItemDisplay.FormatWeaponTooltipBBCode(w),
				};
				sellBtn.AddThemeFontSizeOverride("font_size", 14);
				sellBtn.Pressed += () => OnSellWeapon(weaponIndex, sellValue);
				_sellList.AddChild(sellBtn);
				idx++;
			}
			_sellHeader.Text = $"SUAS ARMAS ({slotsUsed}/{slotsMax})";
		}
	}

	private void BuildUi()
	{
		_root = new Control { AnchorRight = 1, AnchorBottom = 1, MouseFilter = Control.MouseFilterEnum.Stop };
		AddChild(_root);

		var bg = new ColorRect
		{
			Color = new Color(0f, 0f, 0f, 0.65f),
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
			OffsetLeft = -380f,
			OffsetTop = -290f,
			OffsetRight = 380f,
			OffsetBottom = 290f,
		};
		_root.AddChild(panel);

		var margin = new MarginContainer();
		margin.AddThemeConstantOverride("margin_left", 20);
		margin.AddThemeConstantOverride("margin_right", 20);
		margin.AddThemeConstantOverride("margin_top", 16);
		margin.AddThemeConstantOverride("margin_bottom", 16);
		panel.AddChild(margin);

		var rootCol = new VBoxContainer();
		rootCol.AddThemeConstantOverride("separation", 10);
		margin.AddChild(rootCol);

		_titleLabel = new Label { Text = "SHOP", HorizontalAlignment = HorizontalAlignment.Center };
		_titleLabel.AddThemeFontSizeOverride("font_size", 20);
		rootCol.AddChild(_titleLabel);

		_materialsLabel = new Label { Text = "Materiais: 0", HorizontalAlignment = HorizontalAlignment.Center };
		_materialsLabel.AddThemeFontSizeOverride("font_size", 16);
		_materialsLabel.AddThemeColorOverride("font_color", new Color(1f, 0.85f, 0.4f));
		rootCol.AddChild(_materialsLabel);

		rootCol.AddChild(new HSeparator());

		var twoCols = new HBoxContainer();
		twoCols.AddThemeConstantOverride("separation", 16);
		twoCols.SizeFlagsHorizontal = Control.SizeFlags.ExpandFill;
		rootCol.AddChild(twoCols);

		// LEFT — offers
		var leftCol = new VBoxContainer();
		leftCol.AddThemeConstantOverride("separation", 8);
		leftCol.SizeFlagsHorizontal = Control.SizeFlags.ExpandFill;
		twoCols.AddChild(leftCol);

		var offersHeader = new Label { Text = "À VENDA  (cadeado trava p/ próxima wave)" };
		offersHeader.AddThemeFontSizeOverride("font_size", 13);
		offersHeader.AddThemeColorOverride("font_color", new Color(0.7f, 0.85f, 1f));
		leftCol.AddChild(offersHeader);

		for (int i = 0; i < OfferSlots; i++)
		{
			var row = new HBoxContainer();
			row.AddThemeConstantOverride("separation", 4);
			leftCol.AddChild(row);

			var btn = new Button
			{
				Text = "",
				CustomMinimumSize = new Vector2(0f, 90f),
				SizeFlagsHorizontal = Control.SizeFlags.ExpandFill,
			};
			int idx = i;
			btn.Pressed += () => OnBuy(idx);
			row.AddChild(btn);
			_offerButtons[i] = btn;

			var rich = new RichTextLabel
			{
				BbcodeEnabled = true,
				FitContent = true,
				ScrollActive = false,
				AnchorRight = 1f,
				AnchorBottom = 1f,
				OffsetLeft = 8f,
				OffsetTop = 6f,
				OffsetRight = -8f,
				OffsetBottom = -6f,
				MouseFilter = Control.MouseFilterEnum.Ignore,
			};
			rich.AddThemeFontSizeOverride("normal_font_size", 13);
			rich.AddThemeFontSizeOverride("bold_font_size", 15);
			btn.AddChild(rich);
			_offerRichLabels[i] = rich;

			var lockBtn = new Button
			{
				Text = "🔒",
				ToggleMode = true,
				CustomMinimumSize = new Vector2(50f, 90f),
				TooltipText = "Travar item — não vai re-rolar",
			};
			lockBtn.AddThemeFontSizeOverride("font_size", 22);
			int lockIdx = i;
			lockBtn.Toggled += (pressed) => OnLockToggle(lockIdx, pressed);
			row.AddChild(lockBtn);
			_lockButtons[i] = lockBtn;
		}

		_rerollButton = new Button
		{
			Text = $"Reroll ({RerollCost} mat)",
			CustomMinimumSize = new Vector2(380f, 40f),
		};
		_rerollButton.AddThemeFontSizeOverride("font_size", 14);
		_rerollButton.Pressed += OnReroll;
		leftCol.AddChild(_rerollButton);

		// RIGHT — sell
		var rightCol = new VBoxContainer();
		rightCol.AddThemeConstantOverride("separation", 8);
		rightCol.SizeFlagsHorizontal = Control.SizeFlags.ExpandFill;
		twoCols.AddChild(rightCol);

		_sellHeader = new Label { Text = "SUAS ARMAS" };
		_sellHeader.AddThemeFontSizeOverride("font_size", 14);
		_sellHeader.AddThemeColorOverride("font_color", new Color(0.7f, 0.85f, 1f));
		rightCol.AddChild(_sellHeader);

		_sellList = new VBoxContainer();
		_sellList.AddThemeConstantOverride("separation", 4);
		rightCol.AddChild(_sellList);

		var sellHint = new Label { Text = "Hover para ver stats  ·  metade do preço" };
		sellHint.AddThemeFontSizeOverride("font_size", 11);
		sellHint.AddThemeColorOverride("font_color", new Color(0.65f, 0.7f, 0.78f));
		rightCol.AddChild(sellHint);

		// CONTINUE row at bottom
		rootCol.AddChild(new HSeparator());
		_continueButton = new Button
		{
			Text = "Próxima Wave →",
			CustomMinimumSize = new Vector2(720f, 48f),
		};
		_continueButton.AddThemeFontSizeOverride("font_size", 16);
		_continueButton.Pressed += OnContinue;
		rootCol.AddChild(_continueButton);
	}

	private List<WeaponResource> BuildWeaponCatalog()
	{
		var list = new List<WeaponResource>();
		if (ShopWeapon1 != null) list.Add(ShopWeapon1);
		if (ShopWeapon2 != null) list.Add(ShopWeapon2);
		if (ShopWeapon3 != null) list.Add(ShopWeapon3);
		if (ShopWeapon4 != null) list.Add(ShopWeapon4);
		return list;
	}
}
