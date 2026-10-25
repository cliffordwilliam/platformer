# Game flow

The title screen, the order of the levels, the iris that opens and closes
on the player, and what follows a win or a death. Read `overview.md`,
`level-layout.md`, `flag.md` and `player-damage.md` first.

## Scenes in a line

Every scene points forward to exactly one next scene:

```
title  →  level 1  →  level 2  →  …  →  last level  →  title
             ↺ death: the same level again
```

- **The title screen** is its own scene, `res://title.tscn`, and the
  project's main scene (`application/run/main_scene`).
- **After a won level** comes `res://levels/level_<n + 1>.tscn` if that
  file exists (`ResourceLoader.exists(path)`), otherwise the title screen.
  So adding a level is adding its files: nothing else lists the levels.
- The level reads its own number from the built-in `scene_file_path`
  (`"res://levels/level_3.tscn"`):
  `scene_file_path.get_file().get_basename().trim_prefix("level_").to_int()`.
- **After a death** comes the same level again, reloaded fresh with the
  built-in `get_tree().reload_current_scene()`. Unlimited retries: there
  are no lives and no game over.
- Scenes change with the built-in `get_tree().change_scene_to_file()`.
  Tested on 4.7.2: both work while the game is paused, and the new scene
  starts still paused. Neither may be called from inside a `_ready` ("Parent
  node is busy adding/removing children"); here they only run after the
  iris has closed, never in a `_ready`.

## The title screen

- `res://title.tscn`: a `Node2D` root with the script `res://title.gd`,
  which builds its children in its `_ready`, like a level:
  - a black `ColorRect` filling the screen (`Screen.width` ×
    `Screen.height`)
  - a white `Label`, the same size, with the text `Press space to play`,
    centred both ways (`horizontal_alignment` and `vertical_alignment`
    set to centre), in the default font (`ThemeDB.fallback_font`) at size
    16 (`add_theme_font_size_override("font_size", 16)`)
  - a `Music` player playing `adventure_begin.ogg`, looping, and a player for the
    start sound (`sound.md`)
- **It never pauses:** its root's `process_mode` is
  `PROCESS_MODE_ALWAYS`, set in its `_ready`. The game arrives here
  paused, from a won last level, and the pause carries over to the new
  scene (see above). Running always, it needs no code to unpause.
- Each update (`_physics_process`), when
  `Input.is_action_just_pressed("jump")` (space, `controls.md`), it stops
  the music, plays the start sound and waits for it to end, then changes
  to `res://levels/level_1.tscn` (`sound.md`, Game flow with sound). Once
  space has been pressed, pressing it again does nothing.
- Holding space through the start of level 1 is fine: the player may jump
  as soon as the iris has opened.

## The scene being played

- The level root has a read-only property (a GDScript getter),
  `is_main`: `get_tree().current_scene == self`. It is true when the
  level is the scene the game is playing, and false when it is a child of
  the test runner (`overview.md`, Tests) or of the snapshot
  (`level-layout.md`, Snapshot).
- Only when `is_main` is true does the level build the iris, pause itself
  at the start, and close the iris and change scene after a win or a
  death. Otherwise a win or a death only pauses the game, as before, so
  tests and snapshots are not covered in black or swapped out.

## The iris

A box iris: four black rectangles that open out from the player, or close
in on it. Four rectangles are simpler than masking the screen with a
circle, and need no shader.

- `class_name Iris extends CanvasLayer`, built by the level root (child
  20, after the HUD, `level-layout.md`, Building) only while `is_main`,
  and kept as `level.iris`. Like everything the level builds, it gets
  `setup(level)`.
- **`layer = 2`**, so it is drawn in front of the HUD (layer 1,
  `hud.md`) and the whole level.
- **`process_mode = PROCESS_MODE_ALWAYS`**: it runs while the game is
  paused, which is whenever it plays. Its tweens are made with its own
  `create_tween()`, so they follow its `process_mode` and keep running
  while paused, and its wait is `get_tree().create_timer(1.0, true, true)`
  (runs while paused, counts in game updates). Tested on 4.7.2: both run
  while the game is paused, and a paused level that awaits them resumes
  and can unpause the game.
- **Four `ColorRect`s**, black, each exactly the size of the screen,
  `Screen.width` × `Screen.height` (written W × H below), named `Top`,
  `Right`, `Bottom` and `Left`, built in its `_ready`.
- **The target** is the player's middle on the screen: its origin (its
  feet) moved up by half its box's height (15 / 2 = 7.5 px, `assets.md`),
  less the camera's left edge, so in screen pixels:
  `T = level.player.position + Vector2(-level.camera.left_edge, -7.5)`.
  It always targets the player, so the level never passes it in.

| Rectangle | Shut on the target (its position) | Open (its position) |
|---|---|---|
| `Top` | bottom side on the target's y: `(0, T.y - H)` | bottom side on the screen's top: `(0, -H)` |
| `Right` | left side on the target's x: `(T.x, 0)` | left side on the screen's right: `(W, 0)` |
| `Bottom` | top side on the target's y: `(0, T.y)` | top side on the screen's bottom: `(0, H)` |
| `Left` | right side on the target's x: `(T.x - W, 0)` | right side on the screen's left: `(-W, 0)` |

Shut, the four cover the whole screen between them. As they open, the
part of the screen none of them covers is a box around the target that
grows until it is the whole screen:

```
    shut              opening               open
████████████      ████████████
████████████      ███┌─────┐██         (all four rectangles
█████T██████  →   ███│  T  │██    →     off the screen)
████████████      ███└─────┘██
████████████      ████████████
```

- **`open()`**, a coroutine (`await level.iris.open()`):
  1. puts the four rectangles shut on the target
  2. waits **1 s**, so the screen stays black a moment before every open
  3. moves all four to their open positions in **0.5 s**, together (one
     tween, `set_parallel()`, the default linear motion,
     `set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)`, `overview.md`), and
     returns when the tween ends
- **`close()`**, a coroutine (`await level.iris.close()`): puts the four
  rectangles open, then moves all four shut on the target in **0.5 s**,
  the same way, and returns when the tween ends. No wait first.
- Each side moves its own distance in the same 0.5 s, so all four arrive
  together and the box shrinks or grows onto the target.

## Starting a level

At the end of its `_ready` (`level-layout.md`, Building, step 5), only
while `is_main`:

1. `get_tree().paused = true`: nothing moves while the screen is black
   and the iris opens. The level's music starts here (`sound.md`, Music)
   and keeps playing through the pause.
2. `await iris.open()`: 1 s of black, then 0.5 s of opening on the player.
3. `get_tree().paused = false`: play starts.

This runs at every start: after the title screen, after a won level and
after every death. The start goes in its own function, called from
`_ready` without `await`, so `_ready` itself returns at once.

## Winning

At the flag or a door, the player pauses the game (`flag.md`, On winning)
and calls `level.on_win()`:

1. `Level.respawn_cell = PLAYER_CELL` (`checkpoint.md`), always, so the
   next level starts at its own start floor.
2. Only while `is_main`: stops the level's `Music` and
   `await sounds.play_and_wait(Sounds.Effect.WIN)`: the whole win sound
   plays before anything else happens (`sound.md`).
3. Only while `is_main`: `await iris.close()`: the iris closes on the
   player, frozen where it won.
4. Only while `is_main`: changes to the next scene (see Scenes in a line):
   the next level, which starts as above (1 s of black, then the iris
   opens), or the title screen after the last level.

## Death

When the player dies, the death scene does its death jump
(`player-damage.md`), and once it has fallen off the bottom of the screen
it calls `level.on_death()`:

1. Only while `is_main`: `await sounds.wait(Sounds.Effect.DEATH)`: the
   death jingle, which started at the death, plays to its end
   (`sound.md`).
2. Only while `is_main`: `await iris.close()`: the iris closes on where
   the player died. The player node is hidden but still there, so the
   target is where it was at the moment of death (on the death line
   after a fall).
3. Only while `is_main`: `get_tree().reload_current_scene()`. The level
   is built fresh: everything back in place, 2 health, and the player
   standing at the respawn point (`checkpoint.md`), the start floor if no
   checkpoint was touched. It starts as above: 1 s of black, then the iris
   opens on the player.

## Acceptance test

| Case | Expected |
|---|---|
| Game starts | Title screen: black, "Press space to play" in the middle |
| Space pressed on the title screen | Level 1 loads |
| The title screen reached while the game is paused | Space still starts level 1 |
| A level starts | Paused; screen black for 1 s; the iris opens on the player in 0.5 s; then unpaused |
| The iris shut on the player at (81, 216), camera's left edge 0 | Target (81, 208.5): `Top` at (0, -48.5), `Right` at (81, 0), `Bottom` at (0, 208.5), `Left` at (-378, 0) |
| The iris open | `Top` at (0, -257), `Right` at (459, 0), `Bottom` at (0, 257), `Left` at (-459, 0) |
| Halfway through an open | Each rectangle halfway between its shut and open positions |
| Any time the iris is on screen | It covers the heart too |
| Player wins level 1, and `level_2.tscn` exists | The iris closes on the player in 0.5 s; level 2 loads, black for 1 s, then opens |
| Player wins the last level | The iris closes on the player; the title screen shows |
| Player wins through a door | Same as the flag |
| Player dies | The death jump plays; once it is below the screen the iris closes on where the player died; the level reloads with 2 health, everything back in place; black for 1 s, then the iris opens on the player |
| Player dies many times | The level reloads every time; no game over |
| A level run by the tests or the snapshot | `is_main` is false: no iris, not paused at the start; a win or death only pauses the game |
| A level that is the current scene | `is_main` is true |
| Space held from the title screen into level 1 | Nothing happens until the iris has opened; then the player jumps |
