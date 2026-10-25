class_name WalkerBonked
extends Node2D
## A walker knocked out from below: upside down, it hops and falls
## through everything.

const BOUNCE_SPEED := 227.37
const SIDE_SPEED := 33.75
const GRAVITY := 1923.75
const MAX_FALL_SPEED := 270.0

var level: Level
var velocity := Vector2.ZERO
var _texture: Texture2D
var _origin := Vector2.ZERO
var _flip_h := false


func setup(level_: Level, texture: Texture2D, origin: Vector2, flip_h: bool) -> void:
	level = level_
	_texture = texture
	_origin = origin
	_flip_h = flip_h
	# The art faces left, so flip_h means facing right: fly off left.
	velocity = Vector2(-SIDE_SPEED if flip_h else SIDE_SPEED, -BOUNCE_SPEED)


func _ready() -> void:
	assert(level != null, "setup() not called")
	var sprite := Sprite2D.new()
	sprite.texture = _texture
	sprite.centered = false
	sprite.offset = -_origin
	sprite.flip_h = _flip_h
	sprite.flip_v = true
	add_child(sprite)


func _physics_process(delta: float) -> void:
	velocity.y = minf(velocity.y + GRAVITY * delta, MAX_FALL_SPEED)
	position += velocity * delta
	if position.y > Screen.height + Grid.TILE:
		process_mode = PROCESS_MODE_DISABLED
