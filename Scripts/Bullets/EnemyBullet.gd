class_name EnemyBullet
extends Area2D

var Speed: float = 350.0
var Direction: Vector2 = Vector2.RIGHT
var Damage: int = 6
var Lifetime: float = 2.5
var Radius: float = 5.0
var SpikeColor: Color = Color(0.9, 0.4, 0.95)

var _age: float = 0.0
var _consumed: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	rotation = Direction.angle() + PI / 2.0
	queue_redraw()


func _physics_process(delta: float) -> void:
	if _consumed:
		return
	position += Direction * Speed * delta
	_age += delta
	if _age >= Lifetime:
		queue_free()


func _draw() -> void:
	# Spike pointing "up" in local space (Direction is rotated to face +x via Rotation)
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, -Radius * 1.5),
		Vector2(Radius * 0.9, Radius * 0.7),
		Vector2(-Radius * 0.9, Radius * 0.7),
	]), SpikeColor)
	draw_circle(Vector2(0, -Radius * 0.4), Radius * 0.35, Color(1, 1, 1, 0.55))


func _on_body_entered(body: Node2D) -> void:
	if _consumed:
		return
	if body is Player:
		_consumed = true
		var p: Player = body
		p.take_damage(Damage)
		queue_free()
	else:
		# Hit wall
		_consumed = true
		queue_free()
