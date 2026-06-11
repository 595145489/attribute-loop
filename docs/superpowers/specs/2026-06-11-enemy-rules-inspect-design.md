# Enemy Rules & Inspect Panel Design

**Date:** 2026-06-11  
**Status:** Approved

## Goal

1. Enemy T+E component pairs trigger and fire effects during combat — enemies are treated symmetrically with the player.
2. Clicking an enemy tile shows an inspect panel with enemy stats and components.

## Core Principle

Enemies mirror the player. Same triggers, same effects, same evaluation logic. If a trigger type doesn't apply (击杀, 经过, 完成圈数), it simply never fires — no special handling needed.

---

## Part 1: Enemy Rule Execution

### Enemy New State Fields (Enemy.gd)

```gdscript
var shield: int = 0
var slow_stacks: int = 0         # reduces player's attack damage to this enemy
var lifesteal_ratio: float = 0.0
var pending_reflect_ratio: float = 0.0
var _rule_fire_count: int = 0
var _firing_rule_trigger: bool = false
```

Reset on combat start (in `CombatSystem.start()`).  
Trigger counts on all components reset to 0 on combat start.

### Trigger Events (CombatSystem.gd)

| Trigger | When | Where |
|---------|------|-------|
| 受击 | Player hits enemy | end of `_apply_player_attack` |
| 低血 | Enemy HP < 30%, every 1s | `_process(delta)` |
| 满血 | Enemy HP == hp_max, every 1s | `_process(delta)` |
| 规则触发 | Any enemy rule fires | inside `_execute_enemy_effect` |

### Effect Execution on Enemy

| Effect | Result |
|--------|--------|
| 治愈 | `enemy.hp = min(enemy.hp + val, enemy.hp_max)` |
| 护盾 | `enemy.shield += val` |
| 反射 | `enemy.pending_reflect_ratio = val` — consumed in next player attack |
| 减伤 | `enemy.slow_stacks += val` — reduces player dmg to enemy |
| 吸血 | `enemy.lifesteal_ratio += val` — enemy heals on attack |

### Combat Flow Changes

**`_apply_player_attack(enemy)`:**
1. Compute dmg = `DataTables.player.dmg_base`
2. Apply enemy `slow_stacks` damage reduction (same formula as player: `min(phase+1, 8)` stack cap)
3. Apply enemy `shield` absorption
4. `enemy.take_damage(dmg)` if dmg > 0
5. Apply player `lifesteal_ratio` heal (existing)
6. Consume `enemy.pending_reflect_ratio` → deal reflected dmg to player
7. **`_evaluate_enemy_triggers(["受击"])`**
8. `_finish_combat` if dead

**`_apply_enemy_attack(enemy)`:**
1. Compute dmg = `enemy.dmg`
2. Apply player `slow_stacks` reduction (existing)
3. `GameState.take_damage(dmg)`
4. `EventBus.player_hit.emit(dmg)`
5. Apply player `pending_reflect_ratio` → deal reflected dmg back to enemy (existing)
6. Apply enemy `lifesteal_ratio` → enemy heals from dmg dealt

### New Methods in CombatSystem

```gdscript
var _enemy_state_timer: float = 0.0
const _ENEMY_STATE_INTERVAL: float = 1.0

func _process(delta: float) -> void
func _check_enemy_state_triggers() -> void   # 低血 + 满血 checks
func _evaluate_enemy_triggers(ids: Array) -> void
func _execute_enemy_effect(effect: ComponentData) -> void
```

`_evaluate_enemy_triggers` walks `enemy.components` in pairs (index 0+1, 2+3…), matching trigger IDs, accumulating trigger_count, firing when threshold reached.

`规则触发` guard: `enemy._firing_rule_trigger` flag prevents cascade.

---

## Part 2: Enemy Inspect Panel

### Trigger

`Main.gd._on_tile_clicked(tile)`:
```
if tile.is_altar        → altar_panel.open(tile)
elif tile.has_enemy()   → enemy_inspect_panel.open(tile.get_enemy())  ← NEW
else                    → tile_rule_panel.open(tile)
```

`tile.get_enemy()` — new helper on Tile that returns the current Enemy node on this tile (nil if none).

### Panel Content (EnemyInspectPanel.gd)

Built programmatically in `open(enemy)`:
- **Header:** enemy display name
- **Stats row:** HP bar (current/max), DMG, attack interval
- **Components section:** component pairs displayed as rows
  - Each row: T icon + T name (trigger_value) → E icon + E name (effect_value)
  - Hover tooltip via `Tooltip.build_trigger_tip` / `Tooltip.build_effect_tip`
- **Close button**

Panel pauses game while open. Closes on button press or clicking outside.

### Scene

`scenes/ui/enemy_inspect_panel.tscn` — PanelContainer, styled with existing ui_theme.

---

## Files Modified / Created

| File | Change |
|------|--------|
| `src/entities/Enemy.gd` | Add 6 state fields |
| `src/systems/CombatSystem.gd` | Enemy rule evaluation, state timer, combat flow updates |
| `src/Main.gd` | Route enemy tile clicks to inspect panel |
| `src/entities/Tile.gd` | Add `has_enemy()` / `get_enemy()` helpers if not present |
| `src/ui/EnemyInspectPanel.gd` | New panel script |
| `scenes/ui/enemy_inspect_panel.tscn` | New panel scene |

## Tests

- Enemy shield absorbs player's attack damage
- Enemy 受击 trigger increments and fires on threshold
- Enemy 治愈 heals enemy
- Enemy 减伤 reduces player's damage to enemy
- Enemy 反射 reflects player's next attack back to player
- Enemy `lifesteal_ratio` heals enemy on attack
- Enemy state resets on new combat
- 规则触发 guard prevents enemy cascade loop
