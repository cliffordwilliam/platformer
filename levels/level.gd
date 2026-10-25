@abstract
class_name Level
extends Node2D
## The shared base of every level: the level script's layout() only sets
## the fields below; Level checks them, then builds everything.

enum Biome { SNOW, GRASS, DESERT }
enum Origin { TOP_LEFT, FEET, CENTRE }
enum PlatformLook { WOODEN, CLOUD, STONE, MUSHROOM }

## Each physics layer's bit (overview.md, Physics layers).
const LAYER_LEVEL := 1
const LAYER_WALKERS := 2
const LAYER_ENEMIES := 4
const LAYER_PICKUPS := 8
const LAYER_SPRINGS := 16
const LAYER_DOORS := 32
const LAYER_CHECKPOINTS := 64

const START_FLOOR := Vector2i(7, 12)
const END_FLOOR := Vector2i(10, 12)
const PLAYER_CELL := Vector2i(4, 11)
## The last row the screen shows (its top 5 px).
const LAST_ROW := 14

## Where the player starts; moved by checkpoints, kept through reloads.
static var respawn_cell: Vector2i = PLAYER_CELL
## On in a snapshot: guides drawn, random art left out.
static var show_guides := false

# The fields layout() sets.
var biome: Biome
var floors: Array[Vector2i] = []
var has_water := false
var blocks: Array[BlockSpawn] = []
var coins: Array[Vector2i] = []
var walkers: Array[WalkerSpawn] = []
var flyers: Array[FlyerSpawn] = []
var leapers: Array[int] = []
var crushers: Array[Vector2i] = []
var springs: Array[Vector2i] = []
var doors: Array[Vector2i] = []
var checkpoints: Array[Vector2i] = []
var bars: Array[BarSpawn] = []
var platforms: Array[PlatformSpawn] = []
var ladders: Array[LadderSpawn] = []

## Every problem the layout checks found; nothing is built if any.
var errors: Array[String] = []
## The right-edge cells of the things whose jumps failed, for the guides.
var jump_failures: Array[Vector2i] = []

var health := 2:
	set(value):
		health = value
		if heart != null:
			heart.frame = value

# The level's children, kept so things find each other through the level.
var background: Parallax2D
var tree_layer: TileMapLayer
var tree_canopy_layer: TileMapLayer
var tree_canopy_front_layer: TileMapLayer
var rope_ceiling_layer: TileMapLayer
var rope_ceiling_decoration_layer: TileMapLayer
var rope_layer: TileMapLayer
var pipe_layer: TileMapLayer
var decoration_layer: TileMapLayer
var platform_layer: TileMapLayer
var mushroom_decoration_layer: TileMapLayer
var ladder_layer: TileMapLayer
var ground: TileMapLayer
var spike_layer: TileMapLayer
var waterfall_layer: TileMapLayer
var ground_piece_layer: Node2D
var water_layer: TileMapLayer
var effects: Node2D
var guides: Node2D
var heart: AnimatedSprite2D

## The level's right edge, in pixels: where the camera stops.
var level_end_x: int:
	get:
		var columns := 0
		for floor_ in floors:
			columns += floor_.x
		return columns * Grid.TILE

## The row from which a floor is a gap, and below which nothing is placed.
var gap_row: int:
	get:
		return 13 if has_water else 15

## True when the level is the scene the game is playing.
var is_main: bool:
	get:
		return is_inside_tree() and get_tree().current_scene == self

## The first column of each floor in `floors`.
var _floor_starts: Array[int] = []
## Whether the only errors are failing jumps (a snapshot still builds then).
var _only_jump_errors := false


@abstract func layout() -> void


func _ready() -> void:
	process_mode = PROCESS_MODE_PAUSABLE
	layout()
	floors.push_front(START_FLOOR)
	floors.push_back(END_FLOOR)
	_floor_starts.clear()
	var column := 0
	for floor_ in floors:
		_floor_starts.append(column)
		column += floor_.x
	_check_layout()
	if not errors.is_empty():
		if is_main or show_guides:
			for message in errors:
				push_error(message)
		if not (show_guides and _only_jump_errors):
			if is_main or show_guides:
				get_tree().quit(1)
			return
	_build()


## Turns a cell into the position of a thing with that kind of origin.
static func cell_to_position(cell: Vector2i, origin: Origin) -> Vector2:
	match origin:
		Origin.FEET:
			return Vector2(cell * Grid.TILE + Vector2i(Grid.HALF_TILE, Grid.TILE))
		Origin.CENTRE:
			return Vector2(cell * Grid.TILE + Vector2i(Grid.HALF_TILE, Grid.HALF_TILE))
	return Vector2(cell * Grid.TILE)


## The cell a point is in.
static func cell_at(point: Vector2) -> Vector2i:
	return Vector2i(floori(point.x / Grid.TILE), floori(point.y / Grid.TILE))


#region Checking the layout

func _floor_name(index: int) -> String:
	if index == 0:
		return "start floor"
	if index == floors.size() - 1:
		return "end floor"
	var first := _floor_starts[index]
	return "floors[%d] (columns %d to %d, row %d)" % [
		index - 1, first, first + floors[index].x - 1, floors[index].y]


func _is_gap(floor_: Vector2i) -> bool:
	return floor_.y >= gap_row


## The column of the flag: the end floor's first column.
func _flag_column() -> int:
	return _floor_starts[floors.size() - 1]


func _column_count() -> int:
	return level_end_x / Grid.TILE


## The index of the floor holding a column, or -1 outside the level.
func _floor_index_at(column: int) -> int:
	for i in floors.size():
		if column >= _floor_starts[i] and column < _floor_starts[i] + floors[i].x:
			return i
	return -1


## Whether a cell is built ground: in a floor that is not a gap, from its
## surface row down to the last row.
func _is_ground(cell: Vector2i) -> bool:
	var i := _floor_index_at(cell.x)
	return i != -1 and not _is_gap(floors[i]) and cell.y >= floors[i].y and cell.y <= LAST_ROW


## Whether a cell is in some platform.
func _is_platform_cell(cell: Vector2i) -> bool:
	for platform in platforms:
		if cell.y == platform.cell.y and cell.x >= platform.cell.x and cell.x < platform.cell.x + platform.width:
			return true
	return false


## One thing placed by the level script, with every cell it takes.
class Placed:
	var name: String
	var cells: Array[Vector2i] = []
	## What each cell is called in an overlap message.
	var cell_names: Array[String] = []
	## False for bars, flyers and leapers, which may be anywhere.
	var occupies := true
	## False for leapers, written as columns.
	var check_gap := true

	func _init(name_: String) -> void:
		name = name_

	func take(cell: Vector2i, cell_name: String = "") -> Placed:
		cells.append(cell)
		cell_names.append(name if cell_name == "" else cell_name)
		return self


## Everything placed, the things that take cells in the order they take
## them (level-layout.md, Occupied cells), then bars, flyers and leapers.
func _placed() -> Array[Placed]:
	var list: Array[Placed] = []
	for platform in platforms:
		var thing := Placed.new("platform at %s" % platform.cell)
		for i in maxi(platform.width, 0):
			thing.take(platform.cell + Vector2i(i, 0))
		list.append(thing)
	for ladder in ladders:
		var thing := Placed.new("ladder at %s" % ladder.cell)
		for i in maxi(ladder.height, 0):
			thing.take(ladder.cell - Vector2i(0, i))
		list.append(thing)
	for block in blocks:
		if block is GiftBlockSpawn:
			var thing := Placed.new("gift block at %s" % block.cell).take(block.cell)
			if (block as GiftBlockSpawn).contents == GiftBlockSpawn.Contents.DIAMOND:
				thing.take(block.cell + Vector2i.UP, "diamond above gift block at %s" % block.cell)
			list.append(thing)
		else:
			list.append(Placed.new("breakable block at %s" % block.cell).take(block.cell))
	for cell in coins:
		list.append(Placed.new("coin at %s" % cell).take(cell))
	for cell in springs:
		list.append(Placed.new("spring at %s" % cell).take(cell))
	for cell in doors:
		list.append(Placed.new("door at %s" % cell).take(cell).take(cell + Vector2i.UP, "top of door at %s" % cell))
	for cell in checkpoints:
		list.append(Placed.new("checkpoint at %s" % cell).take(cell).take(
				cell + Vector2i.UP, "top of checkpoint at %s" % cell))
	for walker in walkers:
		var thing := Placed.new("walker at %s" % walker.cell)
		if walker.kind == WalkerSpawn.Kind.SHELL:
			for row in [walker.cell.y, walker.cell.y - 1]:
				for column in [walker.cell.x - 1, walker.cell.x, walker.cell.x + 1]:
					thing.take(Vector2i(column, row))
		else:
			thing.take(walker.cell)
		list.append(thing)
	for cell in crushers:
		list.append(Placed.new("crusher at %s" % cell).take(cell))
	for bar in bars:
		var thing := Placed.new("bar at %s" % bar.cell).take(bar.cell)
		thing.occupies = false
		list.append(thing)
	for flyer in flyers:
		var thing := Placed.new("flyer at %s" % flyer.cell).take(flyer.cell)
		thing.occupies = false
		list.append(thing)
	for column in leapers:
		var thing := Placed.new("leaper in column %d" % column).take(Vector2i(column, LAST_ROW))
		thing.occupies = false
		thing.check_gap = false
		list.append(thing)
	return list


## Checks every field layout() wrote, appending a message per problem.
func _check_layout() -> void:
	for i in range(1, floors.size() - 1):
		if floors[i].x < 1:
			errors.append("%s has width %d: it must be 1 or more" % [_floor_name(i), floors[i].x])
	var min_columns := ceili(Screen.width / float(Grid.TILE))
	var max_columns := floori(10 * Screen.width / float(Grid.TILE))
	if level_end_x < Screen.width or level_end_x > 10 * Screen.width:
		errors.append("floors: the level is %d columns wide, start and end floors included; it must be %d to %d" % [
			_column_count(), min_columns, max_columns])

	var placed := _placed()
	var flag_column := _flag_column()
	var columns := _column_count()
	for thing in placed:
		for cell in thing.cells:
			var problem := ""
			if cell.x < 0 or cell.x >= columns:
				problem = "is outside the level"
			elif cell.x < START_FLOOR.x:
				problem = "is in the start area"
			elif cell.x >= flag_column:
				problem = "is in the flag area"
			if problem != "":
				errors.append("%s %s" % [thing.name, problem])
				break
		if thing.check_gap:
			for cell in thing.cells:
				if cell.y >= gap_row:
					errors.append("%s is below the gap line (row %d)" % [thing.name, gap_row])
					break

	for i in platforms.size():
		if platforms[i].width < 1:
			errors.append("platforms[%d] at %s has width %d: it must be 1 or more" % [
				i, platforms[i].cell, platforms[i].width])
	for i in ladders.size():
		if ladders[i].height < 1:
			errors.append("ladders[%d] at %s has height %d: it must be 1 or more" % [
				i, ladders[i].cell, ladders[i].height])
	for i in bars.size():
		if bars[i].units < 0:
			errors.append("bars[%d] at %s has units %d: it must be 0 or more" % [i, bars[i].cell, bars[i].units])
	for cell in checkpoints:
		var under := cell + Vector2i.DOWN
		if not _is_ground(under) and not _is_platform_cell(under):
			errors.append("checkpoint at %s has no ground or platform under it" % cell)
	for block in blocks:
		if block is GiftBlockSpawn and (block as GiftBlockSpawn).contents == GiftBlockSpawn.Contents.DIAMOND \
				and block.cell.y < 1:
			errors.append("gift block at %s holds a diamond on row %d: it must be on row 1 or more" % [
				block.cell, block.cell.y])
	for walker in walkers:
		if walker.cell.y < 0:
			errors.append("walker at %s is above the screen" % walker.cell)
	for cell in springs:
		if cell.y < 0:
			errors.append("spring at %s is above the screen" % cell)
	if not leapers.is_empty() and not has_water:
		for column in leapers:
			errors.append("leaper in column %d needs has_water on: a leaper leaps out of the water" % column)
	for flyer in flyers:
		var y := cell_to_position(flyer.cell, Origin.CENTRE).y
		for end in [y, y + flyer.bob_distance]:
			if end - 10 < 0 or end + 10 > Screen.height:
				errors.append("flyer at %s with bob_distance %s leaves the screen at y %s" % [
					flyer.cell, flyer.bob_distance, end])
				break

	_check_occupied(placed)

	if errors.is_empty():
		_check_jumps()
		_only_jump_errors = not errors.is_empty()


## No two things share a cell (level-layout.md, Occupied cells).
func _check_occupied(placed: Array[Placed]) -> void:
	var occupied: Dictionary[Vector2i, String] = {}
	for i in floors.size():
		if _is_gap(floors[i]):
			continue
		for column in range(_floor_starts[i], _floor_starts[i] + floors[i].x):
			for row in range(floors[i].y, LAST_ROW + 1):
				occupied[Vector2i(column, row)] = _floor_name(i)
	var own: Dictionary[String, Dictionary] = {"bar": {}, "flyer": {}, "leaper": {}}
	for thing in placed:
		if not thing.occupies:
			var kind := thing.name.get_slice(" ", 0)
			var key: Variant = thing.cells[0].x if kind == "leaper" else thing.cells[0]
			if own[kind].has(key):
				errors.append("%ss: two on %s" % [kind, ("column %d" % key) if kind == "leaper" else str(key)])
			own[kind][key] = true
			continue
		for i in thing.cells.size():
			var cell := thing.cells[i]
			var taken: String = occupied.get(cell, "")
			if taken != "":
				errors.append("%s overlaps %s" % [thing.cell_names[i], taken])
			else:
				occupied[cell] = thing.cell_names[i]

#endregion


#region Building

func _build() -> void:
	background = _add_node(Parallax2D.new(), "Background")
	ground = _add_tile_layer("Ground", Tiles.ground(biome))
	_fill_ground()


func _add_node(node: Node, node_name: String) -> Node:
	node.name = node_name
	add_child(node)
	return node


func _add_tile_layer(layer_name: String, tile_set: TileSet) -> TileMapLayer:
	var layer := TileMapLayer.new()
	layer.tile_set = tile_set
	return _add_node(layer, layer_name)


func _fill_ground() -> void:
	var cells: Array[Vector2i] = []
	for i in floors.size():
		if _is_gap(floors[i]):
			continue
		for column in range(_floor_starts[i], _floor_starts[i] + floors[i].x):
			for row in range(floors[i].y, LAST_ROW + 1):
				cells.append(Vector2i(column, row))
	ground.set_cells_terrain_connect(cells, 0, 0)

#endregion


func _check_jumps() -> void:
	pass
