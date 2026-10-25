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
- `height` is 1 or more, and every cell it covers is its own
  (`level-layout.md`, Checking the layout).

## Drawing

- One `TileMapLayer`, `Ladders`, right after `Platforms` and
  `MushroomDecorations` (`one-way-platform.md`) among the level
  root's children (`level-layout.md`, Building). The level keeps it as
  `level.ladder_layer`.
- One ladder `TileSet`: one atlas source (Texture Region Size 18 × 18,
  Separation 0, Margins 0), no terrains.
- Each ladder's top cell gets the cap (0, 0); every other cell gets the
  body (0, 1). Tiles are chosen by place, by hand: terrains would need a
  tile for the bottom cell, which has nothing below it, and the ladder
  sheet has none.

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

The player's side is in `player-movement.md` (Climbing, and the Climb
state). In short: it climbs at 67.5 px/s while `move_up` is held and the
point 1 px above its feet is in a ladder cell (only the origin counts, so
it must be lined up with the ladder, not just touching its edge), stops
with its feet exactly on the cap's top and stands there, and falls when it
lets go or walks off the ladder's column. Ground or a block above stops it
like any ceiling, and a climbing player never bonks a block
(`breakable-block.md`, Hitting a block): pushing up against one every
update would hit it every update.

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
| `LadderSpawn.new(Vector2i(8, 9), 4)` | Ladder cells (8, 6) to (8, 9): cap on (8, 6), body on rows 7 to 9 |
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
| A level only crossable with a ladder | The jump check fails: ladders are not part of it |
