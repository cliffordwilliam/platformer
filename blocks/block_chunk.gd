class_name BlockChunk
extends Node2D
## A quarter of a broken block: flies up and out, spinning, through
## everything, and switches off below the screen.

const TOP_SPEED := 405.0
const BOTTOM_SPEED := 270.0
const SIDE_SPEED := 67.5
const GRAVITY := 1265.625
const MAX_FALL_SPEED := 540.0
## Updates between spin steps.
const SPIN_UPDATES := 4

var level: Level
var velocity := Vector2.ZERO
var sprite: Sprite2D
var _variant := 1
var _updates := 0
var _step := 0


## spot: (-1 or 1, -1 or 1), the quarter it came from.
func setup(level_: Level, variant: int, spot: Vector2) -> void:
	level = level_
	_variant = variant
	velocity = Vector2(spot.x * SIDE_SPEED, -(TOP_SPEED if spot.y < 0 else BOTTOM_SPEED))


func _ready() -> void:
	assert(level != null, "setup() not called")
	sprite = Sprite2D.new()
	sprite.texture = load("res://art/breakable_block_chunk/sprite_%d.png" % _variant)
	sprite.centered = false
	sprite.offset = -Vector2(Grid.HALF_TILE, Grid.HALF_TILE)
	add_child(sprite)


func _physics_process(delta: float) -> void:
	position += velocity * delta
	velocity.y = minf(velocity.y + GRAVITY * delta, MAX_FALL_SPEED)
	_updates += 1
	if _updates % SPIN_UPDATES == 0:
		_step = (_step + 1) % 4
		sprite.flip_h = _step == 1 or _step == 3
		sprite.flip_v = _step >= 2
	if position.y > Screen.height + Grid.TILE:
		process_mode = PROCESS_MODE_DISABLED
