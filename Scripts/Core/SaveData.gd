class_name SaveData
extends RefCounted

const SAVE_PATH := "user://save.json"

static var HighestUnlockedDifficulty: int = 1


static func load_data() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var json_str: String = file.get_as_text()
	file.close()

	var parsed = JSON.parse_string(json_str)
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	if parsed.has("highestDifficulty"):
		HighestUnlockedDifficulty = clampi(int(parsed["highestDifficulty"]), DifficultyConfig.MIN, DifficultyConfig.MAX)


static func save_data() -> void:
	var dict: Dictionary = {
		"highestDifficulty": HighestUnlockedDifficulty,
	}
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(dict))
	file.close()


static func notify_difficulty_completed(completed: int) -> void:
	if completed >= HighestUnlockedDifficulty and completed < DifficultyConfig.MAX:
		HighestUnlockedDifficulty = completed + 1
		save_data()
