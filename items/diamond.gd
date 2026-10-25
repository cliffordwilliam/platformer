class_name Diamond
extends WalkingBody
## Slides up out of a gift block, then walks like a walker; touching it
## heals 1 health.

const IMAGE_SIZE := Vector2(16, 15)
const BOX := Rect2(1, 1, 14, 13)
const ORIGIN := Vector2(8, 14)
const SLIDE_SPEED := 16.875

var pickup: Area2D


func setup(level_: Level) -> void:
	level = level_
	speed = WALK_SPEED


func _ready() -> void:
	assert(level != null, "setup() not called")
	collision_layer = 0
	collision_mask = Level.LAYER_LEVEL
	_build_body(Level.sprite_frames({"default": [["res://art/diamond/sprite_1.png"], 0.0]}),
			IMAGE_SIZE, BOX, ORIGIN)
	pickup = Area2D.new()
	pickup.collision_layer = Level.LAYER_PICKUPS
	pickup.collision_mask = 0
	var pickup_box := CollisionShape2D.new()
	pickup_box.shape = shape.shape
	pickup_box.position = shape.position
	pickup.add_child(pickup_box)
	add_child(pickup)
	set_physics_process(false)
	sprite.position.y = Grid.TILE
	var slide := create_tween()
	slide.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	slide.tween_property(sprite, "position:y", 0.0, Grid.TILE / SLIDE_SPEED)
	slide.tween_callback(set_physics_process.bind(true))


## Hit from below while standing on a block: hops and turns around.
func bump() -> void:
	velocity.y = -MAX_FALL_SPEED
	speed = -speed


func collect() -> void:
	level.health = mini(level.health + 1, 2)
	level.sounds.play(Sounds.Effect.HEAL)
	visible = false
	process_mode = PROCESS_MODE_DISABLED
