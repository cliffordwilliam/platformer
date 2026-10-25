class_name GiftBlock
extends Block
## Hops when hit from below, and lets out a coin or a diamond the first time.

const HOP_HEIGHT := 7.2
const HOP_TIME := 0.1067

var contents: GiftBlockSpawn.Contents
var used := false
var look := "a"
var _hop: Tween


func setup(level_: Level, spawn: GiftBlockSpawn) -> void:
	level = level_
	contents = spawn.contents
	look = ["a", "b", "c"][randi_range(0, 2)]


func _ready() -> void:
	assert(level != null, "setup() not called")
	_build_block(load("res://art/gift_block_%s/sprite_1.png" % look))


func _on_bonk() -> void:
	level.sounds.play(Sounds.Effect.BUMP)
	if _hop == null or not _hop.is_running():
		_hop = create_tween()
		_hop.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
		_hop.tween_property(sprite, "position:y", -HOP_HEIGHT, HOP_TIME).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		_hop.tween_property(sprite, "position:y", 0.0, HOP_TIME).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	if used:
		return
	used = true
	sprite.texture = load("res://art/gift_block_%s/sprite_2.png" % look)
	if contents == GiftBlockSpawn.Contents.COIN:
		var coin: PoppedCoin = load("res://items/popped_coin.tscn").instantiate()
		coin.position = position
		coin.setup(level)
		level.add_block_item(coin)
		level.sounds.play(Sounds.Effect.COIN)
	else:
		_hop.tween_callback(_release_diamond)


func _release_diamond() -> void:
	var diamond: Diamond = load("res://items/diamond.tscn").instantiate()
	diamond.position = position + Vector2(Grid.HALF_TILE, 0)
	diamond.setup(level)
	level.add_block_item(diamond)
	level.sounds.play(Sounds.Effect.DIAMOND)
