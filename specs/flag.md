# Goal flag

The flag at the end of every level. Reaching it wins the level. Read
`overview.md` and `level-layout.md` first.

## Art

- `res://art/flag/sprite_1.png` and `res://art/flag/sprite_2.png`,
  each **18 × 257 px**: as tall as the screen. The top 18 px (one tile)
  are empty; the flag cloth starts at y = 18 (about y 18 to 32) and the
  pole runs from there down to the very bottom of the image.
- Shown with an `AnimatedSprite2D`: `res://art/flag/sprite_1.png` and `res://art/flag/sprite_2.png` looping at
  **7.5 frames per second**, the same as the enemies' animations.
- The image is the full screen height, so the flag needs no ground under it.
  Every level has one, whatever its tiles.

## Placing it

- Every level has exactly one `Flag`, a direct child of the level root.
  It is **placed automatically**: the level script does not say where.
- Its origin is the **top-left corner of the image** (`centered = false`, no
  `offset`), so `position.x` is the image's left edge.
- It always stands in the **10th column from the right end** of the level
  (that column included): the level root sets
  `position = Vector2(level_end_x - 10 * Grid.TILE, 0)`, so the image runs
  from the top of the screen to the bottom.
- The camera stops with its right edge at `level_end_x` (`camera.md`), so
  the flag is always on the level's last screen, with 9 columns after it.
- The checks before the build (`level-layout.md`, Checking the layout)
  make sure the level is 1 to 10 screens wide and nothing is placed in the
  flag area (the end floor's columns). The player always starts on the
  start floor, at the other end (`level-layout.md`, Floors).
- It always stands on ground: its column is the first of the **end floor**,
  10 columns on row 12 that the level root adds after the written floors
  (`level-layout.md`, Floors).
- It goes in the level root's children right after `Decorations` and
  before `Ground`, so it is drawn **behind the ground**: wherever there is
  ground in front of the pole, the flag looks planted in it.

## Winning

- The level root has a read-only property (a GDScript getter), `win_x`: the
  flag's `position.x`.
- The **player** checks it, the same way it checks the death line: each update,
  right after the death line check and before any contact
  (`player-movement.md`, Each update), once its `position.x` is greater
  than or equal to `level.win_x`, the level is won. Touching a door wins
  the same way, in the same step (`door.md`).
- Only the player's x matters: its height, and whether it is on the ground
  or in the air, do not.
- **On winning**, like a death (`player-damage.md`), the game is paused
  with `get_tree().paused` and the player's update ends there, so nothing
  else happens: no contact, no hurt, no second win. The player stays where
  it is, visible, frozen.
- An invincible player flickers (`player-damage.md`), so on winning the
  player first sets its sprite's `visible = true`: it is never frozen
  hidden.
- A dead player cannot win: the death line check comes first, and a death
  pauses the game too.
- Right after pausing, the player calls `level.on_win()`. The level
  closes the iris on the player, then moves on to the next level, or back
  to the title screen after the last one (`game-flow.md`, Winning).

## Acceptance test

| Case | Expected |
|---|---|
| Any level | Exactly one flag, top at y = 0, animating `res://art/flag/sprite_1.png`, `res://art/flag/sprite_2.png` at 7.5 fps |
| Player's x one pixel before the flag's x | Not won |
| Player's x reaches the flag's x, on the ground or in the air | Won: game paused, player frozen and visible where it is |
| Player wins while invincible, on an update its sprite was hidden | Sprite visible, frozen where it is |
| Player reaches the flag's x and the death line in the same update | Dies, does not win |
| Player reaches the flag's x while touching an enemy | Wins; not hurt |
| Written floors 9 columns wide (level 26 columns, `level_end_x` 468) | Flag at x = 288 (column 16, the end floor's first column), y = 0 |
| Player wins | `level.on_win()` called once |
| Any level | Flag's x is `level_end_x - 10 * Grid.TILE` |
