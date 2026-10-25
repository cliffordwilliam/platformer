class_name Bar
extends Area2D
## A line of sprites spinning around its centre. Nothing ever rotates:
## only the sprites' positions change. Cannot be stomped.

const ROTATION_SPEED := 105.5
const SPACING := 30.0
const IMAGE_SIZE := Vector2(26, 26)
const BOX := Rect2(6, 6, 14, 14)
const ORIGIN := Vector2(13, 13)
## From a sprite's centre to the far edge of its drawn 24 px.
const REACH := 12.0

var level: Level
var units := 0
var start_angle := 0.0
var clockwise := true
## The line's angle, in radians.
var angle := 0.0
var sprites: Array[Sprite2D] = []
var shapes: Array[CollisionShape2D] = []


func setup(level_: Level, spawn: BarSpawn) -> void:
	level = level_
	units = spawn.units
	start_angle = spawn.start_angle
	clockwise = spawn.clockwise
	angle = deg_to_rad(start_angle)


func _ready() -> void:
	assert(level != null, "setup() not called")
	collision_layer = Level.LAYER_ENEMIES
	collision_mask = 0
	var texture: Texture2D = load("res://art/bar/sprite_1.png")
	for k in range(-units, units + 1):
		var sprite := Sprite2D.new()
		sprite.texture = texture
		sprite.centered = false
		sprite.offset = -ORIGIN
		add_child(sprite)
		sprites.append(sprite)
		shapes.append(Enemy.add_box(self, BOX, ORIGIN))
	var radius := units * SPACING + REACH
	Enemy.add_enabler(self, Rect2(-radius, -radius, 2 * radius, 2 * radius))
	_place()


func _physics_process(delta: float) -> void:
	angle += deg_to_rad(ROTATION_SPEED) * delta * (1.0 if clockwise else -1.0)
	_place()


func _place() -> void:
	for i in sprites.size():
		var spot := Vector2.from_angle(angle) * (i - units) * SPACING
		sprites[i].position = spot
		shapes[i].position = spot


func _draw() -> void:
	if not Level.show_guides:
		return
	draw_arc(Vector2.ZERO, units * SPACING + REACH, 0.0, TAU, 64, Enemy.GUIDE_COLOR, 1.0)
	var direction := Vector2.from_angle(deg_to_rad(start_angle))
	draw_line(-direction * units * SPACING, direction * units * SPACING, Enemy.GUIDE_COLOR, 1.0)
	for k in range(-units, units + 1):
		draw_circle(direction * k * SPACING, 2.0, Enemy.GUIDE_COLOR)
