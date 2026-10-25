# Ropes

A rope standing on the ground and holding up a mass of ground that hangs
from the top of the screen, with plants hanging under it. Built like a
tree (`trees.md`): the rope is the trunk and the ground mass is the
canopy. Purely visual, drawn behind everything with the trees: nothing
touches it. Read `level-layout.md` and `trees.md` first.

## Art

**`res://art/rope/sprite_1.png`** (1 × 3), 18 × 18 tiles, no gaps.
Coordinates are (column, row):

| Tile | What |
|---|---|
| (0, 0) | Cap: the top of the rope, with a bracket at the top of the tile where it meets the ground above |
| (0, 1) | Body |
| (0, 2) | Base: the bottom of the rope, with a bracket at the bottom of the tile where it stands on the floor |

The ground mass uses the level's own solid tiles (`level-tiles.md`), and
the hanging plants use the level's decorations (`level-layout.md`,
Decorations), upside down.

## Layers

Three `TileMapLayer`s, right after the tree layers among the level root's
children (`level-layout.md`, Building), so behind everything else:

1. `RopeCeilings`: the ground masses. The level's biome solid `TileSet`,
   with `collision_enabled = false`, so nothing collides with them.
2. `RopeCeilingDecorations`: the hanging plants. The level's biome
   decorations `TileSet`.
3. `Ropes`: the ropes. One rope `TileSet`: one atlas source (Texture Region
   Size 18 × 18, Separation 0, Margins 0), no physics, no terrains.

## Where ropes go

- A rope is a **big decoration** (`level-layout.md`, Decorations, Big
  decorations), the third kind next to trees and pipes: planted by the same
  roll, sharing one candidate and one cooldown (one screen width) with them.
- **Every biome** allows it, but only on a floor whose row is **8 or
  more** (at most 6 rows above the screen's last row, 14). The mass always
  takes rows 0 and 1, so on a higher floor the rope would be short and
  the mass would hang low, close enough to the ground to look like
  something the player could bonk.
- Only floors that get decorations can get a rope, and when one is
  planted, no plain decoration goes on that tile.
- Like trees, a rope may cover anything the level placed: it is drawn
  behind everything, so placed things show in front of it.

## Building one rope

All random numbers are whole numbers, `randi_range(min, max)` (both ends
included), each value equally likely.

**The rope**, in `Ropes`, from the bottom up, in the planting tile's
column:

- It always reaches all the way up to the main mass: the **base** (0, 2)
  on the cell above the surface tile, the **cap** (0, 0) on **row 2**,
  right under the main mass, and a **body** (0, 1) on every cell between.
  Its height is not random: on a floor on row `r` it is `r - 2` cells,
  counting the base and the cap (6 cells on row 8, 11 on row 13).

**The main ground mass**: a rectangle on **rows 0 and 1**, always 2 tall,
hanging from the top of the screen right above the cap.

- Width: the rope's column, plus `randi_range(1, 2)` columns to the left,
  plus `randi_range(1, 2)` to the right (3 to 5 wide), like the tree's main
  canopy.

**Supporting masses**: always two, one on the main mass's left edge and one
on its right edge, each **1 tall, on row 0** only, so the mass gets a step
on each side, hanging from above. Each is `randi_range(2, 3)` wide,
counting the edge column it overlaps, growing outward (the left one
grows left, the right one right), so it sticks out 1 or 2 columns past
the main mass.

A mass this high, with a rope always reaching it, never hangs low enough
to look like something the player could bonk into from below.

## Drawing the ground mass

- Unlike a tree's canopies, which are on two layers so each keeps its own
  outline (`trees.md`), the main and supporting masses are **one
  shape with one outline**: all their cells are painted on one layer,
  together, with the built-in `set_cells_terrain_connect(cells, 0, 0)`
  (`level-tiles.md`, Terrains), which gives the merged shape its edges,
  corners and inner corners, and mixes the two fills.
- The mass continues off the top of the screen: for every column that has
  a cell on row 0, the cell on row **-1** is painted too, so row 0 gets
  the tiles of a shape that goes on upward (fill, and side edges on the
  outer columns) instead of a top outline.
- Ropes are at least one screen width apart (the shared cooldown), so two
  masses never touch.

## Hanging plants

- Every cell of the mass whose cell below is not part of the mass is on
  its **underside**. Each such cell has a **20 %** chance (`randf() <
  0.2`) of one of the biome's decorations, picked with `randi_range`, each
  equally likely, in the cell below it, in `RopeCeilingDecorations`.
- They are drawn **upside down**: placed with the built-in
  `TRANSFORM_FLIP_V` flag in `set_cell()`'s alternative tile, like the
  mirrored tree branches (`trees.md`). A decoration stands on the bottom of
  its tile, so flipped it hangs from the top, from the mass.
- The cell right below the main mass in the rope's column holds the cap,
  so it never gets a plant.

## Acceptance test

| Case | Expected |
|---|---|
| Any biome, long flat ground on row 8 or more | Some ropes, never two big decorations (trees, pipes or ropes) closer than 26 tiles |
| Floor on row 7 or less | Never a rope |
| Any rope | Base on the cell above a surface tile, cap on row 2, bodies between |
| Rope on a floor on row 8 | 6 cells in all, rows 2 to 7 |
| Rope on a floor on row 13 | 11 cells in all, rows 2 to 12 |
| Main mass | Rows 0 and 1, directly above the cap; 3 to 5 wide |
| Supporting masses | **By eye:** One on each side, on row 0 only, 2 or 3 wide counting the main mass's edge column, merged with the main mass under one outline |
| Top of the screen | **By eye:** No outline along row 0 over the mass |
| Underside | About 1 in 5 cells has an upside-down plant hanging below it; never in the cap's cell |
| Player jumps into the mass, walkers, anything | Passes through: `collision_enabled` is false |
| Draw order | Behind the pipes, decorations, ground and everything else; in front of the trees and the background |
| Rope over a placed coin or block | Allowed: the coin or block is drawn in front |
