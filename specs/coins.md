# Coins

Coins placed in the level, collected by touching them. Read `overview.md`
and `level-layout.md` first. (The coin that hops out of a gift block is a
different, purely visual thing: see `gift-block.md`.)

## Art

- `res://art/coin/sprite_1.png` and `res://art/coin/sprite_2.png`,
  18 × 18: the same frames as the gift block's coin.
- Shown with an `AnimatedSprite2D`: `res://art/coin/sprite_1.png` and `res://art/coin/sprite_2.png` looping at
  **7.5 frames per second** (0.133 s each).

## Placing them

- Placed from the level script's `coins` cells, in the `Coins` layer node
  (`level-layout.md`, Placing things). With its top-left origin, a coin
  always fills exactly one cell, which it shares with nothing: not the
  ground, a block or anything else placed, bars, flyers and leapers aside
  (checked before the build,
  `level-layout.md`, Occupied cells). A coin is not
  a `Block`, so `block_at` never returns one.
- Collision box 12 × 12 at x 3, y 3 in the image; origin top-left (0, 0)
  (`assets.md`).

## Collecting

- A coin is an `Area2D` with `collision_layer` = `pickups` and
  `collision_mask` = none (`overview.md`): it watches nothing itself. The
  player finds it in its contact check (`player-contact.md`, Pickups).
- `collect()`, called by the player: the coin hides (`visible = false`) and
  switches itself off (`PROCESS_MODE_DISABLED`), so it is out of physics
  and can't be found again. It is never freed. No signals.
- Collected at any time: while invincible, in the air, in any state. Not by
  a dead player.
- Purely for show for now: collecting does not count towards anything.

## Acceptance test

| Case | Expected |
|---|---|
| A placed coin | Animates `res://art/coin/sprite_1.png`, `res://art/coin/sprite_2.png` at 7.5 fps |
| Player touches it | Coin hidden and switched off, in the player's contact check |
| Walker or other enemy touches it | Nothing happens |
| Player touches the spot again | Nothing (already collected) |
