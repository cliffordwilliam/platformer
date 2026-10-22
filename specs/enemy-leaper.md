# Leaper enemy

An enemy that leaps straight up, falls back down to where it started, waits
a random time, and leaps again. Its start point is always hidden behind
the level's water, so it looks like it leaps out of a pool
(`level-layout.md`: the water is drawn in front of the enemies). Leapers
are only allowed in levels with water. Read `overview.md` first.
"Leaper" is a working name. There is one variant.

## Constants

| Name | Value | Unit |
|---|---|---|
| Leap speed | 421.86 (upward, so `velocity.y = -421.86`) | px/s |
| Gravity | 442.99 | px/s² |
| Maximum falling speed | 202.5 | px/s |
| Wait at the start point | random, 1 to 3.05 | s |

## Body

- A leaper is an `Area2D` with `collision_layer` = `enemies` and
  `collision_mask` = none: the player
  can detect it, but it never blocks anything. Only the player touches it,
  through the player's contact check (`player-contact.md`).
- It moves by changing `position`.
- It never moves sideways.

## Leaping

The **start point** is where the leaper is placed. The level script's
`leapers` list gives only its column; the row is always **14**, so the
start point is `cell_to_position(Vector2i(column, 14), Origin.CENTRE)`: y = 261,
the middle of the water body (rows are `Grid.TILE` high). Its 17 px sprite
then covers y 253 to 270, fully behind the water (and mostly below the
screen's bottom edge, 257). It still switches on as its column comes on
screen (see Switching on and off).

Each update, in the same order as the player (gravity first, then a leap
overwrites it, then move):

```
velocity.y = min(velocity.y + 442.99 * delta, 202.5)
if leaping now: velocity.y = -421.86
position.y += velocity.y * delta
```

1. **Leap.** The leaper leaps on its first update after being switched on,
   and again each time its wait ends.
2. **Back at the start.** When it falls back to the start point
   (`position.y >= start_y`), it is put exactly on the start point
   (`position.y = start_y`), its `velocity.y` is set to 0, and it stops.
3. **Wait.** It waits a random time between 1 and 3.05 s, then leaps
   again. The wait is a one-shot `Timer` (`process_callback` set to physics,
   so it counts in game updates), started with
   `start(randf_range(1.0, 3.05))`, a new random time each wait.

The leap height and timing come from the numbers above: it rises about
204.39 px and is back at the start point 132 updates (2.2 s) after leaping.

## Facing

- Rising: `flip_v = false`.
- Falling (`velocity.y > 0`): `flip_v = true`.

## Guide

- It draws the leap path as a guide (only while `Level.show_guides`, see
  Snapshot in `level-layout.md`): a vertical line from the start point up
  to the top of the leap.
- The top is found by running the same per-update steps once, in `_ready`,
  until `velocity.y >= 0`, not with a separate formula, so the line always
  matches the game.

## Switching on and off

- Same as walkers: a `VisibleOnScreenEnabler2D` with a `rect` the size of
  its sprite.
- That is enough, because the sprite never leaves the screen's height: at
  the start point it covers y 253 to 270, so its top 4 px are still above
  the screen's bottom edge (257), and the top of its leap (about y 57) is
  on screen too. So only its x decides.

## Stomped

Leapers are stompable (see `player-contact.md`). When
stomped, a leaper dies exactly like a flyer (see Stomped in
`enemy-flyer.md`): it switches itself off and hides, and adds the same kind
of death scene to the level (`level.add_effect()`). It always shows
`res://art/leaper/sprite_1.png`, upside down (`flip_v = true`), with no
animation, falling with gravity 965.04 capped at 202.5 through
everything and off the screen.

## Animation

- One animation: `res://art/leaper/sprite_1.png` and `res://art/leaper/sprite_2.png`, looping, all the time while switched
  on (also while waiting and while falling).
- Shown with an `AnimatedSprite2D`. Each sprite shows for 0.133 s, so the
  animation runs at **7.5 frames per second** (1 / 7.5 = 0.1333 s, which is
  8 updates at 60 per second). It loops and plays from the start.
- It is a child of the enemy, so it stops whenever the enemy is switched off
  or the game is paused, and carries on afterwards.

## Acceptance test

| Case | Expected |
|---|---|
| Switched on | Leaps on its first update: `velocity.y` within 0.001 of -421.86 (`overview.md`, Tests) |
| Leap | Top of the leap 204.39 px above the start point (within 1 px) |
| Leap | Back at the start point after exactly 132 updates, `velocity.y == 0` |
| Rising | `flip_v` is false |
| Falling | `flip_v` is true |
| Its column on screen, anywhere in its leap (even at the top, or waiting below the screen's edge) | Switched on |
| Its column has left the screen to the left | Switched off for good |
| Back at the start point | Waits between 1 and 3.05 s, then leaps again |
| Any time | `position.x` never changes; never below the start point |
| Stomped | Same as a stomped flyer, showing `res://art/leaper/sprite_1.png` upside down, whichever frame the leaper was on |
