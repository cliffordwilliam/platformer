class_name Squash
extends RefCounted
## Fire-and-forget squash and stretch on one sprite. Only the sprite's
## scale changes; one tween at a time, a new effect takes over.

const LAND_SQUASH_SCALE := Vector2(1.3, 0.7)
const LAND_SQUASH_DURATION := 1.0
const AIR_SQUASH_MAX_Y := 1.2
const AIR_SQUASH_MIN_X := 0.9
const SQUISH_FROM_SCALE := Vector2(1.5, 0.2)
const SQUISH_IMPACT_DURATION := 0.1
const SQUISH_SCALE := Vector2(1.2, 0.5)
const SQUISH_DURATION := 0.6

var sprite: Node2D
var _tween: Tween


func _init(sprite_: Node2D) -> void:
	sprite = sprite_


func cancel_squash() -> void:
	if _tween != null:
		_tween.kill()
		_tween = null


## Snaps wide and short, then springs back to normal.
func play_bounce() -> void:
	cancel_squash()
	_tween = _new_tween()
	_tween.tween_property(sprite, "scale", Vector2.ONE, LAND_SQUASH_DURATION).from(LAND_SQUASH_SCALE)


## Squashes flat, then calls on_done 0.7 s later.
func play_squish(on_done: Callable) -> void:
	cancel_squash()
	_tween = _new_tween()
	_tween.tween_property(sprite, "scale", SQUISH_FROM_SCALE, SQUISH_IMPACT_DURATION).set_trans(Tween.TRANS_EXPO)
	_tween.tween_property(sprite, "scale", SQUISH_SCALE, SQUISH_DURATION)
	_tween.tween_callback(on_done)


## Taller and thinner the faster it falls.
func update_air_squash(speed_y: float, max_fall_speed: float) -> void:
	var speed := absf(speed_y)
	sprite.scale.y = remap(speed, 0.0, max_fall_speed, 1.0, AIR_SQUASH_MAX_Y)
	sprite.scale.x = remap(speed, 0.0, max_fall_speed, 1.0, AIR_SQUASH_MIN_X)


func _new_tween() -> Tween:
	var tween := sprite.create_tween()
	tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	tween.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	return tween
