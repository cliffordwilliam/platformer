# Flyer enemy

An enemy that bobs up and down in the air. Read `overview.md` first.
"Flyer" is a working name.

## Constants

| Name | Value | Unit |
|---|---|---|
| Pull toward the centre | 47.46 | px/s² |
| Maximum bobbing speed | 135 | px/s |
| Death gravity | 965.04 | px/s² |
| Death maximum falling speed | 202.5 | px/s |

## Body

- An `Area2D` on the `enemies` layer, masking nothing (`overview.md`,
  Physics layers): it blocks nothing, and only the player's contact check
  finds it (`player-contact.md`).
- It moves by changing `position`.

## Bobbing

- A flyer never moves sideways. It moves up and down along a straight
  vertical path, and back, forever.
- The flyer is placed from the level script's `flyers` list. Its
  `FlyerSpawn` (`level-layout.md`) gives its cell and its path,
  `bob_distance: float` (pixels, positive is down). The flyer starts at
  rest at its cell's centre, which is one end of the path. The other end is `bob_distance` pixels below it (above it, if
  negative).
- It draws the path as a vertical line, as a guide (only while
  `Level.show_guides`, see Snapshot in `level-layout.md`), so the path can
  be checked on a snapshot.
- The movement is a built-in `Tween` that loops forever, from one end to
  the other and back:
  - transition `TRANS_QUAD`, ease `EASE_IN_OUT`: quadratic easing is
    constant acceleration, so it speeds up toward the middle of the path
    and slows down toward each end at exactly 47.46 px/s²
  - each one-way trip takes `2 * sqrt(abs(bob_distance) / 47.46)` seconds
  - `set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)` so it steps with the
    game's 60 updates per second, like every tween (`overview.md`)
  - created with the flyer's `create_tween()`, so it is bound to the flyer
    and stops whenever the flyer is switched off or the game is paused (the
    default pause mode, `TWEEN_PAUSE_BOUND`)
- The top speed, in the middle of the path, is `sqrt(47.46 * abs(bob_distance))`.
  It only reaches the 135 px/s cap for paths longer than about 384 px,
  taller than the screen, so a tween never needs the cap: the layout check
  keeps every path on screen (`level-layout.md`, Checking the layout).
- **`bob_distance` of 0:** the flyer creates no tween and hovers in place
  at its cell's centre. (A looping tween whose trip takes 0 s would loop
  forever without time passing, so it is not made at all.) Everything else
  is the same: it animates, switches on and off, and can be stomped.

## Switching on and off

- Same as walkers: a `VisibleOnScreenEnabler2D` with a `rect` the size of its
  sprite switches it on when it reaches the screen and off when it leaves.
- That is enough, because its whole path is on screen from top to bottom
  (checked before the build, `level-layout.md`), so only its x decides.

## Stomped

Flyers are stompable (see `player-contact.md`). When
stomped (`stomp()`):

1. The flyer switches itself off and hides
   (`process_mode = PROCESS_MODE_DISABLED`, `visible = false`).
2. It adds a **flyer death** scene to the level (`level.add_effect()`), at
   the same position: `res://enemies/enemy_death.tscn` (`overview.md`,
   Scenes), the one death scene the flyer and the leaper share, given the
   flyer's sprite in its `setup()`.

The flyer death scene is a `Node2D` with a `Sprite2D`:

- The sprite always shows `res://art/flyer/sprite_1.png`, upside down
  (`flip_v = true`), with no animation. Nothing about the flyer's current
  frame is passed in.
- It starts with a vertical speed of 0 and no sideways speed.
- Each update it adds death gravity (965.04), caps the falling speed at
  202.5, then moves by changing `position` directly. It has no collision
  shape, so it falls through everything and off the screen.
- It has its own `VisibleOnScreenEnabler2D` (sprite-sized `rect`), so once
  it has fallen off the screen it is switched off. It is never freed.

## Animation

- **Fly:** `res://art/flyer/sprite_1.png`, `res://art/flyer/sprite_2.png` and `res://art/flyer/sprite_3.png`, looping (1, 2, 3, 1, 2, 3...), all the time
  while switched on.
- An `AnimatedSprite2D` at 7.5 frames per second (`overview.md`,
  Animations).

## Acceptance test

| Case | Expected |
|---|---|
| Any time while alive | `position.x` never changes; `position.y` stays between the two ends |
| `bob_distance = 40` | One-way trip takes 1.836 s, starting and ending at rest |
| `bob_distance = 0` | No tween; the flyer hovers at its cell's centre, animating |
| Switched off or game paused | Flyer stops moving, and carries on from the same spot afterwards |
| Stomped | Flyer switched off and hidden; flyer death scene shows `res://art/flyer/sprite_1.png` upside down at the same position, whichever frame the flyer was on |
| After a stomp | Death scene falls, speed capped at 202.5, no sideways movement |
| Death scene off screen | Switched off |
