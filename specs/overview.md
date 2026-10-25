# Overview

A 2D platformer made in Godot. This folder holds one spec per mechanic.
This file holds the rules every spec shares. Read it first.

## Specs

| File | Covers |
|---|---|
| `overview.md` | Shared rules (this file) |
| `assets.md` | Art files, collision boxes and origins |
| `level-tiles.md` | Solid ground tiles, autotiling and their collision |
| `level-layout.md` | Level scripts, floors, placing things, water, spikes, decorations, level end, the jump check and the snapshot |
| `game-flow.md` | The title screen, the levels in a line, the iris, and what follows a win or a death |
| `flag.md` | The goal flag and winning a level |
| `checkpoint.md` | Checkpoint flags: touching one moves where the player respawns |
| `door.md` | Doors placed anywhere, like coins; touching one wins the level like the flag |
| `background.md` | The still picture behind everything, one per biome, repeated sideways and scrolling at half speed |
| `trees.md` | Randomly built background trees in grass levels |
| `ropes.md` | Randomly built background ropes holding up hanging ground, in every biome |
| `pipes.md` | Background pipes hanging from the top of the screen, in levels with water |
| `one-way-platform.md` | One-way platforms: wooden planks and clouds in every biome, plus stones and mushrooms in the desert |
| `ladder.md` | Ladders placed anywhere; the player climbs them by holding up |
| `breakable-block.md` | Blocks the player breaks from below, killing walkers on top |
| `gift-block.md` | Blocks that hop and release a coin or a diamond when hit from below |
| `coins.md` | Coins placed in the level, collected by touching |
| `diamond.md` | Pickup from a gift block that walks and heals 1 health |
| `spring.md` | Springs that launch the player high on touch |
| `hud.md` | The health heart fixed to the screen |
| `controls.md` | Keys and how input is read |
| `player-movement.md` | Walking, jumping, gravity, collisions and player states |
| `player-animation.md` | Which sprite shows in each state, walk animation speed |
| `player-damage.md` | Health, injury freeze and invincibility, death |
| `player-contact.md` | Everything the player touches, in one fixed order: blocks over its head, pickups, enemies (stomp or hurt), springs, checkpoints |
| `camera.md` | Right-only camera, level end, keeping the player on screen |
| `enemy-walker.md` | Enemies that walk back and forth, turn at walls and fall off ledges: plain, shell and spiked |
| `enemy-flyer.md` | Enemies that bob up and down in the air |
| `enemy-leaper.md` | Enemies that leap straight up and fall back, again and again |
| `enemy-crusher.md` | An enemy that drops on the player and rises back; cannot be stomped |
| `enemy-bar.md` | A line of sprites spinning around its centre; cannot be stomped |
| `squash.md` | Squash and stretch on the player, walkers, crusher, diamond, spring and checkpoint |
| `sound.md` | The title and level music and 14 sound effects (Ninja Adventure pack), when each plays and how loud |

## Engine

- Godot **4.7.2**, the official Linux binary from godotengine.org (not the
  Arch package), pinned so every build is reproducible: the standard build
  (not .NET), `Godot_v4.7.2-stable_linux.x86_64.zip`, SHA-512 (from the
  release's `SHA512-SUMS.txt`):
  `9aa00f7a605200940bce3027a567b782f49bd8e940dd06ae9e987bd65aee1b1467edd56ed84fcdcbdd44354bf613bdbb4e5d2913e925850368e150c59ed54c65`.
- Scripts are GDScript.
- **Running from the command line** (all tested on 4.7.2):
  - After adding or renaming a `class_name` script, run
    `godot --headless --path . --import` once before the next run. Until
    then Godot does not know the new name ("Identifier ... not declared in
    the current scope"). The editor does this by itself.
  - Errors never stop a run or change its exit code, which is always 0: a
    script that fails to parse just doesn't load, and a failed `assert`
    stops only the function it is in. After every run, read the output for
    `SCRIPT ERROR` and `ERROR` lines. The exceptions are the level's own
    checks, which quit with code 1 when the level is the scene being
    played or a snapshot (`level-layout.md`, Checking the layout), and the
    test runner, which quits with code 1 when a check failed (see Tests).
  - Because an `assert` stops only its own function, a check that must
    stop its caller is not an `assert` inside a helper: the helper appends
    its messages to a list of errors, and the caller looks at the list,
    prints every message with `push_error()` and stops
    (`level-layout.md`, Checking the layout).
  - A type inferred from a Variant is an **error**, not a warning, by
    default: `var plank := [1, 2].pick_random()` stops the script from
    loading ("The variable type is being inferred from a Variant value").
    Give such variables their type: `var plank: int = [1, 2].pick_random()`.
  - **No `preload` cycles:** a script that preloads a scene whose scripts
    refer back to it gets an empty scene ("Failed to instantiate scene
    state ... node count is 0"). `Level` preloading the player scene, whose
    script uses `Level`, does exactly this. So the level root loads the
    scenes it builds with `load()` when it builds them, never with
    `preload` (`level-layout.md`, Building a thing).
  - With `--headless`, a `VisibleOnScreenEnabler2D` never switches anything
    on, even in the middle of the screen. So walkers, flyers, leapers, the
    crusher, the bar, the diamond and springs stay switched off, and a test
    that needs them runs with a window. Movie Maker also crashes with
    `--headless`, so snapshots need a window too (`level-layout.md`,
    Snapshot).
- **`.gitignore`** at the project root, holding `.godot/` (Godot's own
  cache, rebuilt by `--import`) and `snapshots/` (`level-layout.md`,
  Snapshot). Godot's project manager writes one when it creates a project
  in the editor, but a project set up from the command line gets none
  (tested on 4.7.2), and `snapshots/` is this project's own.

## Tests

The acceptance tests in every spec are run against the real game, with
Godot's own updates, not against copies of the code.

- They live in `res://tests/`. One runner scene,
  `res://tests/run_tests.tscn`, runs every `test_` function of its
  script, one after another, and prints one line per check.
- Run: `godot --path . res://tests/run_tests.tscn`, **with a window**
  (enemies, the diamond and springs never switch on with `--headless`,
  see above). Anything after `--` picks only the tests whose name holds
  it: `godot --path . res://tests/run_tests.tscn -- ladder`.
- **One run shows every failure:** every test runs, whatever happened in
  the ones before, and a failed check never stops the run. At the end the
  runner calls `get_tree().quit(1)` if any check failed, `quit(0)` if none
  did, so the exit code tells (unlike errors, see above).
- **Each test builds a small level in code:** `res://tests/test_level.gd`
  `extends Level`, and its `layout()` calls a `static var configure:
  Callable` that the test sets first, so each test writes only the fields
  it needs. The test adds the level, plays it by holding keys with the
  built-in `Input.action_press()` and `Input.action_release()`, and waits
  whole updates.
- **Waiting one update:** the runner's `process_physics_priority` is high
  (1000), so its `_physics_process` runs after every other node's; it
  emits a signal there, and a test awaits that signal to wait one update,
  with everything else's update for it already done.
- **Decimal numbers are compared with a tolerance:** a check passes when
  `absf(actual - expected) <= 0.001`, unless its row gives its own (for
  example "within 1 px"). `Vector2` holds 32-bit numbers, so a value that
  has no exact binary form never equals the written number: a
  `velocity.y` set to `-227.37` reads back as `-227.3699951` (tested). In
  the specs' tables, `==` with a decimal number means within 0.001.
- A test level is a child of the runner, not the scene being played, so
  it has no iris, does not pause itself at the start, and a win or death
  only pauses the game, as before (`game-flow.md`, `is_main`). Each test
  sets `Level.respawn_cell` back to `Level.PLAYER_CELL` first: it is a
  `static var` and would carry a checkpoint over from the previous test
  (`checkpoint.md`).
- **A layout error never ends the run:** under the runner, a level with
  errors neither prints them nor quits (`level-layout.md`, Checking the
  layout); it only stops building and keeps its `errors` list. Tests add
  their level through one runner function, `add_level(expect_errors :=
  false)`. A test that expects errors passes `true` and checks the
  messages in the level's `errors`. For every other test, the function
  checks that `errors` is empty, and if not, fails that test with each
  message as its own failed check. Either way the runner goes on to the
  next test.
- **Between tests**, the runner sets `get_tree().paused = false` (a test
  may end paused: after a win, a death or in an injury freeze), frees the
  test level with `queue_free()` and waits one update, so the next test
  starts unpaused, with nothing left over from the last one. Freeing the
  level also drops whatever was still waiting in it: tested on 4.7.2, a
  freed node's pending `await get_tree().create_timer(...).timeout` never
  resumes and prints no error, so an injury freeze cut short can never
  unpause the next test.
- **Two traps (tested on 4.7.2):**
  - The runner keeps going while the game is paused
    (`PROCESS_MODE_ALWAYS`), and a level added under it would inherit
    that and ignore the pause. So the level sets its own `process_mode`
    to `PROCESS_MODE_PAUSABLE` first thing in its `_ready`
    (`level-layout.md`, Building, step 1): under the runner, like under
    the snapshot, it then pauses like a level that is the scene root.
  - A `static var` still holding a lambda when the game quits crashes
    Godot on the way out ("double free or corruption", exit code 134).
    The runner sets `configure` back to an empty `Callable()` before it
    quits.

## Shared rules

- The game updates **60 times per second** with a fixed time step. All
  gameplay logic runs in `_physics_process`.
- The length of one update is `1/60` of a second, called `delta` below.
- **Timers and tweens count in game updates:** every `Timer` node sets
  `process_callback = TIMER_PROCESS_PHYSICS`, every
  `get_tree().create_timer()` passes `process_in_physics = true`, and every
  `Tween` calls `set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)`. (A tween
  steps on drawn frames by default, and some tweens end in gameplay, such
  as the diamond coming out when a gift block's hop ends.)
- Positions are in pixels. Speeds are in pixels per second (px/s).
  Accelerations are in pixels per second per second (px/s²).
- The y axis points down. A negative vertical speed means moving up.
- The screen is **459 px wide and 257 px tall**. These two numbers are set
  once, in the project settings `display/window/size/viewport_width` and
  `display/window/size/viewport_height`, and nowhere else. (Project
  settings, not the live viewport size, so every script reads the same two
  numbers.)
- **Screen size in code:** `res://screen.gd` is `@abstract class_name Screen`.
  It reads the two settings once, with the built-in
  `ProjectSettings.get_setting(...)`, into `static var`s (not `const`s: a
  `const` can't call a function):
  - `width: int` (459) and `height: int` (257)
  - `half_width: float = width / 2.0` (229.5) and
    `half_height: float = height / 2.0` (128.5)

  Every other script and spec uses `Screen.width`, `Screen.height`,
  `Screen.half_width` and `Screen.half_height`, and never divides the size
  by 2 itself: both numbers are odd, and in GDScript an `int` divided by an
  `int` drops the fraction (459 / 2 is 229, not 229.5).
- The art looks pixelated, but the game is **not** rendered as pixel art:
  sprites will be squashed, stretched and tweened later, which needs smooth
  scaling. So:
  - `display/window/stretch/mode = "canvas_items"`: the game is drawn at
    the window's real resolution, not at 459 × 257 and then blown up. At a
    459 × 257 window it is drawn one to one.
  - `display/window/stretch/aspect = "keep"`: the 459 × 257 shape is always
    kept, with bars around it if the window is a different shape. The
    player never sees more of the level than 459 × 257.
  - Textures use nearest-neighbour filtering (project setting
    `rendering/textures/canvas_textures/default_texture_filter`), so the
    art stays sharp, not blurry, when drawn bigger. `canvas_items` still
    keeps squash and stretch smooth.
  - The window opens at **1377 × 771**
    (`display/window/size/window_width_override` and
    `window_height_override`): exactly 3 × 459 by 3 × 257, so every art
    pixel is the same size, with no bars. If the player resizes the window,
    `"keep"` adds bars where the shapes differ.
- The camera only scrolls **right**, never back left. Its top edge is always
  at y = 0 and its bottom edge at y = `Screen.height`. See `camera.md`.
- Nothing is freed during a level. Things that are done (a dead player,
  enemies off screen) are switched off with `process_mode`, not
  `queue_free()`.
- **Never switch a collision object off inside one of its own physics
  signals** (`body_entered` and the like): Godot reports "Disabling a
  CollisionObject node during a physics callback is not allowed". Use
  `set_deferred("process_mode", PROCESS_MODE_DISABLED)` there instead.
  Switching off from a `_physics_process` (a stomp, a block hit, a pickup)
  is fine. Nothing in this game switches off inside a signal: the player
  checks all contact itself (`player-contact.md`).
- The level has **no slopes**. Every floor, wall and ceiling is flat and
  either horizontal or vertical.
- Keep to Godot's built-in features (for example `move_toward`,
  `move_and_slide`, `is_on_floor`, `flip_h`) instead of writing custom
  versions of them.
- **Tile size:** a tile is **18 × 18 px**. This is the one place that
  number is written down. `res://grid.gd` is `@abstract class_name Grid`
  with `const TILE := 18` and `const HALF_TILE := 9`; code uses these for
  every tile calculation and never writes 18 or 9 for it, and the other
  specs write the tile as `Grid.TILE` or `Grid.HALF_TILE` too. Plain pixel
  numbers in the specs describe the art instead: image sizes and positions
  inside an image.
- **No groups:** nothing uses `add_to_group`. Things find each other
  through the level root they get in `setup()` (`level.player`,
  `level.camera`, `level.walker_layer`), and check what something is with `is` (for
  example `collider is Block`).
- No `@tool` and no `@export` anywhere. Each level is plain text in its own
  script, built when the game runs, and checked with a snapshot
  (`level-layout.md`).
- There is no pause button or pause screen. The game only pauses itself:
  for the injury freeze and death (`player-damage.md`), on winning
  (`flag.md`, `door.md`), while the iris opens at a level's start
  (`game-flow.md`), and in a snapshot, so everything stays where it was
  placed (`level-layout.md`, Snapshot).
- **Physics layers** (named in Project Settings > Layer Names > 2D Physics):

  | Layer | Name | On it |
  |---|---|---|
  | 1 | `level` | The solid tiles (`level-tiles.md`), the blocks, the one-way platforms and the ladder tops |
  | 2 | `walkers` | Walkers |
  | 3 | `enemies` | Every other enemy: crusher, flyer, leaper, bar |
  | 4 | `pickups` | Coins and the diamond's pickup area |
  | 5 | `springs` | Springs |
  | 6 | `doors` | Doors |
  | 7 | `checkpoints` | Checkpoints |

  The player is on **no** layer. It is the only thing that looks for the
  others (its contact check, `player-contact.md`); nothing ever looks for
  the player, so it needs no layer to be found on.

  | Node | `collision_layer` | `collision_mask` |
  |---|---|---|
  | Player body | none | `level` |
  | Player contact `Area2D` | none | `walkers`, `enemies`, `pickups`, `springs`, `doors`, `checkpoints` |
  | Walker (all three kinds) | `walkers` | `level`, `walkers` |
  | Kicked shell (walker B, `enemy-walker.md`) | `walkers` | `level` |
  | Crusher | `enemies` | `level` |
  | Flyer, leaper, bar (`Area2D`) | `enemies` | none |
  | Breakable and gift blocks (`StaticBody2D`) | `level` | none |
  | Ground tiles (the `TileSet`'s physics layer) | `level` | none |
  | One-way platforms (the platform `TileSet`'s physics layer) | `level` | none |
  | Ladder tops (the ladder `TileSet`'s physics layer) | `level` | none |
  | Coins (`Area2D`) | `pickups` | none |
  | Diamond body (`CharacterBody2D`) | none | `level` |
  | Diamond pickup (`Area2D`) | `pickups` | none |
  | Springs (`CharacterBody2D`) | `springs` | `level`, `springs` |
  | Doors (`Area2D`) | `doors` | none |
  | Checkpoints (`Area2D`) | `checkpoints` | none |
  | Death and flattened scenes | none | none |

  Every collision object sets **both** `collision_layer` and
  `collision_mask` to its row here. Godot's defaults (layer 1 and mask 1,
  that is `level`) are never left as they are: a block left at the default
  would scan `level`, and an `Area2D` would watch the ground every update
  for nothing.

  Walkers get their own layer so they can bump into each other (turning
  around) without also bumping into the crusher. Springs do the same on
  their own layer, so they stack on each other and nothing else.
- Sound is in `sound.md`: only the music and effects it lists, played
  where it says.
- Do not add mechanics a spec does not describe.

## Scenes

The build has no editor (`level-tiles.md`), so no scene is put together
by hand in one.

- **Every scene is a root and a script.** Each `.tscn` holds only its
  root node, of the type in the table below, with its script, and nothing
  else, like the levels (`level-layout.md`, The level script). Written as
  text (tested on 4.7.2):

  ```
  [gd_scene load_steps=2 format=3]

  [ext_resource type="Script" path="res://items/coin.gd" id="1"]

  [node name="Coin" type="Area2D"]
  script = ExtResource("1")
  ```

- **The script builds every child in code**, in its `_ready`: sprites and
  their `SpriteFrames`, collision shapes, `VisibleOnScreenEnabler2D`s,
  `Timer`s, the diamond's pickup area. The title screen, the iris and the
  bar already work this way. Anything a child needs from outside comes
  through `setup()`, which runs before `_ready` (`level-layout.md`,
  Building a thing).
- **Built-in nodes with no script of their own** need no scene: the
  level's layer `Node2D`s, every `TileMapLayer`, the `Background`, the
  `HUD` and the `Music` player are made with `.new()`.
- Each scene's script sits next to it, with the same name
  (`res://items/coin.gd` for `res://items/coin.tscn`), except the walkers,
  whose three scenes use three scripts named after their classes.

| Scene | Root | Script's `class_name` |
|---|---|---|
| `res://player/player.tscn` | `CharacterBody2D` | `Player` |
| `res://player/player_death.tscn` | `Node2D` | `PlayerDeath` |
| `res://enemies/walker_a.tscn` | `CharacterBody2D` | `Walker` (`res://enemies/walker.gd`) |
| `res://enemies/walker_b.tscn` | `CharacterBody2D` | `ShellWalker` (`res://enemies/shell_walker.gd`) |
| `res://enemies/walker_c.tscn` | `CharacterBody2D` | `SpikedWalker` (`res://enemies/spiked_walker.gd`) |
| `res://enemies/walker_flattened.tscn` | `Node2D` | `WalkerFlattened` |
| `res://enemies/walker_bonked.tscn` | `Node2D` | `WalkerBonked` |
| `res://enemies/flyer.tscn` | `Area2D` | `Flyer` |
| `res://enemies/leaper.tscn` | `Area2D` | `Leaper` |
| `res://enemies/enemy_death.tscn` | `Node2D` | `EnemyDeath`: the flyer's and the leaper's death scene, given its sprite in `setup()` |
| `res://enemies/crusher.tscn` | `CharacterBody2D` | `Crusher` |
| `res://enemies/bar.tscn` | `Area2D` | `Bar` |
| `res://blocks/breakable_block.tscn` | `StaticBody2D` | `BreakableBlock` |
| `res://blocks/gift_block.tscn` | `StaticBody2D` | `GiftBlock` |
| `res://blocks/block_chunk.tscn` | `Node2D` | `BlockChunk` |
| `res://items/coin.tscn` | `Area2D` | `Coin` |
| `res://items/popped_coin.tscn` | `Node2D` | `PoppedCoin` |
| `res://items/diamond.tscn` | `CharacterBody2D` | `Diamond` |
| `res://items/spring.tscn` | `CharacterBody2D` | `Spring` |
| `res://items/door.tscn` | `Area2D` | `Door` |
| `res://items/checkpoint.tscn` | `Area2D` | `Checkpoint` |
| `res://items/flag.tscn` | `Node2D` | `Flag` |
| `res://levels/camera.tscn` | `Camera2D` | `Camera` |
| `res://levels/iris.tscn` | `CanvasLayer` | `Iris` |
| `res://levels/sounds.tscn` | `Node` | `Sounds` |

Scripts with no scene: `res://screen.gd` (`Screen`), `res://grid.gd`
(`Grid`), `res://tiles/tiles.gd` (`Tiles`), `res://levels/level.gd`
(`Level`), `res://levels/spawns/<kind>_spawn.gd` (the spawn classes),
`res://enemies/walking_body.gd` (`WalkingBody`), `res://blocks/block.gd`
(`Block`) and `res://effects/squash.gd` (`Squash`, `squash.md`). The
title, the test runner and the snapshot keep the paths their specs give
(`game-flow.md`, Tests above, `level-layout.md`, Snapshot).
