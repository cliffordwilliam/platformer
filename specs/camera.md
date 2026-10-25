# Camera

How the camera follows the player. Read `overview.md` first.

## Rules

- The camera only ever moves **right**. It never moves left, up or down.
- Its top edge is always at y = 0 and its bottom edge at y = `Screen.height`
  (`Screen` is in `overview.md`).
- The camera is a `Camera2D` that is **not** a child of the player, so it
  does not follow the player back to the left. Its script is
  `class_name Camera extends Camera2D`, and the level keeps it as
  `level.camera`.
- The camera's position is the middle of the screen (the built-in default
  `anchor_mode`).
- `Camera2D` has no built-in property for where the screen's edges are, so
  the camera's script adds two read-only properties with GDScript getters,
  and everything that needs an edge uses them:

  ```
  var left_edge: float:
      get: return position.x - Screen.half_width
  var right_edge: float:
      get: return position.x + Screen.half_width
  ```
- The level starts at x = 0 and ends at `level_end_x` (see Level end).
- No smoothing: the camera keeps the built-in default
  `position_smoothing_enabled = false`.
- The camera's built-in `limit_*` properties are not used. The camera is
  clamped by the two lines below instead, so `camera.position` always
  matches what the screen shows.

## Level end

- The level's root node holds where the level ends, `level_end_x`
  (pixels): the right edge of the level's ground. It is worked out from the
  level's floors, not typed in (see `level-layout.md`).
- The player and the camera get the level root through `setup(level)`
  (`level-layout.md`, Building a thing) and read `level.level_end_x`.

## Starting position

The player starts in `Level.respawn_cell` (`checkpoint.md`): the start
floor's `Level.PLAYER_CELL`, (4, 11) (`level-layout.md`, Floors), until a
checkpoint is touched, then that checkpoint's cell. The **level root**
sets up the starting positions in its own `_ready`, after building
everything (`level-layout.md`, Building), in this order:

1. **Player first:** `position = cell_to_position(respawn_cell, Origin.FEET)`:
   standing in that cell, on the start floor ((81, 216)) or on the ground
   under the checkpoint. Both are always inside the level, so it needs no
   clamp.
2. **Then the camera:** centres on the player, then clamps so the screen
   stays inside the level:
   `position.x = clamp(player.position.x, Screen.half_width, level_end_x - Screen.half_width)`
   and `position.y = Screen.half_height`.

The player and camera do not position themselves in their own `_ready`.
The level root also places the goal flag (`flag.md`).

## Each update

The camera and the player each clamp themselves, in their own update, right
after their own movement. Neither needs the other's clamp to have run first.

**Camera**, in its own `_physics_process`:

```
camera.position.x = max(camera.position.x, player.position.x)
camera.position.x = min(camera.position.x, level_end_x - Screen.half_width)
```

So once the player walks past the middle of the screen, the camera keeps up
with it, never goes back, and stops when the screen's right edge reaches
`level_end_x`. The camera comes after the player in the scene tree, so Godot
runs the camera's update after the player has moved this update.

**Player**, right after its `move_and_slide()`:

```
player.position.x = clamp(player.position.x,
    camera.left_edge, level_end_x)
```

- The clamp uses only the player's origin (the centre of its feet), never
  its width. At an edge, half of the player's body may go off screen. That
  is intended.
- The player gets the camera through the level, `level.camera`, like
  everything else it finds. At this point the camera has not moved yet
  this update. That is fine: the camera only moves when the player is right
  of the middle of the screen, far from the left edge.
- The right side uses `level_end_x` directly, not the camera. The player can
  only reach the screen's right edge once the camera has stopped at the
  level end, and then the two are the same line.

## The screen edges

- This is only a position clamp, not a collision. It does not change the
  player's velocity, state or `is_on_wall()`.
- Only x is clamped, never y. The player may go above the top of the screen
  (gravity always brings it back down). Below the bottom it dies (see
  `player-damage.md`), which a clamp at `Screen.height` would prevent.
- The left edge matters any time the player walks back left. The camera
  never moves left and only moves when the player walks right, so this edge
  can never push the player into a wall.
- The right edge only matters at the level end. Before that, the camera
  keeps the player at or left of the middle of the screen.
- The level is won when the player's x reaches the flag (`flag.md`), or
  when it touches a door (`door.md`).

## Acceptance test

| Case | Expected |
|---|---|
| Any level, at the start, no checkpoint touched | Player at (81, 216); camera's left edge at x = 0 |
| Respawn at a checkpoint in the middle of the level | Player standing in the checkpoint's cell; camera centred on the player |
| Respawn at a checkpoint less than half a screen from the level end | Camera's right edge at `level_end_x` |
| Player in the middle of the level | Camera centred on the player |
| Player walks right past the middle of the screen | Camera moves right with it |
| Player walks left | Camera stays still |
| Player walks left into the screen's left edge | Player's origin stays at `camera.left_edge`; `velocity.x` is untouched |
| Player walks right at the level end | Camera stops with its right edge at `level_end_x`; player's origin stops at `level_end_x`; `velocity.x` is untouched |
| Any time | `camera.position.x` matches the middle of what the screen shows; camera's top edge at y = 0 |
| `Screen.half_width`, `Screen.half_height` | 229.5 and 128.5 (not 229 and 128) |
| `camera.left_edge` with the camera at x = 229.5 | 0 |
