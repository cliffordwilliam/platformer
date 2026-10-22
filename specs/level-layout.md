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
- The game starts at level 1: the project's main scene
  (`application/run/main_scene`) is `res://levels/level_1.tscn`.
- Levels are played in a straight line, one way: level 1, then level 2,
  and so on. No going back and no level select. How a won level moves on
  to the next comes with the later spec on what follows a win (`flag.md`).
- No `@tool` and no `@export`: a level is plain text in its script. One
  level, one script, like one stylesheet per page.
- `Level` declares one abstract function, `@abstract func layout() -> void`.
  Every level script must implement it, with that exact signature, or
  GDScript reports an error. `layout()` does nothing but set these
  fields:

| Field | Type | Meaning |
|---|---|---|
| `biome` | `Level.Biome` (`SNOW`, `GRASS`, `DESERT`) | Which tile look the level uses |
| `floors` | `Array[Vector2i]` | The ground, left to right (see Floors) |
| `has_water` | `bool` | Whether the level has water along the bottom (see Water) |
| `player_cell` | `Vector2i` | Where the player starts (`camera.md`) |
| `blocks` | `Array[BlockSpawn]` | Breakable and gift blocks, in one list (`breakable-block.md`, `gift-block.md`) |
| `coins` | `Array[Vector2i]` | Cells (`coins.md`) |
| `walkers` | `Array[WalkerSpawn]` | `enemy-walker.md` |
| `flyers` | `Array[FlyerSpawn]` | `enemy-flyer.md` |
| `leapers` | `Array[int]` | Columns only: a leaper always starts behind the water (`enemy-leaper.md`) |
| `crushers` | `Array[Vector2i]` | Cells (`enemy-crusher.md`) |
| `springs` | `Array[Vector2i]` | Cells (`spring.md`) |
| `doors` | `Array[Vector2i]` | Cells: each door's bottom tile (`door.md`) |
| `bars` | `Array[BarSpawn]` | `enemy-bar.md` |
| `platforms` | `Array[PlatformSpawn]` | One-way platforms; each gets a random look from its biome's (`one-way-platform.md`) |
| `ladders` | `Array[LadderSpawn]` | Ladders (`ladder.md`) |

Example:

```gdscript
extends Level

func layout() -> void:
	biome = Biome.GRASS
	has_water = false
	floors = [Vector2i(10, 11), Vector2i(3, 15), Vector2i(13, 9)]
	player_cell = Vector2i(2, 10)
	blocks = [
		BreakableBlockSpawn.new(Vector2i(5, 7)),
		BreakableBlockSpawn.new(Vector2i(6, 7)),
		GiftBlockSpawn.new(Vector2i(7, 7), GiftBlockSpawn.Variant.A, GiftBlockSpawn.Contents.DIAMOND),
	]
	coins = [Vector2i(14, 6), Vector2i(15, 6)]
	walkers = [WalkerSpawn.new(Vector2i(8, 10), WalkerSpawn.Variant.B)]
	flyers = [FlyerSpawn.new(Vector2i(12, 4), 36.0)]
	bars = [BarSpawn.new(Vector2i(16, 5), 2, 0.0, true)]
```

- `biome` sets `Ground`'s and `GroundPieces`' `tile_set` to that biome's
  `TileSet` (`level-tiles.md`), `Decorations`' `tile_set` to that biome's
  decorations `TileSet` (see Decorations), and the `Background`'s picture
  (`background.md`).
- `Level._ready()` calls `layout()`, adds the end floor, checks the
  layout, then builds everything (see Building).

## Floors

The ground is an ordered list of floors, each a `Vector2i(width, row)`:

- **`width`**: how many tiles wide the floor is (1 or more).
- **`row`**: the tile row of the floor's top surface, counted from
  row **0** at the top of the screen, like Godot's y. Row 5 means the ground
  starts 5 rows down.
- Floors follow each other with no overlaps or holes. The first floor
  starts at x = 0.
- Each floor is filled solid, from its surface row down to **row 14**, the
  last row the screen shows (rows are `Grid.TILE` high, so row 14 is 252–270 and only
  its top 5 px are on the 257 px screen).
- **A gap** is a floor whose row is 15 or more: below the screen, so
  nothing is drawn.
- **The end floor:** right after `layout()`, the level root adds one more
  floor to the end of `floors`: `Vector2i(10, 12)`, 10 columns on row 12.
  The level script never writes it. It holds the flag's column (the 10th
  from the right, `flag.md`) and the 9 columns after it, so the flag always
  stands on ground, above the water (rows 13 and 14). From then on
  `floors` means the whole list, end floor included: the width, building,
  decorations and the jump check all use it, so the jump from the last
  written floor onto the end floor is checked too.

Example: `[Vector2i(10, 11), Vector2i(3, 15), Vector2i(8, 9)]` is 10 tiles of
ground at row 11, a 3-tile gap, then 8 tiles of ground 2 rows higher.

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
| `WalkerSpawn` | `cell: Vector2i, variant: Variant` (`enum Variant { A, B, C }`: `walker_a/`, `walker_b/`, `walker_c/`) |
| `GiftBlockSpawn` | `cell: Vector2i, variant: Variant, contents: Contents` (`enum Variant { A, B, C }`: `gift_block_a/` to `gift_block_c/`; `enum Contents { COIN, DIAMOND }`) |
| `FlyerSpawn` | `cell: Vector2i, bob_distance: float` |
| `BarSpawn` | `cell: Vector2i, units: int, start_angle: float, clockwise: bool` |
| `PlatformSpawn` | `cell: Vector2i, width: int` (`cell` is the platform's left end) |
| `LadderSpawn` | `cell: Vector2i, height: int` (`cell` is the ladder's bottom; it grows up) |

- **Blocks:** `BlockSpawn` is `@abstract` and holds only `cell`.
  `BreakableBlockSpawn` and `GiftBlockSpawn` extend it, so both kinds go in
  the one typed `Array[BlockSpawn]`, and the level builds each with the
  scene for its class (`spawn is GiftBlockSpawn`).
- A kind with no settings (coins, crushers, springs, doors) is just a list of cells.
  Leapers are just a list of columns: their row is always 14, behind the
  water (`enemy-leaper.md`).
- **One thing per cell:** no two things share a cell, in any list or
  across lists. Bars, flyers and leapers only check their own list (see
  Checking the layout, Occupied cells).

### Checking the layout

Right after `layout()` and the end floor, before anything is built, the
level root checks the values the level script wrote, like validating input
before doing any work. Each check is an `assert` whose message names the
field and the bad value, so a mistake stops the build at once. The checks
read only the written fields (`floors`, `has_water`, `player_cell`, the
lists), never built nodes or physics.

Outside the editor (a headless run, a snapshot), a failed `assert` only
prints `SCRIPT ERROR: Assertion failed: <message>` to the output and stops
`_ready` there: the game keeps running with a half-built level and exits
with code 0 (tested on Godot 4.7.2). So after every run and every snapshot,
read the output for `Assertion failed`. (Asserts are left out of release
exports, so these checks only run in debug builds.)

- **`floors`:** every width is 1 or more, and the level, end floor
  included, is **1 to 10 screens wide**:
  `Screen.width <= level_end_x <= 10 * Screen.width`, which is 26 to 255
  columns. So the written floors cover 16 to 245 columns: everything left
  of the flag. Narrower than a screen, the camera's clamp (`camera.md`)
  would have nowhere to go.
- **`player_cell`:**
  - its column is 0 or more, and left of the flag's column (`flag.md`):
    on or past the flag, the player would win on its first update
  - its row is free. Negative (above the screen): the player drops in from
    the top. On or below the death line: the player dies on its first
    update, which is allowed.
- **Inside the level:** every cell in `blocks`, `coins`, `walkers`,
  `flyers`, `crushers`, `bars`, `springs` and `doors` has a column from 0 to the last column,
  like the leapers below, and so does every cell of every platform in
  `platforms` and every ladder in `ladders`. Rows are free.
- **`platforms`:** every width is 1 or more, like the floors.
- **`ladders`:** every height is 1 or more.
- **`blocks`:** a gift block holding a diamond is on row 1 or more. On
  row 0, the cell its diamond comes out into is above the screen, where
  the diamond's enabler would switch it off for good.
- **`leapers`:** only allowed when `has_water` is on (a leaper always
  leaps out of the water), and every column is inside the level (0 to the
  last column).
- **`flyers`:** the flyer's whole sprite is on screen at both ends of its
  path (a `bob_distance` of 0 is allowed: it hovers, `enemy-flyer.md`):
  for the start `y = cell_to_position(cell, centre).y` and the other end
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
  holds what took it, for example `"coin at (14, 6)"`, so the `assert`
  message can name both things:
  `"walker at (14, 6) overlaps coin at (14, 6)"`.
- Taking a cell: if `occupied.get(cell, "")` is not `""`, the `assert`
  fails, unless an exception below allows it; otherwise the cell is stored.
- Cells are taken **in this order**:
  1. **ground:** every cell of every floor that is not a gap, from its
     surface row down to row 14, as `"ground"`
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
  4. **the player**, its own cell
  5. **coins**
  6. **springs**, each its own cell
  7. **doors**: each its own cell and the cell above it, where its top
     reaches (`door.md`), as `"door at (c, r)"` and
     `"top of door at (c, r)"`
  8. **walkers**: walkers A and C their own cell. **Walker B** takes all six
     cells its 24 × 20 box covers, since it reaches 3 px into the cells on
     each side and 2 px into the row above: for a walker B in cell (c, r),
     (c - 1, r), (c, r), (c + 1, r) and (c - 1, r - 1), (c, r - 1),
     (c + 1, r - 1). So nothing else can be placed where its box is, and
     two walker Bs need two free columns between them.
  9. **crushers**, each its own cell (its 18 × 18 box fills it exactly)
- **Bars, flyers and leapers are not in this check.** They collide with
  nothing, so they are free to be anywhere: in the ground, on a block or on
  another thing. Each only checks its own list for duplicates: no two bars
  on one cell, no two flyers on one cell, no two leapers in one column. A
  duplicate means two of them sit exactly on top of each other, so it
  fails an `assert` naming the list and the cell (or column). Their own
  checks above still apply.
- A walker or crusher in a free cell boxed in by ground is allowed: odd,
  but legal.

### Cell to position

`Level.cell_to_position(cell, origin)` turns a cell into the `position`
for a thing, from the kind of origin it has (`assets.md`):

| Origin | `position` | Where the thing ends up |
|---|---|---|
| Top-left | `cell * Grid.TILE` | Filling the cell |
| Feet | `cell * Grid.TILE + Vector2i(Grid.HALF_TILE, Grid.TILE)` | Standing in the cell, on the top of the cell below |
| Centre | `cell * Grid.TILE + Vector2i(Grid.HALF_TILE, Grid.HALF_TILE)` | Centred in the cell |

The flag is the one exception: it is placed automatically (`flag.md`).

### Building a thing

For every item in a list, the level root:

1. instantiates the kind's scene (`PackedScene.instantiate()`)
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

1. Calls `layout()`, adds the end floor (see Floors), then checks the
   layout (see Checking the layout).
2. Creates its children **in this order**. Godot draws later children on
   top, like layers in a drawing program, so no `z_index` is needed:
   1. `Background` (`Parallax2D`, see `background.md`), drawn behind
      everything
   2. `Trees`, `TreeCanopies`, `TreeCanopiesFront` (`TileMapLayer`s, see
      `trees.md`), drawn behind everything but the background
   3. `Pipes` (`TileMapLayer`, see `pipes.md`)
   4. `Decorations` (`TileMapLayer`)
   5. `Flag` (see `flag.md`)
   6. `Platforms`, then `Ladders` (`TileMapLayer`s, see
      `one-way-platform.md` and `ladder.md`)
   7. `Ground` (`TileMapLayer`)
   8. `Spikes` (`TileMapLayer`, see Spikes)
   9. `Waterfalls`, then `GroundPieces` (`TileMapLayer`s, see
      Decorations, Ground pieces)
   10. `BlockItems` (`Node2D`): empty at the start; the coins and diamonds
       that come out of gift blocks, drawn behind every block
   11. `Blocks` (`Node2D`): the blocks, in list order
   12. `Coins`, `Springs`, `Doors` (a `Node2D` each)
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
3. Fills the tile layers:
   1. every solid cell of `Ground`, with the built-in
      `set_cells_terrain_connect(cells, 0, 0)` (terrain set 0, the
      `ground` terrain), which picks the right autotiles
   2. the one-way platforms (`one-way-platform.md`) and the ladders
      (`ladder.md`)
   3. the decorations and waterfalls (see Decorations), the big
      decorations: trees (`trees.md`) and pipes (`pipes.md`), and the
      ground pieces (see Decorations, Ground pieces)
   4. if `has_water`, the water (see Water); if not, the spikes (see Spikes)
4. Sets the starting positions (`camera.md`, Starting position).
5. Runs the jump check (see Jump check).

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
  terrains), used by both `Water` and `Waterfalls`.
- The animated tiles are (0, 0), (2, 0), (2, 1) and (2, 2), each with 2
  frames laid out left to right (animation columns 0), each frame lasting
  0.1333 s (7.5 frames per second, the same as the enemies' animations),
  default animation mode, so every copy of a tile moves in step.
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
  layer's `position.y` is `death_y - 14 * Grid.TILE` (5 px), the gap
  between the bottom of row 13 and `death_y`. So a row-13 tile is drawn
  from y 239 to 257, and the spikes from y 248 down to exactly 257, the
  death line and the bottom of the screen. On the grid they would end at
  252 and float 5 px above the bottom.
- When `has_water` is on, there are no spikes: rows 13 and 14 are water in
  every column, which already shows the danger.
- `Spikes` is drawn right after `Ground`, so waterfalls, blocks, items,
  enemies and the player are drawn in front of it.
- Nothing touches the spikes. The player dies when its feet reach the
  death line (`death_y`, 257 without water), the spikes' base, so falling
  into a gap looks like landing in the spikes.

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
  Floors whose row is **14 or more** never get decorations, or **13 or
  more** when `has_water` is on (that ground is under the water). Gaps
  never get decorations.
- **Placement:** every surface tile of a decorated floor has a **20 %**
  chance (`randf() < 0.2`) of a decoration. The decoration is picked with
  `randi_range`, each candidate equally likely. The candidates are the
  biome's decorations, plus a **waterfall** when `has_water` is on and the
  floor's row is 11 or less (so the waterfall has room for its top and
  base), plus one **big decoration** when the level allows one and its
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

Trees (`trees.md`) and pipes (`pipes.md`) are big decorations. They share
one candidate in the roll above and one cooldown.

- **Which kinds the level allows:** a tree when `biome` is `GRASS`; a pipe
  when `has_water` is on. A level that allows neither has no big-decoration
  candidate.
- **Cooldown:** the build remembers the x of the last big decoration it
  planted, tree or pipe. The candidate is only there when the current
  surface tile is at least `Screen.width` (459 px, one screen width) to the
  right of it, measured between the two tiles' left edges (that is, 26
  tiles or more apart). Before the first one there is no cooldown.
- **When the roll picks it**, its kind is `pick_random()` from the kinds the
  level allows, each equally likely: in a grass level with water, each big
  decoration is a tree or a pipe at random. It is planted on that surface
  tile, and no plain decoration goes there.

### Ground pieces

So the plain, flat fill under the floors doesn't look bland, some floors
get a **ground piece**: a picture of a lower ledge, drawn in front of the
ground's fill where two floors meet, with its own outline. Purely visual:
it looks like ground but nothing touches it. (Like the bottom of Kenney's
pixel platformer samples, `~/Downloads/kenney_pixel-platformer/SampleB.png`.)

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
- **Tiles:** the biome's solid tiles (`level-tiles.md`), chosen by each
  cell's place in the rectangle, without terrains, like the tree canopies
  (`trees.md`, Canopy tiles): terrain painting would merge a piece into its
  neighbours and erase its outline.
  - 2+ tall: (1, 1) top-left, (2, 1) top, (3, 1) top-right, (1, 2) left,
    the fill in the middle, (3, 2) right, (1, 3) bottom-left, (2, 3)
    bottom, (3, 3) bottom-right. Each fill cell is (2, 2) or (4, 1), each
    equally likely, picked per cell, like the ground's two fills.
  - 1 tall (start row 14): (1, 0) left end, (2, 0) middles, (3, 0) right
    end.
- **Layer:** its own `TileMapLayer`, `GroundPieces`, right after
  `Waterfalls` (see Building): in front of the ground and the waterfalls,
  behind the water and everything placed. It uses the level's biome
  `TileSet`, but with `collision_enabled = false`, so the tiles' collision
  shapes are not made: nothing collides with it.
- **Overlaps:** pieces of neighbouring pairs can overlap (both can use the
  middle floor's columns). Pieces are drawn in floor order with
  `set_cell()`, so a later piece covers the earlier one and keeps its whole
  outline: it looks like a ledge in front of the other.

## Snapshot

To check a level by eye, a snapshot renders one screen of it to a PNG, with
guides drawn on top. It uses Godot's built-in Movie Maker mode, so it needs
no screenshot code:

```
godot --path . --write-movie snapshots/level_1_page_0.png --quit-after 2 res://tools/snapshot.tscn -- 1 0
```

- `res://tools/snapshot.tscn` has one script. It reads the level number and
  the page from `OS.get_cmdline_user_args()` (everything after `--`).
- It sets `Level.show_guides = true` (a `static var` on `Level`, false
  otherwise), instantiates `res://levels/level_<n>.tscn` and adds it. The
  level builds itself as usual.
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

## Level end and death line

- `level_end_x` is a read-only property (a GDScript getter) on the level
  root: the sum of all floor widths × `Grid.TILE`. It is the right edge of the
  ground, where the camera stops (`camera.md`).
- `death_y` is a read-only property (a GDScript getter) on the level root:
  the height at which the player dies (`player-damage.md`).
  - Without water: `Screen.height` (257), the bottom of the screen.
  - With water: **234** (`13 * Grid.TILE`), the top of the water surface, so the
    player dies on touching the water, even over ground on rows 13 or 14
    behind the water.

## Jump check

At the end of building, every run, the level root checks that the level
can be crossed from start to finish: from everything the player can stand
on, there is a way onward to the right.

- **Standable things** are every floor that is not a gap, and every
  one-way platform (`one-way-platform.md`). A floor or platform whose row
  is 15 or more, or 13 or more with `has_water` on, is not standable:
  standing there means being on or past the death line.
- **Ahead:** one standable thing is ahead of another when its right edge is
  further right. (So a floor that runs on under a platform and past it is
  ahead of that platform, and a platform that starts above a floor but ends
  past it is ahead of that floor.)
- The check walks the floors first, then the platforms. For each standable
  thing, it has up to **two targets**: the first floor ahead of it (the
  next standable one in `floors`, which runs left to right, skipping gaps
  and, with water, floors on row 13 or 14) and the first platform
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
  only accepted if it can be crossed. The check first goes through **every**
  standable thing and collects all that fail (no target works), then, if
  any failed, one `assert` fails with a message listing each of them (which
  floor or platform, and its right edge's cell), so one run shows
  everything to fix.
- **In a snapshot** (`Level.show_guides` on) the check does not stop the
  build: it draws a red marker at the right edge of each failing thing
  instead (see Snapshot), so the failures can be seen in place.
- Ladders (`ladder.md`) are not part of the check, and a ladder's top is
  not a standable thing here: every level must be crossable by jumping
  alone.
- Doors (`door.md`) are not part of the check either: a door wins the
  level, but every level must still be crossable to the flag.
- Springs (`spring.md`) are not part of the check: every level must be
  crossable without them. A spring is only ever an extra.

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
| `[Vector2i(30, 11)]` | Ground in columns 0 to 29, rows 11 to 14, then the end floor in columns 30 to 39, rows 12 to 14; nothing anywhere else |
| A floor on row 15 | No tiles and no decorations in its columns |
| A floor on row 14 | Ground tiles, but no decorations |
| A long floor | About 1 in 5 surface tiles has a decoration or waterfall, from the level's biome |
| Decorations | Drawn behind the ground, the player and enemies; never block anything |
| `has_water` on, 30 columns of written floors | Water surface on row 13 and water body on row 14, columns 0 to 39 (end floor included), animating |
| `has_water` off | No water and no waterfalls |
| `[Vector2i(4, 8), Vector2i(5, 11)]`, the pair gets a piece | Start row 12 (one below the lower surface, row 11); left column 1 to 3, right column 4 to 7; rows 12 to 14; outlined, fills mixed |
| Many builds of the same level | About half of the allowed pairs get a piece |
| A pair where either floor is 1 wide | Never a piece |
| A pair with a gap, or with a floor on row 14 | Never a piece |
| A ground piece | Drawn in front of the ground and waterfalls, behind the water, blocks, enemies and the player; nothing collides with it (`collision_enabled` is false) |
| Two overlapping pieces | The later one is drawn whole, outline included, over the earlier one |
| `has_water` off, a 3-column gap | A spike tile on row 13 of each of the 3 columns; nothing else in them |
| Any spike | Spikes drawn from y 248 to 257: their base on the death line and the screen's bottom edge |
| `has_water` on, a gap | No spikes: water on rows 13 and 14 |
| Player falls into a gap | Passes the spikes and dies at `death_y` (257); the spikes block nothing |
| A waterfall on a floor on row 8 | Top on row 8, body on rows 9 to 11, base on row 12 |
| `has_water` on, floor on row 12 | Gets decorations but never a waterfall |
| `has_water` on, floor on row 13 | No decorations; the jump check treats it as a gap |
| `has_water` on | `death_y` is 234; off, it is 257 |
| Leaper rising from water | In front of waterfalls, behind the water |
| Any `floors` | `level_end_x` = sum of widths × `Grid.TILE` |
| Snapshot | Numbered grid and guides shown |
| Normal run | No grid, no guides |
| Snapshot page 1 | Camera's left edge at x = 450 |
| Snapshot page past the level end | Camera's right edge at `level_end_x` |
| Coin at cell (2, 6) | `position` (36, 108) |
| Walker at cell (5, 10) | `position` (99, 198): feet on top of row 11 |
| Flyer at cell (5, 4) | `position` (99, 81) |
| A spawn given a wrong type, e.g. `FlyerSpawn.new(Vector2i(5, 4), "far")` | GDScript error; the level does not run |
| Level root and every placed thing | No `@tool`, no `@export` |
| Two items in the same cell, in one list or across lists (for example a coin and a walker) | The build stops with an `assert` naming both, e.g. "walker at (14, 6) overlaps coin at (14, 6)" |
| A block inside the ground | The build stops with an `assert` |
| Walker A one column right of a walker B | The build stops with an `assert` (walker B takes that cell) |
| Two walker Bs two columns apart | The build stops with an `assert` (both take the column between) |
| A bar, flyer or leaper on ground, a block, a coin or another thing | Allowed |
| Two bars on one cell, two flyers on one cell, or two leapers in one column | The build stops with an `assert` naming the list and the cell or column |
| A floor with width 0 | The build stops with an `assert` |
| `player_cell` on a ground cell or a block's cell | The build stops with an `assert` |
| `player_cell` on row 14 without water (feet at 270, `death_y` 257) | Allowed: the player dies on its first update |
| `player_cell` on row 12 with water (feet at 234 = `death_y`) | Allowed: the player dies on its first update |
| `player_cell` on row -2 (above the screen) | Allowed: the player drops in from the top |
| Written floors 15 columns wide (level 25 columns, under one screen) | The build stops with an `assert` |
| Written floors 16 or 245 columns wide (level 26 or 255) | Allowed |
| Written floors 246 columns wide (level 256) | The build stops with an `assert` |
| Any level | Its last floor is `Vector2i(10, 12)`, added by the level root |
| Written floors ending with a floor on row 12, then a 6-column gap | The jump check fails onto the end floor (same row, 6-tile gap): the build stops |
| `player_cell` in column -1, or in the flag's column or right of it | The build stops with an `assert` |
| The example level above (26 written columns, 36 in all) | End floor in columns 26 to 35; flag in column 26, x = 468 |
| A walker or crusher on a ground cell or a block's cell | The build stops with an `assert` naming both |
| Walker B with ground or anything placed to its left, right, top-left, top or top-right | The build stops with an `assert` naming both |
| Walker A next to ground, in a free cell | Allowed |
| A gift block holding a diamond, with ground, a block or anything placed in the cell above it | The build stops with an `assert` naming both |
| A gift block holding a coin, with a block in the cell above it | Allowed |
| A gift block holding a diamond on row 0 | The build stops with an `assert` |
| A block, coin, walker, flyer, crusher, bar, spring, door or platform cell in column -1 or past the last column | The build stops with an `assert` |
| A spring on ground, a block, a coin or a walker's cell | The build stops with an `assert` naming both |
| A platform 0 wide | The build stops with an `assert` |
| A platform on ground, a block or another platform | The build stops with an `assert` naming both |
| Any platform | Drawn as one of its biome's looks (`one-way-platform.md`) |
| Any leaper with `has_water` off | The build stops with an `assert` |
| A leaper column past the last column | The build stops with an `assert` |
| A leaper in column 5 | `position` (99, 261): the middle of row 14, behind the water |
| A flyer with `bob_distance` 0 | Allowed: it hovers in place |
| A flyer at row 1 (y 27) with `bob_distance` 220 (down to y 247) | Allowed: sprite fully on screen at both ends |
| A flyer at row 1 with `bob_distance` 221, or `bob_distance` -18 | The build stops with an `assert` |
| A flyer at row 0 (y 9) | The build stops with an `assert`: its sprite's top is 1 px above the screen |
| A level script without `layout()`, or with a different signature | GDScript error |
| `Level` attached to a node directly | GDScript error (abstract) |
| A scene added without `setup()` | Stops at its `_ready` with "setup() not called" |
| A coin pops out of a gift block | The coin is in `BlockItems`, drawn behind the block |
| An enemy is stomped | Its death scene is in `Effects`, drawn in front of the water |
| `biome` changed to `GRASS` | `Ground` and `Decorations` use the grass `TileSet`s |
| Same row, 5-tile gap | Jump check passes |
| Same row, 6-tile gap | The build stops with an `assert` naming the floor; in a snapshot, a red marker instead |
| Two failing jumps in one level | One `assert` listing both |
| Next floor 4 rows higher, no gap | Passes |
| Next floor 5 rows higher, no gap | Fails |
| Next floor 1 column wide, same row, 1-tile gap | Passes (the full-speed jump flies over it, but would land past its left edge) |
| Snapshot | Grid and red markers drawn in front of the ground, blocks, water and everything else in the level |
| Same row, 7-tile gap, with a 3-wide platform on that row starting 3 tiles into the gap | Passes: the first floor reaches the platform, the platform reaches the next floor |
| The same without the platform | Fails on the first floor: the build stops; in a snapshot, a red marker there |
| A gap only a spring can get past | Fails: springs are not part of the check |
| A platform 4 rows above a floor's right edge, starting left of it and ending past it | The floor passes: the player jumps up through the platform and lands on it |
| A platform over a floor that runs on past the platform's right end | The platform passes: walking off its end lands on the floor |
| A platform 2 rows below a floor's right edge, starting at the take-off point | The floor passes: walking off the edge lands on it |
