class_name Player
extends CharacterBody2D
## The player: walks, jumps, climbs, and checks everything it touches.

enum State { IDLE, WALK, RISE, BOUNCE, SPRING, FALL, CLIMB }

const WALK_SPEED := 101.25
const WALK_ACCELERATION := 150.3
const JUMP_SPEED := 297.0
const LIGHT_GRAVITY := 550.54
const HEAVY_GRAVITY := 1923.75
const MAX_FALL_SPEED := 270.0
const CLIMB_SPEED := 67.5
const STOMP_BOUNCE_SPEED := 227.37
const SPRING_LAUNCH_SPEED := 445.5

const INJURY_FREEZE := 0.92
const INVINCIBILITY := 2.8

## The walk animation's rate at a standstill and at top speed.
const WALK_FPS_SLOWEST := 4.3
const WALK_FPS := 15.0
const CLIMB_FPS := 7.5

## The art: 24 x 26, box 10 x 15 at (7, 10), origin at the feet (12, 25).
const ORIGIN := Vector2(12, 25)
const BOX := Rect2(7, 10, 10, 15)

var level: Level
var state := State.IDLE
var invincible := false
var sprite: AnimatedSprite2D
var squash: Squash
var contact: Area2D
var invincibility_timer: Timer


func setup(level_: Level) -> void:
	level = level_


func _ready() -> void:
	assert(level != null, "setup() not called")
	collision_layer = 0
	collision_mask = Level.LAYER_LEVEL
	sprite = AnimatedSprite2D.new()
	sprite.sprite_frames = Level.sprite_frames({
		"idle": [["res://art/player/sprite_1.png"], 0.0],
		"air": [["res://art/player/sprite_2.png"], 0.0],
		"walk": [["res://art/player/sprite_1.png", "res://art/player/sprite_2.png"], WALK_FPS],
		"climb": [["res://art/player/sprite_1.png", "res://art/player/sprite_2.png"], CLIMB_FPS],
	})
	sprite.centered = false
	sprite.offset = -ORIGIN
	sprite.flip_h = true
	sprite.play("idle")
	add_child(sprite)
	squash = Squash.new(sprite)
	var shape := RectangleShape2D.new()
	shape.size = BOX.size
	var box := CollisionShape2D.new()
	box.shape = shape
	box.position = BOX.get_center() - ORIGIN
	add_child(box)
	contact = Area2D.new()
	contact.collision_layer = 0
	contact.collision_mask = Level.LAYER_WALKERS | Level.LAYER_ENEMIES | Level.LAYER_PICKUPS \
			| Level.LAYER_SPRINGS | Level.LAYER_DOORS | Level.LAYER_CHECKPOINTS
	var contact_box := CollisionShape2D.new()
	contact_box.shape = shape
	contact_box.position = box.position
	contact.add_child(contact_box)
	add_child(contact)
	invincibility_timer = Timer.new()
	invincibility_timer.one_shot = true
	invincibility_timer.process_callback = Timer.TIMER_PROCESS_PHYSICS
	invincibility_timer.timeout.connect(_on_invincibility_timeout)
	add_child(invincibility_timer)


func _physics_process(delta: float) -> void:
	if invincible:
		sprite.visible = not sprite.visible

	# 1. Input.
	var direction := Input.get_axis("move_left", "move_right")
	var jump_held := Input.is_action_pressed("jump")
	var up_held := Input.is_action_pressed("move_up")
	if direction > 0:
		sprite.flip_h = true
	elif direction < 0:
		sprite.flip_h = false

	# 2. Velocity: walking, gravity, jump, climb.
	velocity.x = move_toward(velocity.x, direction * WALK_SPEED, WALK_ACCELERATION * delta)
	var ladder_cell := cell_at(position + Vector2(0, -1))
	var climbing := up_held and level.ladder_at(ladder_cell)
	if state == State.CLIMB and not climbing:
		velocity.y = 0.0
	var light := (state == State.RISE and jump_held) or state == State.SPRING
	velocity.y = minf(velocity.y + (LIGHT_GRAVITY if light else HEAVY_GRAVITY) * delta, MAX_FALL_SPEED)
	var jumped := false
	if jump_held and is_on_floor() and state != State.SPRING and not climbing:
		velocity.y = -JUMP_SPEED
		jumped = true
		level.sounds.play(Sounds.Effect.JUMP)
		squash.play_bounce()
	var limit := -INF
	if climbing:
		velocity.y = -CLIMB_SPEED
		if not level.ladder_at(ladder_cell + Vector2i.UP):
			limit = ladder_cell.y * Grid.TILE

	# 3. Move.
	move_and_slide()
	if is_on_wall() and velocity.x * get_wall_normal().x < 0:
		velocity.x = 0.0
	if climbing:
		position.y = maxf(position.y, limit)

	# 4. Clamp to the screen edges.
	position.x = clampf(position.x, level.camera.left_edge, level.level_end_x)

	# 5. State.
	_set_state(_next_state(climbing, jumped))

	# 6. Death line.
	if position.y >= Screen.height:
		level.health = 0
		die()
		return

	# 7. Win: the flag or a door.
	if position.x >= level.win_x or _touching().any(func(thing: Node) -> bool: return thing is Door):
		sprite.visible = true
		get_tree().paused = true
		level.on_win()
		return

	# 8. Contact.
	_check_contact()


static func cell_at(point: Vector2) -> Vector2i:
	return Level.cell_at(point)


## The player's box in level coordinates.
func box() -> Rect2:
	return Rect2(position + BOX.position - ORIGIN, BOX.size)


func _next_state(climbing: bool, jumped: bool) -> State:
	if climbing:
		return State.CLIMB
	if is_on_floor():
		return State.IDLE if velocity.x == 0.0 else State.WALK
	if velocity.y < 0.0:
		if jumped:
			return State.RISE
		if state in [State.RISE, State.BOUNCE, State.SPRING]:
			return state
		return State.RISE
	return State.FALL


## Moves to a new state and plays what entering it shows.
func _set_state(new_state: State) -> void:
	var old := state
	state = new_state
	if new_state == State.FALL and old != State.FALL:
		squash.cancel_squash()
	if new_state == State.FALL:
		squash.update_air_squash(velocity.y, MAX_FALL_SPEED)
	if old == State.FALL and new_state in [State.IDLE, State.WALK]:
		squash.play_bounce()
	if new_state == State.CLIMB and old != State.CLIMB:
		squash.cancel_squash()
		sprite.scale = Vector2.ONE
	if old == State.WALK and new_state == State.IDLE and is_on_wall():
		squash.play_bounce()
	_animate(old)


func _animate(old: State) -> void:
	match state:
		State.IDLE:
			sprite.play("idle")
		State.WALK:
			if old != State.WALK:
				sprite.play("walk")
				sprite.frame = 1
			sprite.speed_scale = remap(absf(velocity.x), 0.0, WALK_SPEED, WALK_FPS_SLOWEST, WALK_FPS) / WALK_FPS
		State.CLIMB:
			if old != State.CLIMB:
				sprite.play("climb")
				sprite.frame = 1
		_:
			sprite.play("air")
	if state != State.WALK:
		sprite.speed_scale = 1.0


## Everything the contact area overlaps, as one list.
func _touching() -> Array[Node]:
	var list: Array[Node] = []
	for body in contact.get_overlapping_bodies():
		if body.can_process():
			list.append(body)
	for area in contact.get_overlapping_areas():
		if area.can_process():
			list.append(area)
	return list


## Blocks, pickups, enemies, springs, checkpoints, in that order.
func _check_contact() -> void:
	pass


## Takes one health: an injury, or a death on the last one. Returns true
## on a death, which ends the update.
func hurt() -> bool:
	level.health -= 1
	if level.health <= 0:
		die()
		return true
	level.sounds.play(Sounds.Effect.HURT)
	squash.play_bounce()
	_injury_freeze()
	return false


func _injury_freeze() -> void:
	get_tree().paused = true
	await get_tree().create_timer(INJURY_FREEZE, true, true).timeout
	get_tree().paused = false
	invincible = true
	invincibility_timer.start(INVINCIBILITY)


func _on_invincibility_timeout() -> void:
	invincible = false
	sprite.visible = true


## Pauses the game for good, switches the player off and plays the death.
func die() -> void:
	get_tree().paused = true
	if level.music != null:
		level.music.stop()
	level.sounds.play(Sounds.Effect.DEATH)
	visible = false
	process_mode = PROCESS_MODE_DISABLED
	var death: PlayerDeath = load("res://player/player_death.tscn").instantiate()
	death.position = position
	death.setup(level, sprite.flip_h)
	level.add_effect(death)
