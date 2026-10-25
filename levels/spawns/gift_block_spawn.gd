class_name GiftBlockSpawn
extends BlockSpawn

enum Contents { COIN, DIAMOND }

var contents: Contents


func _init(cell_: Vector2i, contents_: Contents) -> void:
	cell = cell_
	contents = contents_
