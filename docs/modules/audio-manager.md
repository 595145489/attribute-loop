# AudioManager

Autoload responsible for background music (BGM) playback and state-driven muting.

## Responsibilities

- Loads and plays the single idle BGM track at game start
- Keeps the track looping continuously so music never falls silent mid-session
- Fades to silence on game-over or game-won
- Provides `reset()` for game restart without re-instantiation

## Key Classes / Nodes

- `AudioManager` (autoload, `src/autoloads/AudioManager.gd`)
  - `state: State` — current playback state (`PLAYING` / `SILENT`)
  - `reset()` — restores default volume and restarts BGM (call on game restart)
  - `_player: AudioStreamPlayer` — internal player holding the BGM stream

## Execution Flow

1. `_ready`: create `_player`, connect `EventBus.player_died` / `game_won` to `_on_stop`, load the BGM stream, enable native looping (`stream.loop = true`), and start playback (playback guarded for headless test runs)
2. `EventBus.player_died` / `EventBus.game_won` → `_on_stop` → tween volume to silence over `FADE_DURATION`, then stop the player; `state` becomes `SILENT`
3. On game restart: call `AudioManager.reset()` to restore volume and resume from `PLAYING`

## Looping

The BGM must play continuously. Looping is enforced in code by setting
`_player.stream.loop = true` right after loading, rather than relying on the
MP3 import settings (`resources/audio/bgm/idle_1.mp3.import` ships with
`loop=false`). This keeps the behavior deterministic and survives reimports.
The regression test `test_bgm_stream_configured_to_loop` guards against this
reverting.

## Audio Assets

```
resources/audio/bgm/
  idle_1.mp3   — single idle/exploration BGM track
```

## Dependencies

- `EventBus` — listens to `player_died`, `game_won`
