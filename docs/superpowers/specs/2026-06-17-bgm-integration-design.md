# BGM Integration Design

Date: 2026-06-17

## Overview

Add background music to AttributeLoop via a new `AudioManager` autoload. Two BGM categories (explore, combat), each with two track variants selected randomly at game start.

## Audio Assets

```
resources/audio/bgm/
  explore_1.mp3
  explore_2.mp3
  combat_1.mp3
  combat_2.mp3
```

## Architecture

New file: `src/autoloads/AudioManager.gd`  
Registered as autoload in `project.godot`.

Contains two child `AudioStreamPlayer` nodes:
- `_explore_player` — looping explore BGM
- `_combat_player` — looping combat BGM

## Random Track Selection

On `_ready`, randomly pick one track from each pool and cache it for the session:

```
explore_tracks = [explore_1.mp3, explore_2.mp3]
combat_tracks  = [combat_1.mp3,  combat_2.mp3]
```

Selection is fixed per game session (not re-randomized on each switch).

## State Machine

Three states: `EXPLORE`, `COMBAT`, `SILENT`

| Trigger | Transition |
|---------|-----------|
| Game starts (`_ready`) | → EXPLORE |
| `EventBus.player_hit` | → COMBAT |
| `EventBus.combat_resolved` | → EXPLORE |
| `EventBus.player_died` | → SILENT |
| `EventBus.game_won` | → SILENT |

## Fade Transitions

Use `Tween` for 1-second crossfade:
1. Fade out current player (volume -80 dB)
2. Fade in new player (volume -6 dB)
3. Stop previous player after fade completes

## Volume

Default volume: `-6 dB` on both players.  
Both players use the default `Master` audio bus.

## project.godot Change

Add to `[autoload]` section:
```
AudioManager="*res://src/autoloads/AudioManager.gd"
```

## Testing

LOG test (`tests/test_audio_manager.gd`): verify state transitions respond to EventBus signals correctly (no audio playback in headless — test signal connections and state variable only).
