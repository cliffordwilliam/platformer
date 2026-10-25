extends Node
## Renders every page of a level to PNGs with Movie Maker, guides on top:
## godot --path . --write-movie snapshots/level_1_page.png res://tools/snapshot.tscn -- 1

const PAGE_COLUMNS := 25

var level: Level
var _frame := 0
var _last := 0


func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	var number := OS.get_cmdline_user_args()[0].to_int()
	Level.show_guides = true
	seed(1)
	level = load("res://levels/level_%d.tscn" % number).instantiate()
	add_child(level)
	get_tree().paused = true
	_last = maxi(0, ceili((level.level_end_x - Screen.width) / float(PAGE_COLUMNS * Grid.TILE)))


func _process(_delta: float) -> void:
	if level.camera == null:
		return
	var left := _frame * PAGE_COLUMNS * Grid.TILE
	level.camera.position.x = minf(left + Screen.half_width, level.level_end_x - Screen.half_width)
	if _frame >= _last:
		get_tree().quit(1 if not level.errors.is_empty() else 0)
	_frame += 1
