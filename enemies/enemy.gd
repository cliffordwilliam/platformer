@abstract
class_name Enemy
## Helpers the flyer, leaper, crusher and bar share for building
## themselves in code.

const GUIDE_COLOR := Color(1, 0.3, 1, 0.9)


static func add_sprite(owner: Node2D, frames: SpriteFrames, origin: Vector2) -> AnimatedSprite2D:
	var sprite := AnimatedSprite2D.new()
	sprite.sprite_frames = frames
	sprite.centered = false
	sprite.offset = -origin
	owner.add_child(sprite)
	return sprite


static func add_box(owner: Node2D, box: Rect2, origin: Vector2) -> CollisionShape2D:
	var rectangle := RectangleShape2D.new()
	rectangle.size = box.size
	var shape := CollisionShape2D.new()
	shape.shape = rectangle
	shape.position = box.get_center() - origin
	owner.add_child(shape)
	return shape


static func add_enabler(owner: Node2D, rect: Rect2) -> VisibleOnScreenEnabler2D:
	var enabler := VisibleOnScreenEnabler2D.new()
	enabler.rect = rect
	owner.add_child(enabler)
	return enabler


## Switches a stomped flyer or leaper off and drops its death scene.
static func die(enemy: Node2D, level: Level, texture_path: String, origin: Vector2) -> void:
	enemy.process_mode = Node.PROCESS_MODE_DISABLED
	enemy.visible = false
	var death: EnemyDeath = load("res://enemies/enemy_death.tscn").instantiate()
	death.position = enemy.position
	death.setup(level, load(texture_path), origin)
	level.add_effect(death)
