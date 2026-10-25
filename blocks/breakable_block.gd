class_name BreakableBlock
extends Block
## Breaks into four chunks when hit from below.

const CHUNK_OFFSET := 4.0


func setup(level_: Level) -> void:
	level = level_


func _ready() -> void:
	assert(level != null, "setup() not called")
	_build_block(load("res://art/breakable_block/sprite_1.png"))


func _on_bonk() -> void:
	process_mode = PROCESS_MODE_DISABLED
	visible = false
	level.sounds.play(Sounds.Effect.BREAK)
	var variants := [1, 1, 2, 2]
	variants.shuffle()
	var spots := [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]
	var centre := position + Vector2(Grid.HALF_TILE, Grid.HALF_TILE)
	for i in 4:
		var chunk: BlockChunk = load("res://blocks/block_chunk.tscn").instantiate()
		chunk.position = centre + spots[i] * CHUNK_OFFSET
		chunk.setup(level, variants[i], spots[i])
		level.add_effect(chunk)
