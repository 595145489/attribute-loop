# Phase 1 Systems

## Overview

Phase 1 ("可行走的世界") delivers the minimal playable loop: the player auto-walks a rectangular track, encounters enemies, fights automatically, and can die. Every balance value is driven by `.tres` data files — no magic numbers in scripts.

---

## Module Responsibilities

| Module | Responsibility |
|--------|---------------|
| `EventBus` | Global signal hub — decouples all cross-system communication |
| `GameState` | Runtime state (HP, loops completed, current phase, paused flag) |
| `DataTables` | Loads and caches all `.tres` resource files at startup |
| `Player` | PathFollow2D auto-walk, loop detection, emits `loop_completed` |
| `Enemy` | Data-driven init — reads EnemyData + scales stats to current phase |
| `Tile` | Position marker on the track, holds a reference to any occupying enemy |
| `CombatSystem` | Timer-driven auto-attack rounds between player and one enemy |
| `GameLoop` | State machine (WALKING / COMBAT / GAME_OVER) + enemy spawning logic |
| `HUD` | Polls `GameState` every frame and updates HP / Loops / Phase labels |
| `GameOver` | Shows final stats, handles restart via `GameState.reset()` |
| `Main` | Scene root — builds the tile grid at startup, wires all systems together |

---

## Key Classes & Signals

### EventBus signals

| Signal | Emitted by | Consumed by |
|--------|-----------|-------------|
| `loop_completed` | `Player._process` | `GameLoop._on_loop_completed` |
| `combat_resolved` | `CombatSystem._finish_combat` | `GameLoop._on_combat_resolved` |
| `enemy_killed(id)` | `CombatSystem._finish_combat` | (future: stats tracking) |
| `player_died` | `GameState.take_damage` | `GameLoop._on_player_died`, `Main._on_player_died` |

### GameState exported fields

`hp`, `hp_max`, `loops_completed`, `enemies_killed`, `current_phase`, `is_paused`

### DataTables accessors

- `DataTables.get_enemy(id: String) -> EnemyData`
- `DataTables.get_phase(phase_id: int) -> PhaseData`
- `DataTables.calc_stat(base: int, phase: int) -> int` — applies `stat_scale_factor`

---

## Execution Flow

### Startup

1. Godot loads autoloads: `EventBus` → `GameState` → `DataTables` (in order)
2. `DataTables._ready()` loads all `.tres` files into memory
3. `Main._ready()` runs:
   - Calls `_build_tiles()`: instantiates 12 `Tile` nodes evenly spaced along the `Path2D` curve
   - Calls `Player.setup(player_follow, track)` — stores path reference and walk speed from `DataTables.player`
   - Calls `GameLoop.setup(tiles, enemies_container, player, combat_system)` — connects EventBus signals and calls `spawn_enemies()`
4. `GameLoop.spawn_enemies()`: rolls spawn count, picks random tiles, instantiates `Enemy` nodes from `PhaseData` weights

### Walk Loop

- `Player._process(delta)` advances `PathFollow2D.progress` by `walk_speed * delta`
- When `progress / path_length` increments: emits `EventBus.loop_completed`
- `Main._process()` calls `_check_player_tile()` each frame — if player is within 30 px of a tile with an enemy, calls `GameLoop.check_tile_for_enemy(tile)`

### Combat

1. `GameLoop.check_tile_for_enemy()` sets `state = COMBAT`, pauses via `GameState.is_paused = true`, calls `CombatSystem.start(enemy)`
2. Two timers fire alternately: `_player_timer` → `_apply_player_attack`, `_enemy_timer` → `_apply_enemy_attack`
3. When enemy HP ≤ 0: `CombatSystem._finish_combat()` stops timers, emits `combat_resolved` and `enemy_killed`
4. `GameLoop._on_combat_resolved()` clears the tile, sets `state = WALKING`, unpauses

### Death

1. `GameState.take_damage()` clamps HP to 0, emits `player_died`
2. `GameLoop._on_player_died()` sets `state = GAME_OVER`, freezes game
3. `Main._on_player_died()` instantiates `GameOver` overlay
4. Player presses Restart → `GameState.reset()` + `get_tree().reload_current_scene()`

---

## Dependencies Between Modules

```
DataTables
  └─ loaded by: GameState (hp_max default comes from player_data)
  └─ used by: Enemy.init(), CombatSystem (attack intervals), GameLoop (spawn weights)

EventBus
  └─ connects: Player → GameLoop, CombatSystem → GameLoop, GameState → (any listener)

Main
  └─ owns: Player, Tile[], EnemiesContainer, CombatSystem, GameLoop, HUD
  └─ wires: Player.setup(), GameLoop.setup()
```

---

## Data Files

All balance values live under `data/`:

| File | Class | Purpose |
|------|-------|---------|
| `data/game_config.tres` | `GameConfig` | `stat_scale_factor = 0.3` — per-phase stat multiplier |
| `data/player_data.tres` | `PlayerData` | HP, damage, walk speed, attack interval |
| `data/enemies/enemy_*.tres` | `EnemyData` | Per-enemy stats and `unlock_phase` |
| `data/phases/phase_1.tres` … `phase_10.tres` | `PhaseData` | Spawn counts, enemy weights, pressure window |
