class_name EnemyDeath
extends Node2D
## A stomped flyer or leaper: upside down, it falls through everything.

const GRAVITY := 965.04
const MAX_FALL_SPEED := 202.5

var level: Level
var velocity_y := 0.0
var _texture: Texture2D
var _origin := Vector2.ZERO


func setup(level_: Level, texture: Texture2D, origin: Vector2) -> void:
	level = level_
	_texture = texture
	_origin = origin


func _ready() -> void:
	assert(level != null, "setup() not called")
	var sprite := Sprite2D.new()
	sprite.texture = _texture
	sprite.centered = false
	sprite.offset = -_origin
	sprite.flip_v = true
	add_child(sprite)
	Enemy.add_enabler(self, Rect2(-_origin, _texture.get_size()))


func _physics_process(delta: float) -> void:
	velocity_y = minf(velocity_y + GRAVITY * delta, MAX_FALL_SPEED)
	position.y += velocity_y * delta
