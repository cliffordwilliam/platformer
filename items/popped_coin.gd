class_name PoppedCoin
extends Node2D
## The coin that hops out of a gift block: purely for show.

const FPS := 30.0
const HEIGHT := 45.0
const TIME := 0.2667

var level: Level


func setup(level_: Level) -> void:
	level = level_


func _ready() -> void:
	assert(level != null, "setup() not called")
	var sprite := AnimatedSprite2D.new()
	sprite.sprite_frames = Level.sprite_frames({"spin": [
		["res://art/coin/sprite_1.png", "res://art/coin/sprite_2.png"], FPS]})
	sprite.centered = false
	sprite.play("spin")
	add_child(sprite)
	var tween := create_tween()
	tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	tween.tween_property(self, "position:y", position.y - HEIGHT, TIME).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position:y", position.y, TIME).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_callback(func() -> void:
		visible = false
		process_mode = PROCESS_MODE_DISABLED)
