# HUD

What is drawn on top of the game, fixed to the screen. Read `overview.md`
and `player-damage.md` first. So far that is only the health heart.

## Art

- `res://art/heart/sprite_1.png`, `res://art/heart/sprite_2.png`, `res://art/heart/sprite_3.png`, each 16 × 14:

  | File | Shows |
  |---|---|
  | `res://art/heart/sprite_1.png` | 0 health (empty) |
  | `res://art/heart/sprite_2.png` | 1 health |
  | `res://art/heart/sprite_3.png` | 2 health |

## The heart

- A `CanvasLayer` named `HUD`, a child of the level root, holding one
  `AnimatedSprite2D` with the three heart sprites as frames 0, 1 and 2, in
  that order. It never plays: its `frame` is set to the level's `health`,
  so frame 0 is empty, 1 is one health, 2 is two.
- A `CanvasLayer` draws in screen space: the heart stays put while the
  camera scrolls, and is drawn in front of the whole level. It keeps the
  default `layer` (1); the iris (`game-flow.md`) is on layer 2, so it
  covers the heart too.
- Its **top-left corner** is at **(`Screen.width - 26`, 20)**, which is
  (433, 20) on the 459 × 257 screen (`centered = false`, no `offset`):
  the heart is 16 px wide, so its right edge is 10 px from the screen's
  right edge, and its top is 20 px from the top.
- Kept up to date by a setter on the level root's `health`: whenever health
  changes, the heart's `frame` is set to it. Nothing polls it.
- At the start, the level root sets the heart's `frame` from its `health`
  itself, right after it creates the HUD: `health` gets its starting value
  before the HUD exists.

## Acceptance test

| Case | Expected |
|---|---|
| Level starts | Heart shows `res://art/heart/sprite_3.png` (2 health) |
| Player hurt once | `res://art/heart/sprite_2.png` |
| Player dies | `res://art/heart/sprite_1.png` (empty) |
| Player with 1 health collects a diamond | `res://art/heart/sprite_3.png` |
| Any time | Heart's top-left at (433, 20) on screen |
| Camera scrolls | Heart stays at the same place on screen |
