# Platformer

A small 2D platformer for Godot 4.7.2, written first as a full spec, to be
built from that spec by Claude.

- `specs/`: the spec, one file per mechanic. Start with `specs/overview.md`.
- `art/`: the sprites and tiles.
- `music/`: the music.
- `sounds/`: the sound effects.
- `PROMPT.md`: the prompt that builds the game from all of the above.
- `measure/`: how the recorded build was measured, and the meter used.

## Two branches

- **`main`:** the specs, the assets and the prompt. To build the game
  yourself, clone it, open Claude Code in it and say "Read PROMPT.md and
  do what it says."
- **`build`:** the game Claude built from `main` in one recorded run, one
  small commit per step, each ending with that run's time, tokens and
  cost so far (`measure/README.md`).

## Credits

- **Art:** [Kenney](https://kenney.nl), released under
  [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
- **Music and sound effects:** [Pixel-boy](https://pixel-boy.itch.io/)
  and [AAA](https://www.instagram.com/challenger.aaa/), from the
  [Ninja Adventure](https://pixel-boy.itch.io/ninja-adventure-asset-pack)
  asset pack, released under
  [CC0](https://creativecommons.org/publicdomain/zero/1.0/). The licence
  text is in `music/LICENSE.txt` and `sounds/LICENSE.txt`.

Neither licence asks for credit; it is given here because it is deserved.
