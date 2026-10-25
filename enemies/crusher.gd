class_name Crusher
extends CharacterBody2D
## Hangs still, drops when the player is below it, waits, then slowly
## rises back. Cannot be stomped and never dies.

enum State { WATCH, FALL, WAIT, RISE }

const GRAVITY := 1923.75
const MAX_FALL_SPEED := 270.0
const WAIT := 0.5
const RISE_SPEED := 33.75
const BOX := Rect2(2, 1, 16, 18)
const ORIGIN := Vector2(10, 19)

var level: Level
var state := State.WATCH
var start_y := 0.0
var sprite: AnimatedSprite2D
var squash: Squash
var wait_timer: Timer


func setup(level_: Level) -> void:
	level = level_


func _ready() -> void:
	assert(level != null, "setup() not called")
	collision_layer = Level.LAYER_ENEMIES
	collision_mask = Level.LAYER_LEVEL
	sprite = Enemy.add_sprite(self, Level.sprite_frames({
		"still": [["res://art/crusher/sprite_1.png"], 0.0],
		"fall": [["res://art/crusher/sprite_2.png"], 0.0],
	}), ORIGIN)
	sprite.play("still")
	squash = Squash.new(sprite)
	Enemy.add_box(self, BOX, ORIGIN)
	start_y = position.y
	Enemy.add_enabler(self, Rect2(-10, -19, 20, Screen.height - start_y + 19))
	wait_timer = Timer.new()
	wait_timer.one_shot = true
	wait_timer.process_callback = Timer.TIMER_PROCESS_PHYSICS
	wait_timer.timeout.connect(func() -> void: state = State.RISE)
	add_child(wait_timer)


func _player_below() -> bool:
	var player := level.player
	return absf(player.position.x - position.x) < BOX.size.x / 2.0 and player.position.y > position.y


func _physics_process(delta: float) -> void:
	match state:
		State.WATCH:
			if _player_below():
				state = State.FALL
				velocity.y = 0.0
				sprite.play("fall")
				squash.cancel_squash()
				_fall(delta)
		State.FALL:
			_fall(delta)
		State.RISE:
			velocity.y = -RISE_SPEED
			move_and_slide()
			if position.y <= start_y:
				position.y = start_y
				velocity.y = 0.0
				state = State.WATCH


func _fall(delta: float) -> void:
	velocity.y = minf(velocity.y + GRAVITY * delta, MAX_FALL_SPEED)
	move_and_slide()
	squash.update_air_squash(velocity.y, MAX_FALL_SPEED)
	if is_on_floor():
		state = State.WAIT
		velocity.y = 0.0
		sprite.play("still")
		squash.play_bounce()
		wait_timer.start(WAIT)
