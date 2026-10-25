class_name WalkerFlattened
extends Node2D
## A stomped walker: its flattened sprite squishes, then hides.

var level: Level
var sprite: Sprite2D
var squash: Squash
var _texture: Texture2D
var _origin := Vector2.ZERO
var _flip_h := false


func setup(level_: Level, texture: Texture2D, origin: Vector2, flip_h: bool) -> void:
	level = level_
	_texture = texture
	_origin = origin
	_flip_h = flip_h


func _ready() -> void:
	assert(level != null, "setup() not called")
	sprite = Sprite2D.new()
	sprite.texture = _texture
	sprite.centered = false
	sprite.offset = -_origin
	sprite.flip_h = _flip_h
	add_child(sprite)
	squash = Squash.new(sprite)
	squash.play_squish(func() -> void:
		visible = false
		process_mode = PROCESS_MODE_DISABLED)
