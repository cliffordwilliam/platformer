class_name ShellWalker
extends Walker
## Walker B: stomped, it becomes a still shell, then a kicked shell, then
## is flattened. A shell never hurts the player.

enum State { WALK, STILL, KICKED }

const KICK_SPEED := 202.5

var state := State.WALK


func stomp() -> void:
	match state:
		State.WALK:
			state = State.STILL
			speed = 0.0
			sprite.play("shell")
			squash.play_bounce()
		State.STILL:
			state = State.KICKED
			speed = -KICK_SPEED if level.player.position.x > position.x else KICK_SPEED
			collision_mask = Level.LAYER_LEVEL
			squash.play_bounce()
		State.KICKED:
			flatten()


## A kicked shell knocks out every walker it overlaps.
func _after_move() -> void:
	if state != State.KICKED:
		return
	var rect := box()
	for walker: Walker in level.walker_layer.get_children():
		if walker != self and walker.can_process() and walker.box().intersects(rect):
			walker.bonk_death()
			level.sounds.play(Sounds.Effect.KICK)
