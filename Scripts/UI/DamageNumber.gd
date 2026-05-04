class_name DamageNumber
extends Node2D

const _LIFETIME := 0.55
const _FONT_SIZE := 22
const _CRIT_FONT_SIZE := 32

var _text: String = "0"
var _color: Color = Color.WHITE
var _is_crit: bool = false
var _age: float = 0.0
var _velocity: Vector2 = Vector2(0, -55)
static var _font: Font = null


func _ready() -> void:
	z_index = 100
	if _font == null:
		_font = ThemeDB.fallback_font


func _process(delta: float) -> void:
	_age += delta
	position += _velocity * delta
	_velocity = _velocity.lerp(Vector2.ZERO, delta * 4.0)
	queue_redraw()
	if _age >= _LIFETIME:
		queue_free()


func _draw() -> void:
	if _font == null:
		return
	var alpha: float = clampf(1.0 - (_age / _LIFETIME), 0.0, 1.0)
	var color: Color = _color
	color.a = alpha
	var outline := Color(0, 0, 0, alpha * 0.85)
	var font_size: int = _CRIT_FONT_SIZE if _is_crit else _FONT_SIZE

	var size: Vector2 = _font.get_string_size(_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var origin := Vector2(-size.x / 2.0, size.y / 2.0)

	for off in [Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1)]:
		draw_string(_font, origin + off, _text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, outline)
	draw_string(_font, origin, _text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)


static func spawn(parent: Node, world_pos: Vector2, amount: int, color: Color, is_crit: bool = false) -> void:
	var text: String = ("%d!" % amount) if is_crit else str(amount)
	spawn_text(parent, world_pos, text, color, is_crit)


static func spawn_text(parent: Node, world_pos: Vector2, text: String, color: Color, is_crit: bool = false) -> void:
	if parent == null:
		return
	var dn := DamageNumber.new()
	dn._text = text
	dn._color = color
	dn._is_crit = is_crit
	parent.add_child(dn)
	var jitter := Vector2(GameManager.Rng.randf_range(-6, 6), -8)
	dn.global_position = world_pos + jitter
