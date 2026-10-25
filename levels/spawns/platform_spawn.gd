class_name PlatformSpawn
extends RefCounted

## The platform's left end.
var cell: Vector2i
var width: int


func _init(cell_: Vector2i, width_: int) -> void:
	cell = cell_
	width = width_
