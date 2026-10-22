# Crusher enemy

An enemy that hangs in the air, drops when the player is below it, then
slowly rises back to where it started and watches again. It cannot be
stomped. Read `overview.md` first. "Crusher" is a working name.

## Constants

| Name | Value | Unit |
|---|---|---|
| Fall gravity | 1923.75 | px/s² |
| Maximum falling speed | 270 | px/s |
| Wait on the floor | 0.5 | s |
| Rise speed (constant) | 33.75 | px/s |

## Body

- A crusher is a `CharacterBody2D` on the `enemies` layer. Its
  `collision_mask` holds only `level` (floors and walls), so it lands on
  the floor but passes through the player and other enemies. The player
  touches it through the player's contact check
  (`player-contact.md`).
- It moves with `move_and_slide()`.
- It never moves sideways.

## Watching

- The **start point** is where the crusher is placed: standing in its
  cell, from the level script's `crushers` list.
- The crusher compares its position with the player's. It finds the player
  through the level: `level.player`.
- The player is **below** the crusher when both are true:
  - `abs(player.position.x - position.x) < half_width`, where `half_width`
    is half the crusher's own collision width. So it drops only when the
    player's origin (the centre of its feet) is under the crusher's body.
    The player's width is not used, which gives the player a little leeway:
    it can pass with part of its body under the crusher's edge.
  - `player.position.y > position.y` (y points down, so the player is
    lower).
- It only watches while waiting at the start point.

## Each update

The crusher is always in one of four states:

| State | Each update | Ends when |
|---|---|---|
| Watch | Stays still at the start point | The player is below it (see Watching): go to Fall |
| Fall | Adds fall gravity, caps falling speed at 270, `move_and_slide()` | `is_on_floor()`: go to Wait |
| Wait | Stays still on the floor, timed with a one-shot `Timer` | After 0.5 s: go to Rise |
| Rise | `velocity.y = -33.75`, `move_and_slide()` | `position.y <= start_y`: put it exactly on the start point (`position.y = start_y`), `velocity.y = 0`, go to Watch |

- The crusher starts in Watch.
- Fall starts from a vertical speed of 0.
- If there is no floor below it, it falls off the screen and its enabler
  switches it off for good.

## Switching on and off

- Like other enemies, it has a `VisibleOnScreenEnabler2D`. Its `rect`
  covers the crusher's whole path, from the start point down to the bottom
  of the screen, so it is never switched off partway through a fall or rise.

## Not stompable

- A crusher is **not** stompable (`player-contact.md`). Touching it always hurts
  the player, unless the player is invincible (see
  `player-contact.md`).
- It never dies.

## Animation

| State | Shows |
|---|---|
| Fall | `res://art/crusher/sprite_2.png` |
| Watch, Wait, Rise | `res://art/crusher/sprite_1.png` |

No animation plays: it only swaps between the two sprites.

## Acceptance test

| Case | Expected |
|---|---|
| Player not below it | Stays still at the start point |
| Player walks under it | Starts falling on the next update |
| Player level with it or above it, lined up sideways | Stays still |
| Player below it, but not lined up sideways | Stays still |
| Falling | Speed grows by 1923.75 × delta each update, never above 270 |
| Hits the floor | Stops, waits 0.5 s |
| After the wait | Rises at a constant 33.75 px/s |
| Reaches the start point | Stops exactly on it, watches again |
| Player under it while it rises or waits | Nothing changes (it only watches at the start point) |
| Player falls onto it | Player is hurt |
| Any time | `position.x` never changes |
