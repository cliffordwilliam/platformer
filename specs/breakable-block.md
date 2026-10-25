# Breakable block

A block that is solid like a ground tile, and breaks when the player hits
it from below. A walker standing on it when it breaks dies. This spec also
holds what every block shares (the gift block, `gift-block.md`, is the
other kind). Read `overview.md`, `level-layout.md` and `player-movement.md`
first.

## Art

All 18 × 18:

- `res://art/breakable_block/sprite_1.png`: the block.
- `res://art/breakable_block_chunk/sprite_1.png` and
  `res://art/breakable_block_chunk/sprite_2.png`: the two chunk variants.

## Blocks

Breakable and gift blocks are the same thing with a different reaction to
being hit, so they share one base class:

- `@abstract class_name Block extends StaticBody2D`. `BreakableBlock` and
  `GiftBlock` extend it.
- A `Grid.TILE` × `Grid.TILE` box, with `collision_layer` = `level` and
  `collision_mask` = none (`overview.md`): the player and walkers collide
  with it exactly like a ground tile, and it scans nothing itself.
- Placed from the level script's `blocks` list (one list for both kinds,
  `level-layout.md`), in the `Blocks` layer node. Its origin is its
  top-left corner, so a block always fills exactly one cell, like the
  tiles.
- `bonk()` is written once, in `Block`, and never overridden:
  1. calls `_on_bonk()`: `@abstract func _on_bonk() -> void`, each kind's
     own reaction (Breaking, below; `gift-block.md` for the gift block)
  2. kills the walkers on top (see Killing the walkers on top)
  3. bumps the diamonds on top: they hop and turn around (`diamond.md`,
     Bumped from below)
- The level root has a function `block_at(cell)` that returns the block in
  a cell, or null. It keeps no list of blocks: it asks the physics engine,
  which already knows where every block is.
  - It queries the cell's centre,
    `cell * Grid.TILE + Vector2i(Grid.HALF_TILE, Grid.HALF_TILE)`, with the
    built-in `get_world_2d().direct_space_state.intersect_point()` (a
    `PhysicsPointQueryParameters2D` with `collision_mask` = `level`).
  - Of the hits, it returns the `collider` that `is Block`, or null if
    there is none.
  - A broken block is switched off, which takes it out of physics, so
    `block_at` only ever finds blocks that are still there, with no
    bookkeeping.
  - Called only during the physics step (the player's
    `_physics_process`), where direct space queries are safe.

## Cells under and over a box

Both checks below look at every cell a collision box covers along one row.

```
cell = Vector2i(floori(point.x / Grid.TILE), floori(point.y / Grid.TILE))
```

- The box is read from the body's `CollisionShape2D`: `shape.get_rect()`,
  moved by the `CollisionShape2D`'s `position` and the body's `position`.
- Its columns run from `floori(left / Grid.TILE)` to
  `floori((right - 1) / Grid.TILE)`. The `- 1` means a box whose right edge
  sits exactly on a cell boundary does not reach into the next cell.
- Every one of those columns counts, not just the two corners: a box
  narrower than a tile covers one or two columns, but walker B's box
  (24 px) can cover three.
- The row is taken 1 px outside the box (above the head, or under the
  feet), so it lands in the right row even when a body rests a hair away
  from the surface.

## Hitting a block: the player

- Any hit from below hits a block, whether the player is rising from a jump,
  a stomp bounce or a spring, except while climbing a ladder: a climbing
  player pushes up against a block above it on every update, so it would
  hit it every update (`ladder.md`). Climb is the one state check.
- In the player's contact check (`player-contact.md`, step 1, after the
  death line and win checks), if `is_on_ceiling()` and not in Climb: for
  every column its box covers, on the row of `top - 1` (just above its
  head), if `level.block_at(cell)` returns a block, the player calls
  `bonk()` on it. A player under two blocks at once hits both.
- The collision has already stopped the player's upward speed, so the
  player simply falls (the Fall state).

## Breaking: `_on_bonk()`

1. The block switches itself off and hides
   (`process_mode = PROCESS_MODE_DISABLED`, `visible = false`). Switched off,
   it is out of physics: nothing can stand on it or bump into it any more,
   and `block_at` no longer finds it.
2. It adds four **chunk** scenes to the level (`level.add_effect()`, see
   Chunks).

## Killing the walkers on top

Done by `Block.bonk()` right after the block's own reaction, for both kinds
of block, at the moment it is hit, so there is no flag to poll and no
timing to get right.

- For each walker in `level.walker_layer` (each a `Walker`) that is switched
  on (`can_process()`) and on the floor (`is_on_floor()`): if any column its
  box covers, on the row of `bottom + 1` (just under its feet), is this
  block's cell, the walker dies by bonk (see Walker bonk death).
- A walker dies if any part of its box is over the block, even if it also
  stands on the next tile.
- Only walkers die this way: all three kinds, and walker B in any state,
  shell or not (`enemy-walker.md`).

## Walker bonk death

A walker also dies this way when a kicked shell runs into it
(`enemy-walker.md`, Walker B: the shell).

1. The walker switches itself off and hides, like a stomped walker.
2. It adds a **walker bonked** scene to the level (`level.add_effect()`),
   at the same position, passing in `setup()` its kind's flattened
   sprite and its `flip_h`:
   - starting speed: 227.37 px/s up (the player's stomp bounce speed), and
     33.75 px/s sideways in the **opposite** direction to the way the walker
     faces (`flip_h`). So a still shell, which has no speed, flies off
     too, and a kicked shell flies off at 33.75, not 202.5.
   - each update, the same as the player's stomp bounce
     (`player-movement.md`): heavy gravity **1923.75** px/s² added first,
     falling speed capped at **270** px/s, then it moves by changing
     `position`
   - always shows the kind's `res://art/walker_*/sprite_3.png`, **upside
     down** (`flip_v = true`), with the walker's `flip_h`
   - no collision: it falls through everything
   - switched off once below the screen (see Switching off)

## Chunks

Four chunk scenes, each a `Node2D` with an 18 × 18 `Sprite2D`, origin at
its centre (9, 9) (`assets.md`).

- **Variants and spots:** the four spots are the block's top-left,
  top-right, bottom-left and bottom-right quarters. The variants are
  `var variants := [1, 1, 2, 2]`, mixed with the built-in
  `variants.shuffle()`; spot `i` gets `variants[i]`. So there are always two
  of each, in random corners.
- A chunk's centre starts at the block's centre plus (±4, ±4): the top-left
  chunk at (-4, -4), the bottom-right at (4, 4).
- **Starting speed:**
  - the top two: 405 px/s up; the bottom two: 270 px/s up
  - the left two: 67.5 px/s left; the right two: 67.5 px/s right
- **Each update, in this order** (note: move first, unlike the player):
  1. move: `position += velocity * delta`
  2. add gravity 1265.625 px/s², then cap the falling speed at 540 px/s
- **Spin:** every **4 updates** (0.067 s), the sprite steps to the next of:
  normal → `flip_h` → `flip_v` → both `flip_h` and `flip_v` → normal again.
  Counted in updates: the game runs exactly 60 updates per second, so this
  is exact and cannot drift.
- No collision: chunks fly through everything.

## Switching off

- Chunks and the walker bonked scene switch themselves off
  (`PROCESS_MODE_DISABLED`) once their `position.y` is more than one tile
  below the bottom of the screen (`Screen.height + Grid.TILE`). They are
  never freed.
- They use this position check, not a `VisibleOnScreenEnabler2D`: a chunk
  from a high block can fly up past the **top** of the screen, and an
  enabler would switch it off up there, frozen forever, since the camera
  never moves up.

## Acceptance test

| Case | Expected |
|---|---|
| Block at cell (8, 6) | `position` (144, 108) |
| Any block | `collision_layer` is `level`, `collision_mask` is none |
| Player and walkers | Stand on and bump into a block like a ground tile |
| Player jumps into a block from below | Block hidden and switched off; four chunks appear |
| Player's head overlaps a block's column by 1 px | That block breaks |
| Player's head under two blocks | Both break |
| Chunks | Two of each variant, in random corners, centres at the block's centre ± 4; top ones 405 up, bottom ones 270 up, 67.5 sideways outward |
| A chunk, every 4 updates | Steps normal, `flip_h`, `flip_v`, both |
| A chunk that flew above the screen | Comes back down and switches off below the screen |
| Walker standing on the block when it breaks | Walker bonked: shows its kind's `sprite_3.png` upside down, bounces at 227.37 up, moving the other way to its facing, gravity 1923.75, falling capped at 270 |
| Still shell or walker C standing on the block when it breaks | Bonked the same way |
| Walker B (24 px) with only its middle over the block | Dies |
| Walker with part of its box over the block, the rest over the next tile | Dies |
| Walker entirely over the next tile | Survives |
| Player rising from a stomp (Bounce) into a block | Block breaks |
