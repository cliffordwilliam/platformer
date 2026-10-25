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
const MUSIC_VOLUME_DB := -5.4

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
var flag: Flag
var block_item_layer: Node2D
var block_layer: Node2D
var coin_layer: Node2D
var spring_layer: Node2D
var door_layer: Node2D
var checkpoint_layer: Node2D
var walker_layer: Node2D
var flyer_layer: Node2D
var leaper_layer: Node2D
var crusher_layer: Node2D
var bar_layer: Node2D
var player: Player
var camera: Camera
var iris: Iris
var sounds: Sounds
var music: AudioStreamPlayer

## The flag's x: reaching it wins the level.
var win_x: float:
	get:
		return flag.position.x

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
	tree_layer = _add_tile_layer("Trees", Tiles.trees())
	tree_canopy_layer = _add_tile_layer("TreeCanopies", Tiles.trees())
	tree_canopy_front_layer = _add_tile_layer("TreeCanopiesFront", Tiles.trees())
	rope_ceiling_layer = _add_tile_layer("RopeCeilings", Tiles.ground(biome))
	rope_ceiling_layer.collision_enabled = false
	rope_ceiling_decoration_layer = _add_tile_layer("RopeCeilingDecorations", Tiles.decorations(biome))
	rope_layer = _add_tile_layer("Ropes", Tiles.rope())
	pipe_layer = _add_tile_layer("Pipes", Tiles.pipes())
	decoration_layer = _add_tile_layer("Decorations", Tiles.decorations(biome))
	flag = load("res://items/flag.tscn").instantiate()
	flag.setup(self)
	_add_node(flag, "Flag")
	platform_layer = _add_tile_layer("Platforms", Tiles.platforms())
	mushroom_decoration_layer = _add_tile_layer("MushroomDecorations", Tiles.decorations(biome))
	ladder_layer = _add_tile_layer("Ladders", Tiles.ladder())
	ground = _add_tile_layer("Ground", Tiles.ground(biome))
	spike_layer = _add_tile_layer("Spikes", Tiles.spikes())
	spike_layer.position.y = Screen.height - LAST_ROW * Grid.TILE
	waterfall_layer = _add_tile_layer("Waterfalls", Tiles.water())
	ground_piece_layer = _add_node(Node2D.new(), "GroundPieces")
	block_item_layer = _add_node(Node2D.new(), "BlockItems")
	block_layer = _add_node(Node2D.new(), "Blocks")
	coin_layer = _add_node(Node2D.new(), "Coins")
	spring_layer = _add_node(Node2D.new(), "Springs")
	door_layer = _add_node(Node2D.new(), "Doors")
	checkpoint_layer = _add_node(Node2D.new(), "Checkpoints")
	walker_layer = _add_node(Node2D.new(), "Walkers")
	flyer_layer = _add_node(Node2D.new(), "Flyers")
	leaper_layer = _add_node(Node2D.new(), "Leapers")
	crusher_layer = _add_node(Node2D.new(), "Crushers")
	bar_layer = _add_node(Node2D.new(), "Bars")
	player = load("res://player/player.tscn").instantiate()
	player.setup(self)
	_add_node(player, "Player")
	water_layer = _add_tile_layer("Water", Tiles.water())
	effects = _add_node(Node2D.new(), "Effects")
	if show_guides:
		guides = _add_node(Node2D.new(), "Guides")
		guides.draw.connect(_draw_guides)
	camera = load("res://levels/camera.tscn").instantiate()
	camera.setup(self)
	_add_node(camera, "Camera")
	var hud := _add_node(CanvasLayer.new(), "HUD")
	heart = AnimatedSprite2D.new()
	heart.sprite_frames = sprite_frames({"default": [[
		"res://art/heart/sprite_1.png", "res://art/heart/sprite_2.png", "res://art/heart/sprite_3.png"], 0.0]})
	heart.centered = false
	heart.position = Vector2(Screen.width - 26, 20)
	heart.frame = health
	hud.add_child(heart)
	if is_main:
		iris = load("res://levels/iris.tscn").instantiate()
		iris.setup(self)
		_add_node(iris, "Iris")
	sounds = load("res://levels/sounds.tscn").instantiate()
	sounds.setup(self)
	_add_node(sounds, "Sounds")
	if is_main:
		music = _add_node(AudioStreamPlayer.new(), "Music")
		music.process_mode = PROCESS_MODE_ALWAYS
		var track: AudioStreamOggVorbis = load("res://music/adventure.ogg")
		track.loop = true
		music.stream = track
		music.volume_db = MUSIC_VOLUME_DB

	_fill_ground()
	_place_things()
	if has_water:
		_fill_water()
	else:
		_fill_spikes()

	flag.position = Vector2(level_end_x - 10 * Grid.TILE, 0)
	player.position = cell_to_position(respawn_cell, Origin.FEET)
	camera.position = Vector2(clampf(player.position.x, Screen.half_width, level_end_x - Screen.half_width),
			Screen.half_height)
	if is_main:
		_start()


func _add_node(node: Node, node_name: String) -> Node:
	node.name = node_name
	add_child(node)
	return node


func _add_tile_layer(layer_name: String, tile_set: TileSet) -> TileMapLayer:
	var layer := TileMapLayer.new()
	layer.tile_set = tile_set
	return _add_node(layer, layer_name)


## Builds one of everything in the level script's lists.
func _place_things() -> void:
	pass


## Instantiates a scene, places it, sets it up and adds it to its layer.
func _spawn(path: String, cell: Vector2i, origin: Origin, layer: Node2D, settings: Array = []) -> Node:
	var thing: Node2D = load(path).instantiate()
	thing.position = cell_to_position(cell, origin)
	thing.callv("setup", [self] + settings)
	layer.add_child(thing)
	return thing


func _fill_ground() -> void:
	var cells: Array[Vector2i] = []
	for i in floors.size():
		if _is_gap(floors[i]):
			continue
		for column in range(_floor_starts[i], _floor_starts[i] + floors[i].x):
			for row in range(floors[i].y, LAST_ROW + 1):
				cells.append(Vector2i(column, row))
	ground.set_cells_terrain_connect(cells, 0, 0)


func _fill_water() -> void:
	for column in _column_count():
		water_layer.set_cell(Vector2i(column, 13), 0, Tiles.WATER_SURFACE)
		water_layer.set_cell(Vector2i(column, 14), 0, Tiles.WATER_BODY)


func _fill_spikes() -> void:
	for i in floors.size():
		if _is_gap(floors[i]):
			for column in range(_floor_starts[i], _floor_starts[i] + floors[i].x):
				spike_layer.set_cell(Vector2i(column, 13), 0, Vector2i.ZERO)

#endregion


#region Play

## Pauses, opens the iris on the player, then starts play.
func _start() -> void:
	get_tree().paused = true
	music.play()
	await iris.open()
	get_tree().paused = false


## Called by the player once it has won, the game already paused.
func on_win() -> void:
	respawn_cell = PLAYER_CELL
	if not is_main:
		return
	music.stop()
	await sounds.play_and_wait(Sounds.Effect.WIN)
	await iris.close()
	var next := "res://levels/level_%d.tscn" % (number() + 1)
	get_tree().change_scene_to_file(next if ResourceLoader.exists(next) else "res://title.tscn")


## Called by the death scene once it has fallen off the screen.
func on_death() -> void:
	if not is_main:
		return
	await sounds.wait(Sounds.Effect.DEATH)
	await iris.close()
	get_tree().reload_current_scene()


## The level's number, from its scene's file name.
func number() -> int:
	return scene_file_path.get_file().get_basename().trim_prefix("level_").to_int()


func add_effect(node: Node) -> void:
	effects.add_child(node)


func add_block_item(node: Node) -> void:
	block_item_layer.add_child(node)


func ladder_at(cell: Vector2i) -> bool:
	return ladder_layer.get_cell_source_id(cell) != -1


func _exit_tree() -> void:
	if music != null:
		music.stop()
		music.stream = null


## SpriteFrames from {animation: [[paths], fps]}; fps 0 for one still frame.
static func sprite_frames(animations: Dictionary) -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	for animation: String in animations:
		var paths: Array = animations[animation][0]
		var fps: float = animations[animation][1]
		frames.add_animation(animation)
		frames.set_animation_speed(animation, fps if fps > 0.0 else 5.0)
		frames.set_animation_loop(animation, fps > 0.0)
		for path: String in paths:
			frames.add_frame(animation, load(path))
	return frames

#endregion


#region Jump check

## A floor or platform the player can stand on, for the jump check.
class Standable:
	var name: String
	var left: int
	var right: int
	var row: int

	func _init(name_: String, left_: int, right_: int, row_: int) -> void:
		name = name_
		left = left_
		right = right_
		row = row_


## The player's jump from standing at top speed, jump held: after every
## update, (distance right, height above the take-off) of its feet.
static func jump_arc() -> Array[Vector2]:
	var delta := 1.0 / Engine.physics_ticks_per_second
	var arc: Array[Vector2] = []
	var point := Vector2.ZERO
	var velocity := Vector2(Player.WALK_SPEED, 0.0)
	var rising := false
	var first := true
	while point.y > -Screen.height:
		var gravity := Player.LIGHT_GRAVITY if rising else Player.HEAVY_GRAVITY
		velocity.y = minf(velocity.y + gravity * delta, Player.MAX_FALL_SPEED)
		if first:
			velocity.y = -Player.JUMP_SPEED
			first = false
		point += Vector2(velocity.x, -velocity.y) * delta
		rising = velocity.y < 0.0
		arc.append(point)
	return arc


## How high above the take-off the jump reaches at a distance.
static func jump_reach(arc: Array[Vector2], distance: float) -> float:
	var apex := 0
	for i in arc.size():
		if arc[i].y > arc[apex].y:
			apex = i
	if distance <= arc[apex].x:
		return arc[apex].y
	for i in range(apex + 1, arc.size()):
		if arc[i].x >= distance:
			var a := arc[i - 1]
			var b := arc[i]
			return lerpf(a.y, b.y, (distance - a.x) / (b.x - a.x))
	return -INF


## From everything standable there is a way onward to the right.
func _check_jumps() -> void:
	var standing: Array[Standable] = []
	var floor_things: Array[Standable] = []
	var platform_things: Array[Standable] = []
	for i in floors.size():
		if not _is_gap(floors[i]):
			var thing := Standable.new(_floor_name(i), _floor_starts[i], _floor_starts[i] + floors[i].x, floors[i].y)
			floor_things.append(thing)
	for i in platforms.size():
		var p := platforms[i]
		platform_things.append(Standable.new("platforms[%d] at %s" % [i, p.cell], p.cell.x, p.cell.x + p.width, p.cell.y))
	standing.append_array(floor_things)
	standing.append_array(platform_things)
	var arc := jump_arc()
	for from in standing:
		if from.name == "end floor":
			continue
		var targets: Array[Standable] = []
		for thing in floor_things:
			if thing.right > from.right:
				targets.append(thing)
				break
		var nearest: Standable = null
		for thing in platform_things:
			if thing.right > from.right and (nearest == null or thing.left < nearest.left):
				nearest = thing
		if nearest != null:
			targets.append(nearest)
		var passes := false
		for target in targets:
			var distance := maxf((target.left - from.right) * Grid.TILE, 0.0)
			var height := (from.row - target.row) * Grid.TILE
			if height <= jump_reach(arc, distance):
				passes = true
		if not passes:
			var edge := Vector2i(from.right - 1, from.row)
			jump_failures.append(edge)
			errors.append("%s: no jump onward from %s" % [from.name, edge])

#endregion




#region Guides

## Draws the grid, the floor labels and the failing jumps into `guides`.
func _draw_guides() -> void:
	pass

#endregion
