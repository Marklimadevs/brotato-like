using Godot;

namespace BrotatoLike;

public static class SaveData
{
	private const string SavePath = "user://save.json";

	public static int HighestUnlockedDifficulty { get; private set; } = 1;

	public static void Load()
	{
		if (!FileAccess.FileExists(SavePath)) return;
		var file = FileAccess.Open(SavePath, FileAccess.ModeFlags.Read);
		if (file == null) return;
		string json = file.GetAsText();
		file.Close();

		try
		{
			var parsed = Json.ParseString(json);
			if (parsed.VariantType != Variant.Type.Dictionary) return;
			var dict = parsed.AsGodotDictionary();
			if (dict.ContainsKey("highestDifficulty"))
			{
				int v = dict["highestDifficulty"].AsInt32();
				HighestUnlockedDifficulty = Mathf.Clamp(v, DifficultyConfig.Min, DifficultyConfig.Max);
			}
		}
		catch (System.Exception e)
		{
			GD.PushWarning($"SaveData parse failed: {e.Message}");
		}
	}

	public static void Save()
	{
		var dict = new Godot.Collections.Dictionary
		{
			{ "highestDifficulty", HighestUnlockedDifficulty },
		};
		var file = FileAccess.Open(SavePath, FileAccess.ModeFlags.Write);
		if (file == null) return;
		file.StoreString(Json.Stringify(dict));
		file.Close();
	}

	public static void NotifyDifficultyCompleted(int completedDifficulty)
	{
		if (completedDifficulty >= HighestUnlockedDifficulty && completedDifficulty < DifficultyConfig.Max)
		{
			HighestUnlockedDifficulty = completedDifficulty + 1;
			Save();
		}
	}
}
