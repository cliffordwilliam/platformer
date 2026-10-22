# Background

A still picture behind everything else, one per biome, repeated sideways
and scrolling at half the camera's speed (parallax), so the hills look far
away. Purely visual: nothing touches it. Read `overview.md` and
`level-layout.md` first.

## Art

Each **96 × 257 px** (the screen's height), fully opaque. The left and
right edges match, so copies side by side join without a seam.

| File | Biome |
|---|---|
| `res://art/backgrounds/sprite_1.png` | `SNOW` |
| `res://art/backgrounds/sprite_2.png` | `DESERT` |
| `res://art/backgrounds/sprite_3.png` | `GRASS` |

## The node

- `Background`, a built-in `Parallax2D`, the **first** of the level root's
  children (`level-layout.md`, Building), so it is drawn behind everything,
  trees included.
- `scroll_scale = Vector2(0.5, 1)`: sideways it moves half as fast as the
  camera. The camera never moves up or down (`camera.md`), so the 1 keeps
  the picture exactly on the screen, y 0 to 257.
- `repeat_size = Vector2(w, 0)`, where `w` is the picture's width read from
  its texture (`texture.get_width()`, 96): the layer loops every `w`
  pixels, so it never runs out however long the level is.
- It holds one `Sprite2D`, at (0, 0) with `centered = false`, showing the
  level's biome picture as a **strip** several copies wide:
  - `texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED`
  - `region_enabled = true`,
    `region_rect = Rect2(0, 0, (ceili(Screen.width / float(w)) + 1) * w, texture.get_height())`:
    one copy more than it takes to cover the screen, 6 copies (576 px) with
    today's numbers.
- Why a strip: the layer loops every `w` pixels, so the strip must cover
  the screen at every one of those `w` offsets, that is, a screen plus one
  picture. `repeat_size` alone, or `repeat_times`, leaves gaps when the
  picture is narrower than the screen (tested on Godot 4.7.2).
- No code runs each update: `Parallax2D` follows the camera by itself,
  even while the game is paused (tested), so a snapshot shows it in the
  right place too.

## Acceptance test

| Case | Expected |
|---|---|
| Snow, desert or grass level | Shows `res://art/backgrounds/sprite_1.png`, `sprite_2.png` or `sprite_3.png` |
| Level start (camera's left edge at 0) | The picture's left edge at the screen's left edge |
| Camera moves 100 px right | The ground moves 100 px left on screen, the background 50 px |
| Anywhere in a 10-screen level | The background covers the whole screen, with no gaps |
| Snapshot of any page | Background at half the page's scroll, no gaps |
| Any level | Drawn behind the trees, pipes, decorations and everything else |
| Player, enemies, anything | Never touch it |
