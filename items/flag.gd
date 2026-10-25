class_name Flag
extends Node2D
## The goal flag, as tall as the screen; the level places it.

const FPS := 7.5

var level: Level


func setup(level_: Level) -> void:
	level = level_


func _ready() -> void:
	assert(level != null, "setup() not called")
	var sprite := AnimatedSprite2D.new()
	sprite.sprite_frames = Level.sprite_frames({"wave": [
		["res://art/flag/sprite_1.png", "res://art/flag/sprite_2.png"], FPS]})
	sprite.centered = false
	sprite.play("wave")
	add_child(sprite)
