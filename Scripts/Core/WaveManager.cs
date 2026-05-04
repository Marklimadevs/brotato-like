using System;
using System.Collections.Generic;
using Godot;

namespace BrotatoLike;

public partial class WaveManager : Node
{
	[Export] public PackedScene EnemyScene;
	[Export] public EnemyResource RunnerEnemy;
	[Export] public EnemyResource SwarmerEnemy;
	[Export] public EnemyResource TankEnemy;
	[Export] public EnemyResource SplitterEnemy;
	[Export] public EnemyResource ChargerEnemy;
	[Export] public EnemyResource RangedEnemy;
	[Export] public EnemyResource BossEnemy;
	[Export] public NodePath SpawnRootPath;
	[Export] public Vector2 ArenaSize = new(1600, 900);
	[Export] public float SpawnMargin = 60f;
	[Export] public float BossSpawnDelay = 5f;

	public static WaveManager Instance { get; private set; }

	public int CurrentWaveIndex { get; private set; }
	public int TotalWaves => _waves?.Length ?? 0;
	public float WaveTimeRemaining { get; private set; }
	public bool BetweenWaves { get; private set; }
	public bool GameWon { get; private set; }
	public EnemyBase CurrentBoss { get; private set; }
	public bool IsBossWave => _waves != null && CurrentWaveIndex == _waves.Length - 1;

	public event Action WaveStarted;
	public event Action WaveEnded;
	public event Action GameWonEvent;
	public event Action BossSpawned;

	private struct WaveDef
	{
		public float Duration;
		public int BatchSize;
		public float Interval;
		public EnemyResource[] Pool;
	}

	private WaveDef[] _waves;
	private Node _spawnRoot;
	private float _spawnTimer;
	private bool _bossSpawned;

	public override void _EnterTree()
	{
		Instance = this;
	}

	public override void _ExitTree()
	{
		if (Instance == this)
			Instance = null;
		if (GameManager.Instance != null)
		{
			GameManager.Instance.LevelUpClosed -= OnAfterLevelUpBetweenWaves;
			GameManager.Instance.ShopClosed -= OnShopClosedBetweenWaves;
		}
	}

	public override void _Ready()
	{
		_spawnRoot = SpawnRootPath != null && !SpawnRootPath.IsEmpty
			? GetNode(SpawnRootPath)
			: GetParent();

		_waves = new[]
		{
			new WaveDef { Duration = 30f, BatchSize = 4, Interval = 2.2f, Pool = new[] { RunnerEnemy } },
			new WaveDef { Duration = 30f, BatchSize = 5, Interval = 2.0f, Pool = new[] { RunnerEnemy, RunnerEnemy, SwarmerEnemy, SplitterEnemy } },
			new WaveDef { Duration = 30f, BatchSize = 6, Interval = 1.7f, Pool = new[] { RunnerEnemy, SwarmerEnemy, TankEnemy, SplitterEnemy, ChargerEnemy } },
			new WaveDef { Duration = 30f, BatchSize = 7, Interval = 1.5f, Pool = new[] { RunnerEnemy, SwarmerEnemy, TankEnemy, ChargerEnemy, RangedEnemy } },
			// Boss wave: long duration (only ends on boss kill), low minion spawn
			new WaveDef { Duration = 9999f, BatchSize = 2, Interval = 4.0f, Pool = new[] { SwarmerEnemy, SwarmerEnemy, RunnerEnemy, RangedEnemy } },
		};

		StartWave(0);
	}

	public override void _Process(double delta)
	{
		if (GameWon || BetweenWaves) return;
		if (CurrentWaveIndex >= _waves.Length) return;
		if (GameManager.Instance.Player != null && !GameManager.Instance.Player.IsAlive) return;

		float dt = (float)delta;
		WaveTimeRemaining -= dt;

		// Boss spawn check on the last wave
		if (IsBossWave && !_bossSpawned)
		{
			float elapsed = _waves[CurrentWaveIndex].Duration - WaveTimeRemaining;
			if (elapsed >= BossSpawnDelay)
				SpawnBoss();
		}

		_spawnTimer -= dt;
		if (_spawnTimer <= 0f)
		{
			SpawnBatch(_waves[CurrentWaveIndex]);
			_spawnTimer = _waves[CurrentWaveIndex].Interval;
		}

		if (WaveTimeRemaining <= 0f && !IsBossWave)
			EndCurrentWave();
	}

	private void StartWave(int idx)
	{
		CurrentWaveIndex = idx;
		WaveTimeRemaining = _waves[idx].Duration;
		BetweenWaves = false;
		_spawnTimer = 0.5f;
		_bossSpawned = false;
		CurrentBoss = null;
		WaveStarted?.Invoke();
		GD.Print($"Wave {idx + 1} iniciada");
	}

	private void EndCurrentWave()
	{
		BetweenWaves = true;
		WaveTimeRemaining = 0f;
		ClearEnemies();
		WaveEnded?.Invoke();
		GD.Print($"Wave {CurrentWaveIndex + 1} terminada");

		if (GameManager.Instance.Player != null && !GameManager.Instance.Player.IsAlive)
			return;

		GameManager.Instance.LevelUpClosed += OnAfterLevelUpBetweenWaves;
		// Bônus grátis por completar a wave + todos os pendentes acumulados
		GameManager.Instance.ForceLevelUp();
		GameManager.Instance.DrainPendingLevelUps();
	}

	private void OnAfterLevelUpBetweenWaves()
	{
		GameManager.Instance.LevelUpClosed -= OnAfterLevelUpBetweenWaves;

		if (GameManager.Instance.Player != null && !GameManager.Instance.Player.IsAlive)
			return;

		int next = CurrentWaveIndex + 1;
		if (next >= _waves.Length)
		{
			GameWon = true;
			GameWonEvent?.Invoke();
			GD.Print("VITÓRIA! Todas as 5 waves completas.");
			return;
		}

		GameManager.Instance.ShopClosed += OnShopClosedBetweenWaves;
		GameManager.Instance.OpenShop();
	}

	private void OnShopClosedBetweenWaves()
	{
		GameManager.Instance.ShopClosed -= OnShopClosedBetweenWaves;

		if (GameManager.Instance.Player != null && !GameManager.Instance.Player.IsAlive)
			return;

		StartWave(CurrentWaveIndex + 1);
	}

	private void SpawnBoss()
	{
		if (BossEnemy == null || EnemyScene == null) return;
		_bossSpawned = true;
		var enemy = EnemyScene.Instantiate<EnemyBase>();
		enemy.Resource = BossEnemy;
		// Spawn at top edge, telegraphed
		enemy.Position = new Vector2(0f, -ArenaSize.Y / 2f + SpawnMargin);
		_spawnRoot.AddChild(enemy);
		CurrentBoss = enemy;
		GD.Print("BOSS apareceu!");
		BossSpawned?.Invoke();
	}

	public void NotifyBossKilled()
	{
		if (BetweenWaves || GameWon) return;
		CurrentBoss = null;
		if (IsBossWave)
		{
			GD.Print("Boss derrotado — terminando wave 5");
			EndCurrentWave();
		}
	}

	private void SpawnBatch(WaveDef wave)
	{
		if (EnemyScene == null || wave.Pool == null) return;
		var rng = GameManager.Instance.Rng;
		for (int i = 0; i < wave.BatchSize; i++)
		{
			var res = wave.Pool[rng.RandiRange(0, wave.Pool.Length - 1)];
			if (res == null) continue;
			SpawnOne(res);
		}
	}

	private void SpawnOne(EnemyResource res)
	{
		var enemy = EnemyScene.Instantiate<EnemyBase>();
		enemy.Resource = res;
		enemy.Position = RandomEdgePosition();
		_spawnRoot.AddChild(enemy);
	}

	private void ClearEnemies()
	{
		var snapshot = new List<EnemyBase>(GameManager.Instance.Enemies);
		foreach (var e in snapshot)
		{
			if (IsInstanceValid(e))
				e.QueueFree();
		}
		CurrentBoss = null;
	}

	private Vector2 RandomEdgePosition()
	{
		var rng = GameManager.Instance.Rng;
		float halfW = ArenaSize.X / 2f - SpawnMargin;
		float halfH = ArenaSize.Y / 2f - SpawnMargin;
		int side = rng.RandiRange(0, 3);
		return side switch
		{
			0 => new Vector2(rng.RandfRange(-halfW, halfW), -halfH),
			1 => new Vector2(rng.RandfRange(-halfW, halfW), halfH),
			2 => new Vector2(-halfW, rng.RandfRange(-halfH, halfH)),
			_ => new Vector2(halfW, rng.RandfRange(-halfH, halfH)),
		};
	}
}
