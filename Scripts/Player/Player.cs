using System.Collections.Generic;
using System.Linq;
using Godot;

namespace BrotatoLike;

public partial class Player : CharacterBody2D
{
	public const int MaxWeaponSlots = 4;

	[Export] public float Radius = 16f;
	[Export] public Color BaseColor = new(0.45f, 0.85f, 1f);
	[Export] public WeaponResource Weapon1;
	[Export] public WeaponResource Weapon2;
	[Export] public PackedScene WeaponScene;

	public Stats Stats { get; private set; }
	public bool IsAlive => _alive;
	public int EquippedWeaponCount
	{
		get
		{
			int count = 0;
			foreach (var _ in GetActiveWeapons()) count++;
			return count;
		}
	}

	private Node2D _weaponMount;
	private Area2D _hurtBox;
	private CameraShake _camera;
	private float _iframeTimer;
	private float _hitFlashTimer;
	private float _regenAccumulator;
	private bool _alive = true;

	public override void _Ready()
	{
		Stats = new Stats();
		GameManager.Instance.Player = this;

		_weaponMount = GetNode<Node2D>("WeaponMount");
		_hurtBox = GetNode<Area2D>("HurtBox");
		_camera = GetNode<CameraShake>("Camera2D");

		var preset = GameManager.Instance.SelectedCharacter;
		if (preset != null && preset.StartingWeapons != null && preset.StartingWeapons.Count > 0)
		{
			BaseColor = preset.BaseColor;
			foreach (var w in preset.StartingWeapons)
				AddWeapon(w);
		}
		else
		{
			// Fallback for running Main.tscn directly in editor (no character pick)
			AddWeapon(Weapon1);
			AddWeapon(Weapon2);
		}

		QueueRedraw();
	}

	public override void _PhysicsProcess(double delta)
	{
		if (!_alive) return;

		if (_iframeTimer > 0f) _iframeTimer -= (float)delta;

		Vector2 dir = Input.GetVector("move_left", "move_right", "move_up", "move_down");
		Velocity = dir * Stats.MoveSpeed;
		MoveAndSlide();

		if (_iframeTimer <= 0f)
			CheckEnemyContact();
	}

	private void CheckEnemyContact()
	{
		if (_hurtBox == null) return;
		foreach (var body in _hurtBox.GetOverlappingBodies())
		{
			if (body is EnemyBase enemy && enemy.Resource != null)
			{
				TakeDamage(enemy.ScaledDamage);
				return;
			}
		}
	}

	public override void _Process(double delta)
	{
		if (_hitFlashTimer > 0f)
		{
			_hitFlashTimer -= (float)delta;
			if (_hitFlashTimer <= 0f)
				Modulate = Colors.White;
		}

		// HP regen
		if (_alive && Stats != null && Stats.HpRegenPerSec > 0f && Stats.CurrentHp < Stats.MaxHp)
		{
			_regenAccumulator += Stats.HpRegenPerSec * (float)delta;
			if (_regenAccumulator >= 1f)
			{
				int amount = Mathf.FloorToInt(_regenAccumulator);
				_regenAccumulator -= amount;
				int oldHp = Stats.CurrentHp;
				Stats.CurrentHp = Mathf.Min(Stats.MaxHp, Stats.CurrentHp + amount);
				int gained = Stats.CurrentHp - oldHp;
				if (gained > 0)
					DamageNumber.SpawnText(GetTree().CurrentScene, GlobalPosition + new Vector2(0f, -Radius - 4f), $"+{gained}", new Color(0.5f, 1f, 0.55f));
			}
		}
	}

	public bool AddWeapon(WeaponResource res)
	{
		if (res == null || WeaponScene == null) return false;
		if (EquippedWeaponCount >= MaxWeaponSlots) return false;
		var w = WeaponScene.Instantiate<Weapon>();
		w.Resource = res;
		_weaponMount.AddChild(w);
		LayoutWeapons();
		return true;
	}

	public bool RemoveWeaponAt(int index)
	{
		var weapons = GetActiveWeapons().ToList();
		if (index < 0 || index >= weapons.Count) return false;
		var w = weapons[index];
		_weaponMount.RemoveChild(w);
		w.QueueFree();
		LayoutWeapons();
		return true;
	}

	public IEnumerable<Weapon> GetActiveWeapons()
	{
		if (_weaponMount == null || !IsInstanceValid(_weaponMount))
			yield break;
		foreach (var c in _weaponMount.GetChildren())
			if (c is Weapon w) yield return w;
	}

	private void LayoutWeapons()
	{
		var weapons = new List<Weapon>();
		foreach (var w in GetActiveWeapons())
			if (IsInstanceValid(w)) weapons.Add(w);

		int n = weapons.Count;
		float radius = n <= 1 ? 0f : 24f;
		for (int i = 0; i < n; i++)
		{
			float angle = (i / (float)n) * Mathf.Tau - Mathf.Pi / 2f;
			weapons[i].Position = new Vector2(Mathf.Cos(angle), Mathf.Sin(angle)) * radius;
		}
	}

	public void TakeDamage(int dmg)
	{
		if (!_alive || _iframeTimer > 0f) return;

		// Apply armor reduction (always at least 1 dmg)
		int actualDmg = Mathf.Max(1, dmg - Stats.Armor);
		Stats.CurrentHp -= actualDmg;
		_iframeTimer = 0.45f;
		Modulate = new Color(3f, 1.4f, 1.4f);
		_hitFlashTimer = 0.08f;

		DamageNumber.Spawn(GetTree().CurrentScene, GlobalPosition + new Vector2(0f, -Radius - 4f), actualDmg, new Color(1f, 0.55f, 0.55f));
		_camera?.Shake(11f);

		if (Stats.CurrentHp <= 0)
			Die();
	}

	private void Die()
	{
		if (!_alive) return;
		_alive = false;
		Visible = false;

		SetPhysicsProcess(false);
		CollisionLayer = 0;
		CollisionMask = 0;
		if (_hurtBox != null)
			_hurtBox.Monitoring = false;

		if (_weaponMount != null && IsInstanceValid(_weaponMount))
		{
			foreach (var child in _weaponMount.GetChildren())
			{
				if (child is Node n) n.QueueFree();
			}
		}

		GD.Print("Player died!");
		GameManager.Instance.NotifyPlayerDied();
	}

	public override void _Draw()
	{
		DrawCircle(Vector2.Zero, Radius, BaseColor);
		DrawCircle(new Vector2(-Radius * 0.3f, -Radius * 0.3f), Radius * 0.28f, new Color(1f, 1f, 1f, 0.35f));
		DrawArc(Vector2.Zero, Radius - 1.5f, 0f, Mathf.Tau, 32, new Color(0.1f, 0.2f, 0.3f), 2f, true);
	}
}
