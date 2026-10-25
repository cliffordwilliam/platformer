class_name Iris
extends CanvasLayer
## A box iris: four black rectangles that open out from the player or
## close in on it. Runs while the game is paused.

const WAIT := 1.0
const DURATION := 0.5

var level: Level
var _top: ColorRect
var _right: ColorRect
var _bottom: ColorRect
var _left: ColorRect


func setup(level_: Level) -> void:
	level = level_


func _ready() -> void:
	assert(level != null, "setup() not called")
	layer = 2
	process_mode = PROCESS_MODE_ALWAYS
	_top = _add_rect("Top")
	_right = _add_rect("Right")
	_bottom = _add_rect("Bottom")
	_left = _add_rect("Left")


func _add_rect(rect_name: String) -> ColorRect:
	var rect := ColorRect.new()
	rect.name = rect_name
	rect.color = Color.BLACK
	rect.size = Vector2(Screen.width, Screen.height)
	add_child(rect)
	return rect


## The player's middle, on the screen.
func target() -> Vector2:
	return level.player.position + Vector2(-level.camera.left_edge, -Player.BOX.size.y / 2.0)


func _shut_positions() -> Array[Vector2]:
	var t := target()
	return [Vector2(0, t.y - Screen.height), Vector2(t.x, 0), Vector2(0, t.y), Vector2(t.x - Screen.width, 0)]


func _open_positions() -> Array[Vector2]:
	return [Vector2(0, -Screen.height), Vector2(Screen.width, 0), Vector2(0, Screen.height), Vector2(-Screen.width, 0)]


func _put(positions: Array[Vector2]) -> void:
	_top.position = positions[0]
	_right.position = positions[1]
	_bottom.position = positions[2]
	_left.position = positions[3]


func _move_to(positions: Array[Vector2]) -> void:
	var tween := create_tween().set_parallel()
	tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	var rects := [_top, _right, _bottom, _left]
	for i in 4:
		tween.tween_property(rects[i], "position", positions[i], DURATION)
	await tween.finished


## Shut on the player, 1 s of black, then open in 0.5 s.
func open() -> void:
	_put(_shut_positions())
	await get_tree().create_timer(WAIT, true, true).timeout
	await _move_to(_open_positions())


## Open, then shut on the player in 0.5 s.
func close() -> void:
	_put(_open_positions())
	await _move_to(_shut_positions())
