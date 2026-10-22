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

- One `TileSet` resource per biome, with `tile_size` `Grid.TILE` × `Grid.TILE` and one atlas
  source: Texture Region Size 18 × 18, Separation 0, Margins 0.
- **Build the snow `TileSet` once** (atlas, collision, terrains, peering
  bits). Then make the grass and desert ones by **duplicating it and
  swapping only the atlas texture**. Collision and peering bits belong to
  the tiles, so they come along unchanged; nothing is entered twice.
- A level's `TileMapLayer` uses the `TileSet` of that level's biome.
- **Collision:** one physics layer. Every tile gets a full `Grid.TILE` × `Grid.TILE` square
  collision polygon (the `F` shortcut in the TileSet editor). Solid from
  every side: no one-way collision.
- The physics layer has `collision_layer` = **`level`**, the layer the
  player, walkers and crusher collide with, and `collision_mask` = none:
  the tiles are collided with and scan nothing themselves.

## Terrains (autotiling)

- One terrain set, mode **Match Corners and Sides**
  (`TERRAIN_MODE_MATCH_CORNERS_AND_SIDES`). Inner corners need the diagonal
  neighbours, which only this mode looks at.
- One terrain in that set, named `ground` in every biome's `TileSet`.
- Each tile's peering bits come from the table below. "Solid" means that
  neighbour is set to `ground`; every neighbour not listed is set to -1
  (empty).

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
| Paint an L-shape | An inner corner where the two arms meet |
| Player stands on, walks into and jumps into any tile | Blocked from every side |
| Grass and desert `TileSet`s | Same tiles, collision and peering bits as snow; only the texture differs |
