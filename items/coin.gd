class_name Coin
extends Area2D
## A coin placed in the level; the player collects it by touching it.

const FPS := 7.5
const BOX := Rect2(3, 3, 12, 12)

var level: Level


func setup(level_: Level) -> void:
	level = level_


func _ready() -> void:
	assert(level != null, "setup() not called")
	collision_layer = Level.LAYER_PICKUPS
	collision_mask = 0
	var sprite := AnimatedSprite2D.new()
	sprite.sprite_frames = Level.sprite_frames({"spin": [
		["res://art/coin/sprite_1.png", "res://art/coin/sprite_2.png"], FPS]})
	sprite.centered = false
	sprite.play("spin")
	add_child(sprite)
	var rectangle := RectangleShape2D.new()
	rectangle.size = BOX.size
	var box := CollisionShape2D.new()
	box.shape = rectangle
	box.position = BOX.get_center()
	add_child(box)


func collect() -> void:
	visible = false
	process_mode = PROCESS_MODE_DISABLED
	level.sounds.play(Sounds.Effect.COIN)
