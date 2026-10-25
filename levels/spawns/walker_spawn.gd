class_name WalkerSpawn
extends RefCounted

## Walker A, B or C (enemy-walker.md).
enum Kind { PLAIN, SHELL, SPIKED }

var cell: Vector2i
var kind: Kind


func _init(cell_: Vector2i, kind_: Kind) -> void:
	cell = cell_
	kind = kind_
