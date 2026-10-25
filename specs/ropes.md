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
  more** (at most 6 rows above the screen's last row, 14). Higher floors
  never get one: there would be too little room for the ground above.
- Only floors that get decorations can get a rope, and when one is
  planted, no plain decoration goes on that tile.
- Like trees, a rope may cover anything the level placed: it is drawn
  behind everything, so placed things show in front of it.

## Building one rope

All random numbers are whole numbers, `randi_range(min, max)` (both ends
included), each value equally likely.

**The rope**, in `Ropes`, from the bottom up, in the planting tile's
column:

- Its height is `randi_range(4, 6)` cells in all, **counting the base and
  the cap**.
- The **base** (0, 2) on the cell above the surface tile, the **cap** (0, 0)
  on the top cell, and a **body** (0, 1) on every cell between (2 to 4).

**The main ground mass**: a rectangle whose bottom row is directly above
the cap, reaching all the way up to **row 0**, the top of the screen.

- Width: the rope's column, plus `randi_range(1, 2)` columns to the left,
  plus `randi_range(1, 2)` to the right (3 to 5 wide), like the tree's main
  canopy.
- Height: from row 0 down to the row above the cap. With a floor on row 8
  and a 6-cell rope, that is rows 0 and 1; with a floor on row 13 and a
  4-cell rope, rows 0 to 8.

**Supporting masses**: always two, one on the main mass's left edge and one
on its right edge, built like the tree's supporting canopies (`trees.md`,
Building one tree): a random anchor row on that edge column, growing
toward the farther end of the main mass, `randi_range(2, 3)` wide
counting the anchor's column (growing outward), `randi_range(1, 3)` tall
counting the anchor's row.
- **Then stretched up to row 0:** its bottom row stays where that puts it,
  and its top becomes row 0, so it hangs from the top of the screen like
  the main mass. A supporting mass with its own top would look like a
  ledge to land on. So the mass gets steps on its sides, every one
  hanging from above.

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
- Not seeded, like the other decorations.

## Acceptance test

| Case | Expected |
|---|---|
| Any biome, long flat ground on row 8 or more | Some ropes, never two big decorations (trees, pipes or ropes) closer than 26 tiles |
| Floor on row 7 or less | Never a rope |
| Any rope | Base on the cell above a surface tile, cap on its top cell, bodies between; 4 to 6 cells in all |
| Main mass | Bottom row directly above the cap, reaching row 0; 3 to 5 wide |
| Supporting masses | One on each side, 2 or 3 wide, reaching from row 0 down, merged with the main mass under one outline; no top edge anywhere below row 0 |
| Top of the screen | No outline along row 0 over the mass |
| Underside | About 1 in 5 cells has an upside-down plant hanging below it; never in the cap's cell |
| Player jumps into the mass, walkers, anything | Passes through: `collision_enabled` is false |
| Draw order | Behind the pipes, decorations, ground and everything else; in front of the trees and the background |
| Rope over a placed coin or block | Allowed: the coin or block is drawn in front |
