# Door

A door placed anywhere in a level, like a coin. Touching it wins the
level, exactly like reaching the flag. Read `overview.md`,
`level-layout.md` and `flag.md` first.

Where a door leads (for example a hidden level) comes with the later spec
on what follows a win (`flag.md`). For now a door is simply a second way to
win.

## Art

- `res://art/door/sprite_1.png` and `res://art/door/sprite_2.png`, each
  **18 × 36 px** (1 tile wide, 2 tall): two look-only variants of the same
  door. The door is drawn on rows 13 to 35; the top 13 rows are empty.
- Shown with a `Sprite2D`, no animation.
- **Origin (0, 18)**: the top-left corner of the image's bottom tile
  (`centered = false`, `offset = Vector2(0, -18)`, `assets.md`). So a door is
  placed exactly like a coin, with `cell_to_position(cell, top-left)`: its
  bottom tile fills the cell, and its top reaches into the cell above.
- Collision box **18 × 23 at x 0, y 13** in the image: the whole drawn door.

## Placing them

- The level script's `doors` field, an `Array[Vector2i]` of cells
  (`level-layout.md`), like the coins. In the `Doors` layer node.
- **Anywhere**, like a coin: on the ground, floating, behind a breakable
  block, up high. Nothing has to be under it.
- **The variant** is picked per door at build time, `sprite_1.png` or
  `sprite_2.png`, each equally likely (`randi_range(1, 2)`). Like the
  decorations, the randomness is not seeded.
- Checked before the build (`level-layout.md`, Checking the layout): its
  column is inside the level, and it takes **two cells**, its own and the
  one above (where its top reaches), shared with nothing (Occupied cells).

## Body

- A door is an `Area2D` (`class_name Door`) with `collision_layer` =
  `doors` and `collision_mask` = none (`overview.md`): it watches nothing
  itself. Only the player looks for it; walkers, the diamond and everything
  else pass through it.
- It never moves, never switches off and never runs out.

## Winning through a door

- The player checks it in its **win** step (`player-movement.md`, Each
  update, step 7), together with the flag (`flag.md`, Winning): the level
  is won when the player's `position.x` reaches `level.win_x` **or** any
  `Door` is in its contact area's overlap list (`player-contact.md`,
  Checking contact). So a door, like the flag, beats any contact in the
  same update, and loses to the death line.
- Winning through a door is exactly the same as winning at the flag
  (`flag.md`, On winning): the game pauses and the player stays visible,
  frozen where it is.
- Doors are not part of the jump check (`level-layout.md`): every level
  must still be crossable to the flag. A door is only an extra.

## Acceptance test

| Case | Expected |
|---|---|
| Door at cell (5, 10) | `position` (90, 180): its bottom tile fills cell (5, 10), its top reaches into (5, 9) |
| Any door | Shows `res://art/door/sprite_1.png` or `sprite_2.png`, each about half the time over many builds |
| Any door | `collision_layer` is `doors`, `collision_mask` is none |
| Player touches a door, on the ground or in the air | Won: game paused, player frozen and visible where it is |
| Player wins through a door while invincible, on an update its sprite was hidden | Sprite visible, frozen where it is |
| Player touches a door and reaches the death line in the same update | Dies, does not win |
| Player touches a door while touching an enemy | Wins; not hurt |
| Walker, diamond or spring passes a door | Nothing happens |
| Door with ground, a block or anything placed in its cell or the cell above | The build stops with an `assert` naming both |
| Door column -1 or past the last column | The build stops with an `assert` |
| A level whose flag can't be reached by jumps, with a door before the gap | The jump check still fails: doors are not part of it |
