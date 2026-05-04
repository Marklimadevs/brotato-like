class_name CameraShake
extends Camera2D

@export var Decay: float = 7.0
var _strength: float = 0.0


func _process(delta: float) -> void:
	if _strength > 0.05:
		var rng: RandomNumberGenerator = GameManager.Rng
		offset = Vector2(rng.randf_range(-1.0, 1.0), rng.randf_range(-1.0, 1.0)) * _strength
		_strength = lerpf(_strength, 0.0, delta * Decay)
	elif _strength > 0.0:
		_strength = 0.0
		offset = Vector2.ZERO


func shake(amount: float) -> void:
	if amount > _strength:
		_strength = amount
