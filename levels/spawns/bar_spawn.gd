class_name BarSpawn
extends RefCounted

var cell: Vector2i
## Sprites on each side of the centre.
var units: int
## Degrees; 0 points right.
var start_angle: float
var clockwise: bool


func _init(cell_: Vector2i, units_: int, start_angle_: float, clockwise_: bool) -> void:
	cell = cell_
	units = units_
	start_angle = start_angle_
	clockwise = clockwise_
