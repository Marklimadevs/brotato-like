using System;
using System.Collections.Generic;
using Godot;

namespace BrotatoLike;

public partial class GameManager : Node
{
	public static GameManager Instance { get; private set; }

	public RandomNumberGenerator Rng { get; private set; }
	public Player Player { get; set; }
	public HashSet<EnemyBase> Enemies { get; } = new();
	public CharacterPreset SelectedCharacter { get; set; }
	public int SelectedDifficulty { get; set; } = 1;

	public int Xp { get; private set; }
	public int Level { get; private set; } = 1;
	public int XpForNextLevel { get; private set; } = 5;
	public int Materials { get; private set; }
	public int PendingLevelUps { get; private set; }

	public event Action LevelUp;
	public event Action LevelUpClosed;
	public event Action XpChanged;
	public event Action MaterialsChanged;
	public event Action PlayerDied;
	public event Action ShopOpened;
	public event Action ShopClosed;

	public override void _EnterTree()
	{
		Instance = this;
		Rng = new RandomNumberGenerator();
		Rng.Randomize();
		SaveData.Load();
	}

	public override void _ExitTree()
	{
		if (Instance == this)
			Instance = null;
	}

	public void RegisterEnemy(EnemyBase e) => Enemies.Add(e);
	public void UnregisterEnemy(EnemyBase e) => Enemies.Remove(e);

	public void AddXp(int amount)
	{
		float mult = Player?.Stats?.XpGainMult ?? 1f;
		Xp += Mathf.Max(1, (int)(amount * mult));
		XpChanged?.Invoke();
		while (Xp >= XpForNextLevel)
		{
			Xp -= XpForNextLevel;
			Level++;
			XpForNextLevel = 5 + Level * 3;
			PendingLevelUps++;
			// Não dispara LevelUp aqui — acumula até o fim da wave
		}
		XpChanged?.Invoke();
	}

	public void DrainPendingLevelUps()
	{
		int pending = PendingLevelUps;
		PendingLevelUps = 0;
		for (int i = 0; i < pending; i++)
			LevelUp?.Invoke();
		XpChanged?.Invoke();
	}

	public void ForceLevelUp()
	{
		Level++;
		XpForNextLevel = 5 + Level * 3;
		LevelUp?.Invoke();
		XpChanged?.Invoke();
	}

	public void NotifyLevelUpClosed() => LevelUpClosed?.Invoke();

	public void NotifyPlayerDied() => PlayerDied?.Invoke();

	public void AddMaterial(int amount)
	{
		if (amount <= 0) return;
		Materials += amount;
		MaterialsChanged?.Invoke();
	}

	public bool SpendMaterial(int amount)
	{
		if (amount <= 0) return true;
		if (Materials < amount) return false;
		Materials -= amount;
		MaterialsChanged?.Invoke();
		return true;
	}

	public void OpenShop() => ShopOpened?.Invoke();
	public void NotifyShopClosed() => ShopClosed?.Invoke();

	public void ResetRunState()
	{
		Xp = 0;
		Level = 1;
		XpForNextLevel = 5;
		Materials = 0;
		PendingLevelUps = 0;
		Enemies.Clear();
		Player = null;
	}
}
