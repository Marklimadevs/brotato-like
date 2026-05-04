class_name XpGem
extends Area2D

@export var Radius: float = 6.0
@export var GemColor: Color = Color(0.45, 1, 0.55)

var Value: int = 1
var MaterialValue: int = 0

var _player: Player = null
var _attracting: bool = false
var _attract_speed: float = 60.0
var _consumed: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	queue_redraw()


func _physics_process(delta: float) -> void:
	if _consumed:
		return
	if _player == null:
		_player = GameManager.Player
	if _player == null:
		return

	var to_player: Vector2 = _player.global_position - global_position
	var dist: float = to_player.length()
	var magnet_r: float = 80.0
	if _player.Stats != null:
		magnet_r = _player.Stats.PickupRadius

	if _attracting or dist < magnet_r:
		_attracting = true
		_attract_speed += 700.0 * delta
		global_position += to_player.normalized() * _attract_speed * delta


func _draw() -> void:
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, -Radius),
		Vector2(Radius, 0),
		Vector2(0, Radius),
		Vector2(-Radius, 0),
	]), GemColor)
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, -Radius * 0.4),
		Vector2(Radius * 0.4, 0),
		Vector2(0, Radius * 0.4),
		Vector2(-Radius * 0.4, 0),
	]), Color(1, 1, 1, 0.7))


func _on_body_entered(body: Node2D) -> void:
	if _consumed:
		return
	if body is Player:
		_consumed = true
		GameManager.add_xp(Value)
		if MaterialValue > 0:
			GameManager.add_material(MaterialValue)
		queue_free()
