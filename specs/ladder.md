# Ladder

A ladder placed anywhere, like a door. The player climbs it by holding up,
falls off by letting go, and stands on its top. Read `overview.md`,
`level-layout.md`, `controls.md` and `player-movement.md` first.

## Art

`res://art/ladder/sprite_1.png` (1 × 2), 18 × 18 tiles, no gaps.
Coordinates are (column, row):

| Tile | What |
|---|---|
| (0, 0) | Top cap (drawn from row 3 of the tile down) |
| (0, 1) | Body |

## Placing them

- The level script's `ladders` field, an `Array[LadderSpawn]`
  (`level-layout.md`): `LadderSpawn.new(cell, height)`. `cell` is the
  ladder's **bottom** cell; it grows **up** `height` cells, from row
  `cell.y` up to row `cell.y - height + 1`.
- Anywhere, like a door: on the ground, floating, from a floor up to a
  ledge. Nothing has to be under it.
- Checked before the build (`level-layout.md`, Checking the layout):
  `height` is 1 or more, its column is inside the level, and every cell it
  covers is shared with nothing (Occupied cells).

## Drawing

- One `TileMapLayer`, `Ladders`, right after `Platforms` and
  `MushroomDecorations` (`one-way-platform.md`) among the level
  root's children (`level-layout.md`, Building). The level keeps it as
  `level.ladder_layer`.
- One ladder `TileSet`: one atlas source (Texture Region Size 18 × 18,
  Separation 0, Margins 0), no terrains.
- Each ladder's top cell gets the cap (0, 0); every other cell gets the
  body (0, 1). Tiles are chosen by place, like the clouds.

## Physics

- The ladder `TileSet` has one physics layer with `collision_layer` =
  `level` and `collision_mask` = none, like the platforms (`overview.md`).
- The **cap** gets a full `Grid.TILE` × `Grid.TILE` square collision
  polygon with **one-way collision** on, exactly like a one-way platform
  (`one-way-platform.md`, Physics): the player rises through it while
  climbing and stands on it afterwards. Walkers, the crusher, the diamond
  and springs land on it too.
- The **body** has no collision: everything passes through it.
- `Level.ladder_at(cell) -> bool`: `ladder_layer.get_cell_source_id(cell)
  != -1`. Like `block_at` (`breakable-block.md`), it asks what is already
  there instead of keeping a list.

## Climbing

The player's side is in `player-movement.md` (the Climb state). In short:

- **On a ladder:** the cell under the point 1 px above the player's feet
  (`position + Vector2(0, -1)`) is a ladder cell. Only the origin counts,
  like the crusher's check (`enemy-crusher.md`): the player must be lined
  up with the ladder, not just touching its edge.
- **Climbing:** `move_up` is held while on a ladder. Then `velocity.y` is
  set straight to **-67.5** (up), with no gravity, and the player moves
  with `move_and_slide()` as usual, so ground or a block above stops it.
- **The top:** before moving, if the ladder cell the player is on has no
  ladder cell above it, its top (`cell.y * Grid.TILE`) is the limit. After
  `move_and_slide()`, the feet are put no higher than that:
  `position.y = maxf(position.y, limit)`. So the feet stop exactly on top
  of the cap. There, the point above the feet is no longer in a ladder
  cell, so climbing ends, gravity comes back, and the player lands on the
  cap's one-way top and stands there (Idle). Holding up there does
  nothing: there is no flickering in and out of Climb.
- **Letting go:** releasing up, or walking sideways off the ladder's
  column, ends climbing. On the next update the upward speed is dropped
  (`velocity.y = 0` before gravity), so the player simply falls.
- **No bonk while climbing:** pushing up against a block every update
  would hit it every update, so a climbing player never bonks blocks
  (`breakable-block.md`, Hitting a block). It just stops under it.
- Sideways walking works as normal while climbing (`player-movement.md`,
  Walking).

Tested with a prototype on Godot 4.7.2: climbing a 4-cell ladder stops
with the feet exactly on the cap's top and stays standing there with up
held; letting go halfway falls back to the ground; a block right above
the ladder stops the climb with `is_on_ceiling()` true on every update.

## Jump check

Ladders are extras, like springs: the jump check ignores them, and a
ladder's top is not a standable thing there (`level-layout.md`, Jump
check). Every level must still be crossable by jumping alone.

## Acceptance test

| Case | Expected |
|---|---|
| `LadderSpawn.new(Vector2i(5, 9), 4)` | Ladder cells (5, 6) to (5, 9): cap on (5, 6), body on rows 7 to 9 |
| `LadderSpawn.new(cell, 1)` | One cell, the cap |
| Player at the ladder's bottom, up held | State Climb, `velocity.y == -67.5`, rises 67.5 px per second |
| Player climbs to the top, up still held | Feet stop exactly on the cap's top, then Idle standing on it; no flicker between states while up stays held |
| Up released while climbing | Falls: `velocity.y` starts from 0, heavy gravity, state Fall |
| Player walks sideways off the ladder while climbing | Falls |
| Player's origin one column off the ladder, touching its edge, up held | Does not climb |
| Block right above the ladder's top, player climbs | Stops under the block; the block is not bonked |
| Player falls onto a ladder's top | Lands and stands on the cap |
| Player jumps up through a ladder's top | Passes through |
| Walker reaches a ladder | Passes through its body; lands on its cap if it falls onto it |
| Enemy touches a climbing player | Player is hurt (Climb is not Fall, so no stomp) |
| Ladder `height` 0, or a cell in column -1 or past the last column | The build stops with an `assert` |
| Ladder cell on ground, a block, a platform or anything placed | The build stops with an `assert` naming both |
| A level only crossable with a ladder | The jump check fails: ladders are not part of it |
