# Diamond

A pickup that comes out of a gift block set to hold one, walks like a
walker, and gives the player 1 health back when touched. Read
`gift-block.md`, `enemy-walker.md` and `player-damage.md` first.

## Art

- `res://art/diamond/sprite_1.png`, 16 × 15, one frame, no
  animation.
- Collision box 14 × 13 at x 1, y 1 in the image; origin (8, 14), the
  middle of the bottom of the box (`assets.md`).

## Coming out of the block

- A gift block whose `contents` is `DIAMOND` adds the diamond on its first
  hit, **when the hop tween ends** (a `tween_callback` at the end of the
  hop), not straight away like the coin (`gift-block.md`).
- The diamond is added to `BlockItems` (`level.add_block_item()`,
  `level-layout.md`), which is drawn behind every block, so the block is
  drawn over it.
- Its `position` is its final spot from the start: standing on top of the
  block, feet on the block's top edge, centred (the block's top-left plus
  (`Grid.HALF_TILE`, 0)). It can be collected from that moment.
- **The slide is only a picture:** its sprite starts one tile lower
  (`position.y` of the sprite = `Grid.TILE`, hidden behind the block) and a
  tween moves it up to 0 at **16.875 px/s**: `Grid.TILE` / 16.875 =
  **1.0667 s**,
  `TRANS_LINEAR` (constant speed).
- While the slide plays, the diamond does not move (no gravity, no
  walking): its physics processing is off (`set_physics_process(false)`).
  When the slide tween ends, it turns it back on and starts walking.

## Walking

A diamond is a `WalkingBody` (`enemy-walker.md`, WalkingBody): the same
numbers, update order, walls, landing, switching on and off, and squash and
stretch as a walker. Its own parts:

- it starts walking **right**: `speed = 33.75`, set in its `setup()`
- it is not an enemy: not a `Walker` and not in `level.walker_layer`, not
  stompable, never hurts the player, and is never killed by a block hit
  from below: it hops instead (see Bumped from below)
- it does not bump into walkers (see Physics)

## Bumped from below

When the player hits a block (breakable or gift) that a diamond is standing
on, the diamond hops and turns around. The block does it, in `Block.bonk()`
(`breakable-block.md`), the same way it finds walkers on top:

- For each `Diamond` in `level.block_item_layer` that is switched on
  (`can_process()`), walking (its slide has ended:
  `is_physics_processing()`) and on the floor
  (`is_on_floor()`): if any column its box covers, on the row of
  `bottom + 1` (just under its feet), is this block's cell, the block calls
  the diamond's `bump()`.
- `bump()`: `velocity.y = -202.5` (the same number as its falling cap,
  upward) and `speed = -speed`: it hops and walks the other way. Nothing
  else changes: it keeps its walker update, gravity 965.04 and falling cap
  202.5, so it rises 202.5² / (2 × 965.04) = **21.25 px** in
  202.5 / 965.04 = **0.210 s**.
- A diamond still sliding out of its gift block does not react at all.
- Once walking, a diamond can wander onto any block, breakable ones too.
  If the player breaks the breakable block it stands on, it hops the same
  way, then falls through where the block was.

## Physics

- Its body (`CharacterBody2D`) has no `collision_layer` and a
  `collision_mask` of `level` only: it lands on the ground and blocks and
  turns at walls, but passes through walkers and every other enemy, and
  nothing bumps into it.
- Its `VisibleOnScreenEnabler2D` (from `WalkingBody`) has a `rect` the size
  of its sprite: switched off when off screen, so one that falls below the
  screen stays off for good.

## Collecting

- Like a coin (`coins.md`): a child `Area2D` with `collision_layer` =
  `pickups` and `collision_mask` = none, using the same 14 × 13 box. The
  player finds it in its contact check (`player-contact.md`, Pickups).
- `collect()`, called by the player: the level's health goes up by **1,
  but never above 2** (`level.health = min(level.health + 1, 2)`; it only
  heals), then the diamond hides and switches itself off. It is never
  freed. No signals.

## Acceptance test

| Case | Expected |
|---|---|
| Gift block with `contents = DIAMOND`, first hit | No coin; after the 0.213 s hop, the diamond's sprite slides up out of the block over 1.067 s |
| During the slide | Diamond does not move; touching it collects it |
| After the slide | Walks right at 33.75 px/s; turns at walls; falls off ledges |
| Diamond meets a walker | Passes through |
| Player with 1 health touches it | Health 2; diamond hidden and switched off |
| Player with 2 health touches it | Health stays 2; diamond hidden and switched off |
| Player hits the block a walking diamond stands on | Diamond hops (`velocity.y == -202.5`, its usual gravity 965.04 and cap 202.5, about 21.25 px high) and walks the other way |
| Same, while the diamond is still sliding out | Nothing happens to the diamond |
| Player breaks a breakable block a diamond walked onto | Diamond hops, turns, then falls through the gap |
| Diamond partly over the hit block, partly over the next tile | Hops and turns |
