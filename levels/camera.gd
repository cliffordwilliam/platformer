class_name Camera
extends Camera2D
## Follows the player right only, and stops at the level's end.

var level: Level

## The x of the screen's left and right edges.
var left_edge: float:
	get:
		return position.x - Screen.half_width
var right_edge: float:
	get:
		return position.x + Screen.half_width


func setup(level_: Level) -> void:
	level = level_


func _ready() -> void:
	assert(level != null, "setup() not called")


func _physics_process(_delta: float) -> void:
	position.x = maxf(position.x, level.player.position.x)
	position.x = minf(position.x, level.level_end_x - Screen.half_width)
