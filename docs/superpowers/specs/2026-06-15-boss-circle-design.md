# Boss Circle Feature Design

## Overview

After a pressure circle completes (world_pressure_window reached) or the altar is activated, the next loop becomes a "boss circle." The boss circle spawns a single enemy at the last tile before the altar, with scaled-up stats and a larger sprite. All other tiles remain empty.

## Trigger Conditions

Two events set `GameState.boss_circle_pending = true`:

1. **Pressure window hit:** In `GameLoop._on_loop_completed()`, when `loops_in_phase >= phase_data.world_pressure_window`
2. **Altar activated:** Via listener on `EventBus.altar_activated`

The flag is consumed (set back to `false`) at the start of the next `spawn_enemies()` call.

## Data Changes

### GameState.gd
```gdscript
var boss_circle_pending: bool = false
```

### PhaseData.gd (new export fields)
```gdscript
@export var boss_hp_multiplier: float = 2.0
@export var boss_damage_multiplier: float = 2.0
@export var boss_scale: float = 1.6
```

Each `phase_X.tres` file gets these fields configured independently.

## Spawn Logic (GameLoop.gd)

`spawn_enemies()` checks `GameState.boss_circle_pending` at the top:

**Boss circle path:**
1. Clear all existing enemies
2. Find the last tile: `_tiles[_tiles.size() - 1]` (highest index, excluding tile 0 which is the altar)
3. Pick one enemy via existing `_pick_enemy_id()` using current phase spawn weights
4. Instantiate enemy, place at last tile's `guard_position`
5. Call `_assign_components()` as normal
6. Apply boss multipliers to enemy stats (HP × `boss_hp_multiplier`, damage × `boss_damage_multiplier`)
7. Scale enemy sprite node by `boss_scale`
8. Set `GameState.boss_circle_pending = false`

**Normal path:** unchanged when flag is false.

## UI Changes (HUD.gd)

In `_process()`, add a branch between `in_verdict_loop` and the normal else:

```gdscript
elif GameState.boss_circle_pending:
    var phase_data: PhaseData = DataTables.get_phase(GameState.current_phase)
    phase_label.text = "阶段%d · %s  ⚠ Boss圈" % [GameState.current_phase, phase_data.phase_name]
    pressure_label.text = "压力: %d/%d圈" % [GameState.loops_in_phase, phase_data.world_pressure_window]
    for i in GameState.rule_slots.size():
        _update_rule_panel(i)
```

- `phase_label` shows the boss indicator appended to the normal phase name
- `pressure_label` is unchanged — shows normal pressure progress
- Flag consumed after spawn means display reverts automatically next loop

## Constraints

- Boss circle has exactly one enemy — no other spawns
- Enemy type is random (same weighted selection as normal spawns)
- Stats and scale are per-phase configurable, not global constants
- Pressure circle counter (`loops_in_phase`) is not reset or modified by boss circle logic
- No new signals added — boss circle is entirely driven by the `boss_circle_pending` flag
