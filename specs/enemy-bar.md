# Bar enemy

A straight line of sprites that spins around its centre. It cannot be
stomped. Read `overview.md` first. "Bar" is a working name.

## Constants

| Name | Value | Unit |
|---|---|---|
| Rotation speed | 105.5 | degrees per second |
| Sprite spacing | 30 | px |
| Sprite size | 24 × 24 drawn, in a 26 × 26 image | px |
| Collision box per sprite | 14 × 14, centred (see `assets.md`) | px |

## Settings per bar

Placed from the level script's `bars` list. Its `BarSpawn`
(`level-layout.md`) gives its cell (the centre of the line goes on the
cell's centre) and these settings:

| Setting | Type | Meaning |
|---|---|---|
| `units` | `int`, 0 or more | Sprites on each side of the centre |
| `start_angle` | `float`, degrees | Angle of the line at the start. 0 points right |
| `clockwise` | `bool` | Spin direction on screen |

The length snaps by itself: it is set in whole units, and each unit adds
one sprite to **both** ends of the line. A bar has `2 * units + 1` sprites
and reaches `units * 30` px out from the centre on each side.

## Building the line

- The bar's position is the centre (pivot) of the line.
- In `_ready`, it creates one `Sprite2D` per spot, at distances
  `k * 30` for `k` from `-units` to `units`: one on the centre, then every
  30 px out along both halves of the line. The 6 px gaps between the 24 px
  sprites are on purpose.
- Each sprite gets its own 14 × 14 `CollisionShape2D` (see `assets.md`),
  created as a direct child of the bar's `Area2D`, not of the sprite: a
  `CollisionShape2D` only collides as a direct child of a collision object.

## Spinning

- Each update, the angle changes by `deg_to_rad(105.5) * delta`: added if
  `clockwise` (y points down, so a growing angle turns clockwise on screen),
  subtracted if not.
- Each sprite and its collision shape is placed at
  `Vector2.from_angle(angle) * k * 30`.
- **Nothing ever rotates.** Only positions change. No node's `rotation` is
  set, so the sprites always stay upright.

## Body

- One `Area2D` with `collision_layer` = `enemies` and `collision_mask` =
  none: the player
  can detect it, but it never blocks anything. Only the player touches it,
  through the player's contact check (`player-contact.md`).
- It never moves. Only its sprites and collision shapes move around it.

## Guides

- Only while `Level.show_guides` (see Snapshot in `level-layout.md`), it
  draws two things, so the bar can be checked on a snapshot:
  - **The sweep circle:** the outline of everything the bar touches in a
    full turn, radius `units * 30 + 12` (the outer sprites' far edge),
    drawn with the built-in `draw_arc` all the way round. This shows what
    the bar can reach: walls, floors, the player's path.
  - **The starting line:** the line at `start_angle` with the sprite spots
    on it, so the start angle and direction are visible.

## Switching on and off

- Like other enemies, it has a `VisibleOnScreenEnabler2D`. Its `rect`
  covers the whole circle the bar sweeps: a square reaching
  `units * 30 + 12` px from the centre on every side.

## Not stompable

- A bar is **not** stompable (`player-contact.md`). Touching it always hurts the
  player, unless the player is invincible. It never dies.

## Animation

- None. Every spot shows the same single sprite.

## Placing a bar (a note for the level builder)

A bar low enough to cut across the player's way can only be passed if the
part the player passes moves the **same way as the player**. The player
walks at most 101.25 px/s, and a ball 2 units out moves about 110 px/s,
so balls coming toward the player leave no gap to walk through: with a
2-unit bar dipping 19 px below the player's head, walking under it
against its spin fails at every starting moment, while walking with it
gets through from 153 of 180 (simulated, then tested). A deeper bar can't
be passed against its spin at any speed.

So when the level means the player to get past a bar (levels run left to
right):

- **under it:** its bottom must move right: `clockwise = false`.
- **over it** (jumping across its top): its top must move right:
  `clockwise = true`.

A bar turning the other way is a wall to wait out or go around, never the
only way on. The build does not check this (the jump check ignores bars,
`level-layout.md`): check it on a snapshot, where the sweep circle shows
how low and how high the bar reaches.

## Acceptance test

| Case | Expected |
|---|---|
| `units = 0` | One sprite, on the centre |
| `units = 2` | 5 sprites, 30 px apart, the outer ones 60 px from the centre |
| After 1 s, `clockwise = true`, `start_angle = 0` | Line at 105.5° (turned clockwise on screen) |
| After 1 s, `clockwise = false`, `start_angle = 0` | Line at -105.5° |
| Any time | Every sprite's `rotation` is 0 |
| Player touches any sprite | Player is hurt |
| A 2-unit bar whose lowest ball dips 19 px below the head of a player standing 126 px to its left; the player walks right from a standstill, at start angles 0°, 30°, 120° and 150° | `clockwise = false`: passes under unhurt every time; `clockwise = true`: hurt every time |
