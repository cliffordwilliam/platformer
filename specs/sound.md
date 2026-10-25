# Sound

The music and the sound effects: which files, when each one plays, and
how loud. Read `overview.md` and `game-flow.md` first.

## Files

Everything comes from the **Ninja Adventure** asset pack by Pixel-boy and
AAA (<https://pixel-boy.itch.io/ninja-adventure-asset-pack>), released
under CC0; the licence text is next to the files (`LICENSE.txt` in
`music/` and `sounds/`) and the credit is in `README.md`. Each file is
copied unchanged and renamed after what it does:

| File | Length | From the pack |
|---|---|---|
| `res://music/adventure_begin.ogg` | 1:22 | `Audio/Musics/1 - Adventure Begin.ogg`: the title screen |
| `res://music/adventure.ogg` | 1:36 | `Audio/Musics/35 - Adventure.ogg`: every level |
| `res://sounds/jump.wav` | 0.23 s | `Sounds/Jump & Bounce/Jump.wav` |
| `res://sounds/stomp.wav` | 0.21 s | `Sounds/Jump & Bounce/Bounce.wav` |
| `res://sounds/kick.wav` | 0.24 s | `Sounds/Hit & Impact/Impact.wav` |
| `res://sounds/coin.wav` | 0.29 s | `Sounds/Bonus/Coin.wav` |
| `res://sounds/diamond.wav` | 0.47 s | `Sounds/Bonus/PowerUp1.wav` |
| `res://sounds/heal.wav` | 0.31 s | `Sounds/Magic & Skill/Heal.wav` |
| `res://sounds/break.wav` | 0.33 s | `Sounds/Elemental/Explosion3.wav` |
| `res://sounds/bump.wav` | 0.31 s | `Sounds/Hit & Impact/Impact2.wav` |
| `res://sounds/spring.wav` | 0.45 s | `Sounds/Jump & Bounce/Bounce2.wav` |
| `res://sounds/hurt.wav` | 0.34 s | `Sounds/Hit & Impact/Hit1.wav` |
| `res://sounds/death.wav` | 1.50 s | `Jingles/GameOver2.wav` |
| `res://sounds/checkpoint.wav` | 0.38 s | `Sounds/Bonus/Bonus3.wav` |
| `res://sounds/win.wav` | 0.45 s | `Jingles/Success1.wav` |
| `res://sounds/start.wav` | 0.23 s | `Sounds/Menu/Accept5.wav` |

- The `.wav` files are 44100 Hz, 16-bit, stereo.
- Godot imports `.wav` files as `AudioStreamWAV` and `.ogg` files as
  `AudioStreamOggVorbis` (run `godot --headless --path . --import` after
  adding them, `overview.md`). Code loads them with `load()`.

## The sound effects

| Effect | Plays when | `volume_db` |
|---|---|---|
| `JUMP` | The player starts a jump (`player-movement.md`); not a stomp bounce or a spring launch | +1.5 |
| `STOMP` | The player stomps any enemy: flattening a walker, flyer or leaper, turning walker B into a still shell, or flattening a kicked shell. Not a kick: the stomp that kicks a still shell plays `KICK` instead. Once per update, however many are stomped | +8.7 |
| `KICK` | A still shell is kicked (instead of `STOMP`), and when a kicked shell knocks out a walker (`enemy-walker.md`) | -2.6 |
| `COIN` | A placed coin is collected (`coins.md`), or a coin pops out of a gift block (`gift-block.md`) | -2.3 |
| `DIAMOND` | A diamond comes out of a gift block (`diamond.md`) | -0.4 |
| `HEAL` | The player collects a diamond | +4.3 |
| `BREAK` | A breakable block breaks (`breakable-block.md`) | -5.8 |
| `BUMP` | A gift block is hit, every hit, used or not (`gift-block.md`) | +2.7 |
| `SPRING` | A spring launches the player (`spring.md`) | -1.2 |
| `HURT` | The player is injured, not killed: at the hit, as the injury freeze starts (`player-damage.md`) | +2.4 |
| `DEATH` | The player dies, by a hit or the death line (`player-damage.md`) | +4.0 |
| `CHECKPOINT` | A checkpoint is raised (`checkpoint.md`) | +9.6 |
| `WIN` | The level is won, at the flag or a door (`flag.md`, `door.md`) | +5.2 |
| `START` | Space is pressed on the title screen (`game-flow.md`); played by the title screen, not by `Sounds` | +1.6 |

- **The volumes even the effects out.** As they come in the pack, their
  loudest 50 ms differ by 15 dB, from -10.2 dB (`break`) to -25.6 dB
  (`checkpoint`), so a stomp would be hard to hear next to a block
  breaking. Each `volume_db` brings its effect's loudest 50 ms (measured
  as RMS) to about **-16 dB**: `volume_db = -16 - measured`. None of the
  boosts makes an effect clip: the loudest boosted peak is about -8 dB.
  They are a measured starting point: tune them by ear in the game.

## Playing effects in a level

- `class_name Sounds extends Node`, built by the level root in its
  `_ready` (every run, tests and snapshots too, so code never has to check
  for it) and kept as `level.sounds`. Like everything the level builds, it
  gets `setup(level)`. It is not a drawn layer, so its place among the
  level's children does not matter.
- `enum Effect { JUMP, STOMP, KICK, COIN, DIAMOND, HEAL, BREAK, BUMP,
  SPRING, HURT, DEATH, CHECKPOINT, WIN }` on `Sounds`, and
  `const VOLUME_DB: Dictionary[Effect, float]` holding the table above.
- In its `_ready` it makes one built-in `AudioStreamPlayer` per effect,
  with the stream `load("res://sounds/%s.wav" % name.to_lower())`, the
  name being the enum key (`Effect.keys()`), and that effect's
  `volume_db`.
- **`play(effect: Effect) -> void`** plays that effect's player. Each
  player keeps the built-in default `max_polyphony` of 1, so playing an
  effect that is still playing starts it again from the beginning (many
  coins in a row each restart the coin sound) instead of piling up.
  Different effects play over each other.
- **`play_and_wait(effect: Effect) -> void`**, a coroutine: plays the
  effect and returns when its player's built-in `finished` signal fires
  (`await level.sounds.play_and_wait(Sounds.Effect.WIN)`).
- **`wait(effect: Effect) -> void`**, a coroutine: returns at once if that
  effect is not playing, otherwise when it finishes.
- **`process_mode = PROCESS_MODE_ALWAYS`** on `Sounds`, and so on its
  players: the hurt, death and win sounds start while the game is paused.
  Tested on 4.7.2: an `AudioStreamPlayer` with the default `process_mode`
  stops while the game is paused (`stream_paused` turns true) and carries
  on after, while one set to always keeps playing.
- Whatever causes an effect plays it, in the same place as the thing
  itself (the player's jump, its contact check, a block's `bonk()`, and so
  on), through `level.sounds.play(...)`. Nothing listens for signals to
  play sounds.

## Music

- **Looping:** an imported `.ogg` does not loop by default (`loop` is
  false, tested on 4.7.2). The code that plays music sets the built-in
  `loop = true` on the stream after loading it, and the track then starts
  over at its end by itself (tested).
- **One `AudioStreamPlayer` named `Music`**, with
  `process_mode = PROCESS_MODE_ALWAYS`, so the music keeps playing through
  the injury freeze and while the iris opens.
- **Its volume is set per track**, so both sit at about -26 LUFS, roughly
  10 dB under the effects. Measured with ffmpeg's EBU R128 meter
  (integrated loudness), `adventure_begin.ogg` is -12.4 LUFS and
  `adventure.ogg` -20.6 LUFS, so:

  | Track | `volume_db` |
  |---|---|
  | `adventure_begin.ogg` (title) | -13.6 |
  | `adventure.ogg` (levels) | -5.4 |

- **Title screen:** `Music` plays `adventure_begin.ogg` from the title's
  `_ready`. On space, the title stops it (see Game flow below).
- **A level:** only while `is_main` (`game-flow.md`), the level root
  builds `Music` with `adventure.ogg` and plays it at the end of its
  `_ready`, as the screen goes black for the iris. Tests and snapshots
  play no music.
  - It **stops** when the player dies (at the death, before the death
    sound) and when the level is won (before the win sound), so those two
    sounds are heard alone.
  - A death reloads the level, so after a retry the music starts again
    from the beginning.
- Only the default `Master` bus is used. There is no volume setting in
  the game.

## Game flow with sound

These change the steps in `game-flow.md`:

- **Title screen, space pressed:** stop `Music`, play `start.wav` on its
  own `AudioStreamPlayer` (at its `volume_db` above) and `await` its
  `finished`, then change to level 1. Space pressed again while waiting
  does nothing.
- **Death:** the player's death (`player-damage.md`) stops the level's
  `Music` (when there is one) and plays `DEATH`. In `level.on_death()`,
  before closing the iris, the level does `await sounds.wait(Sounds.Effect.DEATH)`:
  the jingle is 1.5 s, about as long as the death jump, and the reload
  would cut it off.
- **Winning:** `level.on_win()` stops `Music` and does
  `await sounds.play_and_wait(Sounds.Effect.WIN)` before closing the
  iris, only while `is_main`, so the jingle is never cut off by the scene
  change.

## Acceptance test

| Case | Expected |
|---|---|
| Title screen | `adventure_begin.ogg` playing, looping |
| Space on the title screen | Music stops, the start sound plays to its end, then level 1 loads |
| Space pressed twice quickly on the title | Level 1 loads once |
| A level starts | `adventure.ogg` playing from its beginning, looping, while the screen is black and after |
| The music reaches its end | It starts over without stopping |
| Injury freeze | The hurt sound plays and the music keeps playing while the game is paused |
| Player jumps | Jump sound |
| Player bounces off a stomp or is launched by a spring | No jump sound; the stomp sound (the kick sound for a kick) or the spring sound instead |
| Player lands on two walkers at once | One stomp sound |
| Player collects five coins in quick succession | The coin sound restarts each time; never five on top of each other |
| Player dies | The music stops; the whole death jingle plays, then the iris closes |
| Player wins | The music stops; the whole win jingle plays, then the iris closes |
| Breakable block hit | Break sound |
| Gift block hit, used or not | Bump sound; on the first hit also the coin sound, or the diamond sound when the diamond comes out |
| Still shell kicked; kicked shell hits a walker | Kick sound each time |
| A checkpoint raised | Checkpoint sound |
| Any effect | Played at its `volume_db` from the table |
| Tests and snapshots | No music; effects may play |
