# Level tiles

The solid ground of every level: one autotiled tile sheet per biome
(snow, grass, desert), painted with Godot's built-in terrains. Read `overview.md`
first.

## Files

- One PNG per biome: `res://art/solids/snow.png`, `res://art/solids/grass.png`,
  `res://art/solids/desert.png`.
- **Every biome sheet uses exactly the same layout.** Only the tiles with an
  open top differ in look: the single block, the ledge, the pillar top and
  the top row of the 3 × 3. All other tiles are pixel-for-pixel the same.
- **Each level uses one biome.**

## The sheet

- Each tile is **`Grid.TILE` × `Grid.TILE`**, packed with **no gaps and no margins**. A sheet
  is 108 × 72 px: 6 columns by 4 rows.
- Tile coordinates below are Godot atlas coordinates: **(column, row)**,
  counted from 0 at the top left. So (1, 0) is the first row, second column.

| Coordinates | Tile |
|---|---|
| (0, 0) | Single block |
| (1, 0), (2, 0), (3, 0) | One-tile-tall ledge: left end, middle, right end |
| (0, 1), (0, 2), (0, 3) | One-tile-wide pillar: top, middle, bottom |
| (1, 1) to (3, 3) | The 3 × 3: corners, edges and the fill (2, 2) in the middle |
| (4, 1) | Second fill, used half the time instead of (2, 2) |
| (4, 2), (5, 2), (4, 3), (5, 3) | Inner corners |
| (4, 0), (5, 0), (5, 1) | Empty, not tiles |

## TileSet setup

- **Every `TileSet` in the game is built in code**, not in the editor
  (the build has no editor): `res://tiles/tiles.gd` is
  `@abstract class_name Tiles`, with one static function per `TileSet`
  (`Tiles.ground(biome)`, `Tiles.decorations(biome)`, `Tiles.water()`,
  `Tiles.platforms()` and so on). Each builds its `TileSet` the first time
  it is asked for and keeps it in a `static var` dictionary, so every
  layer that asks gets the same one.
- One `TileSet` per biome, with `tile_size` `Grid.TILE` × `Grid.TILE` and
  one `TileSetAtlasSource`: `texture_region_size` `Grid.TILE` ×
  `Grid.TILE`, no separation, no margins (the defaults).
- **One function builds all three biomes**, given the biome's sheet: the
  collision, terrains and peering bits are written once, in that function,
  and only the texture differs.
- A level's `TileMapLayer` uses the `TileSet` of that level's biome.
- **Collision:** one physics layer (`add_physics_layer()`). Every tile gets
  a full `Grid.TILE` × `Grid.TILE` square collision polygon
  (`TileData.add_collision_polygon(0)`, then
  `set_collision_polygon_points(0, 0, ...)` with the four corners at
  ±`Grid.HALF_TILE` around the tile's centre, the polygon's origin). Solid
  from every side: no one-way collision. (One-way tiles, the platforms and
  the ladder caps, also call `set_collision_polygon_one_way(0, 0, true)`.)
- **Building tiles in code:** a tile is made with `create_tile(coords)` on
  the atlas source, after the source has been added to the `TileSet`
  (`add_source()`), so its `TileData` knows the `TileSet`'s physics layers
  and terrains. Only the listed tiles are made: empty spots stay empty.
- The physics layer has `collision_layer` = **`level`**, the layer the
  player, walkers, the crusher, the diamond and springs collide with, and
  `collision_mask` = none:
  the tiles are collided with and scan nothing themselves.

## Terrains (autotiling)

- One terrain set, mode **Match Corners and Sides**
  (`TERRAIN_MODE_MATCH_CORNERS_AND_SIDES`). Inner corners need the diagonal
  neighbours, which only this mode looks at.
- One terrain in that set, named `ground` in every biome's `TileSet`.
- Each tile's peering bits come from the table below. "Solid" means that
  neighbour is set to `ground`; every neighbour not listed is set to -1
  (empty).
- In code: `add_terrain_set()`, `set_terrain_set_mode(0, ...)`,
  `add_terrain(0)` and `set_terrain_name(0, 0, "ground")` on the
  `TileSet`; then for each tile `terrain_set = 0` and `terrain = 0` on its
  `TileData`, and `set_terrain_peering_bit()` for each of the 8
  neighbours (`TileSet.CELL_NEIGHBOR_RIGHT_SIDE`,
  `CELL_NEIGHBOR_BOTTOM_RIGHT_CORNER` and so on).

| Tile | Solid neighbours |
|---|---|
| (0, 0) single block | none |
| (1, 0) ledge left end | right |
| (2, 0) ledge middle | left, right |
| (3, 0) ledge right end | left |
| (0, 1) pillar top | bottom |
| (0, 2) pillar middle | top, bottom |
| (0, 3) pillar bottom | top |
| (1, 1) top-left corner | right, bottom-right, bottom |
| (2, 1) top edge | left, bottom-left, bottom, bottom-right, right |
| (3, 1) top-right corner | left, bottom-left, bottom |
| (1, 2) left edge | top, top-right, right, bottom-right, bottom |
| (2, 2) fill | all 8 |
| (3, 2) right edge | top, top-left, left, bottom-left, bottom |
| (1, 3) bottom-left corner | top, top-right, right |
| (2, 3) bottom edge | left, top-left, top, top-right, right |
| (3, 3) bottom-right corner | left, top-left, top |
| (4, 1) second fill | all 8 |
| (4, 2) inner corner | all except bottom-right |
| (5, 2) inner corner | all except bottom-left |
| (4, 3) inner corner | all except top-right |
| (5, 3) inner corner | all except top-left |

- This table is written once in `Tiles` and also used by the tree canopy
  sheet, which has the same layout without the inner corners and the
  second fill (`trees.md`, Canopy tiles).
- The two fills, (2, 2) and (4, 1), have the same peering bits, so terrain
  painting picks between them. Both keep the default `probability` of 1.0,
  so each is used about half the time.
- Some shapes have no exact tile (for example a pillar joining the side of
  a block, or blocks touching only at a corner). Godot then picks the
  closest tile. That may look a little odd but is allowed.

## Acceptance test

| Case | Expected |
|---|---|
| Paint a 5 × 4 block | Corners, edges and fill in the right places |
| Paint a large block | Both fills, (2, 2) and (4, 1), appear |
| Paint a 1 × 4 pillar | Pillar top, two middles, bottom |
| Paint a 4 × 1 ledge | Left end, two middles, right end |
| Paint one tile alone | The single block (0, 0) |
| Paint an L-shape with arms 2 or more tiles thick | An inner corner where the two arms meet |
| Paint an L-shape with arms 1 tile thick | No exact tile where the arms meet: Godot picks the closest one, which is allowed |
| Player stands on, walks into and jumps into any tile | Blocked from every side |
| Grass and desert `TileSet`s | Same tiles, collision and peering bits as snow; only the texture differs |
