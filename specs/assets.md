# Assets

The art files, and the collision box and origin of every sprite. Read `overview.md`
first.

## Files

- All art is in the `art/` folder at the project root, one folder per
  character or tile set. One PNG per sprite: `res://art/<character>/sprite_<n>.png`.
- Every spec names an art file by its full `res://` path, exactly as the
  code loads it (for example `res://art/player/sprite_1.png`), never a
  short name.
- Where a spec covers several variants or kinds (walkers, gift blocks),
  `*` in the path stands for the letter: `res://art/walker_*/sprite_3.png`
  means `walker_a/`, `walker_b/` or `walker_c/`, whichever the node is.
- All the sprites of one character have the same image size.

## Art table

Every sprite's image size, collision box and origin. Box positions and
origins are measured from the top-left corner of the image, in pixels.
`sprite_*.png` means every frame in that folder.

| Art | Image size | Box position | Box size | Origin |
|---|---|---|---|---|
| `res://art/player/sprite_*.png` | 24 × 26 | x 7, y 10 | 10 × 15 | 12, 25 (feet) |
| `res://art/walker_a/sprite_*.png` | 17 × 16 | x 1, y 3 | 15 × 12 | 8, 15 (feet) |
| `res://art/walker_b/sprite_*.png` | 26 × 24 | x 1, y 3 | 24 × 20 | 13, 23 (feet) |
| `res://art/walker_c/sprite_*.png` | 17 × 21 | x 1, y 9 | 15 × 11 | 8, 20 (feet) |
| `res://art/crusher/sprite_*.png` | 20 × 20 | x 2, y 1 | 16 × 18 | 10, 19 (feet) |
| `res://art/diamond/sprite_1.png` | 16 × 15 | x 1, y 1 | 14 × 13 | 8, 14 (feet) |
| `res://art/spring/sprite_1.png` | 18 × 18 | x 1, y 4 | 16 × 14 | 9, 18 (feet) |
| `res://art/flyer/sprite_*.png` | 26 × 20 | x 8, y 7 | 10 × 10 | 13, 10 (centre) |
| `res://art/leaper/sprite_*.png` | 13 × 17 | x 1, y 1 | 11 × 15 | 6, 8 (centre) |
| `res://art/bar/sprite_1.png` (each sprite) | 26 × 26 | x 6, y 6 | 14 × 14 | 13, 13 (centre) |
| `res://art/breakable_block_chunk/sprite_*.png` | 18 × 18 | none | none | 9, 9 (centre) |
| `res://art/breakable_block/sprite_1.png` | 18 × 18 | x 0, y 0 | 18 × 18 | 0, 0 (top-left) |
| `res://art/gift_block_*/sprite_*.png` | 18 × 18 | x 0, y 0 | 18 × 18 | 0, 0 (top-left) |
| `res://art/coin/sprite_*.png`, placed coin (`coins.md`) | 18 × 18 | x 3, y 3 | 12 × 12 | 0, 0 (top-left) |
| `res://art/coin/sprite_*.png`, popped coin (`gift-block.md`) | 18 × 18 | none | none | 0, 0 (top-left) |
| `res://art/flag/sprite_*.png` | 18 × 257 | none | none | 0, 0 (top-left) |
| `res://art/flag/sprite_*.png`, checkpoint (`checkpoint.md`): an 18 × 36 region of it | 18 × 36 (the region) | x 0, y 0 | 18 × 36 | 9, 36 (feet) |
| `res://art/heart/sprite_*.png` | 16 × 14 | none | none | 0, 0 (top-left) |
| `res://art/backgrounds/sprite_*.png` | 96 × 257 | none | none | 0, 0 (top-left) |
| `res://art/door/sprite_*.png` | 18 × 36 | x 0, y 13 | 18 × 23 | 0, 18 (top-left of the bottom tile) |

Decorations, solids, water, spikes, trees, ropes, pipes, one-way platforms and ladders are tiles, not sprites: the `TileSet`
places them and gives the solids and platforms their collision (`level-tiles.md`,
`level-layout.md`, `trees.md`, `ropes.md`, `pipes.md`, `one-way-platform.md`,
`ladder.md`).

## Collision boxes

- Each thing has one rectangle, used both for collisions (`move_and_slide`)
  and for overlaps (the player's contact check).
- Only the box touches things. The sprite images are bigger than their
  boxes, and the parts outside the box never collide or overlap.
- Where one thing needs its box twice, a body and its child `Area2D` (the
  player and its contact area, the diamond and its pickup area), both use
  the same `RectangleShape2D` resource.
- **No moving body's box is a whole tile wide.** The crusher's and the
  spring's boxes are 16 px wide, 1 px inside each side of their 18 px
  cell. With an 18 px box, the body's sides lie exactly on the tile
  edges, and Godot treats a wall or body touching it there as hit
  (tested on 4.7.2): a falling spring caught on the top corner of a
  spring standing in the next column and stood on it, 14 px above the
  floor, and a crusher falling and rising beside a wall reported
  `is_on_wall()` on almost every update and drifted sideways. At 16 px
  none of this happens. The heights stay as drawn.
- `VisibleOnScreenEnabler2D` areas are not these boxes: they are the whole
  sprite, or the whole path, as each enemy's spec says.
- Walker `res://art/walker_*/sprite_3.png` is the flattened sprite, used
  by the walker flattened and bonked scenes, which have no collision box,
  and by walker B's shell, which keeps walker B's box (`enemy-walker.md`).

## Origins

The origin is the point that `position` refers to, and the point a sprite
scales and spins around. Each thing's origin is chosen for what it does:

- **Feet:** the middle of the bottom edge of the box, rounded down to a
  whole pixel. For things that stand and walk on the floor, and the
  checkpoint, which stands on the ground and bounces: squash and
  stretch scale around the origin, so the feet stay on the floor, and
  placing it in a cell (`level-layout.md`) stands it on that cell's floor.
- **Centre:** the centre of the image, rounded down to a whole pixel. For
  things that spin (the bar, the breakable block chunks) and things that never stand
  on the floor (the flyer, the leaper).
- **Top-left:** (0, 0). For things placed on the tile grid (`Grid.TILE`) (blocks, coins)
  or at a fixed place (the flag, the HUD heart). The door is two tiles
  tall, so its origin is the top-left of its **bottom** tile, (0, 18): it
  is placed like a coin, filling its cell, with its top in the cell above
  (`door.md`).

Every sprite node (`Sprite2D` or `AnimatedSprite2D`) is drawn with
`centered = false` and an `offset` of minus the origin, so the origin is
always a whole pixel. A scene that shows a character's art for an effect
(the player death scene, the walker flattened and bonked scenes, the flyer
and leaper death scenes) uses that character's origin.
