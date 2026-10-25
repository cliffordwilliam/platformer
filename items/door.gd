class_name Door
extends Area2D
## A second way to win: touching it wins the level like the flag.

## The art: 18 x 36, door drawn from y 13; origin at the bottom tile's top-left.
const ORIGIN := Vector2(0, 18)
const BOX := Rect2(0, 13, 18, 23)

var level: Level
var variant := 1


func setup(level_: Level) -> void:
	level = level_
	variant = randi_range(1, 2)


func _ready() -> void:
	assert(level != null, "setup() not called")
	collision_layer = Level.LAYER_DOORS
	collision_mask = 0
	var sprite := Sprite2D.new()
	sprite.texture = load("res://art/door/sprite_%d.png" % variant)
	sprite.centered = false
	sprite.offset = -ORIGIN
	add_child(sprite)
	var shape := RectangleShape2D.new()
	shape.size = BOX.size
	var box := CollisionShape2D.new()
	box.shape = shape
	box.position = BOX.get_center() - ORIGIN
	add_child(box)
