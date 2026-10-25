class_name Flyer
extends Area2D
## Bobs up and down along a vertical path, forever.

const PULL := 47.46
const FPS := 7.5
const IMAGE_SIZE := Vector2(26, 20)
const BOX := Rect2(8, 7, 10, 10)
const ORIGIN := Vector2(13, 10)

var level: Level
var bob_distance := 0.0
var sprite: AnimatedSprite2D
var start_y := 0.0


func setup(level_: Level, spawn: FlyerSpawn) -> void:
	level = level_
	bob_distance = spawn.bob_distance


func _ready() -> void:
	assert(level != null, "setup() not called")
	collision_layer = Level.LAYER_ENEMIES
	collision_mask = 0
	sprite = Enemy.add_sprite(self, Level.sprite_frames({"fly": [["res://art/flyer/sprite_1.png",
			"res://art/flyer/sprite_2.png", "res://art/flyer/sprite_3.png"], FPS]}), ORIGIN)
	sprite.play("fly")
	Enemy.add_box(self, BOX, ORIGIN)
	Enemy.add_enabler(self, Rect2(-ORIGIN, IMAGE_SIZE))
	start_y = position.y
	if bob_distance != 0.0:
		var trip := 2.0 * sqrt(absf(bob_distance) / PULL)
		var tween := create_tween().set_loops()
		tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
		tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(self, "position:y", start_y + bob_distance, trip)
		tween.tween_property(self, "position:y", start_y, trip)


func _draw() -> void:
	if Level.show_guides:
		draw_line(Vector2.ZERO, Vector2(0, bob_distance), Enemy.GUIDE_COLOR, 1.0)


func stomp() -> void:
	Enemy.die(self, level, "res://art/flyer/sprite_1.png", ORIGIN)
