# Phase 1 Design — 可行走的世界

**Date:** 2026-05-19
**Status:** Approved
**Playable Goal:** Player auto-walks the loop, encounters enemies, basic combat, can die.

---

## 1. Scene Structure

```
main.tscn
├── GameLoop (Node)               — state machine: walking / combat / gameover
├── Track (Path2D)                — rectangular loop
│   └── PlayerFollow (PathFollow2D)
│       └── [player.tscn]
├── TilesContainer (Node2D)      — 12 × [tile.tscn] instances
├── EnemiesContainer (Node2D)    — dynamically instantiated [enemy.tscn]
├── CombatSystem (Node)          — handles auto-attack rounds
└── [hud.tscn]                   — CanvasLayer, always visible

scenes/
├── main.tscn
├── entities/
│   ├── player.tscn
│   ├── enemy.tscn               — generic, data-driven via enemy_id
│   └── tile.tscn
└── ui/
    ├── hud.tscn
    └── game_over.tscn           — loaded dynamically on player death, freed on restart
```

---

## 2. Autoloads

| Autoload | Responsibility |
|----------|---------------|
| `GameState` | Runtime state: hp, hp_max, loops_completed, enemies_killed, current_phase, is_paused |
| `EventBus` | Global signal hub |
| `DataTables` | Loads and caches all .tres data files at startup |

### EventBus — Phase 1 Signals

```gdscript
signal enemy_killed(enemy_id: String)
signal combat_resolved          # combat ended, player may resume walking
signal loop_completed           # player completed a full loop
signal player_died
```

### GameState — Phase 1 Fields

```gdscript
var hp: int
var hp_max: int
var loops_completed: int
var enemies_killed: int
var current_phase: int = 1
var is_paused: bool = false
```

---

## 3. Data Layer

All balance values live in `.tres` Resource files. No magic numbers in scripts.

```
data/
├── game_config.tres             — global formula coefficients
├── player_data.tres             — player base stats
├── enemies/
│   ├── enemy_汲取者.tres
│   └── enemy_守卫者.tres
├── phases/
│   ├── phase_1.tres
│   ├── phase_2.tres
│   └── ... (phase_3 through phase_10)
└── components/                  — populated in Phase 2+
```

### Resource Schemas

**GameConfig (game_config.tres)**
```gdscript
class_name GameConfig extends Resource
@export var stat_scale_factor: float = 0.3
# stat = base × (1 + (phase - 1) × stat_scale_factor)
```

**PlayerData (player_data.tres)**
```gdscript
class_name PlayerData extends Resource
@export var hp_base: int
@export var dmg_base: int
@export var attack_interval: float  # seconds between player attacks
@export var walk_speed: float       # PathFollow2D progress units per second
```

**EnemyData (per enemy .tres)**
```gdscript
class_name EnemyData extends Resource
@export var id: String
@export var hp_base: int
@export var dmg_base: int
@export var gold_min: int
@export var gold_max: int
@export var unlock_phase: int
@export var attack_interval: float  # seconds between this enemy's attacks
```

**PhaseData (per phase .tres)**
```gdscript
class_name PhaseData extends Resource
@export var phase_id: int
@export var name: String
@export var altar_requirement: int
@export var world_pressure_window: int       # loops before forced advance
@export var spawn_count_min: int
@export var spawn_count_max: int
@export var spawn_weights: Dictionary        # { "汲取者": 50, "守卫者": 50 }
@export var enemy_component_count_min: int
@export var enemy_component_count_max: int
```

`DataTables.gd` preloads all files at `_ready()` and exposes typed accessors. Scripts never access raw dictionaries directly.

---

## 4. Track & Player Movement

- Track is a `Path2D` with a rectangular `Curve2D` (4 corner control points).
- 12 tiles are positioned by sampling the curve at equal intervals: `curve.sample_baked(i / 12.0 * curve.get_baked_length())`.
- Player moves via `PathFollow2D.progress_ratio`, incremented each frame at a rate driven by `PlayerData.walk_speed` (configurable).
- Movement halts when `GameState.is_paused == true`.
- On reaching `progress_ratio >= 1.0` (full loop): emit `loop_completed`, reset to 0.0, re-spawn enemies for the new loop.

---

## 5. Enemy Spawning

On game start and after each `loop_completed`:

1. Read current `PhaseData` from `DataTables`.
2. Roll `spawn_count` in `[spawn_count_min, spawn_count_max]`.
3. Pick `spawn_count` distinct tile indices at random (from 12 tiles).
4. For each selected tile, roll enemy type using `spawn_weights`.
5. Instantiate `enemy.tscn` at the tile position, call `enemy.init(enemy_id)`.

Only enemy types with `unlock_phase <= current_phase` are eligible.

---

## 6. Combat Flow

```
Player reaches tile with enemy
  → GameState.is_paused = true  (player stops)
  → CombatSystem.start(enemy)

CombatSystem (auto-attack rounds):
  Every player.attack_interval seconds:
    enemy.hp -= PlayerData.dmg_base  # no rule effects in Phase 1
  Every enemy.attack_interval seconds:
    GameState.hp -= enemy_dmg (scaled: dmg_base × (1 + (phase-1) × stat_scale_factor))

  enemy.hp <= 0:
    GameState.enemies_killed += 1
    EventBus.emit_signal("enemy_killed", enemy.id)
    enemy.queue_free()
    EventBus.emit_signal("combat_resolved")   ← Phase 2 will delay this for strip panel

  GameState.hp <= 0:
    EventBus.emit_signal("player_died")
```

`combat_resolved` → `GameState.is_paused = false` → player resumes walking.

The `combat_resolved` signal is the Phase 2 hook: the strip panel will intercept `enemy_killed`, show the UI, and only emit `combat_resolved` after the player finishes stripping. No changes needed to Phase 1 code.

---

## 7. HUD (hud.tscn)

Displays during gameplay:
- HP: current / max
- Loops completed
- Current phase name (e.g. "Phase 1 — 觉醒")

No gold, no inventory, no rule slots in Phase 1.

---

## 8. Game Over (game_over.tscn)

Triggered by `player_died` signal. Loaded dynamically into main scene tree.

Displays:
- "GAME OVER"
- Loops survived: N
- Enemies killed: N
- Restart button

Restart: reset `GameState` → reload `main.tscn`.

---

## 9. Out of Scope for Phase 1

- Component stripping and inventory
- Player rule slots
- Tile rule placement and pass_count scaling
- Altar and Phase advancement
- Gold economy
- World pressure system
- Enemy types beyond 汲取者 and 守卫者
