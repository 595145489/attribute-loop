# Game State

`scripts/systems/GameState.gd`

Extends `Node`. Created dynamically in `Main._ready()` and added as a child of Main.

## States

```
RUNNING (0) ←→ PAUSED (1)
```

Toggling also calls `get_tree().paused`, which pauses all nodes not set to `process_mode = ALWAYS`.

## API

| Method | Description |
|--------|-------------|
| `pause()` | RUNNING → PAUSED |
| `resume()` | PAUSED → RUNNING |
| `toggle()` | Switch current state |

## Signal

`state_changed(new_state: State)` — Main listens and tells HUD to show/hide the pause overlay.

## Notes

Any node that must remain active during pause (e.g. drag UI) must set `process_mode = ALWAYS`.

**Input**: `Space` (`ui_accept`) calls `game_state.toggle()` from `Main._input()`.
