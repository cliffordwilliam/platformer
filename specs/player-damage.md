# Player damage

What happens when the player gets hit and when the player dies. Read
`overview.md` first, and `player-movement.md` for the movement this spec
builds on.

## Health

- Health belongs to the **level**, not to the game: the level root has
  `var health := 2`, so every level starts with **2 health**, and nothing
  carries over between levels. A retry after a death reloads the level
  (`game-flow.md`), so it starts with 2 health too.
- Each hit takes away 1 health (`level.health -= 1`).
- The heart in the corner of the screen shows it (`hud.md`).
- A hit that takes the last health is a death (see Death). Any other hit is
  an injury (see Injury).

## Constants

| Name | Value | Unit |
|---|---|---|
| Injury freeze | 0.92 | s |
| Invincibility | 2.8 | s |
| Death freeze | 0.27 | s |
| Death jump start speed | 270 (upward, so `velocity.y = -270`) | px/s |
| Death gravity | 632.84 | px/s² |
| Death maximum falling speed | 227.37 | px/s |

## Freezing the game

This section covers the injury freeze. Death pauses the game differently
(see Death).

- A freeze pauses the whole game with the built-in `get_tree().paused`.
  Everything stops: the player, enemies, physics and gameplay timers.
- The freeze is timed with `get_tree().create_timer(0.92, true, true)`,
  which keeps running while the game is paused (`process_always`, the
  second argument) and counts in game updates (`process_in_physics`, the
  third, `overview.md`). When it ends, `get_tree().paused` goes back to
  false.
- Nodes that must keep running while paused (such as the player death
  scene) say so with the built-in `process_mode`, not with custom code.
- A freeze does not touch the player's sprite, speed or state. The game
  simply stops and then carries on where it was.

## Injury

1. The game freezes for **0.92 s**.
2. When the freeze ends, the game carries on as normal and the player becomes
   **invincible for 2.8 s**, timed with a `Timer` on the player.
3. While invincible, only two things differ from normal: the flicker and
   enemies not hurting the player. Everything else, stomping included,
   works as usual.
   - Enemies cannot hurt the player.
   - Falling off the map still kills the player.
   - The player moves and animates normally.
   - The sprite flickers: it is hidden on every other update, starting with
     it hidden on the first update of invincibility (updates 1, 3, 5...).
     Flip the sprite's built-in `visible` each update.
4. When invincibility ends, the sprite is always visible again.

## Death

Death is played by its own scene, the **player death** scene, so the player
needs no death state.

At the moment of the hit that kills the player:

1. The game is paused with `get_tree().paused`, and stays paused. The
   level is then retried (see After the death jump). The level's music
   stops and the death sound plays (`sound.md`).
2. The player is switched off completely: hidden (`visible = false`) and
   `process_mode = PROCESS_MODE_DISABLED`. It is not freed, so anything
   pointing at it (such as the camera) stays valid.
3. A player death scene is added in the player's place, to the level
   (`level.add_effect()`; a child of a switched-off, hidden node would be switched off and
   hidden too): same global position, same `flip_h`. Its `process_mode` is `PROCESS_MODE_ALWAYS`, so
   it runs while the game is paused.
4. The player's update ends here, whatever caused the death (the death
   line or a hit): nothing after it in this update runs
   (`player-movement.md`, Each update).

The player death scene is a `Node2D` with a `Sprite2D` showing
`res://art/player/sprite_1.png`. When it is added:

1. It stays still for **0.27 s**, timed with
   `get_tree().create_timer(0.27, true, true)` (runs while paused, counts
   in game updates, `overview.md`).
2. Then it does the death jump: its speed is set to `-270` (upward), then
   each update adds death gravity (632.84) and caps the falling speed at 227.37,
   in the same order as `player-movement.md`. It moves straight up and down
   only.
3. It moves by changing `position` directly (`position += velocity * delta`).
   It has no collision shape, so it falls through the floor and off the
   screen. (Physics is stopped while the game is paused, so it could not use
   `move_and_slide()` anyway.)

### After the death jump

Once the death scene's sprite is wholly below the screen (its top,
`position.y - 25`, at or past `Screen.height`; its origin is the player's
feet, 25 px below the image's top, `assets.md`), it switches itself off
and calls `level.on_death()`. The level then closes the iris where the
player died and reloads itself at the respawn point (`game-flow.md`,
Death).

### The death line

Falling off the map also kills the player: when the player's `position.y`
(its feet) reaches the death line, the bottom of the screen
(`position.y >= Screen.height`, 257), the player dies the same way as
above, and `level.health` is set to 0, so the heart shows empty
(`hud.md`). The death line is the same with water: a player who falls into
the water sinks behind it before reaching the line (`level-layout.md`,
Level end, gap line and death line).

## Acceptance test

| Case | Expected |
|---|---|
| Hit with 2 health | Health 1, `get_tree().paused` is true for 0.92 s, then false |
| After the injury freeze | Player invincible for 2.8 s: an enemy touch does not take health |
| During invincibility | Sprite hidden on updates 1, 3, 5..., shown on 2, 4, 6... |
| Invincibility ends | Sprite visible |
| Hit with 1 health | Game paused, player hidden and disabled, player death scene added at the player's position with the same `flip_h` |
| 0.27 s after the killing hit | Death jump starts at -270 px/s, game still paused |
| During the death jump | Death scene passes through the floor |
| Player `position.y` reaches 257 | Player dies, even while invincible |
| Player with 2 health reaches 257 | Dies; health 0, heart empty |
| Level with water, player's feet reach y = 234 (the water's surface) | Still alive, sinking behind the water |
| Level with water, player's feet reach y = 257 | Player dies |
| Death scene's top passes the bottom of the screen | It is switched off and calls `level.on_death()` once |
