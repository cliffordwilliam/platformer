# Gift block

A solid block that hops a little when the player hits it from below, and
releases a coin or a diamond the first time. It never breaks. Read `breakable-block.md`
first: this block is placed and hit from below exactly the same way.

## Art

All 18 × 18:

| Files | What |
|---|---|
| `res://art/gift_block_a/`, `res://art/gift_block_b/`, `res://art/gift_block_c/` | Three look-only variants; each has `res://art/gift_block_*/sprite_1.png` (glowing, unused) and `res://art/gift_block_*/sprite_2.png` (dimmed, used) |
| `res://art/coin/sprite_1.png`, `res://art/coin/sprite_2.png` | The coin, two animation frames |

## The block

- A `Block` (`breakable-block.md`, Blocks): `GiftBlock extends Block`, with
  the same box, layers, placement, `bonk()` and `block_at`.
- Placed from the level script's `blocks` list as a `GiftBlockSpawn`
  (`level-layout.md`), which gives its cell and its contents.
- **Its look** (A, B or C) is picked per block at build time, each equally
  likely, like the doors' (`door.md`): the level script never chooses it,
  since it changes nothing but the picture. The block picks it itself in `setup()`, one
  scene for all three looks, and uses that variant's `sprite_1.png` and
  `sprite_2.png`.
- It starts **glowing** (`res://art/gift_block_*/sprite_1.png`) and has a `used` flag, false at the
  start.
- `contents`: `COIN` or `DIAMOND`, from its `GiftBlockSpawn`. It
  decides what comes out on the first hit.
- The player hits it exactly like a breakable block (`breakable-block.md`,
  Hitting a block).

## `_on_bonk()`

Every hit, used or not:

1. **The hop:** the block's **sprite** (not its collision box, which never
   moves) hops up and back with a tween (see The hop). If a hop is already
   playing, this hit does not start a new one: the playing hop carries on
   to its end, so a diamond waiting for that end always comes out. The rest
   of `bonk()` (killing the walkers on top) still runs.

The first hit only (`used` is false):

2. If `contents` is `COIN`, a **coin** hops out (see The coin). If it is
   `DIAMOND`, a **diamond** comes out once the hop has finished
   (`diamond.md`).
3. `used = true`, and the sprite switches to **dimmed** (`res://art/gift_block_*/sprite_2.png`).

## The hop

From the numbers: launch 135 px/s up against 1265.625 px/s² of gravity.

- Height: 135² / (2 × 1265.625) = **7.2 px**.
- Time up: 135 / 1265.625 = **0.1067 s**; the same back down.

A tween on the sprite's `position:y`, made with the block's
`create_tween()`:

1. to -7.2 over 0.1067 s, `TRANS_QUAD`, `EASE_OUT` (slowing to a stop)
2. back to 0 over 0.1067 s, `TRANS_QUAD`, `EASE_IN` (speeding up)

Quadratic easing is constant acceleration, so this is exactly that gravity.
A tween ends exactly on its target, so the sprite always lands back on its
starting height.

## The coin

- A **popped coin** scene, `class_name PoppedCoin extends Node2D`. It is
  not the placed `Coin` scene (`coins.md`), which is an `Area2D` on the
  `pickups` layer that the player collects. It holds an `AnimatedSprite2D` (origin top-left
  (0, 0), `assets.md`) playing
  `res://art/coin/sprite_1.png` and `res://art/coin/sprite_2.png` at **30 frames per second** (0.033 s, 2 updates
  each), looping.
- Added to `BlockItems` (`level.add_block_item()`, `level-layout.md`),
  which is drawn behind every block, so the coin looks like it rises out
  of the block.
- It starts exactly on the block and hops with a tween on its
  `position:y`, from the numbers: launch 337.5 px/s up against
  1265.625 px/s² of gravity.
  - Height: 337.5² / (2 × 1265.625) = **45 px** (2.5 tiles).
  - Time up: 337.5 / 1265.625 = **0.2667 s**; the same back down.
  1. up 45 px over 0.2667 s, `TRANS_QUAD`, `EASE_OUT`
  2. back down 45 px over 0.2667 s, `TRANS_QUAD`, `EASE_IN`
  3. then (`tween_callback`) it hides and switches itself off, back inside
     the block. It is never freed.
- Purely visual for now: it does not count towards anything.

## Acceptance test

| Case | Expected |
|---|---|
| New block | Glowing (`res://art/gift_block_*/sprite_1.png`), solid like a tile |
| First hit from below | Sprite hops 7.2 px and is back at 0 after 0.213 s; a coin rises 45 px and back in 0.533 s, then is hidden; block now dimmed |
| Second hit | Hops again; no coin; stays dimmed |
| Hit again while a hop is playing | The hop is not restarted and lands back at 0 on time; walkers on top are still bonked |
| Diamond block hit twice within 0.213 s | The diamond still comes out when the first hop ends |
| During a hop | Collision box does not move |
| Coin | Animates `res://art/coin/sprite_1.png`, `res://art/coin/sprite_2.png` at 30 fps; drawn behind the block |
| Walker standing on it when hit | Walker bonked, as on a breakable block (`Block.bonk()` kills the walkers on top after every hit) |
