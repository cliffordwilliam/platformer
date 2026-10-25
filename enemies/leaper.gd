class_name Leaper
extends Area2D
## Leaps straight up out of the water, falls back, waits, leaps again.

const LEAP_SPEED := 421.86
const GRAVITY := 442.99
const MAX_FALL_SPEED := 202.5
const WAIT_MIN := 1.0
const WAIT_MAX := 3.05
const FPS := 7.5
const IMAGE_SIZE := Vector2(13, 17)
const BOX := Rect2(1, 1, 11, 15)
const ORIGIN := Vector2(6, 8)

var level: Level
var velocity_y := 0.0
var start_y := 0.0
var sprite: AnimatedSprite2D
var wait_timer: Timer
## Height of the leap's top above the start point.
var leap_height := 0.0
var _leap_now := true
var _waiting := false


func setup(level_: Level) -> void:
	level = level_


func _ready() -> void:
	assert(level != null, "setup() not called")
	collision_layer = Level.LAYER_ENEMIES
	collision_mask = 0
	sprite = Enemy.add_sprite(self, Level.sprite_frames({"leap": [
		["res://art/leaper/sprite_1.png", "res://art/leaper/sprite_2.png"], FPS]}), ORIGIN)
	sprite.play("leap")
	Enemy.add_box(self, BOX, ORIGIN)
	Enemy.add_enabler(self, Rect2(-ORIGIN, IMAGE_SIZE))
	start_y = position.y
	wait_timer = Timer.new()
	wait_timer.one_shot = true
	wait_timer.process_callback = Timer.TIMER_PROCESS_PHYSICS
	wait_timer.timeout.connect(func() -> void:
		_waiting = false
		_leap_now = true)
	add_child(wait_timer)
	var delta := 1.0 / Engine.physics_ticks_per_second
	var speed := -LEAP_SPEED
	var y := 0.0
	while speed < 0.0:
		y += speed * delta
		speed = minf(speed + GRAVITY * delta, MAX_FALL_SPEED)
	leap_height = -y


func _physics_process(delta: float) -> void:
	if _waiting:
		return
	velocity_y = minf(velocity_y + GRAVITY * delta, MAX_FALL_SPEED)
	if _leap_now:
		velocity_y = -LEAP_SPEED
		_leap_now = false
	position.y += velocity_y * delta
	if velocity_y > 0.0 and position.y >= start_y:
		position.y = start_y
		velocity_y = 0.0
		_waiting = true
		wait_timer.start(randf_range(WAIT_MIN, WAIT_MAX))
	sprite.flip_v = velocity_y > 0.0


func _draw() -> void:
	if Level.show_guides:
		draw_line(Vector2.ZERO, Vector2(0, -leap_height), Enemy.GUIDE_COLOR, 1.0)


func stomp() -> void:
	Enemy.die(self, level, "res://art/leaper/sprite_1.png", ORIGIN)
