# AudioManager

Autoload responsible for background music playback and state-driven track switching.

## Responsibilities

- Randomly selects one explore track and one combat track at game start (fixed for the session)
- Maintains a three-state machine: EXPLORE → COMBAT → SILENT
- Crossfades between tracks on state transitions (1-second Tween fade)
- Stops music on game-over or game-won
- Provides `reset()` for game restart without re-instantiation

## Key Classes / Nodes

- `AudioManager` (autoload, `src/autoloads/AudioManager.gd`)
  - `state: State` — current playback state (EXPLORE / COMBAT / SILENT)
  - `reset()` — restores volumes and restarts explore BGM (call on game restart)

## Execution Flow

1. `_ready`: create `_explore_player` and `_combat_player`, randomly load streams, connect EventBus signals, start explore BGM
2. `EventBus.player_hit` → `_on_player_hit` → crossfade to combat (only if state == EXPLORE)
3. `EventBus.combat_resolved` → `_on_combat_resolved` → crossfade back to explore (only if state == COMBAT)
4. `EventBus.player_died` / `game_won` → `_fade_out_all` → SILENT state, both players faded and stopped
5. On game restart: call `AudioManager.reset()` to resume from EXPLORE

## Audio Assets

```
resources/audio/bgm/
  explore_1.mp3   — explore BGM variant 1
  explore_2.mp3   — explore BGM variant 2
  combat_1.mp3    — combat BGM variant 1
  combat_2.mp3    — combat BGM variant 2
```

## Dependencies

- `EventBus` — listens to `player_hit`, `combat_resolved`, `player_died`, `game_won`
