class_name LadderSpawn
extends RefCounted

## The ladder's bottom cell; it grows up.
var cell: Vector2i
var height: int


func _init(cell_: Vector2i, height_: int) -> void:
	cell = cell_
	height = height_
