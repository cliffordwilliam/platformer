# Checkpoint

A small flag placed in a level, like a door. Touching it raises its flag,
and after a death the player starts again from it instead of from the
start. Read `overview.md`, `level-layout.md`, `flag.md` and `game-flow.md`
first.

## Art

The checkpoint uses the goal flag's art (`flag.md`), cut down to two tiles.
The flag images are 18 × 257: tile row 0 is empty, row 1 holds the cloth
(with the top of the pole), and every row from 2 down is plain pole.

- **Down** (not touched yet): two tiles of plain pole, rows 2 and 3 of the
  image: the region `Rect2(0, 36, 18, 36)` of
  `res://art/flag/sprite_1.png`. One frame.
- **Raised** (touched): the cloth over one tile of pole, rows 1 and 2: the
  region `Rect2(0, 18, 18, 36)` of `res://art/flag/sprite_1.png` and of
  `res://art/flag/sprite_2.png`, looping at **7.5 frames per second**,
  like the goal flag.
- Shown with an `AnimatedSprite2D` with two animations, `"down"` and
  `"raised"`, each frame an `AtlasTexture` with that region. No new art
  file.
- **Origin (9, 36), its feet** (`assets.md`): the middle of the bottom of
  the 18 × 36 picture (`centered = false`, `offset = Vector2(-9, -36)`).
  So it is placed with `cell_to_position(cell, Origin.FEET)`: its bottom
  tile fills its cell, its top tile reaches into the cell above, and its
  bounce squashes it onto the ground.
- Collision box **18 × 36**, the whole picture.

## Placing them

- The level script's `checkpoints` field, an `Array[Vector2i]` of cells
  (`level-layout.md`), like the doors. In the `Checkpoints` layer node.
- Checked before the build (`level-layout.md`, Checking the layout): its
  column is between the start and the flag; it takes **two cells**, its
  own and the one above, shared with nothing (Occupied cells); and the
  cell **under** it is ground or a platform, never air, a gap or a block
  (a block can break), so the player always respawns standing on
  something.
- Not part of the jump check.

## Body

- A checkpoint is an `Area2D` (`class_name Checkpoint`) with
  `collision_layer` = `checkpoints` and `collision_mask` = none
  (`overview.md`): it watches nothing itself. Only the player looks for it
  (`player-contact.md`, Checkpoints); walkers, the diamond and everything
  else pass through it.
- It never moves, never switches off and never runs out.

## The respawn point

- `Level` has `static var respawn_cell: Vector2i = PLAYER_CELL`: the cell
  the player starts in (`camera.md`, Starting position).
- It is a `static var`, not a field of the level node, because a death
  reloads the level scene (`game-flow.md`, Death), which throws the old
  level node and its fields away. A `static var` belongs to the `Level`
  script, which stays loaded. Tested on 4.7.2: a `static var` keeps its
  value through `reload_current_scene()`, and through a change to a scene
  that does not use the class and back. No autoload is needed.
- It goes back to `PLAYER_CELL` on every win, before the next scene loads
  (`game-flow.md`, Winning), so every level starts at its own start
  floor.

## Touching it

The player calls `touch()` (`player-contact.md`, Checkpoints):

- **Down:** it raises itself: plays `"raised"`, its sprite plays
  `play_bounce()` (`squash.md`), and it sets
  `Level.respawn_cell = cell` (its own cell). The player respawns standing
  in that cell, on the ground under it, exactly where the checkpoint
  stands.
- **Raised:** nothing happens.
- Touching one sets the respawn point even if it is left of the current
  one; with the camera only moving right, that can only happen with two
  checkpoints on the same screen.

## After a reload

- In its `setup()`, a checkpoint whose column is at or left of
  `Level.respawn_cell.x` starts **raised**, playing `"raised"` without a
  bounce: the player has already passed it. Every other checkpoint starts
  down.
- `PLAYER_CELL` is in column 4, left of every checkpoint (they start at
  column 7), so on a fresh start every checkpoint is down.

## Acceptance test

| Case | Expected |
|---|---|
| Checkpoint at cell (25, 8) | `position` (459, 162): its bottom tile fills cell (25, 8), its top reaches into (25, 7) |
| Any checkpoint at the start of a level | Down: two tiles of plain pole, no cloth |
| Any checkpoint | `collision_layer` is `checkpoints`, `collision_mask` is none |
| Player touches a checkpoint that is down | Raised: cloth animating at 7.5 fps, sprite bounces; `Level.respawn_cell` is its cell |
| Player touches a raised checkpoint | Nothing changes |
| Player dies after touching a checkpoint | The level reloads; the player starts standing in the checkpoint's cell with 2 health; that checkpoint is raised, without a bounce |
| Player dies without touching one | The player starts on the start floor at (81, 216) |
| Two checkpoints touched, then a death | The player starts at the one touched last |
| Player wins after touching a checkpoint | The next level starts at its start floor: `Level.respawn_cell` is `PLAYER_CELL` |
| Walker, diamond or spring passes a checkpoint | Nothing happens |
| Checkpoint over a gap, over air or over a block | The build stops with an error |
