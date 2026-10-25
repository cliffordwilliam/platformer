class_name Walker
extends WalkingBody
## Walker A, and everything the three walkers share.

const FPS := 7.5
## Per kind: art folder, image size, box, origin (assets.md).
const KINDS := {
	WalkerSpawn.Kind.PLAIN: ["res://art/walker_a", Vector2(17, 16), Rect2(1, 3, 15, 12), Vector2(8, 15)],
	WalkerSpawn.Kind.SHELL: ["res://art/walker_b", Vector2(26, 24), Rect2(1, 3, 24, 20), Vector2(13, 23)],
	WalkerSpawn.Kind.SPIKED: ["res://art/walker_c", Vector2(17, 21), Rect2(1, 9, 15, 11), Vector2(8, 20)],
}

var kind: WalkerSpawn.Kind
var art := ""
var origin := Vector2.ZERO
var flattened_texture: Texture2D


func setup(level_: Level, spawn: WalkerSpawn) -> void:
	level = level_
	kind = spawn.kind
	speed = -WALK_SPEED
	art = KINDS[kind][0]
	origin = KINDS[kind][3]
	flattened_texture = load(art + "/sprite_3.png")


func _ready() -> void:
	assert(level != null, "setup() not called")
	collision_layer = Level.LAYER_WALKERS
	collision_mask = Level.LAYER_LEVEL | Level.LAYER_WALKERS
	_build_body(Level.sprite_frames({
		"walk": [[art + "/sprite_1.png", art + "/sprite_2.png"], FPS],
		"shell": [[art + "/sprite_3.png"], 0.0],
	}), KINDS[kind][1], KINDS[kind][2], origin)
	sprite.play("walk")


func _face() -> void:
	if speed != 0.0:
		sprite.flip_h = speed > 0.0


## Landed on by the player.
func stomp() -> void:
	flatten()


func flatten() -> void:
	_switch_off()
	var flattened: WalkerFlattened = load("res://enemies/walker_flattened.tscn").instantiate()
	flattened.position = position
	flattened.setup(level, flattened_texture, origin, sprite.flip_h)
	level.add_effect(flattened)


## Knocked out from below, or by a kicked shell.
func bonk_death() -> void:
	_switch_off()
	var bonked: WalkerBonked = load("res://enemies/walker_bonked.tscn").instantiate()
	bonked.position = position
	bonked.setup(level, flattened_texture, origin, sprite.flip_h)
	level.add_effect(bonked)


func _switch_off() -> void:
	process_mode = PROCESS_MODE_DISABLED
	visible = false
