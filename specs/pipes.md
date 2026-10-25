# Pipes

Big blue pipes hanging from the top of the screen, in levels **with
water**, any biome. Purely visual, like the trees: nothing touches them.
Read `level-layout.md` first: a pipe is a big decoration, planted by the
same roll as the trees (`level-layout.md`, Decorations, Big decorations).

## Art

**`res://art/decorations/pipe.png`** (1 × 3), 18 × 18 tiles, no gaps.
Coordinates are (column, row):

| Tile | What |
|---|---|
| (0, 0) | Vertical body |
| (0, 1) | Elbow, joining **top and left** as drawn |
| (0, 2) | Horizontal body |

The elbow joining top and right is the same tile mirrored: an alternative
tile of (0, 1), made in code with `create_alternative_tile(Vector2i(0, 1))`
and `flip_h = true` on its `TileData`, so terrain painting can pick it
(see Layer). No new art is needed.

## Layer

- One `TileMapLayer`, `Pipes`, among the level root's children right after
  the rope layers (`ropes.md`; `level-layout.md`, Building): behind the
  plain decorations, the ground and everything else.
- One pipe `TileSet`: one atlas source (Texture Region Size 18 × 18,
  Separation 0, Margins 0), no physics. One terrain set, mode **Match
  Sides** (`TERRAIN_MODE_MATCH_SIDES`), with one terrain, `pipe`. Peering
  bits, "joined" meaning that side is set to `pipe`, every other side -1:

  | Tile | Joined on |
  |---|---|
  | (0, 0) vertical body | top, bottom |
  | (0, 1) elbow | top, left |
  | (0, 1) mirrored (the alternative tile) | top, right |
  | (0, 2) horizontal body | left, right |

## Where pipes go

- Only when `has_water` is on.
- A pipe is a **big decoration** (`level-layout.md`, Decorations, Big
  decorations): one candidate in the decoration roll, shared with the
  trees and ropes (`ropes.md`), with one shared cooldown of a screen width.
  Where more than one kind is allowed on a tile, each big decoration is
  one of them at random.
- It is planted on a surface tile: its first leg is in that tile's column.
  No plain decoration goes on that tile.

## Building one pipe

A pipe is an upside-down U: two legs hanging from the top of the screen,
joined at the bottom. All random numbers are whole numbers,
`randi_range(min, max)` (both ends included), each value equally likely.

1. **Height:** `h = randi_range(2, 6)` rows, from row 0 down to row
   `h - 1`.
2. **Direction:** left or right, `pick_random()` from the two.
3. **Width:** `w = randi_range(2, 6)` columns, counting both legs. The
   second leg is `w - 1` columns from the first, in that direction.

Then, with `L` the left leg's column and `R` the right leg's column, the
U is painted as one path with the built-in
`set_cells_terrain_path(path, 0, 0)`, and Godot picks each tile:

- **The path**, in order: down the left leg from `(L, -1)` to
  `(L, h - 1)`, along the bottom row to `(R, h - 1)`, then up the right
  leg to `(R, -1)`.
- **Row -1**, just above the screen, is painted too, so row 0 gets a
  vertical body that goes on upward, never an end: the pipe hangs from
  beyond the top of the screen, like a rope's mass (`ropes.md`). Row -1 is
  never seen.
- **A path, not a shape:** `set_cells_terrain_path` joins each cell only
  to the cells before and after it in the path. With `set_cells_terrain_connect`,
  the two legs of a 2-wide pipe, side by side, would be joined to each
  other on every row.
- The result: vertical bodies on the legs from row 0 to `h - 2`; on the
  bottom row the mirrored elbow (top and right) in `L`, the elbow as drawn
  (top and left) in `R`, and horizontal bodies between them (none when `w`
  is 2: the two elbows touch). Tested on 4.7.2 with `pipe.png` for 2 × 2,
  2 × 4 and 4 × 3.

Pipes are at least a screen width apart (the shared cooldown), so two
pipes never touch on the layer. A pipe may reach past the level's left or
right edge, or behind high ground; that is fine.

## Acceptance test

| Case | Expected |
|---|---|
| Level without water | No pipes |
| Level with water, any biome, long flat ground | Some pipes, never two big decorations (pipes, trees or ropes) closer than 26 tiles |
| Grass level with water, floors on row 7 or less | Big decorations are trees or pipes, each about half the time |
| Grass level with water, floors on row 8 or more | Big decorations are trees, pipes or ropes, each about a third of the time |
| Pipe planted in column 10, `h` 3, right, `w` 4 | Legs in columns 10 and 13: vertical bodies on rows 0 and 1; row 2: mirrored elbow in 10, horizontal bodies in 11 and 12, elbow as drawn in 13 |
| Pipe with `w` 2 | The two elbows side by side, no horizontal body |
| Any pipe | Top of both legs on row 0; 2 to 6 rows tall, 2 to 6 columns wide |
| Pipes | Drawn behind the plain decorations, the ground and everything else; never block anything |
