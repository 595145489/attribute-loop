# AttributeLoop — Project Architecture & Development Roadmap

**Date:** 2026-05-18
**Status:** Approved

---

## Development Workflow

One phase at a time:

```
Brainstorm Phase N  →  Write Plan  →  Implement  →  Brainstorm Phase N+1
```

Each phase ends with a playable build. Design for the next phase does not start until the current phase is implemented and reviewed.

---

## Phase Roadmap

| Phase | Name | Playable Goal |
|-------|------|---------------|
| 1 | 可行走的世界 | Player auto-walks the loop, encounters enemies, basic combat, can die |
| 2 | 可剥取的规则 | Strip components, 12-slot inventory, player rule slots fire triggers |
| 3 | 永久的地块 | Tile rule placement, pass_count scaling, Altar, gold economy |
| 4 | 世界压力 | Full 10-phase system, all 5 enemy types, all scaling formulas |
| 5 | 裁决圈 + 发布 | Endgame survival loop, win/lose screens, HTML5 export |

---

## Directory Structure

```
S:\attribute-loop\
├── project.godot
├── icon.svg
│
├── src/                          ← all .gd scripts
│   ├── autoloads/
│   │   ├── GameState.gd
│   │   ├── EventBus.gd
│   │   └── DataTables.gd
│   ├── systems/
│   │   ├── RuleEngine.gd
│   │   ├── CombatSystem.gd
│   │   ├── EconomyManager.gd
│   │   └── PhaseManager.gd
│   ├── entities/
│   │   ├── Player.gd
│   │   ├── Enemy.gd
│   │   └── Tile.gd
│   └── ui/
│       ├── HUD.gd
│       ├── StripPanel.gd
│       ├── InventoryUI.gd
│       └── TileRuleUI.gd
│
├── data/                         ← game data (.tres instances)
│   └── components/
│       ├── trigger_受击.tres
│       ├── trigger_击杀.tres
│       ├── trigger_低血.tres
│       ├── trigger_完成一圈.tres
│       ├── trigger_经过.tres
│       ├── effect_治愈.tres
│       ├── effect_护盾.tres
│       ├── effect_反射.tres
│       ├── effect_加速.tres
│       └── effect_蓄能.tres
│
├── scenes/                       ← all .tscn scenes
│   ├── main.tscn
│   ├── entities/
│   │   ├── player.tscn
│   │   ├── enemy.tscn
│   │   └── tile.tscn
│   └── ui/
│       ├── hud.tscn
│       ├── strip_panel.tscn
│       └── inventory_ui.tscn
│
└── resources/                    ← art assets (images, fonts, etc.)
```

---

## Core Architecture Decisions

### 1. Three Autoloads

| Autoload | Responsibility |
|----------|---------------|
| `GameState` | All runtime state: HP, gold, inventory, current phase, is_paused |
| `EventBus` | Global signal hub — all rule triggers broadcast here |
| `DataTables` | All balance/config tables as typed GDScript constants |

### 2. DataTables — All Balance Numbers in One File

Enemy stats, phase requirements, spawn weights, component count ranges, deletion costs — all live in `DataTables.gd`. Nothing is hardcoded in entity scripts.

```gdscript
# Pattern
const ENEMY_DEFS := {
    "汲取者": {hp = 40, dmg = 8, gold_min = 5, gold_max = 15, unlock_phase = 1},
    ...
}
```

### 3. One Enemy Scene, Data-Driven

`enemy.tscn` + `Enemy.gd` is a single generic scene. Different enemy types are driven by `enemy_id` passed to `init()`, which reads from `DataTables.ENEMY_DEFS`.

### 4. ComponentData as Resource

Component definitions (`ComponentData.gd`) extend `Resource`. The ~15 component types are each a `.tres` file in `data/components/`. Class definition lives in `src/`, instances live in `data/`.

```gdscript
class_name ComponentData
extends Resource

enum Kind { TRIGGER, EFFECT }

@export var kind: Kind
@export var id: String
@export var base_value: float
@export var growth_rate: float
@export var count_n: int = 1
```

### 5. EventBus — Decoupled Rule Triggers

Entities never call the rule system directly. They emit events:

```gdscript
EventBus.emit_signal("player_hit", damage)
EventBus.emit_signal("enemy_killed")
EventBus.emit_signal("tile_passed")
EventBus.emit_signal("loop_completed")
```

`RuleEngine` listens to all events and evaluates active rules. Player and rules have no knowledge of each other.

### 6. Systems are Scene Nodes, Not Autoloads

`CombatSystem`, `RuleEngine`, `EconomyManager`, `PhaseManager` are `Node` children of `main.tscn` — not autoloads. They need scene context and are only active during gameplay.

---

## What Is NOT Decided Yet

Each phase's specific scene tree, script interfaces, and implementation details are designed in the brainstorm immediately before that phase is built.
