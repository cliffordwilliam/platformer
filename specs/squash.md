# Squash and stretch

Fire-and-forget squash and stretch on the sprites of the player, the
walkers, the crusher and the checkpoint. Read `overview.md` first.

The flyer, the leaper and the bar never squash or stretch. The diamond and
the spring do, like a walker, and the spring also bounces when it launches
the player.

## Purely visual

- Only the **sprite node** is scaled, never the body, its collision box or
  its contact area. Nothing here changes how anything moves or collides,
  and no other spec's acceptance test changes.
- Sprites are drawn with their origin at the feet (`assets.md`), so the
  sprite scales around its feet: a landing squash stays on the floor.
- Only `scale` is changed. The sprite is never rotated (no tilt).

## The squash script

One small script, used by the player's, the walkers', the crusher's, the
diamond's and the spring's sprite nodes (and the walker flattened scene's
sprite). It
extends `Node2D`, the shared base of `Sprite2D` and `AnimatedSprite2D`: it
only uses `scale` and `create_tween()`, so the one script attaches to
either kind of sprite node.

It keeps one `Tween` at a time. Starting a new effect always kills the
previous tween first (`cancel_squash()`), so effects never fight over
`scale`: a new one simply takes over.

Tweens are made with the sprite's own `create_tween()`, so they are bound to
it: they stop during the injury freeze and when the character is switched
off, and carry on afterwards.

### Constants

| Name | Value |
|---|---|
| `LAND_SQUASH_SCALE` | `Vector2(1.3, 0.7)` |
| `LAND_SQUASH_DURATION` | 1.0 s |
| `AIR_SQUASH_MAX_Y` | 1.2 |
| `AIR_SQUASH_MIN_X` | 0.9 |
| `SQUISH_FROM_SCALE` | `Vector2(1.5, 0.2)` |
| `SQUISH_IMPACT_DURATION` | 0.1 s |
| `SQUISH_SCALE` | `Vector2(1.2, 0.5)` |
| `SQUISH_DURATION` | 0.6 s |

### Functions

- **`cancel_squash()`**: kills the current tween, if there is one.
- **`play_bounce()`**: `cancel_squash()`, then a tween with
  `TRANS_ELASTIC`, `EASE_OUT` that tweens `scale` to `Vector2.ONE` over
  `LAND_SQUASH_DURATION`, starting from `LAND_SQUASH_SCALE` (`.from(...)`).
  The sprite snaps wide and short, then springs back to normal.
- **`play_squish(on_done)`**: `cancel_squash()`, then a tween with
  `TRANS_ELASTIC`, `EASE_OUT` that runs in sequence:
  1. `scale` to `SQUISH_FROM_SCALE` over `SQUISH_IMPACT_DURATION`, with
     this step's transition set to `TRANS_EXPO`
  2. `scale` to `SQUISH_SCALE` over `SQUISH_DURATION`
  3. calls `on_done` (`tween_callback`)

  0.7 s in all.
- **`update_air_squash(speed_y, max_fall_speed)`**: not a tween. Called
  every update while falling. Sets the scale straight from the falling
  speed with the built-in `remap`:

  ```
  var speed := absf(speed_y)
  scale.y = remap(speed, 0.0, max_fall_speed, 1.0, AIR_SQUASH_MAX_Y)
  scale.x = remap(speed, 0.0, max_fall_speed, 1.0, AIR_SQUASH_MIN_X)
  ```

  So the sprite grows taller and thinner the faster it falls, fully
  stretched (0.9 × 1.2) at the character's own maximum falling speed.

## When each one plays

### Player

| When | Call |
|---|---|
| A jump starts | `play_bounce()` |
| A stomp (entering Bounce, see `player-contact.md`) | `play_bounce()` |
| A spring launch (entering Spring, see `spring.md`) | `play_bounce()` |
| Entering Fall | `cancel_squash()` |
| Every update in Fall | `update_air_squash(velocity.y, 270)` |
| Landing: Fall to Idle or Walk | `play_bounce()` |
| Entering Climb | `cancel_squash()`, then `scale = Vector2.ONE` (so a fall's stretch never stays on while climbing) |
| Stopping against a wall: Walk to Idle while `is_on_wall()` | `play_bounce()`, once: pushing on stays Idle (`player-movement.md`, Collisions) |
| Getting hurt (an injury, not a death) | `play_bounce()`. It starts when the injury freeze ends, because the tween stops while the game is paused |

### Walkers

A walker has no states, so "landing" and "starting to fall" are found by
comparing `is_on_floor()` with the previous update's value.

| When | Call |
|---|---|
| Starts falling: was on the floor last update, is not now | `cancel_squash()` |
| Every update not on the floor | `update_air_squash(velocity.y, 202.5)` |
| Lands: was not on the floor last update, is now | `play_bounce()` |
| Turns around at a wall (`speed = -speed`) | `play_bounce()` |
| Stomped | The walker flattened scene's sprite plays `play_squish(...)` (see `enemy-walker.md`) |
| Walker B stomped into a still shell, or kicked | `play_bounce()` on its own sprite (it stays switched on) |

### Checkpoint

| When | Call |
|---|---|
| Touched and raised (`checkpoint.md`) | `play_bounce()` |

### Diamond

The same as walkers (`diamond.md`): `cancel_squash()` on starting to fall,
`update_air_squash(velocity.y, 202.5)` every update in the air,
`play_bounce()` on landing and on turning at a wall.

### Spring

The same as walkers when falling and landing (`spring.md`, Falling; it
never turns, so never bounces at a wall), plus:

| When | Call |
|---|---|
| It launches the player | `play_bounce()` |

### Crusher

| When | Call |
|---|---|
| Entering Fall | `cancel_squash()` |
| Every update in Fall | `update_air_squash(velocity.y, 270)` |
| Landing: Fall to Wait | `play_bounce()` |

## Acceptance test

| Case | Expected |
|---|---|
| Any effect playing | Body position, velocity and collision box unchanged |
| Player jumps | Sprite scale starts at (1.3, 0.7) and is back to (1, 1) after 1 s |
| Player falling at 270 px/s | Sprite scale (0.9, 1.2) |
| Player falling at 135 px/s | Sprite scale (0.95, 1.1) |
| A second bounce while one is playing | The first stops; the second starts from (1.3, 0.7) |
| Walker stomped | Flattened sprite reaches (1.5, 0.2) after 0.1 s, (1.2, 0.5) after 0.7 s, then is hidden |
| Flyer, leaper, bar | Sprite scale is always (1, 1) |
| Walker B stomped while walking, or a still shell kicked | Its sprite's scale starts at (1.3, 0.7) |
| Checkpoint touched | Its sprite's scale starts at (1.3, 0.7), around its feet |
