# Phase 4 Partial Design — 世界压力 + 急袭者

**Date:** 2026-05-25
**Status:** Approved
**Scope:** World pressure system (auto Phase advance without buff) + 急袭者 enemy type. Excludes new effects (护盾/加速/蓄能) and new triggers (低血).

---

## 1. World Pressure System

### Goal

If the player fails to fill the Altar within `world_pressure_window` loops after a Phase transition, the Phase advances automatically — without any altar bonus.

### Data Layer (no changes needed)

`PhaseData.world_pressure_window` already exists on all phase `.tres` files. No schema changes required.

### GameState Additions

```gdscript
var loops_in_phase: int = 0
```

Reset to `0` in:
- `reset()`
- `force_phase_advance()` (pressure path)
- `AltarPanel._on_activate_pressed()` (player path)

New method:

```gdscript
func force_phase_advance() -> void:
    current_phase += 1
    loops_in_phase = 0
    EventBus.phase_changed.emit(current_phase)
```

### GameLoop Changes

In `_on_loop_completed()`, after resetting `visited_this_loop` and before `spawn_enemies()`:

```gdscript
GameState.loops_in_phase += 1
var phase_data := DataTables.get_phase(GameState.current_phase)
if GameState.loops_in_phase >= phase_data.world_pressure_window:
    var altar: Tile = _tiles[0]  # index 0 is always the altar tile
    if not _altar_is_full(altar):
        GameState.force_phase_advance()
```

Helper:

```gdscript
static func _altar_is_full(altar: Tile) -> bool:
    for slot in altar.altar_slots:
        if slot == null:
            return false
    return altar.altar_slots.size() > 0
```

`_tiles[0]` is the altar tile — this is the invariant established in `Main._ready()` where `tile.is_altar = (i == 0)`.

### AltarPanel Change

After `GameState.current_phase += 1` and before `EventBus.phase_changed.emit(...)`:

```gdscript
GameState.loops_in_phase = 0
```

### HUD Change

Add a pressure counter label to the bottom bar. Displays: `压力: {loops_in_phase}/{world_pressure_window}圈`

- Updates on `EventBus.loop_completed` — increment display
- Resets on `EventBus.phase_changed` — re-read `GameState.loops_in_phase` (will be 0)

No new EventBus signals needed.

---

## 2. 急袭者 Enemy Type

### Stats (already in `data/enemies/enemy_急袭者.tres`)

| Field | Value |
|-------|-------|
| `hp_base` | 25 |
| `dmg_base` | 10 |
| `attack_interval` | 0.4 s |
| `unlock_phase` | 4 |
| `gold_min` | 20 |
| `gold_max` | 50 |

### Fields to Add to `enemy_急袭者.tres`

| Field | Value |
|-------|-------|
| `gold_scale` | 0.3 |
| `component_pair_min` | 1 |
| `component_pair_max` | 2 |
| `trigger_weights` | 受击:35, 击杀:35, 经过:30 |
| `effect_weights` | 治愈:50, 反射:50 |
| `phase_drop_presets` | {4: drop_tier_03} |

### Spawn Integration (already configured)

`data/phases/phase_4.tres` already contains:
```
spawn_weights = {"守卫者": 40, "急袭者": 20, "汲取者": 40}
```

`GameLoop._pick_enemy_id()` already filters by `unlock_phase`, so 急袭者 will not appear before Phase 4.

---

## 3. Files Changed

| File | Change |
|------|--------|
| `src/autoloads/GameState.gd` | Add `loops_in_phase`, `force_phase_advance()`, reset in `reset()` |
| `src/systems/GameLoop.gd` | Pressure check in `_on_loop_completed()`, `_altar_is_full()` helper |
| `src/ui/AltarPanel.gd` | Reset `loops_in_phase = 0` on activate |
| `src/ui/HUD.gd` | Add pressure label, wire `loop_completed` + `phase_changed` |
| `scenes/ui/hud.tscn` | Add pressure Label node to bottom bar |
| `data/enemies/enemy_急袭者.tres` | Add missing fields |

No new scenes, no new scripts, no schema changes.

---

## 4. Out of Scope

- New effects: 护盾, 加速, 蓄能
- New triggers: 低血
- Enemy types: 复制者, 先驱者
- Pressure visual warnings (color/flash) — deferred to UI pass
