# Player movement

How the player character moves. Read `overview.md` first for the shared
rules (60 updates per second, y axis down, units, no slopes).

The character only idles, walks, rises (from a jump, a stomp bounce or a spring), falls and climbs ladders. It is a `CharacterBody2D`
moved with `move_and_slide`, with no `collision_layer` and
`collision_mask` = `level` (`overview.md`). The level keeps it as
`level.player`.

## Constants

| Name | Value | Unit |
|---|---|---|
| Walking top speed | 101.25 | px/s |
| Walking acceleration | 150.3 | px/s² |
| Jump start speed | 297 (upward, so `velocity.y = -297`) | px/s |
| Light gravity | 550.54 | px/s² |
| Heavy gravity | 1923.75 | px/s² |
| Maximum falling speed | 270 | px/s |
| Climbing speed | 67.5 (upward, so `velocity.y = -67.5`) | px/s |

These are `const`s on `Player`, so the level's jump check can read them
before any player is built (`level-layout.md`, Jump check).

## Each update

Every update runs these steps in this order:

1. **Get input.** Read the direction, whether jump is held and whether up
   is held (see `controls.md`).
2. **Derive velocity.**
   1. Horizontal speed (see Walking).
   2. Gravity (see Gravity).
   3. Jump (see Jumping). This comes after gravity so a jump overwrites the
      vertical speed and is never swallowed by gravity.
   4. Climb (see Climbing). This comes last, so climbing overwrites both
      gravity and a jump.
3. **Move.** Call `move_and_slide()`. While climbing, then keep the feet
   no higher than the ladder's top (see Climbing).
4. **Clamp to the screen edges** (`camera.md`, Each update).
5. **Decide the state** from the collision results (see States).
6. **Check the death line** (`player-damage.md`).
7. **Check the win:** the flag (`flag.md`) or a door (`door.md`).
8. **Check contact:** blocks, then pickups, then enemies, then springs,
   then checkpoints (`player-contact.md`).

Dying and winning both pause the game and end the update on the spot, so
nothing after them runs. That holds for every death: on the death line
(step 6), or from a hit that takes the last health in the contact check
(step 8, `player-contact.md`, The rule), which then skips the contact
steps after it. So falling past the death line beats reaching the flag,
reaching the flag beats any contact (a player who wins while touching an
enemy wins and is not hurt), and a player killed by an enemy is never
launched by a spring or raises a checkpoint in the same update.

## Walking

- The target speed is `+101.25` when only right is held, `-101.25` when
  only left is held, and `0` when neither (or both) is held.
- Each update, the horizontal speed moves toward the target with
  `move_toward(velocity.x, target, 150.3 * delta)`. It stops exactly on the
  target and never overshoots it.
- The same step is used to speed up, to slow down after letting go, and to
  turn around. Turning around walks the speed down through zero and up the
  other side.
- This works the same in the air, so the character can steer and slow down
  mid-jump.

## Gravity

- Gravity is added every update, including while standing on the floor.
  The collision in `move_and_slide()` cancels it there.
- **Light gravity** (550.54) applies while the character is in the Rise
  state (rising from a jump) and jump is held, and always in the Spring
  state, held or not (`spring.md`). It never applies in Bounce.
- **Heavy gravity** (1923.75) applies at every other time.
- After adding gravity, the falling speed is capped: `velocity.y` is never
  above `270`. Upward speed has no cap.
- On the first update after Climb that is not climbing, `velocity.y` is set
  to 0 before gravity is added, so letting go of a ladder never carries
  the climb's upward speed: the player simply falls.

## Jumping

- A jump starts on any update where jump is **held** and the character is
  on the floor. `is_on_floor()` here gives the result of the previous
  update's `move_and_slide()`.
- No jump starts in the Spring state: a spring launch from the ground
  still reads as "on the floor" on the next update, and a jump there would
  overwrite the launch.
- A jump sets `velocity.y` straight to `-297`, replacing whatever gravity
  just did.
- Holding jump through a landing jumps again right away. This is intended:
  it replaces any jump buffer. There is also no coyote time: walking off a
  ledge and pressing jump in the air does nothing.
- Letting go of jump early only switches to heavy gravity. It does not cut
  the vertical speed.

## Climbing

Ladders are in `ladder.md`; this is the player's side.

- **On a ladder:** `level.ladder_at()` is true for the cell under the
  point 1 px above the feet (`position + Vector2(0, -1)`).
- **Climbing** this update: up is held and the player is on a ladder, in
  any state. Then `velocity.y` is set straight to `-67.5`, replacing
  whatever gravity and a jump just did.
- **The top:** before moving, if the ladder cell the player is on has no
  ladder cell above it, the limit is that cell's top (`cell.y *
  Grid.TILE`). Right after `move_and_slide()`, while climbing,
  `position.y = maxf(position.y, limit)`: the feet stop exactly on top of
  the ladder's cap. On the next update the point above the feet is no
  longer in a ladder cell, so climbing ends and the player lands on the
  cap's one-way top.
- Walking sideways works as normal while climbing; leaving the ladder's
  column ends climbing.
- A climbing player is not on the floor, so it cannot jump. At the
  bottom, on the ground, holding up and jump together climbs.

## Collisions

- Hitting a floor, wall or ceiling sets the speed going into it to zero.
  For floors and ceilings `move_and_slide()` does this by itself.
- **Walls need one line:** while the player keeps pushing into a wall,
  `move_and_slide()` does not zero `velocity.x` on every update. It
  creeps up (2.5 px/s, 5, 7.5...) between the updates that register the
  collision (tested on 4.7.2), so the state would flip between Walk and
  Idle and the wall bounce (`squash.md`) would replay every few updates.
  So right after `move_and_slide()`: if `is_on_wall()` and `velocity.x`
  points into the wall (`velocity.x * get_wall_normal().x < 0`),
  `velocity.x = 0`. Pushing into a wall is then Idle on every update.

## States

Decided after `move_and_slide()`:

| State | When |
|---|---|
| Climb | Climbing this update (see Climbing), checked first: on the floor or not |
| Idle | On the floor and `velocity.x == 0` |
| Walk | On the floor and `velocity.x != 0` |
| Rise | Not on the floor and `velocity.y < 0`, after a jump |
| Bounce | Not on the floor and `velocity.y < 0`, after a stomp (see `player-contact.md`) |
| Spring | Not on the floor and `velocity.y < 0`, after a spring launch (see `spring.md`) |
| Fall | Not on the floor and `velocity.y >= 0` (this includes right after hitting a ceiling) |

Rise, Bounce and Spring all rise. The only difference is gravity: Bounce
always uses heavy gravity, Spring always light gravity, and Rise light
gravity only while jump is held. The player can only stomp while in Fall
(see `player-contact.md`), so Bounce always starts from Fall. A spring
launches the player from any state, and the update right after a launch
from the ground is still Spring. Climb takes over from any state, Spring
and Bounce included, on every update that up is held on a ladder; it uses
no gravity at all.

## Facing

- Facing is shown with the sprite's `flip_h`. **The player art faces
  left**, so `flip_h` is true while facing right. The character starts
  facing right (`flip_h` true).
- Facing follows the held direction, on the update it is pressed, even while
  `velocity.x` is still slowing down from the other way.
- When no direction is held (or both are), it keeps its last facing.

## Acceptance test

Write this test before the movement code. It runs in the test runner
(`overview.md`, Tests) at 60 updates per second, on flat ground with nothing above the character. Passing it is
the definition of done for this spec: the numbers come from the user's own
tuning of the game feel.

| Case | Expected |
|---|---|
| Standing still, then right held | `velocity.x` is below 101.25 after 40 updates and exactly 101.25 after 41 |
| Jump held from the start until landing | Peak height 82.6 px above the start, back on the floor after 56 updates |
| Jump held for exactly 1 update, then released | Peak height 25.45 px above the start, back on the floor after 20 updates |
| Walking into a wall and holding the direction | `velocity.x` is 0 after every update; state Idle on every update; the wall bounce plays once |
| Start; right held; left held | `flip_h` true; true; false |
| Up held at the bottom of a 4-cell ladder | Climbs at 67.5 px/s; the feet stop exactly on the ladder's top, then Idle, standing there with up still held |

- Update counts start with the update on which the jump starts and must
  match exactly.
- Peak heights must match within 1 px either way.
