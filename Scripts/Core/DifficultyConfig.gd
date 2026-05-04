class_name DifficultyConfig
extends RefCounted

const MIN := 1
const MAX := 5


static func get_multipliers(difficulty: int) -> Dictionary:
	var d: int = clampi(difficulty, MIN, MAX)
	match d:
		1: return {"hp_mult": 1.00, "damage_mult": 1.00, "speed_mult": 1.00}
		2: return {"hp_mult": 1.25, "damage_mult": 1.15, "speed_mult": 1.05}
		3: return {"hp_mult": 1.50, "damage_mult": 1.30, "speed_mult": 1.10}
		4: return {"hp_mult": 1.75, "damage_mult": 1.50, "speed_mult": 1.15}
		5: return {"hp_mult": 2.00, "damage_mult": 1.75, "speed_mult": 1.20}
	return {"hp_mult": 1.0, "damage_mult": 1.0, "speed_mult": 1.0}


static func get_label(difficulty: int) -> String:
	return "D%d" % clampi(difficulty, MIN, MAX)


static func get_description(difficulty: int) -> String:
	var m = get_multipliers(difficulty)
	if difficulty == 1:
		return "Padrão — sem modificadores"
	return "+%d%% HP  ·  +%d%% Dano  ·  +%d%% Velocidade" % [
		round((m["hp_mult"] - 1.0) * 100.0),
		round((m["damage_mult"] - 1.0) * 100.0),
		round((m["speed_mult"] - 1.0) * 100.0),
	]
