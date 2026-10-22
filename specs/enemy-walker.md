# Walker enemy

An enemy that walks back and forth. Read `overview.md` first, and
`player-movement.md` for the update order this spec reuses.

"Walker" is a working name. There are three variants. They share exactly the
same logic and differ only in their sprite and size (each has its own
collision shape to match its sprite):

| Variant | Look |
|---|---|
| `A` (`walker_a/`) | Small blue robot with a white chevron and grey legs |
| `B` (`walker_b/`) | Wide blue box robot with a white chevron and grey legs |
| `C` (`walker_c/`) | Red robot with a pointed grey hood |

Placed from the level script's `walkers` list. Each `WalkerSpawn`
(`level-layout.md`) gives the walker's cell and variant.

- **One scene per variant:** `res://enemies/walker_a.tscn`,
  `walker_b.tscn` and `walker_c.tscn`, each with its own sprite frames,
  box, origin and enabler `rect` (`assets.md`), all three using the one
  `Walker` script. The level picks the scene by the spawn's variant.
- The walker's `setup(level, spawn)` gets the `WalkerSpawn` too, and
  takes from its variant the flattened sprite
  (`res://art/walker_*/sprite_3.png`) it hands to its flattened and bonked
  scenes (see Stomped).

Each walker is a `CharacterBody2D` moved with `move_and_slide()`, so the
same "no slopes" rule from `overview.md` applies.

## WalkingBody: shared with the diamond and the spring

The walker, the diamond (`diamond.md`) and the spring (`spring.md`) walk
and fall exactly the same way, so the walking lives in one base class:

- `@abstract class_name WalkingBody extends CharacterBody2D`. `Walker`,
  `Diamond` and `Spring` extend it.
- **In `WalkingBody`** (the sections marked *(WalkingBody)* below): the
  constants, the update order, walking, turning at walls, landing,
  switching on and off, and the squash and stretch calls (`squash.md`).
- **Each kind adds** its starting `speed`, set in its `setup()` (walker
  `-33.75`, walking left; diamond `33.75`, walking right; spring `0`, never
  walking), its collision layers, its sprite and its enabler's `rect`, and
  everything else in its own spec.

## Constants *(WalkingBody)*

| Name | Value | Unit |
|---|---|---|
| Walking speed | 33.75 | px/s |
| Gravity | 965.04 | px/s² |
| Maximum falling speed | 202.5 | px/s |

## Each update *(WalkingBody)*

The same order as the player, without input:

1. **Derive velocity.** Set `velocity.x = speed` (see Walls). Add gravity (every update, even on the floor, as
   with the player), then cap the falling speed: `velocity.y` is never above
   202.5.
2. **Move.** Call `move_and_slide()`.
3. **React to collisions** (see Walls and Landing).

## Walking *(WalkingBody)*

- A walker starts walking **left**: `speed = -33.75`, set in its `setup()`.
- It never speeds up or slows down. Horizontal speed is always exactly
  33.75 one way or the other (0 for a spring).
- It does not turn at ledges. It walks off them and falls.
- It keeps walking sideways at the same speed while falling.

## Walls *(WalkingBody)*

- The walker keeps its own `speed` variable, starting at `-33.75`. Each
  update, `velocity.x = speed` before `move_and_slide()`.
- When `is_on_wall()` is true after `move_and_slide()`, the walker turns
  around: `speed = -speed`.
  - Flip `speed`, not `velocity.x`: `move_and_slide()` changes `velocity`
    when it collides, so `velocity.x` may already be 0 after hitting a wall.
- This also works in the air.
- Another walker counts as a wall: walkers that bump into each other both
  turn around. This part is the walker's own, through its layers: a
  walker's `collision_layer` is `walkers` and its
  `collision_mask` is `level` and `walkers` (see `overview.md`).

## Facing

- The sprite flips with its built-in `flip_h` to face the way the walker
  walks.
- The sprite art faces right, so `flip_h` is true while walking left. A
  walker starts with `flip_h` true.

## Landing *(WalkingBody)*

- When it lands, `move_and_slide()` sets the vertical speed to 0 and the
  walker keeps walking in the same direction. No extra code is needed.

## Switching on and off *(WalkingBody)*

- Each walker has a built-in `VisibleOnScreenEnabler2D` that targets it.
  The walker is switched off (`PROCESS_MODE_DISABLED`) whenever the
  enabler's area is off screen, and switched on while it is on screen.
- Walkers start switched off and start walking when they come on screen.
- Because the camera only moves right and never up or down (see
  `camera.md`), a walker that leaves the screen to the left or falls below
  it can never come back. It simply stays switched off. Walkers are never
  freed.
- Switched off, a walker is also out of the physics simulation (the
  default `disable_mode` of `DISABLE_MODE_REMOVE`), so nothing can bump into
  it.
- The enabler's `rect` is exactly the size of the walker's sprite (each
  variant sets its own), so a walker starts the moment any part of it
  reaches the edge of the screen. The built-in default `rect` is not the
  walker's size, so it must be set.

## Stomped

Walkers are stompable (see `player-contact.md`).
When stomped (`stomp()`):

1. The walker switches itself off and hides
   (`process_mode = PROCESS_MODE_DISABLED`, `visible = false`).
2. It adds a **walker flattened** scene to the level (`level.add_effect()`),
   at the same position
   and with the same `flip_h`, showing the variant's own `res://art/walker_*/sprite_3.png` (each
   variant has its own flattened sprite).

The walker flattened scene is a `Node2D` with a `Sprite2D` that uses the
squash script (`squash.md`). When added, its sprite plays
`play_squish(...)`, and when the squish ends (after **0.7 s**) the scene
hides itself (`visible = false`) and switches itself off. It needs no
`Timer`: the squish tween's end is the signal. It is never freed. It pauses
during the injury freeze like the rest of the game (the default
`process_mode`).

## Animation

- **Walk:** `res://art/walker_*/sprite_1.png` and `res://art/walker_*/sprite_2.png`, looping, all the time while switched on.
- Shown with an `AnimatedSprite2D`. Each sprite shows for 0.133 s, so the
  animation runs at **7.5 frames per second** (1 / 7.5 = 0.1333 s, which is
  8 updates at 60 per second). It loops and plays from the start.
- It is a child of the enemy, so it stops whenever the enemy is switched off
  or the game is paused, and carries on afterwards.
- `res://art/walker_*/sprite_3.png` is only for the flattened scene (see
  Stomped) and the bonked scene (`breakable-block.md`, Walker bonk death).

## Acceptance test

| Case | Expected |
|---|---|
| Just placed on flat ground | `velocity.x == -33.75`, `velocity.y == 0` after landing |
| Walks into a wall on its left | `velocity.x == 33.75` on the next update |
| Walks into a wall on its right | `velocity.x == -33.75` on the next update |
| Walks off a ledge | Keeps `abs(velocity.x) == 33.75`; `velocity.y` reaches 202.5 on the 13th update that ends off the floor, and never goes above it |
| Hits a wall while falling | Turns around, still falling |
| Lands | `velocity.y == 0`, same walking direction |
| Two walkers walk into each other | Both turn around |
| Just placed, walking left | `flip_h` is true |
| Walking right | `flip_h` is false |
| Off screen | Walker does not move |
| Comes on screen | Walker starts walking left |
| Falls below the screen | Walker is switched off |
| Stomped | Walker switched off and hidden; flattened scene shows `res://art/walker_*/sprite_3.png` at the same position and facing |
| 0.7 s after the stomp | Flattened scene is hidden |
