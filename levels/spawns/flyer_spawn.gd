class_name FlyerSpawn
extends RefCounted

var cell: Vector2i
## Pixels from the start to the other end of the path; positive is down.
var bob_distance: float


func _init(cell_: Vector2i, bob_distance_: float) -> void:
	cell = cell_
	bob_distance = bob_distance_
