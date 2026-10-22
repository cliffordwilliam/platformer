# One-way platform

Thin platforms the player jumps up through from below and lands on top of.
Every biome has them; each platform's look is picked at random:
**wooden planks** and **clouds** in every biome, plus, in the desert only,
**stones** and, for platforms 3 or more wide, **mushrooms**. Read `overview.md` and `level-layout.md` first:
a platform is placed in tile units like everything else.

## Art

All 18 × 18 tiles, no gaps. Coordinates are (column, row).

**Wooden planks:** `res://art/wooden_platform/sprite_1.png` and
`res://art/wooden_platform/sprite_2.png`, one tile each, two variants of the
same short plank. Each tile is a whole plank with its own rounded ends, so
a wooden platform is just its tiles side by side.

**Clouds:** `res://art/cloud/sprite_1.png` (3 × 1):

| Tile | What |
|---|---|
| (0, 0) | Cloud end, drawn as a **left** end |
| (1, 0) | Cloud body |
| (2, 0) | A whole one-tile cloud |

**Stones:** `res://art/stone/sprite_1.png` (3 × 1), laid out exactly like
the clouds:

| Tile | What |
|---|---|
| (0, 0) | Stone end, drawn as a **left** end |
| (1, 0) | Stone body |
| (2, 0) | A whole one-tile stone |

**Mushrooms:** `res://art/mushroom/mushroom_cap.png` (2 × 2):

| Tile | What |
|---|---|
| (0, 0) | Cap end, variant 1 |
| (0, 1) | Cap end, variant 2 |
| (1, 0) | Cap middle |
| (1, 1) | Empty |

and `res://art/mushroom/mushroom_stalk.png` (1 × 4):

| Tile | What |
|---|---|
| (0, 0) | Cap centre: a cap middle with the top of the stalk under it |
| (0, 1) | Stalk body, variant 1 |
| (0, 2) | Stalk body, variant 2 |
| (0, 3) | Stalk base, resting on the ground |

The cloud, stone and cap ends are drawn as **left** ends. Right ends use the same
tiles mirrored, placed with the built-in `TRANSFORM_FLIP_H` flag in
`set_cell()`'s alternative tile, like the tree branches (`trees.md`).

## Placing them

- The level script's `platforms` field, an `Array[PlatformSpawn]`
  (`level-layout.md`). `PlatformSpawn` is a spawn class like the others:
  `_init(cell: Vector2i, width: int)`. `cell` is the platform's **left
  end**; its row is the row the player stands on top of (like a floor's
  row).
- The platform covers `width` cells on that row, from `cell.x` to
  `cell.x + width - 1`.
- Unlike `floors`, the list does not have to be continuous or in any
  order: each platform says where it starts, so there can be any space
  between platforms, and platforms on different rows may share columns
  (one above another). Only their cells must not overlap.
- Checked before the build (`level-layout.md`, Checking the layout): every
  width **1 or more**, like the floors; every platform cell inside the
  level's columns; and no platform cell shared with anything else
  (Occupied cells).
- The level script never picks the look: it is random, per platform, at
  build time (see Picking the look).

## Picking the look

For each platform, the candidates are:

- Wooden and cloud, in every biome.
- Plus stone, only in the desert, any width.
- Plus mushroom, only in the desert and only if `width` is 3 or more.

The look is `pick_random()` from the candidates, each equally likely. Like the decorations, the
randomness is not seeded: looks differ on every build. Every random number
below is also a whole number from `randi_range(min, max)`, each value
equally likely.

## Drawing

One `TileMapLayer`, `Platforms`, right before `Ladders` (`ladder.md`) and
`Ground` among the level root's children (`level-layout.md`, Building),
so mushroom stalks are drawn
behind everything the player touches. One platform `TileSet` holds all
six images as atlas sources (the two planks, the cloud, the stone, the cap
and the stalk) (Texture Region Size 18 × 18, Separation 0,
Margins 0), no terrains.

### Wooden

Every cell gets a plank, variant 1 or 2 (`randi_range(1, 2)`), picked per
cell.

### Cloud

- Width 1: the one-tile cloud (2, 0).
- Width 2 or more: the end (0, 0) on the left end, the same end mirrored on
  the right end, and the body (1, 0) on every cell between them (none for
  width 2).

### Stone

Exactly like the cloud, with the stone sheet:

- Width 1: the one-tile stone (2, 0).
- Width 2 or more: the end (0, 0) on the left end, the same end mirrored on
  the right end, and the body (1, 0) on every cell between them.

### Mushroom

**The cap**, on the platform's row:

- **Centre column:** `cell.x + (width - 1) / 2`, with whole-number
  division, so it rounds down: width 3 gives the middle column, width 4 the
  left of the two middle ones.
- The left end column gets a cap end, variant 1 or 2
  (`randi_range(1, 2)`), as drawn.
- The right end column gets a cap end, variant 1 or 2, picked on its own,
  mirrored.
- The centre column gets the cap centre, stalk sheet (0, 0).
- Every other column gets the cap middle (1, 0).

**The stalk**, in the centre column, from the row below the cap going down:

- It stops at the first cell that is **ground** (any floor, gaps included:
  a gap's row is still where its surface is, even off screen) or **another
  platform**, whatever that platform's look. The stalk never paints over
  another platform.
- The last stalk cell, the one just above where it stops, is the **base**
  (0, 3). Every cell above that is a stalk body, variant 1 or 2
  (`randi_range(1, 2)`), picked per cell.
- If the cap sits directly on the ground or another platform, there is no
  stalk: the cap centre's own stalk top meets it.
- Over a gap the stalk runs down past the bottom of the screen to the
  gap's row. That is fine: nothing below row 14 is seen.

## Physics

- The platform `TileSet` has one physics layer with `collision_layer` =
  `level` and `collision_mask` = none, like the ground (`overview.md`).
- Every tile the player stands on (both planks; the cloud end, body and
  one-tile cloud; the stone end, body and one-tile stone; the two cap ends, the cap middle and the cap centre) gets
  a full `Grid.TILE` × `Grid.TILE` square collision polygon with **one-way
  collision** on: solid only from above. The stalk tiles have no collision.
- Every look behaves the same: the player rises through a platform from
  below and lands on top of it. Rising into one from below is never a
  ceiling (`is_on_ceiling()` stays false), so there is no bonk. A platform
  is not a `Block`: `block_at` never returns one.
- Walkers, the crusher and the diamond collide with `level`, so they land
  on platforms too, and walk off their ends.

## Acceptance test

| Case | Expected |
|---|---|
| Snow or grass level, any platform | Wooden or cloud, each about half the time over many builds; never a stone or a mushroom |
| Desert level, platform 3 or more wide | Wooden, cloud, stone or mushroom, each about a quarter of the time |
| Desert level, platform 1 or 2 wide | Wooden, cloud or stone, each about a third of the time; never a mushroom |
| Two platforms on different rows sharing columns | Allowed |
| Wooden platform | Every cell a plank, each variant 1 or 2 |
| Cloud, width 1 | The one-tile cloud (2, 0) |
| Cloud, width 2 | End, mirrored end |
| Cloud, width 4 | End, body, body, mirrored end |
| Stone, width 1 | The one-tile stone (2, 0) |
| Stone, width 2 | End, mirrored end |
| Stone, width 4 | End, body, body, mirrored end |
| Mushroom `PlatformSpawn.new(Vector2i(4, 8), 3)` over ground on row 12 | Cap on row 8, columns 4 to 6: end, centre, mirrored end; stalk bodies on rows 9 and 10 in column 5, base on row 11 |
| Mushroom width 4 at column 4 | Centre in column 5 (rounded down) |
| Mushroom width 5 at column 4 | Centre in column 6 |
| Any cap end | Variant 1 or 2; right ends mirrored |
| Any stalk body | Variant 1 or 2, picked per cell |
| Mushroom cap directly above the ground (row 11, ground row 12) | No stalk cells |
| A mushroom above another platform, of any look | Its stalk stops on that platform, with its base just above it |
| Mushroom centre column over a gap | Stalk runs down off the bottom of the screen |
| Player jumps up into a platform from below, any look | Passes through, is not stopped, nothing is bonked |
| Player falls onto a platform, any look | Lands and stands on it |
| Walker on a platform | Walks along it and falls off the end |
| Player walks into a stalk | Passes through it |
| Width 0 | The build stops with an `assert` |
| A platform cell in column -1 or past the last column | The build stops with an `assert` |
| A platform cell on ground, a block, a coin, a walker, the player, a crusher or another platform | The build stops with an `assert` naming both |
| Two platforms with empty columns between them | Allowed |
