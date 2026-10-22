# Trees

Big, randomly built trees in the background of **grass** levels only.
Purely visual, like the other decorations. Read `level-layout.md` first:
trees are placed by the same build pass and follow the same floor rules.

## Art

All 18 × 18 tiles, no gaps.
Coordinates are (column, row).

**`res://art/decorations/tree_trunk.png`** (1 × 7):

| Tile | What |
|---|---|
| (0, 0) | Top: the trunk's last tile, just under the main canopy |
| (0, 1) | Body, with leaf tufts |
| (0, 2) | Branch point, both sides |
| (0, 3) | Body, plain |
| (0, 4) | Branch point, left side |
| (0, 5) | Branch point, right side |
| (0, 6) | Stump |

**`res://art/decorations/tree_branch.png`** (2 × 2), all drawn pointing **left**:

| Tile | What |
|---|---|
| (0, 0) | Tip, leafy |
| (0, 1) | Tip, bare |
| (1, 0) | Branch piece, leafy |
| (1, 1) | Branch piece, bare |

Right-hand branches use the same tiles mirrored, placed with the built-in
`TRANSFORM_FLIP_H` flag in `set_cell()`'s alternative tile
(`TileSetAtlasSource`).

**`res://art/decorations/tree_canopy.png`** (6 × 4, the same layout as the solids without the
inner corners and the second fill):

| Tile | What |
|---|---|
| (0, 0) | 1 × 1 canopy |
| (1, 0), (2, 0), (3, 0) | 1-tall canopy: left end, middle, right end |
| (0, 1), (0, 2), (0, 3) | 1-wide canopy: top, middle, bottom |
| (1, 1) to (3, 3) | The 3 × 3: corners, edges, fill |
| (4, 0) to (5, 3) | Empty |

## Layers

- Three new `TileMapLayer`s, the level root's first children after the
  `Background` (`background.md`), so behind everything else, including the
  plain decorations, in this order:
  1. `Trees`: stumps, trunks and branches
  2. `TreeCanopies`: the main canopies
  3. `TreeCanopiesFront`: the supporting canopies
- One tree `TileSet` holding the three sheets as atlas sources, no physics,
  no terrains. All three layers use it.
- Built in the same pass as the decorations (`level-layout.md`, Building),
  after the ground.

## Where trees go

- Only when `biome` is `GRASS`.
- A tree is a **big decoration** (`level-layout.md`, Decorations, Big
  decorations): planted by the same roll as the plain decorations, sharing
  one candidate and one cooldown (one screen width) with the pipes and
  ropes (`ropes.md`). Only
  floors that get decorations can get a tree.
- When a tree is planted, its stump goes in the cell directly above the
  surface tile, and no plain decoration goes there.

## Building one tree

All random numbers are whole numbers, `randi_range(min, max)` (both ends
included), each value equally likely.

**Trunk**, from the bottom up, in `Trees`:

1. The **stump** on the cell above the surface tile.
2. The **middle**: `randi_range(3, 5)` tiles. For each one, one of four
   cases, equally likely:
   - no branch: a body tile, (0, 1) or (0, 3), equally likely
   - left branch: branch point (0, 4) and a left branch
   - right branch: branch point (0, 5) and a right branch
   - both: branch point (0, 2) and a branch on each side
3. The **top**, (0, 0).

**A branch** grows sideways from its branch point, in the same row:
`randi_range(1, 2)` tiles long, counting the tip.

- 1 long: just a tip, next to the trunk.
- 2 long: a branch piece next to the trunk, then a tip.
- Each tip and each piece picks its leafy or bare version, equally likely.
- Left branches use the tiles as drawn; right branches use them mirrored.

**Main canopy**, in `TreeCanopies`: a rectangle whose bottom row is directly
above the trunk's top tile.

- Width: the trunk's column, plus `randi_range(1, 2)` columns to the left,
  plus `randi_range(1, 2)` to the right (3 to 5 wide).
- Height: `randi_range(1, 5)` rows.

**Supporting canopies**, in `TreeCanopiesFront`: always two, one on the main
canopy's left edge and one on its right edge. For each side:

1. **Anchor:** a random row of the main canopy, on that side's edge column
   (its leftmost column for the left one, rightmost for the right one).
2. **Vertical direction:** toward the farther end of the main canopy. If the
   anchor is nearer the bottom, the canopy grows up; nearer the top, it
   grows down. Exactly in the middle: up or down, equally likely.
3. **Width:** `randi_range(1, 3)`, **counting the anchor's column**, growing
   outward (the left one grows left, the right one grows right). So it
   always overlaps the main canopy's edge column: width 1 sits exactly on
   it.
4. **Height:** `randi_range(1, 3)` rows, **counting the anchor's row**,
   growing in the chosen direction. So height 1 is the anchor row alone,
   and height 2 is the anchor row plus one more.

## Canopy tiles

Every canopy is a plain rectangle, so each cell's tile is chosen by its
place in the rectangle, without Godot terrains (terrain painting would merge
overlapping canopies and erase their outlines):

| Rectangle | Tiles |
|---|---|
| 1 × 1 | (0, 0) |
| 1 tall, 2+ wide | (1, 0) left end, (2, 0) middles, (3, 0) right end |
| 1 wide, 2+ tall | (0, 1) top, (0, 2) middles, (0, 3) bottom |
| 2+ wide, 2+ tall | The 3 × 3: (1, 1) top-left, (2, 1) top, (3, 1) top-right, (1, 2) left, (2, 2) fill, (3, 2) right, (1, 3) bottom-left, (2, 3) bottom, (3, 3) bottom-right |

A tree may reach above the top of the screen. That is fine.

## Acceptance test

| Case | Expected |
|---|---|
| Snow or desert level | No trees |
| Grass level, long flat ground | Some trees, never two big decorations (trees, pipes or ropes) closer than 26 tiles |
| Supporting canopy, width 1 | Exactly on the main canopy's edge column |
| Any tree | Stump on the cell above a surface tile, 3 to 5 middle tiles, then the top |
| A branch point | Its branch(es) in the same row, 1 or 2 tiles long, ending in a tip; right ones mirrored |
| Main canopy | Bottom row directly above the top tile, 3 to 5 wide, 1 to 5 tall, outline unbroken |
| Supporting canopies | One on each side, drawn in front of the main canopy with their own outlines |
| Trees | Drawn behind the ropes, the plain decorations and everything else, in front of the background |
