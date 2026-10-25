# Walker enemy

Enemies that walk back and forth. Read `overview.md` first, and
`player-movement.md` for the update order this spec reuses.

"Walker" is a working name. There are three kinds. They all walk, turn and
fall exactly the same way, but each reacts to the player differently:

| Kind | Art | Look | When the player lands on it |
|---|---|---|---|
| `PLAIN` (walker A) | `walker_a/` | Small blue robot with a white chevron and grey legs | Flattened (see Stomped) |
| `SHELL` (walker B) | `walker_b/` | Wide blue box robot with a white chevron and grey legs | Becomes a still shell, then a kicked shell, then flattened (see Walker B: the shell) |
| `SPIKED` (walker C) | `walker_c/` | Red robot with a pointed grey hood, which is a spike | Cannot be stomped: the player is hurt (see Walker C: the spike) |

Placed from the level script's `walkers` list. Each `WalkerSpawn`
(`level-layout.md`) gives the walker's cell and its kind:
`WalkerSpawn.new(cell, WalkerSpawn.Kind.SHELL)`. The kind changes how the
level plays, so the level script always chooses it; nothing about a walker
is picked at random.

- **One class per kind**, so the player can tell them apart with `is`
  (`player-contact.md`):
  - `class_name Walker extends WalkingBody`: walker A, and everything all
    three share.
  - `class_name ShellWalker extends Walker`: walker B.
  - `class_name SpikedWalker extends Walker`: walker C. It adds no code of
    its own: the class only exists so the contact check can tell it is not
    stompable, like the crusher.
  - So every walker `is Walker`: they all share the `walkers` layer,
    `level.walker_layer` and the bonk death (`breakable-block.md`).
- **One scene per kind:** `res://enemies/walker_a.tscn` (script `Walker`),
  `walker_b.tscn` (`ShellWalker`) and `walker_c.tscn` (`SpikedWalker`),
  each only a root and its script (`overview.md`, Scenes). The level
  picks the scene by the spawn's kind. Each walker builds its own sprite
  frames, box, origin and enabler `rect` in its `_ready`, from its kind's
  art folder and numbers (`assets.md`); the kind comes from the spawn in
  `setup()`.
- The walker's `setup(level, spawn)` gets the `WalkerSpawn` and takes from
  its kind the flattened sprite (`res://art/walker_a/sprite_3.png`,
  `walker_b/` or `walker_c/`) it hands to its flattened and bonked scenes
  (see Stomped).

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

Walker B adds one of its own:

| Name | Value | Unit |
|---|---|---|
| Kicked shell speed | 202.5 | px/s |

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
  `abs(speed)` one way or the other: 33.75 for a walker (0 for a spring,
  and for a still shell, 202.5 for a kicked shell).
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
  `collision_mask` is `level` and `walkers` (see `overview.md`). A kicked
  shell is the one exception (see Walker B: the shell).

## Facing

- The sprite flips with its built-in `flip_h` to face the way the walker
  walks.
- **The walker art faces left** (all three kinds), so `flip_h` is true
  while walking right. A walker starts walking left, with `flip_h` false.
- A still shell (speed 0) keeps the facing it had.

## Landing *(WalkingBody)*

- When it lands, `move_and_slide()` sets the vertical speed to 0 and the
  walker keeps walking in the same direction. No extra code is needed.

## Switching on and off *(WalkingBody)*

- Each walker has a built-in `VisibleOnScreenEnabler2D` that targets it.
  The walker is switched off (`PROCESS_MODE_DISABLED`) whenever the
  enabler's area is off screen, and switched on while it is on screen.
- Walkers start switched off and start walking when they come on screen.
  A walker placed above the screen (on a negative row) would never come
  on screen, so the layout check forbids it (`level-layout.md`, Checking
  the layout).
- Because the camera only moves right and never up or down (see
  `camera.md`), a walker that leaves the screen to the left or falls below
  it can never come back. It simply stays switched off. Walkers are never
  freed.
- A kicked shell that runs off the right of the screen is switched off
  there and carries on when the camera reaches it.
- Switched off, a walker is also out of the physics simulation (the
  default `disable_mode` of `DISABLE_MODE_REMOVE`), so nothing can bump into
  it.
- The enabler's `rect` is exactly the size of the walker's sprite (each
  kind sets its own), so a walker starts the moment any part of it
  reaches the edge of the screen. The built-in default `rect` is not the
  walker's size, so it must be set.

## Stomped

Walker A is stompable (see `player-contact.md`), and so is walker B in
every state; walker C is not. When a walker is flattened (`stomp()` on
walker A, or on a kicked walker B):

1. The walker switches itself off and hides
   (`process_mode = PROCESS_MODE_DISABLED`, `visible = false`).
2. It adds a **walker flattened** scene to the level (`level.add_effect()`),
   at the same position
   and with the same `flip_h`, showing its kind's own `res://art/walker_*/sprite_3.png` (each
   kind has its own flattened sprite).

The walker flattened scene is a `Node2D` with a `Sprite2D` and a `Squash`
helper for it (`squash.md`). When added, its sprite plays
`play_squish(...)`, and when the squish ends (after **0.7 s**) the scene
hides itself (`visible = false`) and switches itself off. It needs no
`Timer`: the squish tween's end is the signal. It is never freed. It pauses
during the injury freeze like the rest of the game (the default
`process_mode`).

## Walker B: the shell

Walker B has three states, `enum State { WALK, STILL, KICKED }`, starting
in `WALK`. Each stomp moves it on one state:

| State | Moves | Shows | Hurts the player | Stomped |
|---|---|---|---|---|
| `WALK` | Walks like walker A, 33.75 | Walk animation | Yes, like any walker | Becomes `STILL` |
| `STILL` | `speed = 0`: stays put, still falls | `sprite_3.png` | No | Becomes `KICKED` |
| `KICKED` | `speed = ±202.5`: walks like a walker, 6 times faster | `sprite_3.png` | No | Flattened (see Stomped) |

- **A shell never hurts the player**, still or kicked. The player passes
  through it from any side; only landing on it (a stomp) does anything.
  The player's stomp bounce works as on any walker.
- **`stomp()` in `WALK`:** `state = STILL`, `speed = 0`, and the sprite
  shows `res://art/walker_b/sprite_3.png` (the `AnimatedSprite2D` plays a
  second animation, `"shell"`, with that one frame). The box stays the
  same: `sprite_3.png` fills exactly the same 24 × 20 box as the walk
  frames (tested on the image: its drawn pixels are x 1, y 3, 24 × 20).
- **`stomp()` in `STILL`:** `state = KICKED`, and it is kicked away from
  the player: `speed = -202.5` if `level.player.position.x` is greater
  than its own `position.x`, else `202.5`. So the player on its left or
  right at the same x kicks it to the right.
- **`stomp()` in `KICKED`:** flattened like walker A (see Stomped).
- **A still shell never wakes up.** It stays still until it is kicked,
  bonked or switched off.
- **A kicked shell** is a walker at 202.5 px/s: the same gravity and
  falling cap, it turns at walls (`speed = -speed`, as in Walls) and falls
  off ledges. It keeps showing `sprite_3.png`, facing the way it moves.
- **Knocking out walkers:** while kicked, its `collision_mask` is `level`
  only, so it passes through walkers instead of turning at them; its
  `collision_layer` stays `walkers`, so the player's contact area still
  finds it. Each update, right after it moves, every other walker in
  `level.walker_layer` that is switched on (`can_process()`) and whose box
  overlaps its own (`Rect2.intersects()`, the boxes read as in
  `breakable-block.md`, Cells under and over a box) dies by bonk
  (`breakable-block.md`, Walker bonk death). Any kind, in any state, a
  still or kicked shell too. The kicked shell keeps going.
- Walkers that are not kicked still bump into a still shell and turn
  around, like into any walker.
- Bonked from below by a block (`breakable-block.md`), walker B dies by
  bonk in any state: it never turns into a shell that way.

## Walker C: the spike

- Its grey hood is a spike, so it cannot be stomped: a player landing on
  it is hurt, exactly as if it had walked into it (`player-contact.md`).
  `SpikedWalker` has no `stomp()` of its own and is never sent one.
- Everything else is walker A's: it walks, turns and falls the same, bumps
  into walkers, and dies by bonk when a block is hit under it.

## Animation

- **Walk:** `res://art/walker_*/sprite_1.png` and `res://art/walker_*/sprite_2.png`, looping, all the time while switched on (walker B: only in `WALK`).
- Shown with an `AnimatedSprite2D`. Each sprite shows for 0.133 s, so the
  animation runs at **7.5 frames per second** (1 / 7.5 = 0.1333 s, which is
  8 updates at 60 per second). It loops and plays from the start.
- It is a child of the enemy, so it stops whenever the enemy is switched off
  or the game is paused, and carries on afterwards.
- `res://art/walker_*/sprite_3.png` is for the flattened scene (see
  Stomped), the bonked scene (`breakable-block.md`, Walker bonk death),
  and walker B's shell.

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
| Just placed, walking left | `flip_h` is false |
| Walking right | `flip_h` is true |
| Off screen | Walker does not move |
| Comes on screen | Walker starts walking left |
| Falls below the screen | Walker is switched off |
| `Kind.PLAIN`, `Kind.SHELL`, `Kind.SPIKED` | `Walker`, `ShellWalker`, `SpikedWalker` from `walker_a.tscn`, `walker_b.tscn`, `walker_c.tscn`; every one `is Walker` |
| Walker A stomped | Walker switched off and hidden; flattened scene shows `res://art/walker_a/sprite_3.png` at the same position and facing |
| 0.7 s after the stomp | Flattened scene is hidden |
| Walker B stomped while walking | Stays switched on and visible, `speed == 0`, shows `sprite_3.png`; no flattened scene |
| Still shell, many updates later | Has not moved |
| Still shell on a ledge's edge with the floor broken under it | Falls straight down |
| Player walks into a still or kicked shell from the side, or jumps up into it | Not hurt; passes through |
| Still shell stomped, player left of it | `velocity.x == 202.5` on the next update |
| Still shell stomped, player right of it | `velocity.x == -202.5` on the next update |
| Still shell stomped, player at exactly its x | Kicked to the right |
| Kicked shell hits a wall | Turns around at 202.5 |
| Kicked shell walks off a ledge | Falls, `velocity.y` capped at 202.5, still 202.5 sideways |
| Kicked shell stomped | Switched off and hidden; flattened scene with `res://art/walker_b/sprite_3.png` |
| Kicked shell runs into a walker A, a walker C or another shell | That walker dies by bonk; the kicked shell keeps its speed |
| Walker A walks into a still shell | Walker A turns around; the shell stays put |
| Walker B bonked from below by a block, in any state | Dies by bonk |
| Player lands on walker C | Player hurt (unless invincible), no bounce; walker C keeps walking |
