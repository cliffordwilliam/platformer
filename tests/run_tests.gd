extends Node
## Runs every test_ function of this script, one after another, against
## the real game, and prints one line per check. Anything after `--` picks
## only the tests whose name holds it. Quits with 1 if any check failed.

## Emitted at the end of every update, after every other node's.
signal updated

const ACTIONS: Array[String] = ["move_left", "move_right", "jump", "move_up"]
## A test that has not finished after this many updates has hung.
const TEST_TIMEOUT := 60 * 60

var level: Level
var _test := ""
var _checks := 0
var _failures := 0
var _failed_tests: Array[String] = []


func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	process_physics_priority = 1000
	_run.call_deferred()


func _physics_process(_delta: float) -> void:
	updated.emit()


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var filter := args[0] if args.size() > 0 else ""
	var names: Array[String] = []
	for method in get_method_list():
		var method_name: String = method.name
		if method_name.begins_with("test_") and (filter == "" or method_name.contains(filter)):
			names.append(method_name)
	for test_name in names:
		_test = test_name
		Level.respawn_cell = Level.PLAYER_CELL
		Level.show_guides = false
		for action in ACTIONS:
			Input.action_release(action)
		var done := [false]
		var run_one := func() -> void:
			await call(test_name)
			done[0] = true
		run_one.call()
		var waited := 0
		while not done[0] and waited < TEST_TIMEOUT:
			await updated
			waited += 1
		if not done[0]:
			fail("did not finish (a script error, or it hung)")
		for action in ACTIONS:
			Input.action_release(action)
		get_tree().paused = false
		if level != null and is_instance_valid(level):
			level.queue_free()
		level = null
		await updated
	print("%d checks, %d failed" % [_checks, _failures])
	for test_name in _failed_tests:
		print("  failed: %s" % test_name)
	TestLevel.configure = Callable()
	get_tree().quit(1 if _failures > 0 else 0)


#region Helpers

func check(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("PASS %s: %s" % [_test, message])
	else:
		fail(message)


func fail(message: String) -> void:
	_failures += 1
	if not _failed_tests.has(_test):
		_failed_tests.append(_test)
	print("FAIL %s: %s" % [_test, message])


func check_near(actual: float, expected: float, message: String, tolerance := 0.001) -> void:
	check(absf(actual - expected) <= tolerance, "%s (%s, expected %s)" % [message, actual, expected])


func check_equal(actual: Variant, expected: Variant, message: String) -> void:
	check(actual == expected, "%s (%s, expected %s)" % [message, actual, expected])


## Adds the test level built by `configure`. Unless errors are expected,
## each layout error fails the test.
func add_level(expect_errors := false) -> Level:
	level = TestLevel.new()
	add_child(level)
	if not expect_errors:
		for message in level.errors:
			fail("layout error: %s" % message)
	return level


## Builds a test level from `configure` and adds it.
func make(configure: Callable, expect_errors := false) -> Level:
	TestLevel.configure = configure
	return add_level(expect_errors)


## Waits whole updates.
func wait(updates: int) -> void:
	for i in updates:
		await updated


func press(action: String) -> void:
	Input.action_press(action)


func release(action: String) -> void:
	Input.action_release(action)


## A plain level: 30 columns of written ground on row 11.
func flat(extra := Callable()) -> Callable:
	return func(l: Level) -> void:
		l.floors = [Vector2i(30, 11)]
		if extra.is_valid():
			extra.call(l)


func has_error(l: Level, text: String) -> bool:
	for message in l.errors:
		if message.contains(text):
			return true
	return false

#endregion


#region Level tiles (level-tiles.md)

func _paint(cells: Array[Vector2i], biome := Level.Biome.SNOW) -> TileMapLayer:
	var layer := TileMapLayer.new()
	layer.tile_set = Tiles.ground(biome)
	add_child(layer)
	layer.set_cells_terrain_connect(cells, 0, 0)
	return layer


func _rect_cells(rect: Rect2i) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			cells.append(Vector2i(x, y))
	return cells


func test_tiles_block() -> void:
	var layer := _paint(_rect_cells(Rect2i(0, 0, 5, 4)))
	check_equal(layer.get_cell_atlas_coords(Vector2i(0, 0)), Vector2i(1, 1), "top-left corner")
	check_equal(layer.get_cell_atlas_coords(Vector2i(2, 0)), Vector2i(2, 1), "top edge")
	check_equal(layer.get_cell_atlas_coords(Vector2i(4, 0)), Vector2i(3, 1), "top-right corner")
	check_equal(layer.get_cell_atlas_coords(Vector2i(0, 2)), Vector2i(1, 2), "left edge")
	check(layer.get_cell_atlas_coords(Vector2i(2, 1)) in [Vector2i(2, 2), Vector2i(4, 1)], "fill")
	check_equal(layer.get_cell_atlas_coords(Vector2i(4, 2)), Vector2i(3, 2), "right edge")
	check_equal(layer.get_cell_atlas_coords(Vector2i(0, 3)), Vector2i(1, 3), "bottom-left corner")
	check_equal(layer.get_cell_atlas_coords(Vector2i(2, 3)), Vector2i(2, 3), "bottom edge")
	check_equal(layer.get_cell_atlas_coords(Vector2i(4, 3)), Vector2i(3, 3), "bottom-right corner")
	layer.free()


func test_tiles_both_fills() -> void:
	var layer := _paint(_rect_cells(Rect2i(0, 0, 12, 12)))
	var seen := {}
	for cell in _rect_cells(Rect2i(1, 1, 10, 10)):
		seen[layer.get_cell_atlas_coords(cell)] = true
	check(seen.has(Vector2i(2, 2)) and seen.has(Vector2i(4, 1)), "both fills appear")
	layer.free()


func test_tiles_pillar_ledge_single() -> void:
	var layer := _paint([Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2), Vector2i(0, 3)])
	check_equal([layer.get_cell_atlas_coords(Vector2i(0, 0)), layer.get_cell_atlas_coords(Vector2i(0, 1)),
			layer.get_cell_atlas_coords(Vector2i(0, 2)), layer.get_cell_atlas_coords(Vector2i(0, 3))],
			[Vector2i(0, 1), Vector2i(0, 2), Vector2i(0, 2), Vector2i(0, 3)], "pillar")
	layer.set_cells_terrain_connect([Vector2i(5, 0), Vector2i(6, 0), Vector2i(7, 0), Vector2i(8, 0)], 0, 0)
	check_equal([layer.get_cell_atlas_coords(Vector2i(5, 0)), layer.get_cell_atlas_coords(Vector2i(6, 0)),
			layer.get_cell_atlas_coords(Vector2i(7, 0)), layer.get_cell_atlas_coords(Vector2i(8, 0))],
			[Vector2i(1, 0), Vector2i(2, 0), Vector2i(2, 0), Vector2i(3, 0)], "ledge")
	layer.set_cells_terrain_connect([Vector2i(20, 20)], 0, 0)
	check_equal(layer.get_cell_atlas_coords(Vector2i(20, 20)), Vector2i(0, 0), "single block")
	layer.free()


func test_tiles_inner_corner() -> void:
	# An L: a 2-thick vertical arm and a 2-thick horizontal arm.
	var cells := _rect_cells(Rect2i(0, 0, 2, 5))
	cells.append_array(_rect_cells(Rect2i(2, 3, 3, 2)))
	var layer := _paint(cells)
	check_equal(layer.get_cell_atlas_coords(Vector2i(1, 3)), Vector2i(4, 3), "inner corner where the arms meet")
	layer.free()


func test_tiles_biomes_match() -> void:
	var snow := Tiles.ground(Level.Biome.SNOW).get_source(0) as TileSetAtlasSource
	for biome in [Level.Biome.GRASS, Level.Biome.DESERT]:
		var other := Tiles.ground(biome).get_source(0) as TileSetAtlasSource
		var same := other.get_tiles_count() == snow.get_tiles_count()
		for i in snow.get_tiles_count():
			var coords := snow.get_tile_id(i)
			var a := snow.get_tile_data(coords, 0)
			var b := other.get_tile_data(coords, 0)
			if b == null or a.get_collision_polygon_points(0, 0) != b.get_collision_polygon_points(0, 0):
				same = false
				continue
			for neighbour in Tiles.ALL_NEIGHBOURS:
				if a.get_terrain_peering_bit(neighbour) != b.get_terrain_peering_bit(neighbour):
					same = false
		check(same and other.texture != snow.texture, "biome %d: same tiles, collision and peering bits" % biome)

#endregion


#region Level layout (level-layout.md)

func test_layout_ground_cells() -> void:
	var l := make(func(l: Level) -> void: l.floors = [Vector2i(30, 11)])
	var expected := {}
	for column in 47:
		var top := 11 if column >= 7 and column <= 36 else 12
		for row in range(top, 15):
			expected[Vector2i(column, row)] = true
	var used := l.ground.get_used_cells()
	var all_match := used.size() == expected.size()
	for cell in used:
		if not expected.has(cell):
			all_match = false
	check(all_match, "ground: start floor, written floor, end floor and nothing else")
	check_equal(l.level_end_x, 47 * Grid.TILE, "level_end_x")


func test_layout_gap_has_no_ground() -> void:
	var l := make(func(l: Level) -> void: l.floors = [Vector2i(5, 11), Vector2i(3, 15), Vector2i(5, 11)])
	var none := true
	for column in range(12, 15):
		for row in 15:
			if l.ground.get_cell_source_id(Vector2i(column, row)) != -1:
				none = false
	check(none, "no tiles in a floor on row 15")


func test_layout_cell_to_position() -> void:
	check_equal(Level.cell_to_position(Vector2i(8, 6), Level.Origin.TOP_LEFT), Vector2(144, 108), "coin at (8, 6)")
	check_equal(Level.cell_to_position(Vector2i(8, 10), Level.Origin.FEET), Vector2(153, 198), "walker at (8, 10)")
	check_equal(Level.cell_to_position(Vector2i(8, 4), Level.Origin.CENTRE), Vector2(153, 81), "flyer at (8, 4)")
	check_equal(Level.cell_to_position(Vector2i(8, 14), Level.Origin.CENTRE), Vector2(153, 261), "leaper in column 8")


func test_layout_width_limits() -> void:
	var l := make(func(l: Level) -> void: l.floors = [Vector2i(8, 12)], true)
	check(has_error(l, "columns wide"), "8 written columns: error")
	level.free()
	l = make(func(l: Level) -> void: l.floors = [Vector2i(9, 12)])
	check(l.errors.is_empty(), "9 written columns: allowed")
	level.free()
	l = make(func(l: Level) -> void: l.floors = [Vector2i(238, 12)])
	check(l.errors.is_empty(), "238 written columns: allowed")
	level.free()
	l = make(func(l: Level) -> void: l.floors = [Vector2i(239, 12)], true)
	check(has_error(l, "columns wide"), "239 written columns: error")


func test_layout_zero_width_floor() -> void:
	var l := make(func(l: Level) -> void: l.floors = [Vector2i(30, 11), Vector2i(0, 11)], true)
	check(has_error(l, "floors[1] (columns 37 to 36, row 11) has width 0"), "width 0: error naming the floor")


func test_layout_areas() -> void:
	var l := make(flat(func(l: Level) -> void:
		l.coins = [Vector2i(1, 6), Vector2i(37, 6), Vector2i(-1, 6), Vector2i(47, 6)]), true)
	check(has_error(l, "coin at (1, 6) is in the start area"), "start area")
	check(has_error(l, "coin at (37, 6) is in the flag area"), "flag area")
	check(has_error(l, "coin at (-1, 6) is outside the level"), "left of the level")
	check(has_error(l, "coin at (47, 6) is outside the level"), "right of the level")
	level.free()
	l = make(flat(func(l: Level) -> void:
		l.walkers = [WalkerSpawn.new(Vector2i(7, 10), WalkerSpawn.Kind.SHELL)]), true)
	check(has_error(l, "walker at (7, 10) is in the start area"), "walker B in column 7 reaches the start area")
	level.free()
	l = make(flat(func(l: Level) -> void: l.doors = [Vector2i(36, 10)]))
	check(l.errors.is_empty(), "door on the column left of the flag: allowed")


func test_layout_every_kind_in_start_area() -> void:
	var l := make(flat(func(l: Level) -> void:
		l.blocks = [BreakableBlockSpawn.new(Vector2i(0, 5))]
		l.walkers = [WalkerSpawn.new(Vector2i(1, 5), WalkerSpawn.Kind.PLAIN)]
		l.flyers = [FlyerSpawn.new(Vector2i(2, 5), 0.0)]
		l.crushers = [Vector2i(3, 5)]
		l.bars = [BarSpawn.new(Vector2i(4, 5), 1, 0.0, true)]
		l.springs = [Vector2i(5, 5)]
		l.doors = [Vector2i(6, 5)]
		l.checkpoints = [Vector2i(6, 2)]
		l.platforms = [PlatformSpawn.new(Vector2i(0, 8), 2)]
		l.ladders = [LadderSpawn.new(Vector2i(2, 9), 1)]), true)
	for name in ["breakable block at (0, 5)", "walker at (1, 5)", "flyer at (2, 5)", "crusher at (3, 5)",
			"bar at (4, 5)", "spring at (5, 5)", "door at (6, 5)", "checkpoint at (6, 2)", "platform at (0, 8)",
			"ladder at (2, 9)"]:
		check(has_error(l, name + " is in the start area"), name)
	level.free()
	l = make(func(l: Level) -> void:
		l.floors = [Vector2i(30, 11)]
		l.has_water = true
		l.leapers = [3], true)
	check(has_error(l, "leaper in column 3 is in the start area"), "leaper")


func test_layout_gap_line() -> void:
	var l := make(func(l: Level) -> void:
		l.floors = [Vector2i(30, 11)]
		l.has_water = true
		l.coins = [Vector2i(20, 13)]
		l.blocks = [BreakableBlockSpawn.new(Vector2i(21, 14))]
		l.platforms = [PlatformSpawn.new(Vector2i(22, 13), 1)], true)
	check(has_error(l, "coin at (20, 13) is below the gap line (row 13)"), "coin on row 13 with water")
	check(has_error(l, "breakable block at (21, 14) is below the gap line (row 13)"), "block on row 14 with water")
	check(has_error(l, "platform at (22, 13) is below the gap line (row 13)"), "platform on row 13 with water")
	level.free()
	l = make(func(l: Level) -> void:
		l.floors = [Vector2i(5, 11), Vector2i(4, 14), Vector2i(5, 11), Vector2i(4, 15), Vector2i(12, 11)]
		l.blocks = [BreakableBlockSpawn.new(Vector2i(14, 13))]
		l.coins = [Vector2i(22, 14), Vector2i(10, -1)])
	check(l.errors.is_empty(), "no water: a block or coin on row 13 or 14, a coin on row -1: allowed")
	level.free()
	l = make(func(l: Level) -> void:
		l.floors = [Vector2i(5, 11), Vector2i(4, 15), Vector2i(21, 11)]
		l.coins = [Vector2i(13, 15)], true)
	check(has_error(l, "coin at (13, 15) is below the gap line (row 15)"), "no water: row 15 is an error")
	level.free()
	l = make(func(l: Level) -> void:
		l.floors = [Vector2i(30, 13)]
		l.has_water = true
		l.walkers = [WalkerSpawn.new(Vector2i(20, 12), WalkerSpawn.Kind.SHELL)], true)
	check(not has_error(l, "walker at (20, 12)"), "with water, a walker B on row 12: allowed")


func test_layout_above_screen() -> void:
	var l := make(flat(func(l: Level) -> void:
		l.walkers = [WalkerSpawn.new(Vector2i(10, -1), WalkerSpawn.Kind.PLAIN)]
		l.springs = [Vector2i(20, -1)]), true)
	check(has_error(l, "walker at (10, -1) is above the screen"), "walker on row -1")
	check(has_error(l, "spring at (20, -1) is above the screen"), "spring on row -1")
	level.free()
	l = make(flat(func(l: Level) -> void:
		l.walkers = [WalkerSpawn.new(Vector2i(10, 0), WalkerSpawn.Kind.PLAIN)]
		l.springs = [Vector2i(20, 0)]))
	check(l.errors.is_empty(), "walker and spring on row 0: allowed")


func test_layout_overlaps() -> void:
	var l := make(flat(func(l: Level) -> void:
		l.coins = [Vector2i(14, 6)]
		l.walkers = [WalkerSpawn.new(Vector2i(14, 6), WalkerSpawn.Kind.PLAIN)]), true)
	check(has_error(l, "walker at (14, 6) overlaps coin at (14, 6)"), "walker on a coin")
	level.free()
	l = make(func(l: Level) -> void:
		l.floors = [Vector2i(7, 11), Vector2i(3, 9), Vector2i(20, 11)]
		l.walkers = [WalkerSpawn.new(Vector2i(14, 10), WalkerSpawn.Kind.PLAIN)]
		l.blocks = [BreakableBlockSpawn.new(Vector2i(20, 12))], true)
	check(has_error(l, "walker at (14, 10) overlaps floors[1] (columns 14 to 16, row 9)"), "walker inside the ground")
	check(has_error(l, "breakable block at (20, 12) overlaps floors[2]"), "block inside the ground")
	level.free()
	l = make(flat(func(l: Level) -> void:
		l.walkers = [WalkerSpawn.new(Vector2i(14, 10), WalkerSpawn.Kind.SHELL),
			WalkerSpawn.new(Vector2i(15, 10), WalkerSpawn.Kind.PLAIN),
			WalkerSpawn.new(Vector2i(20, 10), WalkerSpawn.Kind.SHELL),
			WalkerSpawn.new(Vector2i(22, 10), WalkerSpawn.Kind.SHELL)]), true)
	check(has_error(l, "walker at (15, 10) overlaps walker at (14, 10)"), "walker A right of walker B")
	check(has_error(l, "walker at (22, 10) overlaps walker at (20, 10)"), "two walker Bs two columns apart")
	level.free()
	l = make(flat(func(l: Level) -> void:
		l.coins = [Vector2i(14, 6)]
		l.bars = [BarSpawn.new(Vector2i(14, 6), 1, 0.0, true), BarSpawn.new(Vector2i(15, 11), 1, 0.0, true)]
		l.flyers = [FlyerSpawn.new(Vector2i(14, 6), 0.0)]))
	check(l.errors.is_empty(), "a bar or flyer on a coin or in the ground: allowed")
	level.free()
	l = make(func(l: Level) -> void:
		l.floors = [Vector2i(30, 11)]
		l.has_water = true
		l.bars = [BarSpawn.new(Vector2i(14, 6), 1, 0.0, true), BarSpawn.new(Vector2i(14, 6), 2, 0.0, true)]
		l.flyers = [FlyerSpawn.new(Vector2i(16, 6), 0.0), FlyerSpawn.new(Vector2i(16, 6), 0.0)]
		l.leapers = [20, 20], true)
	check(has_error(l, "bars: two on (14, 6)"), "two bars on one cell")
	check(has_error(l, "flyers: two on (16, 6)"), "two flyers on one cell")
	check(has_error(l, "leapers: two on column 20"), "two leapers in one column")


func test_layout_doors_checkpoints_springs_blocks() -> void:
	var l := make(flat(func(l: Level) -> void:
		l.coins = [Vector2i(10, 9), Vector2i(12, 10)]
		l.doors = [Vector2i(10, 10)]
		l.checkpoints = [Vector2i(12, 9)]
		l.springs = [Vector2i(14, 10)]
		l.blocks = [BreakableBlockSpawn.new(Vector2i(14, 10)), GiftBlockSpawn.new(Vector2i(16, 6),
				GiftBlockSpawn.Contents.DIAMOND), BreakableBlockSpawn.new(Vector2i(16, 5)),
				GiftBlockSpawn.new(Vector2i(18, 6), GiftBlockSpawn.Contents.COIN),
				BreakableBlockSpawn.new(Vector2i(18, 5)), GiftBlockSpawn.new(Vector2i(20, 0),
				GiftBlockSpawn.Contents.DIAMOND)]), true)
	check(has_error(l, "top of door at (10, 10) overlaps coin at (10, 9)"), "door top on a coin")
	check(has_error(l, "checkpoint at (12, 9) has no ground or platform under it"), "checkpoint over a coin")
	check(has_error(l, "spring at (14, 10) overlaps breakable block at (14, 10)"), "spring on a block")
	check(has_error(l, "breakable block at (16, 5) overlaps diamond above gift block at (16, 6)"),
			"block above a diamond gift block")
	check(not has_error(l, "(18, 5)"), "block above a coin gift block: allowed")
	check(has_error(l, "gift block at (20, 0) holds a diamond on row 0"), "diamond gift block on row 0")
	level.free()
	l = make(func(l: Level) -> void:
		l.floors = [Vector2i(5, 11), Vector2i(3, 15), Vector2i(22, 11)]
		l.checkpoints = [Vector2i(13, 10), Vector2i(20, 6), Vector2i(25, 10), Vector2i(27, 5)]
		l.platforms = [PlatformSpawn.new(Vector2i(27, 6), 2)]
		l.blocks = [BreakableBlockSpawn.new(Vector2i(20, 7))], true)
	check(has_error(l, "checkpoint at (13, 10) has no ground"), "checkpoint over a gap")
	check(has_error(l, "checkpoint at (20, 6) has no ground"), "checkpoint over a block")
	check(not has_error(l, "checkpoint at (25, 10)"), "checkpoint on a floor: allowed")
	check(not has_error(l, "checkpoint at (27, 5)"), "checkpoint on a platform: allowed")


func test_layout_platforms_ladders_bars_leapers_flyers() -> void:
	var l := make(flat(func(l: Level) -> void:
		l.platforms = [PlatformSpawn.new(Vector2i(10, 8), 0), PlatformSpawn.new(Vector2i(14, 8), 3),
				PlatformSpawn.new(Vector2i(16, 8), 2)]
		l.ladders = [LadderSpawn.new(Vector2i(20, 10), 0), LadderSpawn.new(Vector2i(22, 11), 2)]
		l.bars = [BarSpawn.new(Vector2i(24, 5), -1, 0.0, true)]
		l.leapers = [25]
		l.flyers = [FlyerSpawn.new(Vector2i(26, 1), 221.0), FlyerSpawn.new(Vector2i(27, 0), 0.0),
				FlyerSpawn.new(Vector2i(28, 1), -18.0), FlyerSpawn.new(Vector2i(29, 1), 220.0)]), true)
	check(has_error(l, "platforms[0] at (10, 8) has width 0"), "platform width 0")
	check(has_error(l, "platform at (16, 8) overlaps platform at (14, 8)"), "platform on a platform")
	check(has_error(l, "ladders[0] at (20, 10) has height 0"), "ladder height 0")
	check(has_error(l, "ladder at (22, 11) overlaps floors[0]"), "ladder on the ground")
	check(has_error(l, "bars[0] at (24, 5) has units -1"), "bar units -1")
	check(has_error(l, "leaper in column 25 needs has_water"), "leaper without water")
	check(has_error(l, "flyer at (26, 1)"), "flyer path 221 leaves the screen")
	check(has_error(l, "flyer at (27, 0)"), "flyer on row 0")
	check(has_error(l, "flyer at (28, 1)"), "flyer path -18 leaves the screen")
	check(not has_error(l, "flyer at (29, 1)"), "flyer path 220 from row 1: allowed")


func test_layout_all_errors_in_one_run() -> void:
	var l := make(func(l: Level) -> void:
		l.floors = [Vector2i(30, 11), Vector2i(0, 11)]
		l.coins = [Vector2i(1, 6), Vector2i(20, 6), Vector2i(20, 6)], true)
	check(has_error(l, "coin at (1, 6) is in the start area") and has_error(l, "has width 0")
			and has_error(l, "coin at (20, 6) overlaps coin at (20, 6)"), "all three errors")
	check(l.ground == null, "nothing is built")

#endregion


#region Player movement (player-movement.md)

## Waits until the player stands on the floor.
func settle() -> void:
	for i in 10:
		await updated
		if level.player.is_on_floor():
			return


func test_movement_walk_acceleration() -> void:
	make(flat())
	await settle()
	press("move_right")
	var speeds: Array[float] = []
	for i in 45:
		await updated
		speeds.append(level.player.velocity.x)
	var first := speeds.find_custom(func(v: float) -> bool: return v > 0.0)
	check(speeds[first + 39] < Player.WALK_SPEED, "below top speed after 40 updates (%s)" % speeds[first + 39])
	check_near(speeds[first + 40], Player.WALK_SPEED, "exactly top speed after 41")


## Holds jump for `hold` updates (0: until landing); returns [peak, updates
## until back on the floor], counting the jump's own update as 1.
func _jump(hold: int) -> Array[float]:
	await settle()
	var start_y := level.player.position.y
	press("jump")
	var peak := 0.0
	var updates := 0
	while updates < 200:
		await updated
		updates += 1
		if updates == hold:
			release("jump")
		peak = maxf(peak, start_y - level.player.position.y)
		if updates > 1 and level.player.is_on_floor():
			break
	release("jump")
	return [peak, updates]


func test_movement_full_jump() -> void:
	make(flat())
	var result := await _jump(0)
	check_near(result[0], 82.6, "peak height", 1.0)
	check_equal(int(result[1]), 56, "back on the floor after 56 updates")


func test_movement_short_jump() -> void:
	make(flat())
	var result := await _jump(1)
	check_near(result[0], 25.45, "peak height", 1.0)
	check_equal(int(result[1]), 20, "back on the floor after 20 updates")


func test_movement_wall() -> void:
	make(func(l: Level) -> void: l.floors = [Vector2i(3, 12), Vector2i(27, 8)])
	await settle()
	press("move_right")
	var touched := false
	var all_zero := true
	var all_idle := true
	var bounces := 0
	var tween: Tween = null
	for i in 120:
		await updated
		var p := level.player
		if p.is_on_wall():
			touched = true
		if touched:
			if p.velocity.x != 0.0:
				all_zero = false
			if p.state != Player.State.IDLE:
				all_idle = false
			if p.squash._tween != tween:
				tween = p.squash._tween
				bounces += 1
	check(touched, "reaches the wall")
	check(all_zero, "velocity.x is 0 on every update against the wall")
	check(all_idle, "Idle on every update against the wall")
	check_equal(bounces, 1, "the wall bounce plays once")


func test_movement_facing() -> void:
	make(flat())
	await settle()
	check(level.player.sprite.flip_h, "starts facing right")
	press("move_right")
	await wait(3)
	check(level.player.sprite.flip_h, "right held: facing right")
	release("move_right")
	press("move_left")
	await updated
	check(not level.player.sprite.flip_h, "left held: facing left at once")
	release("move_left")
	await wait(3)
	check(not level.player.sprite.flip_h, "nothing held: keeps facing")


func test_movement_falls_and_lands() -> void:
	make(flat())
	await settle()
	check_equal(level.player.state, Player.State.IDLE, "standing: Idle")
	press("move_right")
	await wait(5)
	check_equal(level.player.state, Player.State.WALK, "walking: Walk")
	check(level.player.sprite.animation == "walk", "walk animation")

#endregion


#region Player animation (player-animation.md)

func test_animation_walk_rate() -> void:
	make(flat())
	await settle()
	press("move_right")
	var first_frame := -1
	for i in 60:
		await updated
		if first_frame == -1 and level.player.state == Player.State.WALK:
			first_frame = level.player.sprite.frame
	check_equal(first_frame, 1, "Idle to Walk starts on sprite_2")
	check_near(level.player.sprite.speed_scale * Player.WALK_FPS, 15.0, "top speed: 15 fps")
	check_near(remap(50.625, 0, Player.WALK_SPEED, 4.3, 15), 9.65, "half speed: 9.65 fps")
	press("jump")
	await wait(2)
	check_equal(level.player.sprite.speed_scale, 1.0, "Walk to Rise: speed_scale back to 1")
	check(level.player.sprite.animation == "air", "Rise shows sprite_2")
	check(not level.player.sprite.is_playing() or level.player.sprite.sprite_frames.get_frame_count("air") == 1,
			"Rise: not animating")

#endregion


#region Camera (camera.md)

func test_camera_start() -> void:
	make(flat())
	check_equal(level.player.position, Vector2(81, 216), "player at (81, 216)")
	check_near(level.camera.left_edge, 0.0, "camera's left edge at 0")
	check_equal(Screen.half_width, 229.5, "half width")
	check_equal(Screen.half_height, 128.5, "half height")


func test_camera_follows_right_only() -> void:
	make(flat())
	await settle()
	press("move_right")
	await wait(240)
	check_near(level.camera.position.x, level.player.position.x, "follows the player right")
	release("move_right")
	press("move_left")
	var turned_at := -1.0
	for i in 120:
		await updated
		if turned_at < 0 and level.player.velocity.x < 0:
			turned_at = level.camera.position.x
	check_near(level.camera.position.x, turned_at, "stays still once the player moves left")


func test_camera_left_edge() -> void:
	make(flat())
	await settle()
	press("move_left")
	await wait(120)
	check_near(level.player.position.x, level.camera.left_edge, "player held at the left edge")
	check(level.player.velocity.x < 0, "velocity.x untouched")


func test_camera_level_end() -> void:
	make(flat())
	await settle()
	level.player.position.x = level.level_end_x - 30
	level.flag.position.x = level.level_end_x + 100
	press("move_right")
	await wait(90)
	check_near(level.camera.right_edge, level.level_end_x, "camera's right edge at the level end")
	check_near(level.player.position.x, level.level_end_x, "player stops at the level end")
	check(level.player.velocity.x > 0, "velocity.x untouched")

#endregion


#region Player damage (player-damage.md)

func test_damage_injury_and_invincibility() -> void:
	make(flat())
	await settle()
	level.player.hurt()
	check_equal(level.health, 1, "health 1")
	check(get_tree().paused, "paused")
	await wait(54)
	check(get_tree().paused, "still paused at 0.9 s")
	await wait(3)
	check(not get_tree().paused, "unpaused after 0.92 s")
	check(level.player.invincible, "invincible")
	var hidden: Array[bool] = []
	for i in 6:
		await updated
		hidden.append(not level.player.sprite.visible)
	check_equal(hidden, [true, false, true, false, true, false], "flickers, hidden on updates 1, 3, 5")
	await wait(170)
	check(not level.player.invincible and level.player.sprite.visible, "visible once invincibility ends")
	check_equal(level.heart.frame, 1, "heart shows 1 health")


func test_damage_death() -> void:
	make(flat())
	await settle()
	level.player.sprite.flip_h = false
	level.health = 1
	level.player.hurt()
	check(get_tree().paused, "paused")
	check(not level.player.visible and level.player.process_mode == Node.PROCESS_MODE_DISABLED,
			"player hidden and disabled")
	var death: PlayerDeath = level.effects.get_child(0)
	check(death != null and death.position == level.player.position, "death scene at the player")
	check(not (death.get_child(0) as Sprite2D).flip_h, "same flip_h")
	await wait(17)
	check_near(death.velocity.y, -PlayerDeath.JUMP_SPEED + PlayerDeath.GRAVITY / 60.0, "death jump starts after 0.27 s", 0.01)
	check(get_tree().paused, "still paused")
	await wait(120)
	check(death.position.y > level.player.position.y + 18, "falls through the floor")
	check_equal(level.heart.frame, 0, "heart empty")


func test_damage_death_line() -> void:
	make(func(l: Level) -> void: l.floors = [Vector2i(5, 12), Vector2i(4, 15), Vector2i(21, 12)])
	await settle()
	level.player.invincible = true
	level.player.position = Vector2(220, 200)
	var died := false
	for i in 60:
		await updated
		if level.player.process_mode == Node.PROCESS_MODE_DISABLED:
			died = true
			break
	check(died, "dies at the death line, even invincible")
	check(level.player.position.y >= 257, "feet reached y 257")
	check_equal(level.health, 0, "health 0")


func test_damage_water_death_line() -> void:
	make(func(l: Level) -> void:
		l.floors = [Vector2i(5, 12), Vector2i(4, 13), Vector2i(21, 12)]
		l.has_water = true)
	await settle()
	level.player.position = Vector2(220, 200)
	var alive_at_surface := false
	for i in 60:
		await updated
		if level.player.position.y >= 234 and level.player.process_mode != Node.PROCESS_MODE_DISABLED:
			alive_at_surface = true
		if level.player.process_mode == Node.PROCESS_MODE_DISABLED:
			break
	check(alive_at_surface, "alive below the water's surface")
	check(level.player.position.y >= 257 and level.player.process_mode == Node.PROCESS_MODE_DISABLED,
			"dies at y 257")

#endregion


#region Flag (flag.md)

func test_flag_place() -> void:
	make(func(l: Level) -> void: l.floors = [Vector2i(9, 12)])
	check_equal(level.level_end_x, 468, "level_end_x")
	check_equal(level.flag.position, Vector2(288, 0), "flag at x 288")
	var sprite: AnimatedSprite2D = level.flag.get_child(0)
	check(sprite.is_playing() and sprite.sprite_frames.get_animation_speed("wave") == 7.5, "animates at 7.5 fps")


func test_flag_win() -> void:
	make(flat())
	await settle()
	level.player.position.x = level.win_x - 1.5
	await updated
	check(not get_tree().paused, "one pixel before: not won")
	level.player.position.x = level.win_x
	level.player.invincible = true
	level.player.sprite.visible = false
	await updated
	check(get_tree().paused, "won: paused")
	check(level.player.sprite.visible, "sprite visible")


func test_flag_death_beats_win() -> void:
	make(func(l: Level) -> void: l.floors = [Vector2i(5, 12), Vector2i(4, 15), Vector2i(21, 12)])
	await settle()
	level.flag.position.x = 225
	level.player.position = Vector2(226, 260)
	await updated
	check(level.player.process_mode == Node.PROCESS_MODE_DISABLED, "dies, does not win")
	check_equal(level.effects.get_child_count(), 1, "the death scene plays")

#endregion


#region HUD and iris (hud.md, game-flow.md)

func test_hud_heart() -> void:
	make(flat())
	check_equal(level.heart.frame, 2, "starts at 2 health")
	check_equal(level.heart.position, Vector2(433, 20), "top-left at (433, 20)")
	check(level.heart.get_parent() is CanvasLayer, "fixed to the screen")
	level.health = 1
	check_equal(level.heart.frame, 1, "follows health")


func test_iris_positions() -> void:
	make(flat())
	var iris: Iris = load("res://levels/iris.tscn").instantiate()
	iris.setup(level)
	add_child(iris)
	check_equal(iris.target(), Vector2(81, 208.5), "target")
	iris._put(iris._shut_positions())
	check_equal([iris._top.position, iris._right.position, iris._bottom.position, iris._left.position],
			[Vector2(0, -48.5), Vector2(81, 0), Vector2(0, 208.5), Vector2(-378, 0)], "shut")
	iris._put(iris._open_positions())
	check_equal([iris._top.position, iris._right.position, iris._bottom.position, iris._left.position],
			[Vector2(0, -257), Vector2(459, 0), Vector2(0, 257), Vector2(-459, 0)], "open")
	iris.close()
	await wait(15)
	check_near(iris._right.position.x, (459 + 81) / 2.0, "halfway: halfway between", 6.0)
	check_equal(iris.layer, 2, "in front of the HUD")
	iris.free()


func test_level_is_main() -> void:
	make(flat())
	check(not level.is_main, "a test level is not main")
	check(level.iris == null and not get_tree().paused, "no iris, not paused")

#endregion


#region Jump check (level-layout.md)

func test_jumps_gaps() -> void:
	var l := make(func(l: Level) -> void: l.floors = [Vector2i(10, 12), Vector2i(5, 15), Vector2i(10, 12)])
	check(l.errors.is_empty(), "same row, 5-tile gap: passes")
	level.free()
	l = make(func(l: Level) -> void: l.floors = [Vector2i(10, 12), Vector2i(6, 15), Vector2i(10, 12)], true)
	check(has_error(l, "floors[0] (columns 7 to 16, row 12): no jump onward from (16, 12)"), "6-tile gap fails")
	check(l.ground == null, "nothing built")
	level.free()
	l = make(func(l: Level) -> void: l.floors = [Vector2i(10, 12), Vector2i(6, 15), Vector2i(10, 12), Vector2i(6, 15), Vector2i(4, 12)], true)
	check_equal(l.errors.size(), 2, "two failing jumps, both reported")
	level.free()
	l = make(func(l: Level) -> void: l.floors = [Vector2i(10, 12), Vector2i(6, 12), Vector2i(6, 15)], true)
	check(has_error(l, "floors[1] (columns 17 to 22, row 12): no jump onward"), "6-tile gap onto the end floor fails")


func test_jumps_heights() -> void:
	var l := make(func(l: Level) -> void: l.floors = [Vector2i(10, 12), Vector2i(10, 8)])
	check(l.errors.is_empty(), "4 rows higher: passes")
	level.free()
	l = make(func(l: Level) -> void: l.floors = [Vector2i(10, 12), Vector2i(10, 7), Vector2i(10, 12)], true)
	check(has_error(l, "floors[0]"), "5 rows higher: fails")
	level.free()
	l = make(func(l: Level) -> void: l.floors = [Vector2i(10, 12), Vector2i(1, 15), Vector2i(1, 12), Vector2i(10, 12)])
	check(l.errors.is_empty(), "1 wide, same row, 1-tile gap: passes")


func test_jumps_table() -> void:
	# The reference table: [rows higher, furthest gap that passes].
	var table := [[4, 3], [3, 4], [1, 4], [0, 5], [-2, 5], [-3, 6], [-4, 6], [-5, 7], [-7, 7], [-8, 8],
			[-10, 8], [-11, 9], [-12, 9], [-13, 10], [-14, 10]]
	var arc := Level.jump_arc()
	for row in table:
		var height: float = row[0] * Grid.TILE
		var gap: int = row[1]
		check(height <= Level.jump_reach(arc, gap * Grid.TILE) and height > Level.jump_reach(arc, (gap + 1) * Grid.TILE),
				"%d rows higher: furthest %d tiles" % [row[0], gap])
	check(5 * Grid.TILE > Level.jump_reach(arc, 0), "5 rows higher: unreachable")


func test_jumps_platforms() -> void:
	var l := make(func(l: Level) -> void:
		l.floors = [Vector2i(10, 12), Vector2i(7, 15), Vector2i(10, 12)]
		l.platforms = [PlatformSpawn.new(Vector2i(20, 12), 3)])
	check(l.errors.is_empty(), "7-tile gap with a platform 3 into it: passes")
	level.free()
	l = make(func(l: Level) -> void:
		l.floors = [Vector2i(10, 12), Vector2i(7, 15), Vector2i(10, 12)], true)
	check(has_error(l, "floors[0]"), "the same without the platform: fails")
	level.free()
	l = make(func(l: Level) -> void:
		l.floors = [Vector2i(10, 12), Vector2i(7, 15), Vector2i(10, 12)]
		l.platforms = [PlatformSpawn.new(Vector2i(18, 6), 2), PlatformSpawn.new(Vector2i(20, 12), 3)], true)
	check(has_error(l, "floors[0]"), "an unreachable platform just ahead hides a reachable one")
	level.free()
	l = make(func(l: Level) -> void:
		l.floors = [Vector2i(10, 12), Vector2i(10, 5), Vector2i(10, 5)]
		l.platforms = [PlatformSpawn.new(Vector2i(15, 8), 4)])
	check(l.errors.is_empty(), "a platform 4 rows up over the edge, then a floor 3 rows above it: passes")
	level.free()
	l = make(func(l: Level) -> void:
		l.floors = [Vector2i(20, 12)]
		l.platforms = [PlatformSpawn.new(Vector2i(10, 8), 3)])
	check(l.errors.is_empty(), "a platform over a floor that runs on: passes")
	level.free()
	l = make(func(l: Level) -> void:
		l.floors = [Vector2i(10, 10), Vector2i(6, 15), Vector2i(10, 12)]
		l.platforms = [PlatformSpawn.new(Vector2i(17, 12), 2)])
	check(l.errors.is_empty(), "a platform 2 rows below at the take-off: passes")


func test_jumps_only_after_other_checks() -> void:
	var l := make(func(l: Level) -> void:
		l.floors = [Vector2i(10, 12), Vector2i(6, 15), Vector2i(10, 12)]
		l.coins = [Vector2i(1, 5)], true)
	check_equal(l.errors.size(), 1, "only the coin's error")

#endregion
