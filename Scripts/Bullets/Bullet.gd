class_name Bullet
extends Area2D

var Speed: float = 600.0
var Direction: Vector2 = Vector2.RIGHT
var Damage: int = 4
var BulletColor: Color = Color(1, 0.95, 0.5)
var Radius: float = 5.0
var Lifetime: float = 1.5
var Pierce: int = 0  # additional enemies the bullet can pass through

var _age: float = 0.0
var _hits_remaining: int = 1
var _consumed: bool = false
var _already_hit: Dictionary = {}


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_hits_remaining = 1 + Pierce

	var shape: CollisionShape2D = get_node("CollisionShape2D")
	var circle: CircleShape2D = shape.shape.duplicate() as CircleShape2D
	circle.radius = Radius
	shape.shape = circle

	queue_redraw()


func _physics_process(delta: float) -> void:
	if _consumed:
		return
	position += Direction * Speed * delta
	_age += delta
	if _age >= Lifetime:
		queue_free()


func _draw() -> void:
	draw_circle(Vector2.ZERO, Radius, BulletColor)
	draw_circle(Vector2.ZERO, Radius * 0.5, Color(1, 1, 1, 0.6))


func _on_body_entered(body: Node2D) -> void:
	if _consumed:
		return
	if body is EnemyBase:
		var enemy: EnemyBase = body
		if _already_hit.has(enemy):
			return
		_already_hit[enemy] = true

		var player: Player = GameManager.Player
		var is_crit: bool = false
		var final_dmg: int = Damage

		if player != null and player.stats != null:
			if GameManager.Rng.randf() < player.stats.CritChance:
				is_crit = true
				final_dmg = maxi(1, int(Damage * player.stats.CritMultiplier))

		enemy.take_damage(final_dmg, is_crit)

		if player != null and player.stats != null and player.stats.Knockback > 0.0:
			enemy.apply_knockback(Direction * player.stats.Knockback)

		_hits_remaining -= 1
		if _hits_remaining <= 0:
			_consumed = true
			queue_free()
	else:
		# Hit wall — always despawn
		_consumed = true
		queue_free()
