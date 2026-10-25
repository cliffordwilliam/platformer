class_name Checkpoint
extends Area2D
## A small flag: touching it raises it and makes it the respawn point.

const FPS := 7.5
const ORIGIN := Vector2(9, 36)
const SIZE := Vector2(18, 36)

var level: Level
var cell: Vector2i
var raised := false
var sprite: AnimatedSprite2D
var squash: Squash


func setup(level_: Level) -> void:
	level = level_


func _ready() -> void:
	assert(level != null, "setup() not called")
	collision_layer = Level.LAYER_CHECKPOINTS
	collision_mask = 0
	cell = Vector2i(floori(position.x / Grid.TILE), floori(position.y / Grid.TILE) - 1)
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	frames.add_animation("down")
	frames.set_animation_loop("down", false)
	frames.add_frame("down", _region("res://art/flag/sprite_1.png", 36))
	frames.add_animation("raised")
	frames.set_animation_speed("raised", FPS)
	frames.add_frame("raised", _region("res://art/flag/sprite_1.png", 18))
	frames.add_frame("raised", _region("res://art/flag/sprite_2.png", 18))
	sprite = Enemy.add_sprite(self, frames, ORIGIN)
	squash = Squash.new(sprite)
	Enemy.add_box(self, Rect2(Vector2.ZERO, SIZE), ORIGIN)
	raised = cell == Level.respawn_cell
	sprite.play("raised" if raised else "down")


func _region(path: String, top: int) -> AtlasTexture:
	var texture := AtlasTexture.new()
	texture.atlas = load(path)
	texture.region = Rect2(0, top, SIZE.x, SIZE.y)
	return texture


func touch() -> void:
	if raised:
		return
	Level.respawn_cell = cell
	raised = true
	sprite.play("raised")
	squash.play_bounce()
	level.sounds.play(Sounds.Effect.CHECKPOINT)
	for other: Checkpoint in level.checkpoint_layer.get_children():
		if other != self and other.raised:
			other.raised = false
			other.sprite.play("down")
