class_name PlayerDeath
extends Node2D
## The player's death: a still moment, then a jump up and a fall through
## everything, off the bottom of the screen. Runs while the game is paused.

const FREEZE := 0.27
const JUMP_SPEED := 270.0
const GRAVITY := 632.84
const MAX_FALL_SPEED := 227.37

var level: Level
var velocity := Vector2.ZERO
var _jumping := false
var _flip_h := false


func setup(level_: Level, flip_h: bool) -> void:
	level = level_
	_flip_h = flip_h


func _ready() -> void:
	assert(level != null, "setup() not called")
	process_mode = PROCESS_MODE_ALWAYS
	var sprite := Sprite2D.new()
	sprite.texture = load("res://art/player/sprite_1.png")
	sprite.centered = false
	sprite.offset = -Player.ORIGIN
	sprite.flip_h = _flip_h
	add_child(sprite)
	await get_tree().create_timer(FREEZE, true, true).timeout
	velocity.y = -JUMP_SPEED
	_jumping = true


func _physics_process(delta: float) -> void:
	if not _jumping:
		return
	velocity.y = minf(velocity.y + GRAVITY * delta, MAX_FALL_SPEED)
	position += velocity * delta
	if position.y - Player.ORIGIN.y >= Screen.height:
		process_mode = PROCESS_MODE_DISABLED
		level.on_death()
