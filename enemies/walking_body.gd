@abstract
class_name WalkingBody
extends CharacterBody2D
## What walkers, the diamond and springs share: they walk at a steady
## speed, turn at walls, fall off ledges, and switch on only on screen.

const WALK_SPEED := 33.75
const GRAVITY := 965.04
const MAX_FALL_SPEED := 202.5

var level: Level
## Sideways speed; flipped at walls.
var speed := 0.0
var sprite: AnimatedSprite2D
var squash: Squash
var shape: CollisionShape2D
var _was_on_floor := true


## Builds the sprite, box and enabler from the art's numbers.
func _build_body(frames: SpriteFrames, image_size: Vector2, box_rect: Rect2, origin: Vector2) -> void:
	sprite = AnimatedSprite2D.new()
	sprite.sprite_frames = frames
	sprite.centered = false
	sprite.offset = -origin
	add_child(sprite)
	squash = Squash.new(sprite)
	var rectangle := RectangleShape2D.new()
	rectangle.size = box_rect.size
	shape = CollisionShape2D.new()
	shape.shape = rectangle
	shape.position = box_rect.get_center() - origin
	add_child(shape)
	var enabler := VisibleOnScreenEnabler2D.new()
	enabler.rect = Rect2(-origin, image_size)
	add_child(enabler)


## The collision box in level coordinates.
func box() -> Rect2:
	var rect := shape.shape.get_rect()
	rect.position += shape.position + position
	return rect


func _physics_process(delta: float) -> void:
	velocity.x = speed
	velocity.y = minf(velocity.y + GRAVITY * delta, MAX_FALL_SPEED)
	move_and_slide()
	_after_move()
	if is_on_wall() and speed != 0.0:
		speed = -speed
		squash.play_bounce()
	var on_floor := is_on_floor()
	if _was_on_floor and not on_floor:
		squash.cancel_squash()
	if not on_floor:
		squash.update_air_squash(velocity.y, MAX_FALL_SPEED)
	if not _was_on_floor and on_floor:
		squash.play_bounce()
	_was_on_floor = on_floor
	_face()


## Right after moving, before reacting to walls and floors.
func _after_move() -> void:
	pass


func _face() -> void:
	pass


## The cells on the row just under the box, one per column it covers.
func cells_under() -> Array[Vector2i]:
	var rect := box()
	var row := floori((rect.end.y + 1) / Grid.TILE)
	var cells: Array[Vector2i] = []
	for column in range(floori(rect.position.x / Grid.TILE), floori((rect.end.x - 1) / Grid.TILE) + 1):
		cells.append(Vector2i(column, row))
	return cells
