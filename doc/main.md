# Main Scene

`scenes/main/Main.gd` + `scenes/main/Main.tscn`

## Responsibility

Top-level coordinator. Wires signals between systems, manages enemy spawning, drives HUD updates. No `class_name` — not referenced by other scripts.

## Scene Tree

```
Main (Node)
├── World (Node2D)
│   ├── Track
│   ├── Player
│   └── Enemies     ← dynamically spawned enemies go here
└── HUD (CanvasLayer)
```

`GameState` is created in code (`_ready()`), not pre-placed in the scene tree.

## Initialization (_ready)

1. Create GameState, add_child
2. Assign Track reference to Player
3. Connect Player `took_damage` / `healed` → refresh HUD
4. Connect GameState `state_changed` → notify HUD
5. Give player the starter rule (heal on hit)
6. Initial HUD HP update

## Enemy Spawning

Every 5 seconds (`_spawn_interval`): instantiate Enemy, place at random track position, assign `player_ref`, call `setup_components()`.

## Input

`Space` (`ui_accept`) → `game_state.toggle()` in `_input()`.

## Preload Convention

All custom types are brought in via `preload()` at the top of Main.gd. This is the project-wide headless compatibility requirement — see `CLAUDE.md`.
