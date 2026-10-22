# Controls

Which keys play the game. Read `overview.md` first.

## Keys

| Action | Key |
|---|---|
| `move_left` | Left arrow |
| `move_right` | Right arrow |
| `jump` | Space |
| `move_up` | Up arrow (climbs ladders, `ladder.md`) |

- Keyboard only. No gamepad, and the player cannot remap keys.

## How they are set up

The Godot docs recommend input actions over checking raw keys
(tutorials, "Input examples"):

- The four actions above are defined in **Project Settings > Input Map**,
  each with its one key. Nothing else (no extra keys, no gamepad buttons).
- Use these custom actions, not Godot's built-in `ui_left`, `ui_right` or
  `ui_accept`: those come with extra keys and gamepad buttons already bound
  (`ui_accept` also fires on Enter, for example).
- Code never checks keys directly, only these action names.

## How they are read

Input is read in the player's `_physics_process`, in step 1 of each update
(see `player-movement.md`), by polling the built-in `Input` singleton, not
with `_input()` events:

- **Direction:** `Input.get_axis("move_left", "move_right")`. It gives -1
  for left, 1 for right, and 0 when neither or both are held, which is
  exactly the target-speed rule in `player-movement.md`.
- **Jump:** `Input.is_action_pressed("jump")`. Jumping happens while jump is
  **held** (not only on the update it is pressed), so "pressed" polling is
  the right call, not `is_action_just_pressed`.
- **Up:** `Input.is_action_pressed("move_up")`, held the same way: the
  player climbs while it is held.
- While dead (the player is switched off), nothing reads input.

## Acceptance test

| Case | Expected |
|---|---|
| Right arrow held | Direction 1 |
| Left arrow held | Direction -1 |
| Both arrows held | Direction 0 |
| Space held | Jump held |
| Up arrow held | Up held |
| Enter, A, D or W pressed | Nothing happens |
