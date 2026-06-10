# New Components Design — Triggers & Effects Expansion

**Date:** 2026-06-10  
**Status:** Approved

## Overview

Expand the component system from 4 triggers + 2 effects to 7 triggers + 5 effects by implementing 3 new triggers and 3 new effects. Two previously planned components (加速, 溢出治愈) are excluded as not fitting the game's mechanics.

## New Triggers

### 低血 (Low HP)
- **Icon:** `trigger_low_hp.png`
- **Condition:** Player HP < 30% of hp_max
- **Evaluation:** Time-based. RuleEngine runs a 1-second interval timer via `_process(delta)`. Each tick where the condition is true increments `trigger_count`.
- **trigger_value meaning:** Number of consecutive seconds at low HP before firing. Resets to 0 once fired.
- **Implementation site:** `RuleEngine._check_state_triggers()` called from `_process()`

### 满血 (Full HP)
- **Icon:** `trigger_full_hp.png`
- **Condition:** Player HP == hp_max
- **Evaluation:** Same 1-second timer as 低血. Each tick at full HP increments `trigger_count`.
- **trigger_value meaning:** Number of consecutive seconds at full HP before firing.
- **Implementation site:** `RuleEngine._check_state_triggers()`

### 规则触发 (Rule Fire)
- **Icon:** `trigger_rule_fire.png`
- **Condition:** Any rule fires
- **Evaluation:** Event-based. RuleEngine maintains `_any_rule_fire_count: int`. Every time `EventBus.rule_fired` emits, increment this counter. When count reaches `trigger_value`, fire all 规则触发 rules and reset counter.
- **trigger_value meaning:** How many total rule-fires before this activates.
- **Self-trigger guard:** Use a `_firing_rule_trigger: bool` flag. While 规则触发 is evaluating/firing, skip incrementing `_any_rule_fire_count` to prevent cascading infinite loops.
- **Implementation site:** `RuleEngine._on_rule_fired()` (extend existing handler)

## New Effects

### 护盾 (Shield)
- **Icon:** `effect_shield.png`
- **Effect:** Adds shield buffer that absorbs damage before HP.
- **formula:** `shield += int(final_value)`
- **Damage order:** In `GameState.take_damage()`: absorb from `shield` first, remainder hits HP.
- **State:** `GameState.shield: int` (reset to 0 on `reset()`)
- **HUD display:** Separate line below HP label — `"护盾: %d" % GameState.shield`. Hidden when shield == 0.

### 减速 (Slow)
- **Icon:** `effect_slow.png`
- **Effect:** Reduces all enemy damage by stacking percentage debuff.
- **Formula:** Each activation adds `int(final_value)` slow stacks. Each stack = 10% damage reduction. Cap: 80% reduction (8 stacks max).
- **State:** `GameState.slow_stacks: int` (reset to 0 on `reset()`)
- **Damage application:** In `CombatSystem`, before applying enemy damage: `damage = int(damage * (1.0 - min(GameState.slow_stacks * 0.1, 0.8)))`

### 吸血 (Lifesteal)
- **Icon:** `effect_lifesteal.png`
- **Effect:** After dealing damage to an enemy, heal for a percentage of damage dealt. Persistent stat (accumulates over the run).
- **State:** `GameState.lifesteal_ratio: float` — accumulates each time the effect fires (like `slow_stacks`). Never resets to 0 mid-run; reset only on `reset()`.
- **Formula per activation:** `GameState.lifesteal_ratio += final_value`
- **Combat formula:** In `CombatSystem._apply_player_attack()`, after damage: `heal = int(DataTables.player.dmg_base * GameState.lifesteal_ratio)`. Applied to HP, capped at hp_max. Emits `rule_fired` for HUD log.

## Data Files

One `.tres` resource file per component in `data/components/`:
- `trigger_低血.tres`
- `trigger_满血.tres`
- `trigger_规则触发.tres`
- `effect_护盾.tres`
- `effect_减速.tres`
- `effect_吸血.tres`

Each trigger `.tres` uses `trigger_value = 2` as default. Each effect `.tres` uses `effect_value` and `growth_rate` per GDD V1 priority set.

## Files Modified

| File | Change |
|------|--------|
| `src/systems/RuleEngine.gd` | Add `_process()` timer, `_check_state_triggers()`, extend `_on_rule_fired()`, add 3 new effect cases in `_execute_effect()` |
| `src/autoloads/GameState.gd` | Add `shield`, `slow_stacks`, `lifesteal_ratio`; update `reset()`; update `take_damage()` for shield absorption |
| `src/systems/CombatSystem.gd` | Apply slow damage reduction; apply lifesteal heal after player attack |
| `src/ui/HUD.gd` | Add shield label, show/hide when shield changes |
| `src/ui/ComponentIcons.gd` | Register 6 new icon mappings |
| `data/components/` | 6 new `.tres` files |

## Excluded Components

- **加速 (Haste):** Tile-based movement means speed has no strategic impact on trigger counts or outcomes.
- **溢出治愈 (Overflow Heal):** Unnecessary complexity; straightforward heal + shield cover the design space.
