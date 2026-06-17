# BOTH Components Expansion Design

**Date:** 2026-06-17
**Status:** Approved

---

## Overview

Expand all components to support `BOTH` slot type where meaningful, giving players full freedom to place any component in either T or E slot. Only `完成圈数` remains `TRIGGER_ONLY`.

**Before:** 7 TRIGGER_ONLY, 8 EFFECT_ONLY, 2 BOTH  
**After:** 1 TRIGGER_ONLY, 0 EFFECT_ONLY, 16 BOTH

---

## Component Definitions

### 完成圈数 — TRIGGER_ONLY (unchanged)
- **T:** Every N completed loops

---

### 治愈 — BOTH (unchanged)
- **T:** Every N times a heal effect fires
- **E:** Restore a fixed amount of HP

### 反射 — BOTH (unchanged)
- **T:** Every N times a reflect effect fires
- **E:** Next hit taken is reflected back to attacker at a set ratio

---

### 受击 — TRIGGER_ONLY → BOTH
- **T:** Every N hits taken (existing)
- **E:** Deal true damage to self; does not kill (min 1 HP); counts as a hit event (triggers 受击 T counters)

### 击杀 — TRIGGER_ONLY → BOTH
- **T:** Every N kills (existing)
- **E:** Deal bonus damage to current enemy equal to a set percentage of their current HP

### 经过 — TRIGGER_ONLY → BOTH
- **T:** Every N tiles passed (existing)
- **E:** Immediately fire the current tile's rule one extra time

### 低血 — TRIGGER_ONLY → BOTH
- **T:** While HP < 30%, fires every second (existing)
- **E:** Deal true damage to self; does not kill (min 1 HP)

### 满血 — TRIGGER_ONLY → BOTH
- **T:** While at full HP, fires every second (existing)
- **E:** All current stack types (charge, dmg_boost, amplify) each gain +1 if already > 0

### 规则触发 — TRIGGER_ONLY → BOTH
- **T:** Every N times any other rule fires (existing)
- **E:** All player rule slots gain +1 to their trigger count; does not trigger immediately, only accelerates buildup

---

### 护盾 — EFFECT_ONLY → BOTH
- **T:** Every N times shield absorbs damage
- **E:** Gain a set amount of shield (absorbs damage before HP) (existing)

### 减伤 — EFFECT_ONLY → BOTH
- **T:** Every N times enemy damage is reduced
- **E:** Permanently reduce all enemy damage, stackable, capped at 80% (existing)

### 吸血 — EFFECT_ONLY → BOTH
- **T:** Every N times lifesteal heals
- **E:** Permanently increase lifesteal ratio on each attack, stackable (existing)

### 强化 — EFFECT_ONLY → BOTH
- **T:** Every N times an amplify stack is consumed
- **E:** Gain 1 amplify stack; next rule fired hits at double value then consumes it (existing)

### 增伤 — EFFECT_ONLY → BOTH
- **T:** Every N times an 增伤 hit lands
- **E:** Gain several 增伤 stacks; each boosts next attack damage; decays each loop (existing)

### 蓄能 — EFFECT_ONLY → BOTH
- **T:** Every N times charge releases
- **E:** Accumulate charge stacks; auto-releases as burst damage when full (existing)

### 灼烧 — EFFECT_ONLY → BOTH
- **T:** Every N times a burn tick deals damage
- **E:** Apply burn stacks to current enemy; deals damage per second (existing)

### 侵蚀 — EFFECT_ONLY → BOTH
- **T:** Every N times an erosion tick fires
- **E:** Permanently reduce current enemy's max HP (existing)

---

## New Events Required

The following new EventBus signals or internal tracking counters are needed to support the new T behaviors:

| Component as T | Event needed |
|----------------|-------------|
| 护盾 | Counter incremented each time shield absorbs damage in `GameState.take_damage()` |
| 减伤 | Counter incremented each time slow_stacks reduces incoming damage in `CombatSystem._apply_enemy_attack()` |
| 吸血 | Counter incremented each time lifesteal heal fires in `CombatSystem._apply_player_attack()` |
| 强化 | Counter incremented each time amplify_stacks is consumed in `RuleEngine._execute_effect()` |
| 增伤 | Counter incremented each time 增伤 boosts an attack in `CombatSystem._calc_player_dmg()` |
| 蓄能 | Already fires `rule_fired` with id `蓄能释放` — reuse this signal |
| 灼烧 | Already fires each burn tick in `CombatSystem._process()` — add counter |
| 侵蚀 | Already fires `rule_fired` with id `侵蚀` — reuse this signal |
| 治愈 | Already fires `rule_fired` with id `治愈` — already handled |
| 反射 | Already fires `rule_fired` with id `反射` — already handled |

---

## New E Behaviors to Implement

| Component as E | Implementation site | Notes |
|----------------|-------------------|-------|
| 受击 | `RuleEngine._execute_effect()` | `GameState.take_damage(final_value)`; emit `player_hit` so 受击 T counters fire |
| 击杀 | `RuleEngine._execute_effect()` | `enemy.take_damage(int(enemy.hp * final_value / 100.0))` |
| 经过 | `RuleEngine._execute_effect()` | Call `_evaluate_tile_rules(current_tile)` on whatever tile player is on |
| 低血 | `RuleEngine._execute_effect()` | `GameState.take_damage(final_value)`; do NOT emit `player_hit` |
| 满血 | `RuleEngine._execute_effect()` | `charge_stacks`, `dmg_boost_stacks`, `amplify_stacks` each +1 if > 0 |
| 规则触发 | `RuleEngine._execute_effect()` | Loop all rule slots, each `trigger.trigger_count += 1` (no fire check) |

---

## Data Changes

All 15 currently non-BOTH components need their `.tres` files updated:

- `trigger_受击.tres` → `slot_type = 2`
- `trigger_击杀.tres` → `slot_type = 2`
- `trigger_经过.tres` → `slot_type = 2`
- `trigger_低血.tres` → `slot_type = 2`
- `trigger_满血.tres` → `slot_type = 2`
- `trigger_规则触发.tres` → `slot_type = 2`
- `effect_护盾.tres` → `slot_type = 2`
- `effect_减伤.tres` → `slot_type = 2`
- `effect_吸血.tres` → `slot_type = 2`
- `effect_强化.tres` → `slot_type = 2`
- `effect_增伤.tres` → `slot_type = 2`
- `effect_蓄能.tres` → `slot_type = 2`
- `effect_灼烧.tres` → `slot_type = 2`
- `effect_侵蚀.tres` → `slot_type = 2`

Each BOTH component also needs `trigger_formula = "fires_every"` and `trigger_value` set where currently missing.

---

## Files Changed

| File | Change |
|------|--------|
| `data/components/*.tres` | Update slot_type + add trigger_formula/trigger_value for 15 files |
| `src/systems/RuleEngine.gd` | Add 6 new E cases in `_execute_effect()`; add T evaluation calls for new trigger events |
| `src/systems/CombatSystem.gd` | Add counters/signals for 护盾/减伤/吸血/增伤/灼烧 trigger events |
| `src/autoloads/EventBus.gd` | Add new signals if needed for new trigger events |
| `src/autoloads/GameState.gd` | Expose current tile reference for 经过(E) if not already accessible |
