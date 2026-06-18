# Numerical Balance Redesign — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rebalance all numerical values in AttributeLoop to achieve 8-12 second normal combat, rule-combination-focused growth, and a 6-phase 30-minute run structure.

**Architecture:** Pure data + formula changes. No new systems, signals, or nodes. Modify `.tres` data files, resource scripts (where defaults change), system code (where formulas are hardcoded), and tests (where assertions reference old values). Delete surplus phase files (phase_7 through phase_10).

**Tech Stack:** Godot 4 / GDScript / GUT test framework

**Spec:** `docs/superpowers/specs/2026-06-18-numerical-balance-design.md`

---

### Task 1: Update GameConfig resource and data

**Files:**
- Modify: `src/resources/GameConfig.gd`
- Modify: `data/game_config.tres`

- [ ] **Step 1: Update GameConfig.gd default values**

Change defaults in `src/resources/GameConfig.gd`:

```gdscript
# Line 5
@export var stat_scale_factor: float = 0.25
# Line 10
@export var deletion_cost_sequence: Array[int] = [15, 35, 70]
# Line 12
@export var verdict_trigger_phase: int = 5
# Line 14
@export var verdict_enemy_phase: int = 6
# Line 15
@export var verdict_spawn_phase: int = 7
# Line 18
@export var combat_enrage_time: float = 10.0
# Line 19 — REMOVE combat_enrage_multiplier, ADD combat_enrage_bonus_per_stack
# Delete: @export var combat_enrage_multiplier: float = 1.5
# Add:    @export var combat_enrage_bonus_per_stack: float = 0.30
# Line 20
@export var combat_enrage_interval: float = 2.0
# Line 21
@export var combat_burn_dmg_per_stack: int = 2
```

Full updated `src/resources/GameConfig.gd`:

```gdscript
class_name GameConfig
extends Resource

# stat = base × (1 + (phase - 1) × stat_scale_factor)
@export var stat_scale_factor: float = 0.25
@export var inventory_cap: int = 12
@export var rule_slot_count_base: int = 2
@export var rule_slot_count_max: int = 5
@export var low_hp_threshold: float = 0.3
@export var deletion_cost_sequence: Array[int] = [15, 35, 70]
@export var deletion_cost_multiplier: float = 2.0
@export var verdict_trigger_phase: int = 5
@export var verdict_survive_loops: int = 5
@export var verdict_enemy_phase: int = 6
@export var verdict_spawn_phase: int = 7
@export var combat_log_max_entries: int = 50
@export var amplify_max_stacks_base: int = 1
@export var combat_enrage_time: float = 10.0
@export var combat_enrage_bonus_per_stack: float = 0.30
@export var combat_enrage_interval: float = 2.0
@export var combat_burn_dmg_per_stack: int = 2
@export var combat_burn_interval: float = 1.0

# --- Auction (梦境残市) ---
@export var auction_service_bar_cap: int = 5
@export var auction_pool_size: int = 3
@export var auction_enemy_pardon_count: int = 3
@export var auction_comp_merge_ratio: float = 0.8
@export var auction_comp_rewrite_delta: float = 0.2
@export var auction_phantom_income_per_phase: Array[int] = [0, 40, 40, 70, 70, 110, 110]
@export var auction_phantom_a_spend_ratio: float = 0.75
@export var auction_phantom_a_token_bid: int = 15
@export var auction_phantom_b_threshold: int = 200
@export var auction_phantom_b_timeout_loops: int = 5
@export var auction_phantom_b_allin_ratio: float = 0.85
@export var auction_dmg_per_purchase: int = 2
@export var auction_hp_per_purchase: int = 15
@export var auction_speed_delta: float = 0.05
@export var auction_amplify_per_purchase: int = 1
@export var auction_service_bar_max_purchases: int = 3
```

- [ ] **Step 2: Update game_config.tres**

Rewrite `data/game_config.tres` to match the new defaults. Key changes:
- `stat_scale_factor` → 0.25
- `deletion_cost_sequence` → [15, 35, 70]
- `verdict_trigger_phase` → 5
- `verdict_enemy_phase` → 6
- `verdict_spawn_phase` → 7
- Remove `combat_enrage_multiplier`, add `combat_enrage_bonus_per_stack = 0.3`
- `combat_enrage_time` → 10.0
- `combat_enrage_interval` → 2.0
- `combat_burn_dmg_per_stack` → 2
- `auction_phantom_income_per_phase` → [0, 40, 40, 70, 70, 110, 110]
- `auction_dmg_per_purchase` → 2
- `auction_service_descriptions` for STAT_DMG → "永久 基础攻击 +2"

- [ ] **Step 3: Commit**

```bash
git add src/resources/GameConfig.gd data/game_config.tres
git commit -m "feat(balance): update GameConfig for 6-phase numerical redesign"
```

---

### Task 2: Update PlayerData

**Files:**
- Modify: `src/resources/PlayerData.gd`
- Modify: `data/player_data.tres`

- [ ] **Step 1: Update PlayerData.gd**

```gdscript
class_name PlayerData
extends Resource

@export var hp_base: int = 200
@export var dmg_base: int = 10
@export var attack_interval: float = 0.8
@export var walk_speed: float = 120.0
```

- [ ] **Step 2: Update player_data.tres**

Set `hp_base = 200`, `dmg_base = 10`. Attack interval and walk speed stay the same.

- [ ] **Step 3: Update GameState.gd hp_max default**

Change line 4 in `src/autoloads/GameState.gd`:
```gdscript
var hp_max: int = 200
```

- [ ] **Step 4: Commit**

```bash
git add src/resources/PlayerData.gd data/player_data.tres src/autoloads/GameState.gd
git commit -m "feat(balance): set player base HP=200, attack=10"
```

---

### Task 3: Update all 5 enemy data files

**Files:**
- Modify: `data/enemies/enemy_汲取者.tres`
- Modify: `data/enemies/enemy_守卫者.tres`
- Modify: `data/enemies/enemy_急袭者.tres`
- Modify: `data/enemies/enemy_复制者.tres`
- Modify: `data/enemies/enemy_先驱者.tres`

- [ ] **Step 1: Update enemy_汲取者.tres**

```
id = "汲取者"
hp_base = 100
dmg_base = 3
gold_min = 8
gold_max = 15
gold_scale = 0.3
attack_interval = 1.0
trigger_weights = {
"受击": 30,
"吸血": 20,
"治愈": 15,
"低血": 15,
"灼烧": 5,
"护盾": 5,
"击杀": 3,
"满血": 3,
"经过": 3,
"完成圈数": 3,
"规则触发": 3,
"反射": 3,
"减伤": 3,
"强化": 3,
"增伤": 3,
"蓄能": 3,
"侵蚀": 3
}
effect_weights = {
"吸血": 30,
"治愈": 25,
"灼烧": 15,
"护盾": 10,
"受击": 5,
"击杀": 3,
"低血": 3,
"满血": 3,
"经过": 3,
"规则触发": 3,
"反射": 3,
"减伤": 3,
"强化": 3,
"增伤": 3,
"蓄能": 3,
"侵蚀": 3
}
phase_drop_presets = { 1: tier_01, 3: tier_02, 5: tier_03 }
```

- [ ] **Step 2: Update enemy_守卫者.tres**

```
hp_base = 150
dmg_base = 2
gold_min = 10
gold_max = 18
gold_scale = 0.3
attack_interval = 1.4
trigger_weights = {
"受击": 25, "护盾": 20, "满血": 15, "治愈": 10, "减伤": 10, "反射": 5,
others: 3 each
}
effect_weights = {
"护盾": 30, "减伤": 25, "治愈": 20, "反射": 10,
others: 3 each
}
phase_drop_presets = { 1: tier_01, 3: tier_02, 5: tier_03 }
```

- [ ] **Step 3: Update enemy_急袭者.tres**

```
hp_base = 60
dmg_base = 5
gold_min = 15
gold_max = 25
gold_scale = 0.3
unlock_phase = 2
attack_interval = 0.7
trigger_weights = {
"击杀": 20, "增伤": 20, "受击": 15, "蓄能": 15, "灼烧": 10, "强化": 5,
others: 3 each
}
effect_weights = {
"增伤": 25, "蓄能": 25, "灼烧": 20, "强化": 10,
others: 3 each
}
phase_drop_presets = { 2: tier_01, 4: tier_02, 5: tier_03 }
```

- [ ] **Step 4: Update enemy_复制者.tres**

```
hp_base = 80
dmg_base = 3
gold_min = 12
gold_max = 20
gold_scale = 0.3
unlock_phase = 3
attack_interval = 0.9
trigger_weights = {
"规则触发": 25, "治愈": 15, "反射": 15, "强化": 15, "灼烧": 10, "侵蚀": 5,
others: 3 each
}
effect_weights = {
"强化": 20, "反射": 20, "治愈": 15, "护盾": 15, "灼烧": 15, "侵蚀": 15,
others: 3 each
}
phase_drop_presets = { 3: tier_01, 4: tier_02, 5: tier_03 }
```

- [ ] **Step 5: Update enemy_先驱者.tres**

```
hp_base = 180
dmg_base = 2
gold_min = 18
gold_max = 30
gold_scale = 0.3
unlock_phase = 4
attack_interval = 1.2
component_pair_min = 2
component_pair_max = 3
trigger_weights = { all 16 BOTH components: ~6 each }
effect_weights = { all 16 BOTH components: ~6 each }
phase_drop_presets = { 4: tier_02, 5: tier_03 }
```

- [ ] **Step 6: Commit**

```bash
git add data/enemies/
git commit -m "feat(balance): update all 5 enemy base stats and rule weights"
```

---

### Task 4: Rewrite drop preset tiers

**Files:**
- Modify: `data/drop_presets/drop_tier_01.tres`
- Modify: `data/drop_presets/drop_tier_02.tres`
- Modify: `data/drop_presets/drop_tier_03.tres`

- [ ] **Step 1: Rewrite drop_tier_01.tres**

All BOTH components need both `trigger` and `effect` ranges. Pure trigger (完成圈数) only has `trigger`.

```
component_ranges = {
"受击": {"trigger": Vector2(4, 6), "effect": Vector2(3, 5)},
"击杀": {"trigger": Vector2(2, 3), "effect": Vector2(5, 8)},
"完成圈数": {"trigger": Vector2(2, 2)},
"经过": {"trigger": Vector2(5, 8), "effect": Vector2(1, 1)},
"低血": {"trigger": Vector2(3, 4), "effect": Vector2(2, 3)},
"满血": {"trigger": Vector2(3, 4), "effect": Vector2(1, 1)},
"规则触发": {"trigger": Vector2(5, 8), "effect": Vector2(1, 1)},
"治愈": {"trigger": Vector2(3, 4), "effect": Vector2(10, 15)},
"反射": {"trigger": Vector2(2, 3), "effect": Vector2(0.15, 0.25)},
"护盾": {"trigger": Vector2(3, 4), "effect": Vector2(12, 20)},
"减伤": {"trigger": Vector2(2, 3), "effect": Vector2(1, 1)},
"吸血": {"trigger": Vector2(3, 4), "effect": Vector2(0.08, 0.15)},
"强化": {"trigger": Vector2(2, 3), "effect": Vector2(1, 1)},
"增伤": {"trigger": Vector2(2, 3), "effect": Vector2(1, 1)},
"蓄能": {"trigger": Vector2(2, 3), "effect": Vector2(1, 1)},
"灼烧": {"trigger": Vector2(2, 3), "effect": Vector2(1, 2)},
"侵蚀": {"trigger": Vector2(2, 3), "effect": Vector2(5, 10)}
}
```

- [ ] **Step 2: Rewrite drop_tier_02.tres**

```
component_ranges = {
"受击": {"trigger": Vector2(3, 5), "effect": Vector2(8, 15)},
"击杀": {"trigger": Vector2(1, 2), "effect": Vector2(12, 18)},
"完成圈数": {"trigger": Vector2(1, 2)},
"经过": {"trigger": Vector2(4, 6), "effect": Vector2(1, 1)},
"低血": {"trigger": Vector2(2, 3), "effect": Vector2(5, 8)},
"满血": {"trigger": Vector2(2, 3), "effect": Vector2(1, 1)},
"规则触发": {"trigger": Vector2(4, 6), "effect": Vector2(1, 1)},
"治愈": {"trigger": Vector2(2, 3), "effect": Vector2(20, 30)},
"反射": {"trigger": Vector2(2, 2), "effect": Vector2(0.30, 0.45)},
"护盾": {"trigger": Vector2(2, 3), "effect": Vector2(25, 40)},
"减伤": {"trigger": Vector2(2, 2), "effect": Vector2(1, 2)},
"吸血": {"trigger": Vector2(2, 3), "effect": Vector2(0.20, 0.30)},
"强化": {"trigger": Vector2(2, 2), "effect": Vector2(1, 1)},
"增伤": {"trigger": Vector2(2, 2), "effect": Vector2(2, 3)},
"蓄能": {"trigger": Vector2(2, 2), "effect": Vector2(1, 2)},
"灼烧": {"trigger": Vector2(2, 2), "effect": Vector2(3, 4)},
"侵蚀": {"trigger": Vector2(2, 2), "effect": Vector2(15, 25)}
}
```

- [ ] **Step 3: Rewrite drop_tier_03.tres**

```
component_ranges = {
"受击": {"trigger": Vector2(2, 4), "effect": Vector2(18, 30)},
"击杀": {"trigger": Vector2(1, 1), "effect": Vector2(22, 35)},
"完成圈数": {"trigger": Vector2(1, 1)},
"经过": {"trigger": Vector2(3, 5), "effect": Vector2(1, 1)},
"低血": {"trigger": Vector2(2, 2), "effect": Vector2(10, 18)},
"满血": {"trigger": Vector2(2, 2), "effect": Vector2(1, 1)},
"规则触发": {"trigger": Vector2(3, 5), "effect": Vector2(1, 1)},
"治愈": {"trigger": Vector2(2, 2), "effect": Vector2(35, 50)},
"反射": {"trigger": Vector2(1, 2), "effect": Vector2(0.50, 0.70)},
"护盾": {"trigger": Vector2(2, 2), "effect": Vector2(45, 65)},
"减伤": {"trigger": Vector2(1, 2), "effect": Vector2(2, 4)},
"吸血": {"trigger": Vector2(2, 2), "effect": Vector2(0.35, 0.50)},
"强化": {"trigger": Vector2(1, 2), "effect": Vector2(1, 1)},
"增伤": {"trigger": Vector2(1, 2), "effect": Vector2(3, 5)},
"蓄能": {"trigger": Vector2(1, 2), "effect": Vector2(2, 3)},
"灼烧": {"trigger": Vector2(1, 2), "effect": Vector2(5, 8)},
"侵蚀": {"trigger": Vector2(1, 2), "effect": Vector2(30, 45)}
}
```

- [ ] **Step 4: Commit**

```bash
git add data/drop_presets/
git commit -m "feat(balance): rewrite drop preset tiers with new value ranges"
```

---

### Task 5: Update component data files

**Files:**
- Modify: all 17 files under `data/components/`

- [ ] **Step 1: Update effect component growth rates**

In each `.tres` file, set `growth_rate` to the new spec values:

| File | growth_rate |
|------|------------|
| `both_治愈.tres` | 0.15 (unchanged) |
| `both_反射.tres` | 0.10 (unchanged) |
| `effect_护盾.tres` | 0.12 (was 0.2) |
| `effect_吸血.tres` | 0.08 (was 0.1) |
| `effect_灼烧.tres` | 0.05 (unchanged) |
| `effect_侵蚀.tres` | 0.10 (unchanged) |
| All others | 0 (unchanged) |

- [ ] **Step 2: Ensure all BOTH components have trigger_value = 0**

The base component template should have `trigger_value = 0` — actual trigger values come from drop presets at runtime. Only `完成圈数` keeps its default `trigger_value` since it has no effect. Check that effect_* components no longer have hardcoded `trigger_value = 2.0` in the .tres files — those values should come from drop presets.

For each `effect_*.tres` file (护盾, 增伤, 灼烧, 侵蚀, 吸血, 减伤, 强化, 蓄能): set `trigger_value = 0.0` in the .tres (the drop preset provides the actual value when spawning).

- [ ] **Step 3: Commit**

```bash
git add data/components/
git commit -m "feat(balance): update component growth rates and clear hardcoded trigger_values"
```

---

### Task 6: Rewrite phase data files (reduce from 11 to 7)

**Files:**
- Modify: `data/phases/phase_1.tres` through `phase_6.tres`
- Create: `data/phases/phase_7.tres` (verdict loop, replaces old phase_11)
- Delete: `data/phases/phase_7.tres` through `phase_11.tres` (old files)

Note: Old phase_7 through phase_11 must be deleted before creating the new phase_7. Process: delete old surplus files first, then write new ones.

- [ ] **Step 1: Rewrite phase_1.tres**

```
phase_id = 1
phase_name = "觉醒"
altar_requirement = 2
world_pressure_window = 8
spawn_count_min = 2
spawn_count_max = 3
spawn_weights = { "汲取者": 50, "守卫者": 50 }
enemy_component_count_min = 1
enemy_component_count_max = 2
```

- [ ] **Step 2: Rewrite phase_2.tres**

```
phase_id = 2
phase_name = "涌动"
altar_requirement = 3
world_pressure_window = 7
spawn_count_min = 2
spawn_count_max = 3
spawn_weights = { "汲取者": 35, "守卫者": 35, "急袭者": 30 }
enemy_component_count_min = 2
enemy_component_count_max = 2
```

- [ ] **Step 3: Rewrite phase_3.tres**

```
phase_id = 3
phase_name = "侵蚀"
altar_requirement = 4
world_pressure_window = 6
spawn_count_min = 3
spawn_count_max = 3
spawn_weights = { "汲取者": 25, "守卫者": 25, "急袭者": 25, "复制者": 25 }
enemy_component_count_min = 2
enemy_component_count_max = 3
```

- [ ] **Step 4: Rewrite phase_4.tres**

```
phase_id = 4
phase_name = "失衡"
altar_requirement = 5
world_pressure_window = 5
spawn_count_min = 3
spawn_count_max = 4
spawn_weights = { "汲取者": 15, "守卫者": 15, "急袭者": 25, "复制者": 25, "先驱者": 20 }
enemy_component_count_min = 3
enemy_component_count_max = 3
```

- [ ] **Step 5: Rewrite phase_5.tres**

```
phase_id = 5
phase_name = "裁决前夜"
altar_requirement = 6
world_pressure_window = 4
spawn_count_min = 3
spawn_count_max = 4
spawn_weights = { "汲取者": 10, "守卫者": 10, "急袭者": 25, "复制者": 30, "先驱者": 25 }
enemy_component_count_min = 3
enemy_component_count_max = 4
```

- [ ] **Step 6: Rewrite phase_6.tres**

```
phase_id = 6
phase_name = "裁决前夜Boss"
altar_requirement = 0
world_pressure_window = 999
spawn_count_min = 3
spawn_count_max = 4
spawn_weights = { "汲取者": 10, "守卫者": 10, "急袭者": 25, "复制者": 30, "先驱者": 25 }
enemy_component_count_min = 4
enemy_component_count_max = 4
```

Note: This phase is used as the stat_phase for verdict enemies. Phase 6 serves as the "verdict enemy stats" phase.

- [ ] **Step 7: Delete old phase_7 through phase_10, rewrite phase_7 as verdict**

Delete files: `data/phases/phase_7.tres`, `phase_8.tres`, `phase_9.tres`, `phase_10.tres`

Then update the existing `data/phases/phase_11.tres` → rename to `phase_7.tres`:

```
phase_id = 7
phase_name = "裁决圈"
altar_requirement = 0
world_pressure_window = 999
spawn_count_min = 5
spawn_count_max = 6
spawn_weights = { "汲取者": 15, "守卫者": 15, "急袭者": 20, "复制者": 25, "先驱者": 25 }
enemy_component_count_min = 4
enemy_component_count_max = 4
```

Delete old `phase_11.tres`.

- [ ] **Step 8: Update DataTables autoload**

Check `src/autoloads/DataTables.gd` — ensure it loads phases 1-7 (not 1-11). If it dynamically loads from folder, no change needed. If it has hardcoded phase references, update them.

- [ ] **Step 9: Commit**

```bash
git add data/phases/ src/autoloads/DataTables.gd
git commit -m "feat(balance): reduce to 6 phases + verdict loop (7 phase files)"
```

---

### Task 7: Implement per-phase tier drop probabilities

**Files:**
- Modify: `src/systems/GameLoop.gd`
- Modify: `src/resources/PhaseData.gd`
- Modify: `data/phases/phase_1.tres` through `phase_7.tres`

The spec defines a probabilistic tier system: each phase has a % chance of dropping Tier 1/2/3 components, rather than a fixed preset per enemy+phase. This replaces the `enemy.phase_drop_presets` approach.

- [ ] **Step 1: Add tier drop probabilities to PhaseData.gd**

Add new exports to `src/resources/PhaseData.gd`:

```gdscript
@export var tier_drop_weights: Array[int] = [85, 12, 3]
```

This array holds weights for [Tier1, Tier2, Tier3]. The GameLoop rolls against these weights to pick which DropPreset to use.

- [ ] **Step 2: Set tier_drop_weights in each phase .tres**

| Phase | tier_drop_weights |
|-------|------------------|
| 1 | [85, 12, 3] |
| 2 | [70, 25, 5] |
| 3 | [40, 50, 10] |
| 4 | [20, 55, 25] |
| 5 | [10, 40, 50] |
| 6 | [5, 30, 65] |
| 7 (verdict) | [5, 30, 65] |

- [ ] **Step 3: Update _assign_components in GameLoop.gd**

Replace `_resolve_drop_preset` with tier probability rolling:

```gdscript
func _assign_components(enemy: Enemy, stat_phase: int = -1) -> void:
    var enemy_data: EnemyData = DataTables.get_enemy(enemy.enemy_id)
    var effective_phase := stat_phase if stat_phase > 0 else GameState.current_phase
    var phase_data: PhaseData = DataTables.get_phase(effective_phase)
    var pairs = randi_range(
        enemy_data.component_pair_min + phase_data.component_count_bonus,
        enemy_data.component_pair_max + phase_data.component_count_bonus
    )
    for i in pairs:
        var preset: DropPreset = _roll_tier_preset(phase_data)
        if preset == null:
            continue
        var t_id = _weighted_pick_with_modifiers(enemy_data.trigger_weights, phase_data)
        var e_id = _weighted_pick_with_modifiers(enemy_data.effect_weights, phase_data)
        enemy.components.append(_create_component(t_id, preset))
        enemy.components.append(_create_component(e_id, preset))

static func _roll_tier_preset(phase_data: PhaseData) -> DropPreset:
    var weights: Array[int] = phase_data.tier_drop_weights
    var total := 0
    for w in weights:
        total += w
    var roll := randi_range(1, total)
    var acc := 0
    var tier_names: Array[String] = ["tier_01", "tier_02", "tier_03"]
    for idx in weights.size():
        acc += weights[idx]
        if roll <= acc:
            return DataTables.get_drop_preset(tier_names[idx])
    return DataTables.get_drop_preset("tier_01")
```

Note: This requires `DataTables` to have a `get_drop_preset(name: String)` method. Check if it exists; if not, add it by loading all presets from `data/drop_presets/` at startup.

- [ ] **Step 4: Clean up — remove phase_drop_presets from enemy .tres files**

Since tier selection is now per-phase (not per-enemy), remove the `phase_drop_presets` dictionary from all 5 enemy `.tres` files. The `EnemyData.gd` export can stay for backwards compatibility but is no longer used.

- [ ] **Step 5: Commit**

```bash
git add src/systems/GameLoop.gd src/resources/PhaseData.gd data/phases/ data/enemies/
git commit -m "feat(balance): implement per-phase tier drop probability system"
```

---

### Task 8: Update CombatSystem — enrage formula

**Files:**
- Modify: `src/systems/CombatSystem.gd`

- [ ] **Step 1: Change enrage from exponential to linear**

In `_apply_enemy_attack` (line 142-143), change:

```gdscript
# OLD (line 142-143):
if _enrage_stacks > 0:
    dmg = int(dmg * pow(DataTables.config.combat_enrage_multiplier, _enrage_stacks))

# NEW:
if _enrage_stacks > 0:
    dmg = int(dmg * (1.0 + _enrage_stacks * DataTables.config.combat_enrage_bonus_per_stack))
```

- [ ] **Step 2: Commit**

```bash
git add src/systems/CombatSystem.gd
git commit -m "feat(balance): change enrage from exponential to linear scaling"
```

---

### Task 9: Update AuctionManager — phantom preferences and STAT_DMG description

**Files:**
- Modify: `src/systems/AuctionManager.gd`

- [ ] **Step 1: Update phantom_a preferences**

In `_ready()` (line 88), change phantom_a preferred types:

```gdscript
# OLD:
phantom_a.init(PhantomBuyer.Personality.AGGRESSIVE, [ServiceType.STAT_DMG, ServiceType.STAT_HP])

# NEW:
phantom_a.init(PhantomBuyer.Personality.AGGRESSIVE, [ServiceType.STAT_DMG, ServiceType.STAT_HP, ServiceType.STAT_SPEED])
```

- [ ] **Step 2: Update phantom_b preferences**

In `_ready()` (line 90), add additional preferences:

```gdscript
# OLD:
phantom_b.init(PhantomBuyer.Personality.PATIENT, [ServiceType.COMP_REWRITE])

# NEW:
phantom_b.init(PhantomBuyer.Personality.PATIENT, [ServiceType.COMP_REWRITE, ServiceType.COMP_MERGE])
```

- [ ] **Step 3: Update STAT_DMG service description**

In `SERVICE_DESCRIPTIONS` (line 37), change:

```gdscript
# OLD:
ServiceType.STAT_DMG: "永久 基础攻击 +1",

# NEW:
ServiceType.STAT_DMG: "永久 基础攻击 +2",
```

And in `SERVICE_SUBTITLES`, update the STAT_DMG subtitle similarly if it references "+1".

- [ ] **Step 4: Update phantom income array clamping**

In `PhantomBuyer.earn()` (line 288), change the clamp to match 7-phase array:

```gdscript
# OLD:
gold += income_table[clampi(phase, 1, 10)]

# NEW:
gold += income_table[clampi(phase, 1, income_table.size() - 1)]
```

- [ ] **Step 5: Commit**

```bash
git add src/systems/AuctionManager.gd
git commit -m "feat(balance): update phantom buyer preferences and STAT_DMG to +2"
```

---

### Task 10: Update tests for new values

**Files:**
- Modify: `tests/unit/test_combat_system.gd`
- Modify: `tests/unit/test_economy_manager.gd`
- Modify: `tests/unit/test_auction_manager.gd`
- Modify: `tests/unit/test_game_loop.gd`

- [ ] **Step 1: Update test_combat_system.gd**

Key changes:
- `test_player_damage_uses_player_dmg_base`: `dmg_base` is now 10 (was 15). The test uses `DataTables.player.dmg_base` so it auto-adjusts ✓
- `test_enrage_multiplier_formula` (line 138-141): Replace with linear test:

```gdscript
func test_enrage_linear_formula() -> void:
    var cfg: GameConfig = DataTables.config
    var base_dmg := 10
    var stacks := 2
    var result := int(base_dmg * (1.0 + stacks * cfg.combat_enrage_bonus_per_stack))
    assert_eq(result, int(base_dmg * 1.6))
```

- `test_lifesteal_heals_after_player_attack` (line 84-91): Uses `DataTables.player.dmg_base` — auto-adjusts ✓
- `test_dmg_boost_increases_player_damage` (line 174-178): Uses `DataTables.player.dmg_base` — auto-adjusts ✓
- `test_charge_release_deals_bonus_damage` (line 180-184): Uses `DataTables.player.dmg_base` — auto-adjusts ✓

- [ ] **Step 2: Update test_economy_manager.gd**

The gold drop test likely uses specific enemy gold values. Since it references `DataTables.get_enemy()`, it should auto-adjust with new .tres values. Verify no hardcoded expected values.

- [ ] **Step 3: Update test_auction_manager.gd**

Key changes:
- Tests referencing `combat_enrage_multiplier` → change to `combat_enrage_bonus_per_stack`
- Tests referencing `auction_dmg_per_purchase = 1` → now 2
- Tests referencing phantom income array indices > 6 → clamp or adjust
- Phantom preference assertions: update if tests check specific preferred_types arrays

- [ ] **Step 4: Update test_game_loop.gd**

- Tests referencing enemy unlock phases (急袭者 was 4, now 2; 复制者 was 7, now 3; 先驱者 was 10, now 4)
- Tests referencing phase spawn counts or component count ranges

- [ ] **Step 5: Run all tests**

```bash
cd "S:/attribute-loop" && powershell -NoProfile -File scripts/self-test.ps1
```

Expected: All tests pass. If any fail, fix and re-run.

- [ ] **Step 6: Commit**

```bash
git add tests/
git commit -m "test(balance): update test assertions for new numerical values"
```

---

### Task 11: Final integration verification

- [ ] **Step 1: Run full test suite**

```bash
cd "S:/attribute-loop" && powershell -NoProfile -File scripts/self-test.ps1
```

All tests must pass.

- [ ] **Step 2: Visual integration test**

If Godot editor is open:
1. Create sentinel file: `tests/.test_mode`
2. Use MCP to play main scene
3. Verify game launches without errors
4. Verify combat engages and resolves
5. Delete `tests/.test_mode`

- [ ] **Step 3: Commit all remaining changes**

```bash
git add -A
git commit -m "feat(balance): complete numerical balance redesign (6-phase, HP=200, linear enrage)"
```
