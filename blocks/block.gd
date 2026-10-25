@abstract
class_name Block
extends StaticBody2D
## What breakable and gift blocks share: a solid tile-sized box that
## reacts when the player hits it from below.

var level: Level
var sprite: Sprite2D
## The cell the block fills.
var cell: Vector2i


func _build_block(texture: Texture2D) -> void:
	collision_layer = Level.LAYER_LEVEL
	collision_mask = 0
	cell = Level.cell_at(position)
	sprite = Sprite2D.new()
	sprite.texture = texture
	sprite.centered = false
	add_child(sprite)
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(Grid.TILE, Grid.TILE)
	var box := CollisionShape2D.new()
	box.shape = rectangle
	box.position = Vector2(Grid.HALF_TILE, Grid.HALF_TILE)
	add_child(box)


## Hit from below: the block's own reaction, then whatever stands on it.
func bonk() -> void:
	_on_bonk()
	for walker: Walker in level.walker_layer.get_children():
		if walker.can_process() and walker.is_on_floor() and walker.cells_under().has(cell):
			walker.bonk_death()
	for item in level.block_item_layer.get_children():
		if item is Diamond:
			var diamond := item as Diamond
			if diamond.can_process() and diamond.is_physics_processing() and diamond.is_on_floor() \
					and diamond.cells_under().has(cell):
				diamond.bump()


@abstract func _on_bonk() -> void
