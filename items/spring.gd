class_name Spring
extends WalkingBody
## A walker that never walks: falls, lands, stacks, and launches the
## player high when touched.

const LAUNCH_SPEED := 445.5
const IMAGE_SIZE := Vector2(18, 18)
const BOX := Rect2(1, 4, 16, 14)
const ORIGIN := Vector2(9, 18)

## How high the player's feet rise after a launch.
var reach := 0.0


func setup(level_: Level) -> void:
	level = level_
	speed = 0.0


func _ready() -> void:
	assert(level != null, "setup() not called")
	collision_layer = Level.LAYER_SPRINGS
	collision_mask = Level.LAYER_LEVEL | Level.LAYER_SPRINGS
	_build_body(Level.sprite_frames({"default": [["res://art/spring/sprite_1.png"], 0.0]}),
			IMAGE_SIZE, BOX, ORIGIN)
	var delta := 1.0 / Engine.physics_ticks_per_second
	var velocity_y := -LAUNCH_SPEED
	var y := 0.0
	while velocity_y < 0.0:
		velocity_y = minf(velocity_y + Player.LIGHT_GRAVITY * delta, Player.MAX_FALL_SPEED)
		y += velocity_y * delta
	reach = -y


func _draw() -> void:
	if Level.show_guides:
		draw_line(Vector2.ZERO, Vector2(0, -reach), Enemy.GUIDE_COLOR, 1.0)


func launch() -> void:
	squash.play_bounce()
	level.sounds.play(Sounds.Effect.SPRING)
	level.player.spring_launch()
