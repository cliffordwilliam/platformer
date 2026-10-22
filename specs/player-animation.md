# Player animation

Which sprite the player character shows. Read `overview.md` first, and
`player-movement.md` for the states and facing this spec builds on.

The character has only two sprites, `res://art/player/sprite_1.png` and `res://art/player/sprite_2.png`. They are
shown with an `AnimatedSprite2D`. Facing (`flip_h`) is covered in
`player-movement.md`.

## Sprite per state

| State | Shows |
|---|---|
| Idle | `res://art/player/sprite_1.png` |
| Walk | `res://art/player/sprite_1.png` and `res://art/player/sprite_2.png` in turn (see Walk speed) |
| Rise | `res://art/player/sprite_2.png` |
| Bounce | `res://art/player/sprite_2.png` |
| Spring | `res://art/player/sprite_2.png` |
| Fall | `res://art/player/sprite_2.png` |
| Climb | `res://art/player/sprite_1.png` and `res://art/player/sprite_2.png` in turn, a separate `climb` animation at a fixed **7.5 frames per second** (the same as the enemies' animations), starting on `sprite_2.png` |

The state is the one decided at the end of the update, after
`move_and_slide()`.

## Walk speed

The walk animation speeds up with the walking speed. The speed range maps
in a straight line onto the animation range:

| Walking speed `abs(velocity.x)` | Animation rate |
|---|---|
| 0 px/s | 4.3 frames per second |
| 101.25 px/s (top speed) | 15 frames per second |

```
rate = remap(abs(velocity.x), 0, 101.25, 4.3, 15)
```

- Use Godot's built-in `remap` for this, not hand-written math.
- A speed of exactly 0 is never in the Walk state (it is Idle), so the
  slowest walk plays just above 4.3 frames per second.
- Set the rate with the built-in `speed_scale`, for example by giving the
  walk animation 15 frames per second and setting
  `speed_scale = rate / 15`.
- The rate is recalculated every update, while the animation keeps playing
  from where it is.
- Entering Walk (from Idle or on landing) always starts on `res://art/player/sprite_2.png`.
- Walk is the only state that changes `speed_scale`. Leaving Walk sets it
  back to 1.

## Acceptance test

| Case | Expected |
|---|---|
| Walking at top speed | Walk animation plays at 15 frames per second |
| Walking at half top speed (50.625 px/s) | Walk animation plays at 9.65 frames per second |
| Idle to Walk | First walk sprite shown is `res://art/player/sprite_2.png` |
| Walk to Idle, Rise, Bounce, Spring, Fall or Climb | `speed_scale` is back to 1 |
| Climb | `climb` animation: `sprite_1.png` and `sprite_2.png` in turn at 7.5 frames per second |
| Idle | `res://art/player/sprite_1.png`, not animating |
| Rise, Bounce, Spring or Fall | `res://art/player/sprite_2.png`, not animating |
