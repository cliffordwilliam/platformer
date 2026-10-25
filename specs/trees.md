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
| (0, 0) | Top: the trunk's last tile, its tip drawn into the main canopy's bottom row |
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
- One tree `TileSet` holding the three sheets as atlas sources, no physics.
  All three layers use it. It has one terrain set, mode Match Corners and
  Sides, with one terrain, `canopy`, used only by the canopy sheet's tiles
  (see Canopy tiles).
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

**Main canopy**, in `TreeCanopies`: a rectangle whose bottom row is on the
trunk's top tile's row, so the canopy covers the top of the trunk (it is
drawn in front of `Trees`) and the trunk runs up into it. (Unlike the
rope's mass, which sits directly above the rope's cap, `ropes.md`.)

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
3. **Width:** `randi_range(2, 3)`, **counting the anchor's column**, growing
   outward (the left one grows left, the right one grows right). So it
   overlaps the main canopy's edge column and always sticks out 1 or 2
   columns past it. (Never 1 wide: that would sit inside the edge column
   and look wrong.)
4. **Height:** `randi_range(1, 3)` rows, **counting the anchor's row**,
   growing in the chosen direction. So height 1 is the anchor row alone,
   and height 2 is the anchor row plus one more.

## Canopy tiles

Every canopy is a rectangle painted with the built-in
`set_cells_terrain_connect(cells, 0, 0)` on its layer, like the ground:
Godot picks each cell's tile from its neighbours.

- **Peering bits:** the canopy sheet has the solids' layout without the
  inner corners and the second fill, so its 16 tiles take the same peering
  bits as those tiles in `level-tiles.md` (Terrains). `Tiles` writes that
  table once and uses it for both sheets.
- **Why the outlines stay apart:** terrain painting merges touching cells
  on one layer into one shape. No two canopies on one layer ever touch:
  the main canopies are on `TreeCanopies` and the supporting ones on
  `TreeCanopiesFront`; a tree's two supporting canopies are on opposite
  sides of a main canopy at least 3 wide; and trees are at least 26
  columns apart. So each canopy keeps its own outline, and a supporting
  canopy is drawn in front of its main canopy with its own.
- Tested on 4.7.2 with `tree_canopy.png`: rectangles 1 × 1, 3 × 1, 1 × 4,
  2 × 2, 5 × 3 and 4 × 5 came out exactly as by place: (0, 0) alone; (1,
  0), (2, 0), (3, 0) for one row; (0, 1), (0, 2), (0, 3) for one column;
  the 3 × 3's corners, edges and fill for the rest.

A tree may reach above the top of the screen. That is fine.

## Acceptance test

| Case | Expected |
|---|---|
| Snow or desert level | No trees |
| Grass level, long flat ground | Some trees, never two big decorations (trees, pipes or ropes) closer than 26 tiles |
| Supporting canopy | 2 or 3 wide, overlapping the main canopy's edge column and sticking out 1 or 2 columns past it; never 1 wide |
| Any tree | Stump on the cell above a surface tile, 3 to 5 middle tiles, then the top |
| A branch point | Its branch(es) in the same row, 1 or 2 tiles long, ending in a tip; right ones mirrored |
| Main canopy | **By eye:** Bottom row on the trunk's top tile's row, covering it; 3 to 5 wide, 1 to 5 tall, outline unbroken |
| Supporting canopies | **By eye:** One on each side, drawn in front of the main canopy with their own outlines |
| Trees | Drawn behind the ropes, the plain decorations and everything else, in front of the background |
