@abstract
class_name Tiles
## Every TileSet in the game, built in code the first time it is asked for
## and kept, so every layer that asks gets the same one.

## Solid neighbours of each tile in the 3 x 3 sheet layout, shared by the
## ground sheets and the tree canopy sheet (level-tiles.md, Terrains).
const TOP := TileSet.CELL_NEIGHBOR_TOP_SIDE
const TOP_RIGHT := TileSet.CELL_NEIGHBOR_TOP_RIGHT_CORNER
const RIGHT := TileSet.CELL_NEIGHBOR_RIGHT_SIDE
const BOTTOM_RIGHT := TileSet.CELL_NEIGHBOR_BOTTOM_RIGHT_CORNER
const BOTTOM := TileSet.CELL_NEIGHBOR_BOTTOM_SIDE
const BOTTOM_LEFT := TileSet.CELL_NEIGHBOR_BOTTOM_LEFT_CORNER
const LEFT := TileSet.CELL_NEIGHBOR_LEFT_SIDE
const TOP_LEFT := TileSet.CELL_NEIGHBOR_TOP_LEFT_CORNER
const ALL_NEIGHBOURS: Array[TileSet.CellNeighbor] = [
	TOP, TOP_RIGHT, RIGHT, BOTTOM_RIGHT, BOTTOM, BOTTOM_LEFT, LEFT, TOP_LEFT]

## The 16 tiles both sheets share.
const SHAPE_TILES: Dictionary[Vector2i, Array] = {
	Vector2i(0, 0): [],
	Vector2i(1, 0): [RIGHT],
	Vector2i(2, 0): [LEFT, RIGHT],
	Vector2i(3, 0): [LEFT],
	Vector2i(0, 1): [BOTTOM],
	Vector2i(0, 2): [TOP, BOTTOM],
	Vector2i(0, 3): [TOP],
	Vector2i(1, 1): [RIGHT, BOTTOM_RIGHT, BOTTOM],
	Vector2i(2, 1): [LEFT, BOTTOM_LEFT, BOTTOM, BOTTOM_RIGHT, RIGHT],
	Vector2i(3, 1): [LEFT, BOTTOM_LEFT, BOTTOM],
	Vector2i(1, 2): [TOP, TOP_RIGHT, RIGHT, BOTTOM_RIGHT, BOTTOM],
	Vector2i(2, 2): [TOP, TOP_RIGHT, RIGHT, BOTTOM_RIGHT, BOTTOM, BOTTOM_LEFT, LEFT, TOP_LEFT],
	Vector2i(3, 2): [TOP, TOP_LEFT, LEFT, BOTTOM_LEFT, BOTTOM],
	Vector2i(1, 3): [TOP, TOP_RIGHT, RIGHT],
	Vector2i(2, 3): [LEFT, TOP_LEFT, TOP, TOP_RIGHT, RIGHT],
	Vector2i(3, 3): [LEFT, TOP_LEFT, TOP],
}

## The ground sheets' extra tiles: the second fill and the inner corners.
const GROUND_EXTRA_TILES: Dictionary[Vector2i, Array] = {
	Vector2i(4, 1): [TOP, TOP_RIGHT, RIGHT, BOTTOM_RIGHT, BOTTOM, BOTTOM_LEFT, LEFT, TOP_LEFT],
	Vector2i(4, 2): [TOP, TOP_RIGHT, RIGHT, BOTTOM, BOTTOM_LEFT, LEFT, TOP_LEFT],
	Vector2i(5, 2): [TOP, TOP_RIGHT, RIGHT, BOTTOM_RIGHT, BOTTOM, LEFT, TOP_LEFT],
	Vector2i(4, 3): [TOP, RIGHT, BOTTOM_RIGHT, BOTTOM, BOTTOM_LEFT, LEFT, TOP_LEFT],
	Vector2i(5, 3): [TOP, TOP_RIGHT, RIGHT, BOTTOM_RIGHT, BOTTOM, BOTTOM_LEFT, LEFT],
}

const BIOME_NAMES: Array[String] = ["snow", "grass", "desert"]

## The platform TileSet's sources (one-way-platform.md, Drawing).
const PLANK_1_SOURCE := 0
const PLANK_2_SOURCE := 1
const CLOUD_SOURCE := 2
const STONE_SOURCE := 3
const CAP_SOURCE := 4
const STALK_SOURCE := 5
const CLOUD_TERRAIN := 0
const STONE_TERRAIN := 1

## The tree TileSet's sources (trees.md, Layers).
const TRUNK_SOURCE := 0
const BRANCH_SOURCE := 1
const CANOPY_SOURCE := 2

## Water tiles (level-layout.md, Water).
const WATER_SURFACE := Vector2i(0, 0)
const WATER_BODY := Vector2i(0, 1)
const WATERFALL_TOP := Vector2i(2, 0)
const WATERFALL_BODY := Vector2i(2, 1)
const WATERFALL_BASE := Vector2i(2, 2)

## Frame length of every animated tile: 7.5 frames per second.
const TILE_FRAME_DURATION := 0.1333

static var _cache: Dictionary[String, TileSet] = {}


static func ground(biome: int) -> TileSet:
	var key := "ground_%s" % BIOME_NAMES[biome]
	if not _cache.has(key):
		_cache[key] = _build_ground(load("res://art/solids/%s.png" % BIOME_NAMES[biome]))
	return _cache[key]


static func decorations(biome: int) -> TileSet:
	var key := "decorations_%s" % BIOME_NAMES[biome]
	if not _cache.has(key):
		var tile_set := _new_tile_set()
		var source := _add_atlas(tile_set, load("res://art/decorations/%s.png" % BIOME_NAMES[biome]))
		_create_all_tiles(source)
		_cache[key] = tile_set
	return _cache[key]


## How many decorations a biome's sheet holds.
static func decoration_count(biome: int) -> int:
	var source := decorations(biome).get_source(0) as TileSetAtlasSource
	return source.get_atlas_grid_size().x


static func water() -> TileSet:
	if not _cache.has("water"):
		var tile_set := _new_tile_set()
		var source := _add_atlas(tile_set, load("res://art/decorations/water.png"))
		for coords: Vector2i in [WATER_SURFACE, WATER_BODY, WATERFALL_TOP, WATERFALL_BODY, WATERFALL_BASE]:
			source.create_tile(coords)
		for coords: Vector2i in [WATER_SURFACE, WATERFALL_TOP, WATERFALL_BODY, WATERFALL_BASE]:
			source.set_tile_animation_columns(coords, 0)
			source.set_tile_animation_frames_count(coords, 2)
			for frame in 2:
				source.set_tile_animation_frame_duration(coords, frame, TILE_FRAME_DURATION)
		_cache["water"] = tile_set
	return _cache["water"]


static func spikes() -> TileSet:
	if not _cache.has("spikes"):
		var tile_set := _new_tile_set()
		var source := _add_atlas(tile_set, load("res://art/spike/sprite_1.png"))
		source.create_tile(Vector2i.ZERO)
		_cache["spikes"] = tile_set
	return _cache["spikes"]


static func platforms() -> TileSet:
	if not _cache.has("platforms"):
		var tile_set := _new_tile_set()
		_add_level_physics(tile_set)
		tile_set.add_terrain_set()
		tile_set.set_terrain_set_mode(0, TileSet.TERRAIN_MODE_MATCH_SIDES)
		tile_set.add_terrain(0)
		tile_set.set_terrain_name(0, CLOUD_TERRAIN, "cloud")
		tile_set.add_terrain(0)
		tile_set.set_terrain_name(0, STONE_TERRAIN, "stone")
		for path in ["res://art/wooden_platform/sprite_1.png", "res://art/wooden_platform/sprite_2.png"]:
			var plank := _add_atlas(tile_set, load(path))
			plank.create_tile(Vector2i.ZERO)
			_add_square(plank.get_tile_data(Vector2i.ZERO, 0), true)
		for terrain in [CLOUD_TERRAIN, STONE_TERRAIN]:
			var path := "res://art/cloud/sprite_1.png" if terrain == CLOUD_TERRAIN else "res://art/stone/sprite_1.png"
			var source := _add_atlas(tile_set, load(path))
			source.create_tile(Vector2i(0, 0))
			source.create_tile(Vector2i(1, 0))
			source.create_tile(Vector2i(2, 0))
			var mirrored := source.create_alternative_tile(Vector2i(0, 0))
			source.get_tile_data(Vector2i(0, 0), mirrored).flip_h = true
			var sides := {
				Vector2i(2, 0): [],
				Vector2i(0, 0): [RIGHT],
				Vector2i(1, 0): [LEFT, RIGHT],
			}
			for coords: Vector2i in sides:
				var data := source.get_tile_data(coords, 0)
				_set_terrain(data, terrain, sides[coords], [LEFT, RIGHT, TOP, BOTTOM])
				_add_square(data, true)
			var end := source.get_tile_data(Vector2i(0, 0), mirrored)
			_set_terrain(end, terrain, [LEFT], [LEFT, RIGHT, TOP, BOTTOM])
			_add_square(end, true)
		var cap := _add_atlas(tile_set, load("res://art/mushroom/mushroom_cap.png"))
		for coords: Vector2i in [Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 0)]:
			cap.create_tile(coords)
			_add_square(cap.get_tile_data(coords, 0), true)
		var stalk := _add_atlas(tile_set, load("res://art/mushroom/mushroom_stalk.png"))
		_create_all_tiles(stalk)
		_add_square(stalk.get_tile_data(Vector2i(0, 0), 0), true)
		_cache["platforms"] = tile_set
	return _cache["platforms"]


static func ladder() -> TileSet:
	if not _cache.has("ladder"):
		var tile_set := _new_tile_set()
		_add_level_physics(tile_set)
		var source := _add_atlas(tile_set, load("res://art/ladder/sprite_1.png"))
		_create_all_tiles(source)
		_add_square(source.get_tile_data(Vector2i(0, 0), 0), true)
		_cache["ladder"] = tile_set
	return _cache["ladder"]


static func trees() -> TileSet:
	if not _cache.has("trees"):
		var tile_set := _new_tile_set()
		tile_set.add_terrain_set()
		tile_set.set_terrain_set_mode(0, TileSet.TERRAIN_MODE_MATCH_CORNERS_AND_SIDES)
		tile_set.add_terrain(0)
		tile_set.set_terrain_name(0, 0, "canopy")
		_create_all_tiles(_add_atlas(tile_set, load("res://art/decorations/tree_trunk.png")))
		_create_all_tiles(_add_atlas(tile_set, load("res://art/decorations/tree_branch.png")))
		var canopy := _add_atlas(tile_set, load("res://art/decorations/tree_canopy.png"))
		for coords: Vector2i in SHAPE_TILES:
			canopy.create_tile(coords)
			_set_terrain(canopy.get_tile_data(coords, 0), 0, SHAPE_TILES[coords], ALL_NEIGHBOURS)
		_cache["trees"] = tile_set
	return _cache["trees"]


static func rope() -> TileSet:
	if not _cache.has("rope"):
		var tile_set := _new_tile_set()
		_create_all_tiles(_add_atlas(tile_set, load("res://art/rope/sprite_1.png")))
		_cache["rope"] = tile_set
	return _cache["rope"]


static func pipes() -> TileSet:
	if not _cache.has("pipes"):
		var tile_set := _new_tile_set()
		tile_set.add_terrain_set()
		tile_set.set_terrain_set_mode(0, TileSet.TERRAIN_MODE_MATCH_SIDES)
		tile_set.add_terrain(0)
		tile_set.set_terrain_name(0, 0, "pipe")
		var source := _add_atlas(tile_set, load("res://art/decorations/pipe.png"))
		_create_all_tiles(source)
		var mirrored := source.create_alternative_tile(Vector2i(0, 1))
		source.get_tile_data(Vector2i(0, 1), mirrored).flip_h = true
		var sides := [LEFT, RIGHT, TOP, BOTTOM]
		_set_terrain(source.get_tile_data(Vector2i(0, 0), 0), 0, [TOP, BOTTOM], sides)
		_set_terrain(source.get_tile_data(Vector2i(0, 1), 0), 0, [TOP, LEFT], sides)
		_set_terrain(source.get_tile_data(Vector2i(0, 1), mirrored), 0, [TOP, RIGHT], sides)
		_set_terrain(source.get_tile_data(Vector2i(0, 2), 0), 0, [LEFT, RIGHT], sides)
		_cache["pipes"] = tile_set
	return _cache["pipes"]


## One function for all three biomes: only the texture differs.
static func _build_ground(texture: Texture2D) -> TileSet:
	var tile_set := _new_tile_set()
	_add_level_physics(tile_set)
	tile_set.add_terrain_set()
	tile_set.set_terrain_set_mode(0, TileSet.TERRAIN_MODE_MATCH_CORNERS_AND_SIDES)
	tile_set.add_terrain(0)
	tile_set.set_terrain_name(0, 0, "ground")
	var source := _add_atlas(tile_set, texture)
	var tiles := SHAPE_TILES.duplicate()
	tiles.merge(GROUND_EXTRA_TILES)
	for coords: Vector2i in tiles:
		source.create_tile(coords)
		var data := source.get_tile_data(coords, 0)
		_set_terrain(data, 0, tiles[coords], ALL_NEIGHBOURS)
		_add_square(data, false)
	return tile_set


static func _new_tile_set() -> TileSet:
	var tile_set := TileSet.new()
	tile_set.tile_size = Vector2i(Grid.TILE, Grid.TILE)
	return tile_set


static func _add_atlas(tile_set: TileSet, texture: Texture2D) -> TileSetAtlasSource:
	var source := TileSetAtlasSource.new()
	source.texture = texture
	source.texture_region_size = Vector2i(Grid.TILE, Grid.TILE)
	tile_set.add_source(source)
	return source


static func _create_all_tiles(source: TileSetAtlasSource) -> void:
	var size := source.get_atlas_grid_size()
	for y in size.y:
		for x in size.x:
			source.create_tile(Vector2i(x, y))


static func _add_level_physics(tile_set: TileSet) -> void:
	tile_set.add_physics_layer()
	tile_set.set_physics_layer_collision_layer(0, Level.LAYER_LEVEL)
	tile_set.set_physics_layer_collision_mask(0, 0)


## A full tile square, solid from every side or (one_way) only from above.
static func _add_square(data: TileData, one_way: bool) -> void:
	data.add_collision_polygon(0)
	data.set_collision_polygon_points(0, 0, PackedVector2Array([
		Vector2(-Grid.HALF_TILE, -Grid.HALF_TILE), Vector2(Grid.HALF_TILE, -Grid.HALF_TILE),
		Vector2(Grid.HALF_TILE, Grid.HALF_TILE), Vector2(-Grid.HALF_TILE, Grid.HALF_TILE)]))
	if one_way:
		data.set_collision_polygon_one_way(0, 0, true)


## Sets a tile's terrain and its peering bits: `joined` neighbours to the
## terrain, every other neighbour in `neighbours` to -1.
static func _set_terrain(data: TileData, terrain: int, joined: Array, neighbours: Array) -> void:
	data.terrain_set = 0
	data.terrain = terrain
	for neighbour: TileSet.CellNeighbor in neighbours:
		data.set_terrain_peering_bit(neighbour, terrain if joined.has(neighbour) else -1)
