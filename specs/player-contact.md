# Player contact

What happens when the player touches something: a block over its head, a
pickup (coin or diamond), an enemy or a spring. The player checks all of it itself,
in one place, in a fixed order, right after it moves. Nothing reacts to the
player on its own: no `body_entered` signals anywhere. Read `overview.md`,
`player-movement.md` and `player-damage.md` first.

Stompable enemies are the walkers (`enemy-walker.md`), the flyers
(`enemy-flyer.md`) and the leapers (`enemy-leaper.md`). The player checks
this by class, in this one place:
`enemy is Walker or enemy is Flyer or enemy is Leaper`. The crusher (`enemy-crusher.md`) and the bar
(`enemy-bar.md`) cannot be stomped.

## Constants

| Name | Value | Unit |
|---|---|---|
| Stomp bounce speed | 227.37 (upward, so `velocity.y = -227.37`) | px/s |

## One place, one order

Every update, after the player has moved, its state has been decided, and
it has neither died on the death line nor won (`player-movement.md`, Each
update; those come first, so a win beats any contact), it checks, in this
order:

1. **Blocks:** if `is_on_ceiling()` and it is not in Climb, it bonks every
   block over its head (`breakable-block.md`, Hitting a block).
2. **Pickups:** every overlapping coin and diamond is collected (see
   Pickups).
3. **Enemies:** stomps and hurts (see The rule).
4. **Springs:** launches (see Springs).

The order is a game design decision, not left to when Godot happens to
fire signals. Pickups come before enemies, so a player with 1 health who
touches a diamond and an enemy in the same update heals to 2 first, then
is hurt to 1, and survives. Springs come last, so a player who lands on an
enemy and a spring in the same update stomps the enemy and is then
launched by the spring: the spring's launch wins over the stomp's bounce.

## Bodies do not block each other

- The player and enemies pass through each other. Neither is in the
  other's `collision_mask`, so `move_and_slide()` never treats an enemy as
  a floor or wall.
- Touching is found with an `Area2D` on the player, with no
  `collision_layer` and a `collision_mask` of the `walkers`, `enemies`,
  `pickups`, `springs` and `doors` layers (see `overview.md`). Doors are
  read from the same list, but in the win step, before any contact
  (`door.md`). Its `CollisionShape2D` uses the **same**
  `RectangleShape2D` resource as the player's body, so the two can never
  differ (see `assets.md`).
- Enemies come in two kinds of node:
  - Enemies that land on floors and turn at walls (walker, crusher) are
    `CharacterBody2D`s, because they need `move_and_slide()`.
  - Enemies that collide with nothing (flyer, leaper, bar) are `Area2D`s,
    Godot's built-in node for "detect, but never block".
- Pickups are `Area2D`s too: a coin, and the diamond's pickup area (a
  child of the diamond's body).
- A spring is a `CharacterBody2D`, like a walker, because it falls and
  stacks (`spring.md`).

## Checking contact

- Every update, in steps 2 to 4 above, the player reads both
  `get_overlapping_bodies()` and `get_overlapping_areas()` on its area, as
  one list of everything it touches, and tells them apart by class with
  `is`.
- Use this list every update, not `body_entered` signals (on the player,
  the enemies or the pickups):
  - A signal only fires once on entry, so an enemy still overlapping when
    invincibility ends would never hurt the player.
  - With one signal per enemy, the first stomp would set the player moving
    up before the next enemy's signal is handled, so landing on two enemies
    would stomp one and hurt the player. Checking all overlaps in one place
    avoids this.
  - The list is updated once per physics step, so it can be one update
    behind. That is fine.
  - Everything here runs in the player's `_physics_process`, not inside a
    physics signal, so things can switch themselves off straight away, with
    no `set_deferred`.

## Pickups

- `area is Coin`: the player calls the coin's `collect()` (`coins.md`).
- `area.get_parent() is Diamond`: the player calls the diamond's
  `collect()` (`diamond.md`).
- Collected in any state, in the air, and while invincible. Not by a dead
  player: it is switched off, so it no longer checks anything.

## Springs

- `body is Spring`: unless the player is already in the **Spring** state,
  the player calls the spring's `launch()` (`spring.md`). Touching several
  springs at once launches once.
- The Spring-state check stops a spring still overlapping the player on
  the next updates (the list can be one update behind) from launching it
  again and again.
- Launched in any other state, in the air, and while invincible. Not by a
  dead player.

## The rule

The player can only stomp while in the **Fall** state (see
`player-movement.md`). The contact check runs after the state for this
update has been decided, and the state is read once, before any stomp in
this update switches the player to Bounce.

For the enemies overlapping the player in this update (step 3):

1. If the player is in Fall, every overlapping **stompable** enemy is
   stomped. So landing on any number of them at once stomps all of them.
2. The **player** is hurt (see `player-damage.md`), unless invincible, if
   any overlapping enemy was not stomped: a stompable one while the player
   was not in Fall, or any non-stompable one.

The player is hurt at most once per update, however many enemies cause it.
Landing on a walker while touching a crusher stomps the walker *and* hurts
the player.

Stomping works while the player is invincible too.

## Stomp: the player

- The player's `velocity.y` is set straight to `-227.37`.
- The player enters the **Bounce** state (see `player-movement.md`): it
  rises with heavy gravity only, even if jump is held.

## Stomp: the enemy

- The player calls the enemy's `stomp()` method. What happens next is up to
  each enemy's own spec.
- Every enemy uses the same pattern as the player's death: it switches
  itself off and hides (`process_mode = PROCESS_MODE_DISABLED`,
  `visible = false`), and adds its own death scene in its place. Switched
  off, it is out of physics, so it cannot be touched again.
- The death scene is added to the level (`level.add_effect()`), not as a
  child of the enemy: a child of a switched-off, hidden node would be switched off and
  hidden too.

## Acceptance test

| Case | Expected |
|---|---|
| Player falls onto a walker | Walker is switched off and hidden, its death scene appears in its place; player `velocity.y == -227.37`, state Bounce |
| Player walks into a walker on the floor | Player is hurt (health goes down by 1) |
| Player rises into a walker from below | Player is hurt |
| Player stays overlapping a walker until invincibility ends | Player is hurt again |
| Player falls onto two walkers at once | Both are flattened |
| Player in Idle, Walk, Rise, Bounce, Spring or Climb overlapping a walker | Player is hurt |
| Invincible player falls onto a walker | Walker is flattened |
| Invincible player walks into a walker | Nothing happens |
| Player falls onto a crusher | Player is hurt |
| Player falls onto a walker while touching a crusher | Walker is flattened, player bounces and is hurt |
| Player touches a coin | Coin hidden and switched off, in the player's contact check |
| Player with 1 health touches a diamond and a crusher in the same update | Healed to 2, then hurt to 1: survives |
| Player falls onto a walker and a coin in the same update | Coin collected and walker stomped |
| Coins and diamonds | Have no `body_entered` connection |
| Player reaches the flag's x while touching an enemy | Won; not hurt |
| Player falls onto a walker and a spring in the same update | Walker stomped, then launched: `velocity.y == -445.5`, state Spring |
| Player touches a spring while already in Spring | Not launched again |
