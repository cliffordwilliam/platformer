# Level layout

How a level is written, how its ground, water, decorations and placed
things are built, how its jumps are checked, and how to look at it. Read `overview.md` and `level-tiles.md` first.
Designing the levels themselves (how many, how long, what goes where) is up
to the builder.

## The level script

- `res://levels/level.gd` is the shared base: `@abstract class_name Level
  extends Node2D` (`@abstract`, Godot 4.5 and later). It holds all the
  building, the getters and `health`. Being abstract, it can never be
  attached to a node or instantiated on its own.
- Each level is a scene, `res://levels/level_<n>.tscn`, holding only a root
  `Node2D` with its own script, `res://levels/level_<n>.gd`, which
  `extends Level`. Nothing else is saved in the scene: the root builds all
  its children when the game runs.
- The game starts at the title screen, and pressing space starts level 1
  (`game-flow.md`).
- Levels are played in a straight line, one way: level 1, then level 2,
  and so on, and the last level leads back to the title screen. No going
  back and no level select (`game-flow.md`).
- No `@tool` and no `@export`: a level is plain text in its script. One
  level, one script, like one stylesheet per page.
- `Level` declares one abstract function, `@abstract func layout() -> void`.
  Every level script must implement it, with that exact signature, or
  GDScript reports an error. `layout()` does nothing but set these
  fields. The level script declares nothing and checks nothing: `Level`
  declares every field and does every check (see Checking the layout),
  like a stylesheet that only sets properties while the browser does the
  rest.

| Field | Type | Meaning |
|---|---|---|
| `biome` | `Level.Biome` (`SNOW`, `GRASS`, `DESERT`) | Which tile look the level uses |
| `floors` | `Array[Vector2i]` | The ground, left to right (see Floors) |
| `has_water` | `bool` | Whether the level has water along the bottom (see Water) |
| `blocks` | `Array[BlockSpawn]` | Breakable and gift blocks, in one list (`breakable-block.md`, `gift-block.md`) |
| `coins` | `Array[Vector2i]` | Cells (`coins.md`) |
| `walkers` | `Array[WalkerSpawn]` | `enemy-walker.md` |
| `flyers` | `Array[FlyerSpawn]` | `enemy-flyer.md` |
| `leapers` | `Array[int]` | Columns only: a leaper always starts behind the water (`enemy-leaper.md`) |
| `crushers` | `Array[Vector2i]` | Cells (`enemy-crusher.md`) |
| `springs` | `Array[Vector2i]` | Cells (`spring.md`) |
| `doors` | `Array[Vector2i]` | Cells: each door's bottom tile (`door.md`) |
| `checkpoints` | `Array[Vector2i]` | Cells: each checkpoint's bottom tile (`checkpoint.md`) |
| `bars` | `Array[BarSpawn]` | `enemy-bar.md` |
| `platforms` | `Array[PlatformSpawn]` | One-way platforms; each gets a random look from its biome's (`one-way-platform.md`) |
| `ladders` | `Array[LadderSpawn]` | Ladders (`ladder.md`) |

A field the level script doesn't set keeps its type's default: an empty
list, `has_water` false, and `biome` `SNOW` (the enum's first value).

The level script never says where the player starts or where the flag
stands: like the flag at the right end, the player always starts at the
left end, on the start floor (see Floors). The level script fills in what
lies between them.

Example:

```gdscript
extends Level

func layout() -> void:
	biome = Biome.GRASS
	has_water = false
	floors = [Vector2i(10, 11), Vector2i(3, 15), Vector2i(13, 9)]
	blocks = [
		BreakableBlockSpawn.new(Vector2i(9, 7)),
		BreakableBlockSpawn.new(Vector2i(10, 7)),
		GiftBlockSpawn.new(Vector2i(11, 7), GiftBlockSpawn.Contents.DIAMOND),
	]
	coins = [Vector2i(18, 6), Vector2i(19, 6)]
	walkers = [WalkerSpawn.new(Vector2i(12, 10), WalkerSpawn.Kind.SHELL)]
	flyers = [FlyerSpawn.new(Vector2i(16, 4), 36.0)]
	bars = [BarSpawn.new(Vector2i(20, 5), 2, 0.0, true)]
	checkpoints = [Vector2i(25, 8)]
```

- `biome` sets `Ground`'s, every ground piece's (`Piece<n>`) and
  `RopeCeilings`' `tile_set` to that biome's `TileSet` (`level-tiles.md`),
  `Decorations`', every `Piece<n>Decorations`', `RopeCeilingDecorations`'
  and `MushroomDecorations`' `tile_set` to
  that biome's decorations `TileSet` (see Decorations), and the
  `Background`'s picture (`background.md`).
- `Level._ready()` calls `layout()`, adds the start and end floors,
  checks the layout, then builds everything (see Building).

## Floors

The ground is an ordered list of floors, each a `Vector2i(width, row)`:

- **`width`**: how many tiles wide the floor is (1 or more).
- **`row`**: the tile row of the floor's top surface, counted from
  row **0** at the top of the screen, like Godot's y. Row 5 means the ground
  starts 5 rows down.
- Floors follow each other with no overlaps or holes. The start floor
  (below) starts at x = 0, so the first written floor starts at column 7.
- Each floor is filled solid, from its surface row down to **row 14**, the
  last row the screen shows (rows are `Grid.TILE` high, so row 14 is 252–270 and only
  its top 5 px are on the 257 px screen).
- **A gap** is a floor whose row is `gap_row` or more (see Level end, gap
  line and death line): no ground is built there. `gap_row` is a line
  that moves with the water: **15** without water, just below the screen,
  and **13** with water (`has_water` on), the water's surface row, since
  ground there would be under the water. Walkers, the diamond and springs
  that walk or fall into the water sink behind it and off the bottom of
  the screen, where their enablers switch them off for good, instead of
  walking along under the water. Everything that treats gaps (ground
  cells, spikes, decorations, ground pieces, occupied cells, the jump
  check) uses `gap_row` and nothing else.
- **The start and end floors:** right after `layout()`, the level root
  adds one floor to the front of `floors` and one to the end. The level
  script never writes them. Both are constants on `Level`:
  - **`START_FLOOR`**, `Vector2i(7, 12)`: 7 columns on row 12, columns 0
    to 6. The player starts on it, standing in **`PLAYER_CELL`**,
    `Vector2i(4, 11)`, the 5th tile (`camera.md`, Starting position),
    unless a checkpoint was touched (`checkpoint.md`). From there to the
    floor's right edge is 45 px, more than the 34 px the player needs to
    reach top walking speed, so the first jump can always be made at full
    speed.
  - **`END_FLOOR`**, `Vector2i(10, 12)`: 10 columns on row 12. It holds the
    flag's column (the 10th from the right, `flag.md`) and the 9 columns
    after it.
  - Both are on row 12, so the player and the flag always stand on ground,
    above the water (rows 13 and 14).
  - From then on `floors` means the whole list, start and end floors
    included: the width, building, decorations and the jump check all use
    it, so the jumps off the start floor and onto the end floor are checked
    too.
- **The start and flag areas:** the start floor's columns (0 to 6) are the
  **start area**, the end floor's columns (the flag's column to the last
  column) the **flag area**. Nothing is placed there, from any list (see
  Checking the layout), so the player's start and the flag are always
  clear. Big decorations keep away from both areas too (see Big
  decorations).
- **Naming a floor:** a message names a written floor by its index in the
  list the level script wrote, counted from 0, with its columns and row,
  so it needs no counting by hand: `floors[3] (columns 14 to 16, row 9)`.
  The two added floors are `start floor` and `end floor`.

Example: `[Vector2i(10, 11), Vector2i(3, 15), Vector2i(8, 9)]` is the start
floor (columns 0 to 6), then 10 tiles of ground at row 11, a 3-tile gap,
then 8 tiles of ground 2 rows higher, then the end floor.

## Placing things

Everything placed in a level is written in tile units, in a typed list, and
the level root turns the cells into positions.

### Spawn classes

A kind of thing that has settings gets one small class holding them:
`res://levels/spawns/<kind>_spawn.gd`, `class_name <Kind>Spawn extends
RefCounted`. Every field is typed, and `_init` takes every field, with no
defaults, so a missing or wrongly typed value is a GDScript error, not a
silent mistake.

| Class | `_init` arguments |
|---|---|
| `BreakableBlockSpawn` | `cell: Vector2i` |
| `WalkerSpawn` | `cell: Vector2i, kind: Kind` (`enum Kind { PLAIN, SHELL, SPIKED }`: walker A, B or C, each with its own behaviour, `enemy-walker.md`) |
| `GiftBlockSpawn` | `cell: Vector2i, contents: Contents` (`enum Contents { COIN, DIAMOND }`; its look is picked at random, `gift-block.md`) |
| `FlyerSpawn` | `cell: Vector2i, bob_distance: float` |
| `BarSpawn` | `cell: Vector2i, units: int, start_angle: float, clockwise: bool` |
| `PlatformSpawn` | `cell: Vector2i, width: int` (`cell` is the platform's left end) |
| `LadderSpawn` | `cell: Vector2i, height: int` (`cell` is the ladder's bottom; it grows up) |

- **Only choices that matter:** a spawn holds only what changes how the
  level plays. A look that changes nothing (a gift block's, a door's, a
  platform's) is never written: the level picks it at random at build
  time, so the level script only decides things like what a gift block
  holds or which kind of walker goes where.
- **Blocks:** `BlockSpawn` is `@abstract` and holds only `cell`.
  `BreakableBlockSpawn` and `GiftBlockSpawn` extend it, so both kinds go in
  the one typed `Array[BlockSpawn]`, and the level builds each with the
  scene for its class (`spawn is GiftBlockSpawn`).
- A kind with no settings (coins, crushers, springs, doors, checkpoints) is just a list of cells.
  Leapers are just a list of columns: their row is always 14, behind the
  water (`enemy-leaper.md`).
- **One thing per cell:** no two things share a cell, in any list or
  across lists. Bars, flyers and leapers only check their own list (see
  Checking the layout, Occupied cells).
- **Between the start and the flag:** everything placed, from every list,
  goes in columns 7 to the column left of the flag: never in the start or
  flag area.

### Checking the layout

Right after `layout()` and the start and end floors, before anything is
built, the level root checks the values the level script wrote, like
validating input before doing any work. The checks read only the written
fields (`floors`, `has_water`, the lists), never built nodes or physics.

- **Errors are collected, never asserted:** the level root has
  `var errors: Array[String]`. Every check appends a message for each
  problem it finds and goes on, so **one run shows every mistake**, not
  just the first. Each message names the field and the bad value (a floor
  by its index, see Floors).
- **One function does all the checks**, `_check_layout() -> void`, which
  only appends to `errors`. `_ready` then looks at `errors` itself:
  if any, it prints each with the built-in `push_error()`, calls
  `get_tree().quit(1)` and returns, so nothing is built. No `assert`: an
  `assert` inside a helper stops only the helper (`overview.md`, Running
  from the command line), and asserts are left out of release exports.
- `quit()` lets the current frame finish first (tested on Godot 4.7.2: one
  more `_process` ran), which is harmless here, since nothing is built
  yet. The run exits with **code 1**, and each message shows in the output
  as an `ERROR:` line, followed by the line of the script that pushed it.
  Without this, a run always exits with code 0 (`overview.md`).
- The jump check (see Jump check) appends to the same `errors` at the end
  of building, and is handled the same way.

The checks:

- **`floors`:** every width is 1 or more, and the level, start and end
  floors included, is **1 to 10 screens wide**:
  `Screen.width <= level_end_x <= 10 * Screen.width`, which is 26 to 255
  columns. So the written floors cover 9 to 238 columns: everything
  between the start floor and the flag. Narrower than a screen, the
  camera's clamp (`camera.md`) would have nowhere to go.
- **Between the start and the flag:** every cell in `blocks`, `coins`,
  `walkers`, `flyers`, `crushers`, `bars`, `springs`, `doors` and
  `checkpoints`, every cell of every platform in `platforms` and every
  ladder in `ladders`, and every column in `leapers` has a column from 7
  to the column left of the flag. Columns 0 to 6 are the start area, the
  flag's column to the last column the flag area (see Floors), and any
  other column is outside the level: the message says which, e.g. `"coin
  at (1, 6) is in the start area"`.
- **Above the gap line:** every one of those cells (every cell each thing
  takes, as in Occupied cells: a walker B's whole box, a door's or
  checkpoint's top) is on a row less than `gap_row`. That is the same
  line that turns floors into gaps (see Floors), and it moves with the
  water the same way: row 14 at the lowest without water, row 12 at the
  lowest with water.
  Below it, a thing would be under the screen, or behind the water where
  the player could stand on it in the water or never reach it. The
  message names the thing and the line, e.g. `"coin at (20, 13) is below
  the gap line (row 13)"`. Above the screen (negative rows) is allowed.
  Leapers are written as columns, not cells, so this never applies to
  them: they always sit on row 14, behind the water (`enemy-leaper.md`).
- **`platforms`:** every width is 1 or more, like the floors.
- **`ladders`:** every height is 1 or more.
- **`checkpoints`:** the cell under each checkpoint is ground (a cell of a
  floor that is not a gap, from its surface row down to row 14) or a cell
  of a platform, so the player always respawns standing on something
  (`checkpoint.md`). The message names the checkpoint, e.g.
  `"checkpoint at (25, 8) has no ground or platform under it"`.
- **`blocks`:** a gift block holding a diamond is on row 1 or more. On
  row 0, the cell its diamond comes out into is above the screen, where
  the diamond's enabler would switch it off for good.
- **`leapers`:** only allowed when `has_water` is on (a leaper always
  leaps out of the water). Water is not turned on by the leapers: it also
  moves the gap line and swaps the spikes for water, so the level script
  turns it on itself.
- **`flyers`:** the flyer's whole sprite is on screen at both ends of its
  path (a `bob_distance` of 0 is allowed: it hovers, `enemy-flyer.md`):
  for the start `y = cell_to_position(cell, Origin.CENTRE).y` and the other end
  `y + bob_distance`, both `y - 10 >= 0` and `y + 10 <= Screen.height` (the
  sprite reaches 10 px up and down from its origin, `assets.md`). The path
  is a straight vertical line, so checking its two ends covers all of it.
- **Nothing overlaps** (see Occupied cells).

#### Occupied cells

No two things may share a cell, across every list, except bars, flyers
and leapers: those are free to be anywhere (see below). One pass fills a
lookup of taken cells:

- `var occupied: Dictionary[Vector2i, String]`, keyed by cell. A cell that
  is not in it is air: `occupied.get(cell, "")` returns `""`. A taken cell
  holds what took it, for example `"coin at (14, 6)"`, so the message can
  name both things:
  `"walker at (14, 6) overlaps coin at (14, 6)"`.
- Taking a cell reads first, then sets: if `occupied.get(cell, "")` is not
  `""`, an error is appended to `errors`, unless an exception below allows
  it, and the cell keeps what took it first; otherwise the cell is stored.
  The order below is fixed by the level root, never by the order the level
  script wrote its fields in, so the same mistake is always caught the
  same way.
- Every cell a thing takes, not only its own cell, must be between the
  start and the flag (see the checks above): a walker B's whole box, a
  door's or checkpoint's top, the cell above a gift block holding a
  diamond.
- Cells are taken **in this order**:
  1. **ground:** every cell of every floor that is not a gap, from its
     surface row down to row 14, named by its floor (see Floors), e.g.
     `"walker at (14, 8) overlaps floors[3] (columns 14 to 16, row 8)"`
  2. **platforms:** every cell of every platform, as
     `"platform at (c, r)"` (its left end). Mushroom stalks take no cells:
     they are purely visual. The look is picked later, while building, so
     this does not depend on it. Then every cell of every ladder, as
     `"ladder at (c, r)"` (its bottom cell).
  3. **blocks**, each its own cell. A **gift block holding a diamond**
     also takes the cell above it, where its diamond comes out
     (`diamond.md`), as `"diamond above gift block at (c, r)"`. So nothing
     solid can be there for the diamond to start inside. A gift block
     holding a coin takes only its own cell: the coin is purely visual.
  4. **coins**
  5. **springs**, each its own cell
  6. **doors**: each its own cell and the cell above it, where its top
     reaches (`door.md`), as `"door at (c, r)"` and
     `"top of door at (c, r)"`
  7. **checkpoints**: each its own cell and the cell above it, like a
     door, as `"checkpoint at (c, r)"` and `"top of checkpoint at (c, r)"`
  8. **walkers**: walker A (`Kind.PLAIN`) and walker C (`Kind.SPIKED`)
     their own cell. **Walker B** (`Kind.SHELL`) takes all six
     cells its 24 × 20 box covers, since it reaches 3 px into the cells on
     each side and 2 px into the row above: for a walker B in cell (c, r),
     (c - 1, r), (c, r), (c + 1, r) and (c - 1, r - 1), (c, r - 1),
     (c + 1, r - 1). So nothing else can be placed where its box is, and
     two walker Bs need two free columns between them.
  9. **crushers**, each its own cell (its 16 × 18 box fits inside it)
- The player takes no cell here: it starts in `PLAYER_CELL`, in the start
  area, where nothing else can be, or in a checkpoint's cell, which the
  checkpoint already took.
- **Bars, flyers and leapers are not in this check.** They collide with
  nothing, so they are free to be anywhere: in the ground, on a block or on
  another thing. Each only checks its own list for duplicates: no two bars
  on one cell, no two flyers on one cell, no two leapers in one column. A
  duplicate means two of them sit exactly on top of each other, so it
  appends an error naming the list and the cell (or column). Their own
  checks above still apply.
- A walker or crusher in a free cell boxed in by ground is allowed: odd,
  but legal.

### Cell to position

`Level.cell_to_position(cell: Vector2i, origin: Origin) -> Vector2`, with
`enum Origin { TOP_LEFT, FEET, CENTRE }` on `Level`, turns a cell into
the `position` for a thing, from the kind of origin it has (`assets.md`):

| Origin | `position` | Where the thing ends up |
|---|---|---|
| `Origin.TOP_LEFT` | `cell * Grid.TILE` | Filling the cell |
| `Origin.FEET` | `cell * Grid.TILE + Vector2i(Grid.HALF_TILE, Grid.TILE)` | Standing in the cell, on the top of the cell below |
| `Origin.CENTRE` | `cell * Grid.TILE + Vector2i(Grid.HALF_TILE, Grid.HALF_TILE)` | Centred in the cell |

The flag is the one exception: it is placed automatically (`flag.md`).

### Building a thing

For every item in a list, the level root:

1. instantiates the kind's scene (`load(path).instantiate()`: `load()`
   when building, never `preload`, which would be a cycle, `overview.md`)
2. sets its `position` with `cell_to_position`
3. calls its `setup(...)` with everything it needs (below)
4. adds it to the kind's layer node with `add_child()`

Godot calls the thing's `_ready` during `add_child()`, so its settings are
already there.

- **Everything a thing needs from outside comes through `setup()`.** A
  scene can't take constructor arguments (`instantiate()` calls `_init()`
  with none), so `setup()` stands in for one. Settings arrive as the
  thing's spawn object, or not at all for a kind that is just a cell.
- **Every thing gets the level root:** every scene the level builds, and
  every scene added during play, has `setup(level: Level, ...)` with the
  level as its first argument, and keeps it in `var level: Level`, even if
  it has no other use for it. It never uses `get_parent()` to reach the
  level.
- **Every `_ready` starts with**
  `assert(level != null, "setup() not called")`, so a scene added without
  `setup()` stops at once with that message.
- **The level keeps a typed reference** to each layer node it creates
  (`walker_layer: Node2D`, `block_item_layer: Node2D` and so on), to the
  player (`player: Player`) and to the camera (`camera: Camera`),
  so things find each other through `level`, never through groups.
- **A thing's `_ready` only touches the thing itself** and its own
  children, never other things.
- **Scenes added during play** go into a layer through the level, never
  with `add_child()` on something else:
  - `level.add_effect(node)` adds it to `Effects`: the death, flattened,
    bonked and chunk scenes.
  - `level.add_block_item(node)` adds it to `BlockItems`: the coin and
    diamond that come out of a gift block (`gift-block.md`, `diamond.md`).

## Building

`Level._ready()` does all of this in one go, so no update runs before the
whole level exists.

1. Calls `layout()`, adds the start and end floors (see Floors), then
   checks the layout (see Checking the layout). With any errors it stops
   there: nothing is built.
2. Creates its children **in this order**. Godot draws later children on
   top, like layers in a drawing program, so no `z_index` is needed:
   1. `Background` (`Parallax2D`, see `background.md`), drawn behind
      everything
   2. `Trees`, `TreeCanopies`, `TreeCanopiesFront`, then `RopeCeilings`,
      `RopeCeilingDecorations`, `Ropes` (`TileMapLayer`s, see `trees.md`
      and `ropes.md`), drawn behind everything but the background
   3. `Pipes` (`TileMapLayer`, see `pipes.md`)
   4. `Decorations` (`TileMapLayer`)
   5. `Flag` (see `flag.md`)
   6. `Platforms`, then `MushroomDecorations`, then `Ladders`
      (`TileMapLayer`s, see `one-way-platform.md` and `ladder.md`)
   7. `Ground` (`TileMapLayer`)
   8. `Spikes` (`TileMapLayer`, see Spikes)
   9. `Waterfalls` (`TileMapLayer`), then `GroundPieces` (`Node2D`
      holding three `TileMapLayer`s per piece, see Decorations, Ground
      pieces)
   10. `BlockItems` (`Node2D`): empty at the start; the coins and diamonds
       that come out of gift blocks, drawn behind every block
   11. `Blocks` (`Node2D`): the blocks, in list order
   12. `Coins`, `Springs`, `Doors`, `Checkpoints` (a `Node2D` each)
   13. `Walkers`, `Flyers`, `Leapers`, `Crushers`, `Bars` (a `Node2D` each)
   14. `Player`
   15. `Water` (`TileMapLayer`)
   16. `Effects` (`Node2D`): empty at the start; death, flattened, bonked
       and chunk scenes, drawn in front of everything in the level
   17. `Guides` (`Node2D`), only while `Level.show_guides` (see Guides):
       the grid and the jump markers, drawn in front of everything else in
       the level
   18. `Camera` (draws nothing; after the player, see `camera.md`)
   19. `HUD` (`CanvasLayer`, see `hud.md`): drawn on the screen, in front
       of the whole level, wherever it sits in this list
   20. `Iris` (`CanvasLayer`, see `game-flow.md`), only when the level is
       the scene being played (`is_main`, `game-flow.md`): drawn in front
       of the HUD
3. Fills the tile layers:
   1. every solid cell of `Ground`, with the built-in
      `set_cells_terrain_connect(cells, 0, 0)` (terrain set 0, the
      `ground` terrain), which picks the right autotiles
   2. the one-way platforms (`one-way-platform.md`) and the ladders
      (`ladder.md`)
   3. the decorations and waterfalls (see Decorations), the big
      decorations: trees (`trees.md`), pipes (`pipes.md`) and ropes
      (`ropes.md`), and the
      ground pieces (see Decorations, Ground pieces). Not in a snapshot
      (`Level.show_guides` on): see Snapshot.
   4. if `has_water`, the water (see Water); if not, the spikes (see Spikes)
4. Sets the starting positions (`camera.md`, Starting position).
5. Runs the jump check (see Jump check), then stops on any errors it
   found.
6. Starts the level: pauses the game and opens the iris
   (`game-flow.md`, Starting a level).

- So the leaper is in front of the waterfalls but behind the water, and a
  death scene (in `Effects`) falls in front of the water.
- Nothing above the ground comes from `floors`.

## Water

Purely visual, like the decorations, and the same in every biome.

- One sheet, `res://art/decorations/water.png`:
  72 × 54 px, 18 × 18 tiles, no gaps. Coordinates are (column, row):

  | Tiles | What |
  |---|---|
  | (0, 0), (1, 0) | Water surface, frames 1 and 2 |
  | (0, 1) | Water body (one frame) |
  | (2, 0), (3, 0) | Waterfall top, frames 1 and 2 |
  | (2, 1), (3, 1) | Waterfall body, frames 1 and 2 |
  | (2, 2), (3, 2) | Waterfall base, frames 1 and 2 |
  | (1, 1), (0, 2), (1, 2) | Empty |

- One water `TileSet` (`tile_size` `Grid.TILE` × `Grid.TILE`, one atlas source, no physics, no
  terrains), used by `Water`, `Waterfalls` and every ground piece's
  `Piece<n>Waterfalls`.
- The animated tiles are (0, 0), (2, 0), (2, 1) and (2, 2), each with 2
  frames laid out left to right (animation columns 0), each frame lasting
  0.1333 s (7.5 frames per second, the same as the enemies' animations),
  default animation mode, so every copy of a tile moves in step. In code,
  on the atlas source: `set_tile_animation_columns(coords, 0)`,
  `set_tile_animation_frames_count(coords, 2)` and
  `set_tile_animation_frame_duration(coords, frame, 0.1333)` for each
  frame.
- Whether the water and waterfalls keep animating while the game is paused
  (the injury freeze, death, the win) does not matter: either is fine.
  Nothing needs to be done about it.
- When `has_water` is on, `Water` gets the **water surface** on every
  column of **row 13** and the **water body** on every column of **row 14**,
  from column 0 to the level's last column.

## Spikes

So a gap reads as a deadly drop, not a way out, every gap gets a row of
spikes. Purely visual, like the water.

- One tile, `res://art/spike/sprite_1.png` (18 × 18). The spikes fill only
  its bottom 9 px; the top half is empty.
- One spikes `TileSet` (`tile_size` `Grid.TILE` × `Grid.TILE`, one atlas
  source, no physics, no terrains), the same in every biome, used by
  `Spikes`.
- When `has_water` is **off**, `Spikes` gets a spike tile on **row 13** of
  every column of every gap.
- **The spikes stand on the death line**, not on the grid: the `Spikes`
  layer's `position.y` is `Screen.height - 14 * Grid.TILE` (5 px), the gap
  between the bottom of row 13 and the death line. So a row-13 tile is drawn
  from y 239 to 257, and the spikes from y 248 down to exactly 257, the
  death line and the bottom of the screen. On the grid they would end at
  252 and float 5 px above the bottom.
- When `has_water` is on, there are no spikes: rows 13 and 14 are water in
  every column, which already shows the danger.
- `Spikes` is drawn right after `Ground`, so waterfalls, blocks, items,
  enemies and the player are drawn in front of it.
- Nothing touches the spikes. The player dies when its feet reach the
  death line (`Screen.height`, 257), the spikes' base, so falling into a
  gap looks like landing in the spikes.

## Decorations

Small one-cell pictures (plants, fences, mushrooms and so on) that sit on
the ground, plus waterfalls when the level has water. Purely visual: the
player and enemies never touch them.

- One sheet per biome: `res://art/decorations/snow.png` (9 decorations),
  `res://art/decorations/grass.png` (7) and `res://art/decorations/desert.png` (8). Each is one row of 18 × 18 tiles, no gaps; every
  decoration stands on the bottom of its tile.
- One decorations `TileSet` per biome: `tile_size` `Grid.TILE` × `Grid.TILE`, one atlas
  source (Texture Region Size 18 × 18, Separation 0, Margins 0), no physics
  layer, no terrains.
- **Which floors:** checked once per floor, before anything is placed.
  Gaps never get decorations, and neither does a floor on **row 14**
  (only its top 5 px are on screen).
- **Placement:** every surface tile of a decorated floor has a **20 %**
  chance (`randf() < 0.2`) of a decoration. The decoration is picked with
  `randi_range`, each candidate equally likely. The candidates are the
  biome's decorations, plus a **waterfall** when `has_water` is on and the
  floor's row is 11 or less (so the waterfall has room for its top and
  base), plus one **big decoration** when that tile allows one and its
  cooldown allows (see Big decorations).
- **A plain decoration** goes in the cell directly above the surface tile,
  in `Decorations`, with the built-in `set_cell()`.
- **A waterfall** goes in `Waterfalls`, in that tile's column: its top on the
  surface tile itself (covering it), waterfall body on every row below down
  to row 11, and its base on **row 12**, just above the water surface. It
  is drawn in front of the ground and behind the water.
- The randomness is not seeded: decorations come out differently on every
  build. That is fine.

### Big decorations

Trees (`trees.md`), pipes (`pipes.md`) and ropes (`ropes.md`) are big
decorations. They share one candidate in the roll above and one cooldown.

- **Away from the start and the flag:** a big decoration is only planted
  on a surface tile at least **5 columns** from the start area and from
  the flag area: from column 12 to the 6th column left of the flag's
  column. 5 columns is the furthest a big decoration reaches sideways from
  its tile (a pipe's second leg; a tree's or rope's supporting pieces
  reach 4), so none of it is ever drawn over the start or the flag.
  Outside those columns there is no big-decoration candidate.
- **Which kinds are allowed on a surface tile:** a tree when `biome` is
  `GRASS`; a pipe when `has_water` is on; a rope in every biome, but only
  on a floor whose row is 8 or more. When none is allowed on that tile,
  there is no big-decoration candidate there.
- **Cooldown:** the build remembers the x of the last big decoration it
  planted, of any kind. The candidate is only there when the current
  surface tile is at least `Screen.width` (459 px, one screen width) to the
  right of it, measured between the two tiles' left edges (that is, 26
  tiles or more apart). Before the first one there is no cooldown.
- **When the roll picks it**, its kind is `pick_random()` from the kinds
  allowed on that tile, each equally likely: on a floor on row 8 or more in
  a grass level with water, each big decoration is a tree, a pipe or a rope
  at random. It is planted on that surface tile, and no plain decoration
  goes there.

### Ground pieces

So the plain, flat fill under the floors doesn't look bland, some floors
get a **ground piece**: a picture of a lower ledge, drawn in front of the
ground's fill where two floors meet, with its own outline. Purely visual:
it looks like ground but nothing touches it.

- **Which floors:** every floor except the first, each paired with the floor
  before it, end floor included. A pair can get a piece only if both
  floors are **2 or more** wide, and the start row below is 14 or less (so
  a pair with a gap, or with a floor on row 14, never gets one: there is
  no room on screen).
- **Chance:** each such pair gets a piece **half** the time
  (`randf() < 0.5`). Not seeded, like the decorations.
- **Start row:** one row below the **lower** of the two surfaces:
  `maxi(previous.row, this.row) + 1`. So the piece is always inside solid
  ground, under both floors, and never reaches into the air the player
  walks through.
- **Columns:** a left column picked in the previous floor and a right
  column picked in this floor (`randi_range`, each equally likely), never
  the pair's outer ends: the left one is never the previous floor's first
  column, the right one is never this floor's last column. The columns
  where the two floors meet can be picked. So a piece always crosses the
  join between the two floors and is 2 or more wide.
- **Shape:** a rectangle from the start row down to row 14, between the
  two picked columns (both included).
- **One layer per piece:** every piece gets its own `TileMapLayer`, so
  each keeps its own outline. Pieces of neighbouring pairs can overlap
  (both can use the middle floor's columns); on one shared layer, terrain
  painting would merge them into one shape.
  - `GroundPieces` (see Building) is a `Node2D` holding, for each piece in
    floor order, three layers: `Piece<n>`, then `Piece<n>Waterfalls`, then
    `Piece<n>Decorations` (see Decorations on top), `<n>` counting from 0.
  - Godot draws later children on top, so a later piece is drawn in front
    of the earlier one, outline, waterfalls and decorations included: it
    looks like a ledge in front of the other. Nothing is erased or drawn
    over by hand.
  - Each `Piece<n>` uses the level's biome `TileSet`, with
    `collision_enabled = false`, so the tiles' collision shapes are not
    made: nothing collides with it.
- **Tiles:** the piece's rectangle is painted with the built-in
  `set_cells_terrain_connect(cells, 0, 0)` on its own layer, like the
  ground (`level-tiles.md`, Terrains): Godot picks the corners, edges and
  ends and mixes the two fills. Tested on 4.7.2 with the ground sheet:
  rectangles 1 × 1, 3 × 1, 1 × 4, 2 × 2, 5 × 3 and 4 × 5 all came out with
  the right outline tile in every cell.
- **Decorations on top:** a piece's top row is decorated like a floor's
  surface (see Placement above), except that it never gets a big
  decoration: every cell of its top row has a **20 %** chance
  (`randf() < 0.2`) of a decoration, picked with `randi_range` from the
  biome's decorations, plus a **waterfall** when `has_water` is on and the
  piece's top row is 11 or less, the same condition as a floor's. A piece
  whose top row is 14 or more gets none, or 13 or more when `has_water` is
  on.
  - **A plain decoration** goes in the cell directly above, in the piece's
    own `Piece<n>Decorations` layer, using the biome's decorations
    `TileSet`. The plain `Decorations` layer is behind the ground, where
    it would be hidden.
  - **A waterfall** goes in the piece's own `Piece<n>Waterfalls` layer,
    using the water `TileSet` (see Water), built exactly like a floor's:
    its top on the piece's top-row cell (covering it), body down to row
    11, base on row 12. It is drawn in front of its piece and behind the
    water. With water a piece starts one row below the lower of its two
    floors, so only a piece under floors on row 10 or less can get one.
  - Each kind needs its own layer because a `TileMapLayer` holds one
    `TileSet`: the piece the biome's, the waterfalls the water one, the
    decorations the decorations one.
  - A later piece's layers come after all three, so a later piece drawn
    over an earlier piece's waterfall or decoration covers it.
  - Over the lower floor's columns, the cell above a piece is that floor's
    surface row, so a decoration there is drawn in front of the floor's
    top tile, never above its surface line.

## Snapshot

To check a level by eye, a snapshot renders one screen of it to a PNG, with
guides drawn on top. It uses Godot's built-in Movie Maker mode, so it needs
no screenshot code:

```
godot --path . --write-movie snapshots/level_1_page_0.png --quit-after 2 res://tools/snapshot.tscn -- 1 0
```

- **The `snapshots/` folder must exist first** (`mkdir -p snapshots`).
  Movie Maker does not create it: without it, it prints
  `Condition "d.is_null()" is true`, writes nothing, and still exits with
  code 0 (tested on 4.7.2).
- **No random art in a snapshot:** while `Level.show_guides` is on, the
  build skips the plain decorations, the waterfalls, the big decorations
  (trees, pipes, ropes), the ground pieces with their decorations, and
  the plants hanging under mushroom caps.
  They are only random pictures that nothing touches, and each snapshot
  is its own run, so they would come out differently on every page and
  every snapshot and get in the way of reading the level. Everything else
  is built as usual: the ground, water, spikes, platforms, ladders and
  every placed thing.
- **The same looks on every page:** the rest of the build still picks at
  random (the platforms', doors' and gift blocks' looks, the ground's two
  fills), so the snapshot seeds Godot's random numbers with a fixed
  number, `seed(1)`, before it adds the level. Every page of a level then
  shows the same looks. Tested on 4.7.2: after `seed()`, `pick_random()`,
  `randi_range()` and terrain painting come out the same on every run.
  Editing the level script can change which looks come out, since things
  may then ask for random numbers in a different order; that is fine.
- `res://tools/snapshot.tscn` has one script. It reads the level number and
  the page from `OS.get_cmdline_user_args()` (everything after `--`).
- It sets `Level.show_guides = true` (a `static var` on `Level`, false
  otherwise), calls `seed(1)`, instantiates `res://levels/level_<n>.tscn`
  and adds it. The level builds itself as usual. It is not the scene being
  played (`is_main` is false, `game-flow.md`), so it has no iris and does
  not pause itself.
- Then it pauses the game (`get_tree().paused = true`), so everything stays
  exactly where it was placed, and puts the camera on the page.
- **Pages step by whole tiles:** page `p` puts the camera's left edge at
  column `25 * p` (x = 450 × p). A screen is 25.5 columns wide, so each
  page overlaps the next by half a column. The camera's right edge is still
  clamped to `level_end_x`, like in the game, so a page past the end shows
  the last screen.
- Movie Maker writes numbered frames (`level_1_page_000000000.png`,
  `level_1_page_000000001.png`); the last one is the snapshot. Frames are
  the window's size, 1377 × 771 (3 × the screen). It also writes a sound
  file next to them (`level_1_page_0.wav`), which is not used.
- A snapshot needs a window: it opens one for about a second. With
  `--headless`, Movie Maker crashes (tested on 4.7.2). Drawing on the first
  frame, a camera moved while paused, and drawing into another node from
  its `draw` signal were all tested and work.

### Guides

Drawn only while `Level.show_guides` is true, never in a normal run.

The level root does not draw the grid and markers on itself: a node's own
drawing goes under its children, so the ground and everything else would
cover them. It draws them into its `Guides` child instead, which comes after
every other drawn layer (see Building): it connects to the built-in `draw`
signal of `Guides` and draws with `guides.draw_line()` and the like.

- a grid: faint lines on every tile (`Grid.TILE`), from x = 0
  to `level_end_x` and over rows 0 to 14; column numbers along the top of
  every column, and row numbers (0 to 14) down the left edge of every page
  (every 25 columns), in Godot's built-in fallback font
  (`ThemeDB.fallback_font`), small and high-contrast
- red markers for failing jumps (see Jump check)
- each enemy's and spring's own guides, drawn by the thing itself (so later
  layers, such as the player or the water, may cover parts of them): the
  flyer's path (`enemy-flyer.md`), the leaper's path (`enemy-leaper.md`),
  the bar's sweep circle and starting line (`enemy-bar.md`), the spring's
  reach (`spring.md`)

The loop is: edit a cell in the level script, take a snapshot, look, edit
again.

## Level end, gap line and death line

- `level_end_x` is a read-only property (a GDScript getter) on the level
  root: the sum of all floor widths × `Grid.TILE`. It is the right edge of the
  ground, where the camera stops (`camera.md`).
- `gap_row` is a read-only property (a GDScript getter) on the level root:
  the row from which a floor is a gap and no ground is built (see Floors),
  and below which nothing may be placed (see Checking the layout). **15**
  without water, **13** with water.
- **The death line** is the same in every level: `Screen.height` (257),
  the bottom of the screen. The player dies when its feet reach it
  (`player-damage.md`). It does not move with the water: a player who
  falls into the water sinks behind it (`Water` is drawn after `Player`)
  for its last 23 px, then dies. No property holds it; code uses
  `Screen.height`.

## Jump check

At the end of building, every run, the level root checks that the level
can be crossed from start to finish: from everything the player can stand
on, there is a way onward to the right.

- **Standable things** are every floor that is not a gap, and every
  one-way platform (`one-way-platform.md`). Both come from the same line:
  a floor on `gap_row` or below is a gap, and a platform there is already
  an error (see Checking the layout), so the check never needs to look at
  rows itself.
- **Ahead:** one standable thing is ahead of another when its right edge is
  further right. (So a floor that runs on under a platform and past it is
  ahead of that platform, and a platform that starts above a floor but ends
  past it is ahead of that floor.)
- The check walks the floors first, start floor included (so the first
  jump is checked too), then the platforms. For each standable
  thing, it has up to **two targets**: the first floor ahead of it (the
  next standable one in `floors`, which runs left to right, skipping gaps)
  and the first platform
  ahead of it (the one with the leftmost left edge; `platforms` can be in
  any order, and on a tie the one listed first). A thing with nothing ahead
  of it (the end floor, or a platform reaching the level's end) needs no
  check.
- **A standable thing passes** if the player can get onto at least one of
  its targets.
- This is enough for the whole level: if every standable thing passes,
  then from wherever the player stands, a chain of jumps, each ending
  further right, leads to the end floor.
- **The arc:** once per build, the level root **simulates one full jump
  with the player's own update steps** (`player-movement.md`): standing at
  top walking speed (101.25 px/s to the right), jump held the whole time,
  gravity first then the jump, then move. It records the player's origin
  (the centre of its feet, as in `camera.md`) after every update, as
  distance to the right and height above the take-off, until the arc has
  dropped `Screen.height` below the take-off (nothing standable is lower).
  It uses the player's constants, never a copied table of results, so it
  stays right if a number is tuned. The arc is the same from every
  take-off, so it is simulated only once.
- **Reach at a distance `d`** to the right of the take-off:
  - up to the apex's distance: the apex height. Before the apex, the player
    can get that high above anything there: it rises up a cliff's side,
    rises through a one-way platform, or jumps from right under it.
  - past the apex: the arc's height at `d`, on the straight line between
    the two recorded updates either side of `d`.
- **A target works** if its surface is no higher than the reach at its
  left edge, measured from the take-off: the right edge of the thing the
  jump starts from. A target that starts at or behind the take-off counts
  as `d` = 0. Floors and platforms are judged the same way.
- So a jump fails for one of two reasons: the target is too tall (above
  the apex, or above the falling arc at its distance), or too far (the arc
  has already dropped below it).
- Only a target's left edge matters, never its right edge: the arc holds
  right at top speed, and a real player lands on a narrow target by letting
  go of right sooner.
- **A failing jump stops the build**, like the layout checks: the level is
  only accepted if it can be crossed. The check goes through **every**
  standable thing and appends one message to `errors` for each that fails
  (no target works), naming the floor (see Floors) or the platform by its
  index, with its right edge's cell, e.g.
  `"floors[3] (columns 14 to 16, row 9): no jump onward from (16, 9)"`.
  So one run shows everything to fix, printed and stopped the same way as
  the layout errors (see Checking the layout). The level is already built
  here, so one more frame runs before the quit, which is harmless.
- **In a snapshot** (`Level.show_guides` on) the check does not stop the
  build: the messages are still printed, and it draws a red marker at the right edge of each failing thing
  instead (see Snapshot), so the failures can be seen in place.
- Ladders (`ladder.md`) are not part of the check, and a ladder's top is
  not a standable thing here: every level must be crossable by jumping
  alone.
- Doors (`door.md`) are not part of the check either: a door wins the
  level, but every level must still be crossable to the flag.
- Springs (`spring.md`) are not part of the check: every level must be
  crossable without them. A spring is only ever an extra.
- Blocks (`breakable-block.md`, `gift-block.md`) are not part of the
  check either: a block is not a standable thing here, and the check never
  looks for blocks in the way of a jump. Keeping blocks out of the way
  across (for example, no row of gift blocks just above a gap's take-off,
  where they would cut the jump short) is up to the level design: check
  it on a snapshot.

For reference, with today's numbers and no water, the furthest reachable
next floor is:

| Next floor is… | Furthest it can start |
|---|---|
| 5 or more rows higher | Unreachable (a full jump peaks at 4.59 tiles) |
| 4 rows higher | 3 tiles away |
| 1 to 3 rows higher | 4 tiles away |
| Same row, or 1 or 2 rows lower | 5 tiles away |
| 3 or 4 rows lower | 6 tiles away |
| 5 to 7 rows lower | 7 tiles away |
| 8 to 10 rows lower | 8 tiles away |
| 11 or 12 rows lower | 9 tiles away |
| 13 or 14 rows lower | 10 tiles away |

**Reach straight up:** standing on a floor (or a block), the player is
expected to reach anything with up to **5 air cells** between it and the
floor in one jump: the feet rise 82.6 px and the head is 15 px above them,
so the head reaches 97.6 px, past a block's bottom 5 cells up (90 px) but
not 6 (108 px). Use this when placing blocks (to be bonked from below) and
coins. It is a guide for the level design, not a check: blocks and coins
may go anywhere.

## Acceptance test

| Case | Expected |
|---|---|
| `[Vector2i(30, 11)]` | `Ground` cells: the start floor in columns 0 to 6, rows 12 to 14; columns 7 to 36, rows 11 to 14; then the end floor in columns 37 to 46, rows 12 to 14; no other `Ground` cells |
| A floor on row 15 | No tiles and no decorations in its columns |
| A floor on row 14 | Ground tiles, but no decorations |
| A long floor | About 1 in 5 surface tiles has a decoration or waterfall, from the level's biome |
| Decorations | Drawn behind the ground, the player and enemies; never block anything |
| `has_water` on, 30 columns of written floors | Water surface on row 13 and water body on row 14, columns 0 to 46 (start and end floors included), animating |
| `has_water` off | No water and no waterfalls |
| Floors starting `[Vector2i(4, 8), Vector2i(5, 11), ...]`, the pair gets a piece | The written floors start at column 7, so: start row 12 (one below the lower surface, row 11); left column 8 to 10, right column 11 to 14; rows 12 to 14; outlined, fills mixed |
| Many builds of the same level | About half of the allowed pairs get a piece |
| A pair where either floor is 1 wide | Never a piece |
| A pair with a gap, or with a floor on row 14 | Never a piece |
| A ground piece | Drawn in front of the ground and waterfalls, behind the water, blocks, enemies and the player; nothing collides with it (`collision_enabled` is false) |
| Two overlapping pieces | Each on its own layer; the later one is drawn whole, outline included, over the earlier one |
| A level with 2 pieces | `GroundPieces` holds `Piece0`, `Piece0Waterfalls`, `Piece0Decorations`, `Piece1`, `Piece1Waterfalls`, `Piece1Decorations`, in that order |
| A long ground piece | About 1 in 5 cells of its top row has a plain decoration above it, from the level's biome, drawn in front of the ground |
| A later piece drawn over an earlier piece's decoration | That decoration is hidden behind the later piece |
| A piece whose top row is 14 (or 13 with water) | No decorations on it |
| `has_water` on, many pieces with top row 11 or less | About 1 in 5 top-row cells has a decoration or a waterfall; a waterfall's top covers the piece's top-row cell, body down to row 11, base on row 12, in front of the piece and behind the water |
| `has_water` on, a piece with top row 12 | Plain decorations only, never a waterfall |
| `has_water` off | No waterfall on any piece |
| A later piece drawn over an earlier piece's waterfall | The waterfall is hidden behind the later piece |
| `has_water` off, a 3-column gap | A spike tile on row 13 of each of the 3 columns; nothing else in them |
| Any spike | Spikes drawn from y 248 to 257: their base on the death line and the screen's bottom edge |
| `has_water` on, a gap | No spikes: water on rows 13 and 14 |
| Player falls into a gap | Passes the spikes and dies at the death line (257); the spikes block nothing |
| A waterfall on a floor on row 8 | Top on row 8, body on rows 9 to 11, base on row 12 |
| `has_water` on, floor on row 12 | Gets decorations but never a waterfall |
| `has_water` on, floor on row 13 or 14 | A gap (`gap_row` is 13): no ground tiles, no decorations, no ground piece; the jump check skips it |
| `has_water` off, floor on row 14 | Ground (`gap_row` is 15), but no decorations |
| `has_water` on, a walker walks off a ledge into the water | It sinks behind the water, falls below the screen and is switched off; it never walks under the water |
| `has_water` on, the player falls into the water | Sinks behind the water and dies when its feet reach y 257, the same death line as without water |
| `has_water` on, a coin, block, walker, platform cell, ladder cell, door or anything else placed on row 13 or 14 | The build stops with an error: it is below the gap line (row 13) |
| `has_water` on, a walker B on row 12 | Allowed: its box takes rows 11 and 12 |
| `has_water` off, a block or coin on row 14 | Allowed |
| `has_water` off, anything placed on row 15 or lower | The build stops with an error: it is below the gap line (row 15) |
| A coin on row -1, above the screen | Allowed |
| `has_water` on, leapers | Allowed: they are columns, always on row 14 |
| Leaper rising from water | In front of waterfalls, behind the water |
| Any `floors` | `level_end_x` = sum of widths × `Grid.TILE` |
| Snapshot | Numbered grid and guides shown |
| Snapshot | No plain decorations, waterfalls, trees, pipes, ropes, ground pieces or plants under mushroom caps; ground, water, spikes, platforms, ladders and placed things as usual |
| Two snapshots of different pages of the same level | Every platform, door and gift block looks the same in both, and so do the ground's fills |
| Snapshot | No iris, not paused by the level |
| Many builds of a long level | No tree, pipe or rope is planted left of column 12 or right of the 6th column left of the flag, and none reaches into the start or flag area |
| Snapshot with no `snapshots/` folder | Nothing written; create the folder first |
| Normal run | No grid, no guides |
| Snapshot page 1 | Camera's left edge at x = 450 |
| Snapshot page past the level end | Camera's right edge at `level_end_x` |
| Coin at cell (4, 6) | `position` (72, 108) |
| Walker at cell (5, 10) | `position` (99, 198): feet on top of row 11 |
| Flyer at cell (5, 4) | `position` (99, 81) |
| A spawn given a wrong type, e.g. `FlyerSpawn.new(Vector2i(5, 4), "far")` | GDScript error; the level does not run |
| Level root and every placed thing | No `@tool`, no `@export` |
| Two items in the same cell, in one list or across lists (for example a coin and a walker) | The build stops with an error naming both, e.g. "walker at (14, 6) overlaps coin at (14, 6)" |
| A block inside the ground | The build stops with an error |
| A walker A one column right of a walker B | The build stops with an error (walker B takes that cell) |
| Two walker Bs two columns apart | The build stops with an error (both take the column between) |
| A bar, flyer or leaper on ground, a block, a coin or another thing | Allowed |
| Two bars on one cell, two flyers on one cell, or two leapers in one column | The build stops with an error naming the list and the cell or column |
| A floor with width 0 | The build stops with an error |
| Any level | Its first floor is `Vector2i(7, 12)` and its last `Vector2i(10, 12)`, both added by the level root; the level script has no `player_cell` |
| Any level, no checkpoint touched | The player starts in cell (4, 11), standing on the start floor: `position` (81, 216) |
| Written floors 8 columns wide (level 25 columns, under one screen) | The build stops with an error |
| Written floors 9 or 238 columns wide (level 26 or 255) | Allowed |
| Written floors 239 columns wide (level 256) | The build stops with an error |
| A coin, block, walker, flyer, leaper, crusher, bar, spring, door, checkpoint, platform cell or ladder cell in columns 0 to 6 | The build stops with an error saying it is in the start area |
| Any of them in the flag's column or right of it, inside the level | The build stops with an error saying it is in the flag area |
| Any of them in column -1 or past the last column | The build stops with an error saying it is outside the level |
| A walker B in column 7 (its box reaches column 6) | The build stops with an error: it is in the start area |
| A door on the column left of the flag | Allowed (the door and its top take one column) |
| A level with a coin in the start area, a floor 0 wide and two coins on one cell | One run prints all three errors, as `ERROR:` lines, and nothing is built |
| Any error | The run exits with code 1; a level with no errors runs as usual |
| An error message about a written floor | Names it by its index and its columns and row, e.g. `floors[3] (columns 14 to 16, row 9)` |
| A walker inside the ground | The error names the floor, e.g. "walker at (14, 10) overlaps floors[3] (columns 14 to 16, row 9)" |
| Written floors ending with a floor on row 12, then a 6-column gap | The jump check fails onto the end floor (same row, 6-tile gap): the build stops |
| The example level above (26 written columns, 43 in all) | Written floors in columns 7 to 32; end floor in columns 33 to 42; flag in column 33, x = 594; no errors |
| A checkpoint with a floor's surface cell or a platform cell under it | Allowed |
| A checkpoint over a gap, over air, or over a block | The build stops with an error naming the checkpoint |
| A checkpoint with anything placed in its cell or the cell above | The build stops with an error naming both |
| A walker or crusher on a ground cell or a block's cell | The build stops with an error naming both |
| Walker B with ground or anything placed to its left, right, top-left, top or top-right | The build stops with an error naming both |
| A walker A or C next to ground, in a free cell | Allowed |
| `Kind.PLAIN`, `Kind.SHELL`, `Kind.SPIKED` walkers | Walker A, B and C, every build; A and C take one cell, B its six |
| Any gift block | Look A, B or C, each equally likely, picked at build time; `GiftBlockSpawn` has no look to set |
| A gift block holding a diamond, with ground, a block or anything placed in the cell above it | The build stops with an error naming both |
| A gift block holding a coin, with a block in the cell above it | Allowed |
| A gift block holding a diamond on row 0 | The build stops with an error |
| A spring on ground, a block, a coin or a walker's cell | The build stops with an error naming both |
| A platform 0 wide | The build stops with an error |
| A platform on ground, a block or another platform | The build stops with an error naming both |
| Any platform | Drawn as one of its biome's looks (`one-way-platform.md`) |
| Any leaper with `has_water` off | The build stops with an error |
| A leaper in column 5 | `position` (99, 261): the middle of row 14, behind the water |
| A flyer with `bob_distance` 0 | Allowed: it hovers in place |
| A flyer at row 1 (y 27) with `bob_distance` 220 (down to y 247) | Allowed: sprite fully on screen at both ends |
| A flyer at row 1 with `bob_distance` 221, or `bob_distance` -18 | The build stops with an error |
| A flyer at row 0 (y 9) | The build stops with an error: its sprite's top is 1 px above the screen |
| A level script without `layout()`, or with a different signature | GDScript error |
| `Level` attached to a node directly | GDScript error (abstract) |
| A scene added without `setup()` | Stops at its `_ready` with "setup() not called" |
| A coin pops out of a gift block | The coin is in `BlockItems`, drawn behind the block |
| An enemy is stomped | Its death scene is in `Effects`, drawn in front of the water |
| `biome` changed to `GRASS` | `Ground`, every `Piece<n>` and `RopeCeilings` use the grass `TileSet`; `Decorations`, every `Piece<n>Decorations` and `RopeCeilingDecorations` use the grass decorations `TileSet`; the background is `res://art/backgrounds/sprite_3.png` |
| Same row, 5-tile gap | Jump check passes |
| Same row, 6-tile gap | The build stops with an error naming the floor; in a snapshot, a red marker instead |
| Two failing jumps in one level | Both in the errors, printed in one run |
| Next floor 4 rows higher, no gap | Passes |
| Next floor 5 rows higher, no gap | Fails |
| Next floor 1 column wide, same row, 1-tile gap | Passes (the full-speed jump flies over it, but would land past its left edge) |
| Snapshot | Grid and red markers drawn in front of the ground, blocks, water and everything else in the level |
| Same row, 7-tile gap, with a 3-wide platform on that row starting 3 tiles into the gap | Passes: the first floor reaches the platform, the platform reaches the next floor |
| The same without the platform | Fails on the first floor: the build stops; in a snapshot, a red marker there |
| A gap only a spring can get past | Fails: springs are not part of the check |
| A row of gift blocks just above a gap's take-off, low enough to cut the jump short | Passes: blocks are not part of the check |
| A platform 4 rows above a floor's right edge, starting left of it and ending past it | The floor passes: the player jumps up through the platform and lands on it |
| A platform over a floor that runs on past the platform's right end | The platform passes: walking off its end lands on the floor |
| A platform 2 rows below a floor's right edge, starting at the take-off point | The floor passes: walking off the edge lands on it |
