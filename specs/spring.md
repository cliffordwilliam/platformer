# Spring

A spring standing on the ground. When the player touches it, the player is
launched high into the air. Read `overview.md`, `player-movement.md` and
`player-contact.md` first.

## Art

- `res://art/spring/sprite_1.png`, 18 × 18, one frame, no animation. The
  art fills rows 4 to 17 of the image, so it stands on the bottom of its
  cell.
- Collision box 16 × 14 at x 1, y 4 in the image: the drawn spring, 1 px
  narrower on each side so it never sits exactly on a tile edge
  (`assets.md`, Collision boxes); origin (9, 18), its feet (`assets.md`),
  so it squashes into the floor.

## Constants

| Name | Value | Unit |
|---|---|---|
| Launch speed | 445.5 (1.5 × the jump start speed 297, upward, so `velocity.y = -445.5`) | px/s |

## Placing them

- The level script's `springs` field, an `Array[Vector2i]` of cells
  (`level-layout.md`), like the coins. With its feet origin, a spring
  starts standing in its cell, on the top of the cell below
  (`cell_to_position(cell, Origin.FEET)`).
- Each in the `Springs` layer node. Checked before the build like the
  coins: between the start and the flag, and its starting cell shared with
  nothing (`level-layout.md`, Occupied cells).
- A spring never runs out: it works every time.

## Falling

A spring falls like in Mario Maker: it is a walker that never walks.

- `class_name Spring extends WalkingBody` (`enemy-walker.md`, WalkingBody),
  with `speed = 0`, set in its `setup()`. So it has the walker's gravity
  (965.04), falling cap (202.5), update order, landing, switching on and
  off (a `VisibleOnScreenEnabler2D` with a `rect` the size of its sprite)
  and squash and stretch. With a speed of 0 it never moves sideways, so it
  never turns at a wall.
- A spring placed in the air falls until it lands on ground, a block or a
  platform. If the breakable block under it breaks, it falls through where
  the block was. One that falls below the screen stays switched off for
  good, like a walker.
- A block hit from below does nothing to a spring standing on it (unlike
  the diamond, `diamond.md`, Bumped from below), unless the block breaks.
- Springs stack: a spring that falls onto another spring lands on it and
  stands on it, like on the floor.

## Body

- The body (`CharacterBody2D`, from `WalkingBody`) has `collision_layer` =
  `springs` and `collision_mask` = `level` and `springs` (`overview.md`),
  the same pattern as a walker: it lands on ground, blocks, platforms and
  other springs. Walkers, the diamond and the crusher don't have `springs`
  in their masks, so they pass through it.
- The player finds the body itself in its contact check, the way it finds
  a walker (`player-contact.md`, Springs): its contact area's mask holds
  `springs`.

## Launching

`launch()`, called by the player (`player-contact.md`):

- The player's `velocity.y` is set straight to `-445.5`, and it enters the
  **Spring** state (`player-movement.md`).
- The spring's sprite plays `play_bounce()` (`squash.md`), and so does the
  player's, as on a jump or a stomp.

In the Spring state the player rises with **light gravity** (550.54) the
whole way up, whether jump is held or not, and has no control over its
height. It rises about 176.6 px (about 9.8 tiles) over 49 updates, then
falls (the Fall state).

Springs are never needed to cross a level: the jump check ignores them
(`level-layout.md`, Jump check). They are extras: shortcuts, bonus heights,
coins up high.

## Guide

- Only while `Level.show_guides` (see Snapshot in `level-layout.md`), the
  spring draws its **reach**: a vertical line from its own position (the
  floor it stands on) straight up to the highest point the player's feet
  reach after a launch, so what a spring is good for can be seen on a
  snapshot.
- That height is found in `_ready` by running the Spring state's steps once
  (`velocity.y = -445.5`, then each update light gravity and move) until
  `velocity.y >= 0`, like the leaper's guide: never written in as a number,
  so it stays right if a value is tuned. With today's numbers it is about
  176.6 px.
- A snapshot is paused, so a spring placed in the air draws its line from
  where it was placed, not from where it will land.

## Acceptance test

| Case | Expected |
|---|---|
| Spring at cell (8, 10) | `position` (153, 198): standing on the top of row 11 |
| Player walks or falls into a spring | `velocity.y == -445.5`, state Spring; both sprites play the bounce |
| Player in Spring, jump held or not | Light gravity every update; rises about 176.6 px over 49 updates, then Fall |
| Player still overlapping the spring while in Spring | Not launched again |
| Player touches the spring again later | Launched again: it never runs out |
| Spring state hits a ceiling or a block | Stops rising (Fall); a block from below is bonked |
| Walker or diamond walks into a spring | Passes through; nothing happens |
| Spring on ground, a block or anything placed | The build stops with an error naming both |
| Spring placed in the air | Falls (gravity 965.04, capped at 202.5) and lands on the ground, block or platform below; plays the landing squash |
| The breakable block under a spring breaks | The spring falls through where the block was |
| The gift block under a spring is hit | Nothing happens to the spring |
| Two springs placed in one column | The upper one lands on the lower one and stands on it |
| Spring off screen | Does not fall until it comes on screen |
| Spring falls below the screen | Switched off for good |
| Any spring | `velocity.x` is always 0 |
| Snapshot | A vertical line from the spring up about 176.6 px |
| Normal run | No guide |
