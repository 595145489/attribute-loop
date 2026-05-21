# Phase 2 Design — 可剥取的规则

**Date:** 2026-05-21
**Status:** Draft
**Playable Goal:** Strip components from enemies, manage 12-slot inventory, equip rule slots (trigger + effect), rules fire and apply effects.

---

## 1. Scope Summary

Phase 2 adds the component system — the core mechanic of AttributeLoop. After defeating an enemy, the player strips individual components, stores them in inventory, and equips them into rule slots. When trigger conditions are met during gameplay, paired effects fire automatically.

### What Phase 2 Includes

- ComponentData resource class with slot_type (T_ONLY / E_ONLY / BOTH)
- 4 triggers: 受击, 击杀, 完成圈数, 经过 (all count-based)
- 2 effects: 治愈 (heal HP), 反射 (reflect damage)
- Enemy component assignment at spawn (pair-based, weighted pools)
- DropPreset system for value ranges (tier-based .tres files)
- Strip panel UI (post-combat, selective take)
- Inventory panel UI (12 slots, Tab/button toggle)
- Rule slot management (click-to-select, click-to-equip)
- RuleEngine node (trigger evaluation + effect execution)
- HUD update (rule slot summary + bag button)
- Free component deletion (no gold cost)

### What Phase 2 Does NOT Include

- Gold economy (earning, spending) — Phase 3
- Tile rule placement, pass_count scaling — Phase 3
- Altar and phase advancement — Phase 3
- Shield, speed, charge effects — Phase 3+
- 低血 (state-based trigger) — deferred
- Enemy types beyond 汲取者 and 守卫者

---

## 2. Component System

### ComponentData Resource

```gdscript
class_name ComponentData extends Resource

enum SlotType { TRIGGER_ONLY, EFFECT_ONLY, BOTH }

@export var id: String
@export var display_name: String
@export var description: String
@export var slot_type: SlotType
@export var trigger_formula: String   # behavior when placed in T sub-slot
@export var effect_formula: String    # behavior when placed in E sub-slot

# Runtime state (not exported, set by drop system / gameplay)
var trigger_value: float = 0.0
var effect_value: float = 0.0
var trigger_count: int = 0            # only used in T sub-slot, counts toward trigger_value
```

### V1 Component Definitions

| id | slot_type | trigger_formula | effect_formula |
|----|-----------|----------------|---------------|
| 受击 | TRIGGER_ONLY | `fires_every(trigger_value)` on player_hit | — |
| 击杀 | TRIGGER_ONLY | `fires_every(trigger_value)` on enemy_killed | — |
| 完成圈数 | TRIGGER_ONLY | `fires_every(trigger_value)` on loop_completed | — |
| 经过 | TRIGGER_ONLY | `fires_every(trigger_value)` on tile_passed | — |
| 治愈 | BOTH | `fires_every(trigger_value)` on heal_event | `heal(effect_value)` → restore HP |
| 护盾 | BOTH | `fires_every(trigger_value)` on shield_absorb | `add_shield(effect_value)` |
| 反射 | BOTH | `fires_every(trigger_value)` on reflect_event | `reflect(effect_value)` |
| 加速 | EFFECT_ONLY | — | `speed_up(effect_value)` |
| 蓄能 | EFFECT_ONLY | — | `charge(effect_value)` |

Phase 2 only implements: 受击, 击杀, 完成圈数, 经过 (trigger logic) and 治愈, 反射 (effect logic). All other components can be stripped, stored, and equipped but their effects are silent no-ops.

Phase 2 only creates .tres files for these 6 components. Remaining V1 components (护盾, 加速, 蓄能) are added in later phases.

### trigger_value vs effect_value

A single component instance carries both values (if slot_type = BOTH). Each value is rolled independently by the drop system. The value used depends on which sub-slot the player places the component in:

- Placed in T sub-slot → uses trigger_value, trigger_formula
- Placed in E sub-slot → uses effect_value, effect_formula

For TRIGGER_ONLY: only trigger_value is populated (effect_value = 0).
For EFFECT_ONLY: only effect_value is populated (trigger_value = 0).

### trigger_count Behavior

- Only active when component is in a T sub-slot AND the rule slot has both T and E filled.
- Increments when the corresponding event fires.
- When trigger_count reaches trigger_value → fires the paired E → resets to 0.
- Moving to inventory: trigger_count is frozen (preserved).
- New drop from enemy: trigger_count = 0.
- UI displays progress: `受击 [1/2]`.

---

## 3. Drop System

### Overview

The drop system determines what components an enemy carries at spawn time. It has three layers:

1. **Quantity** — how many components
2. **Selection** — which component types
3. **Values** — what trigger_value / effect_value each component gets

### 3.1 Quantity

Each enemy generates components in pairs. Each pair = 1 from T pool + 1 from E pool.

```
pairs = randi_range(
    enemy_data.component_pair_min + phase_data.component_count_bonus,
    enemy_data.component_pair_max + phase_data.component_count_bonus
)
```

| Config Source | Field | Example |
|--------------|-------|---------|
| EnemyData | `component_pair_min: int` | 汲取者: 1 |
| EnemyData | `component_pair_max: int` | 汲取者: 2 |
| PhaseData | `component_count_bonus: int` | Phase 1: 0, Phase 5: +2 |

Enemy pair ranges:

| Enemy | Pair Min | Pair Max |
|-------|----------|----------|
| 汲取者 | 1 | 2 |
| 守卫者 | 1 | 2 |
| 急袭者 | 2 | 3 |
| 复制者 | 3 | 4 |
| 先驱者 | 4 | 5 |

### 3.2 Selection

Each pair rolls one component from the T pool and one from the E pool. BOTH-type components appear in both pools.

```gdscript
var trigger_id = _weighted_pick(final_trigger_weights)
var effect_id = _weighted_pick(final_effect_weights)
```

**Base weights** — defined per enemy type in EnemyData:

```gdscript
@export var trigger_weights: Dictionary
# 汲取者: { "受击": 40, "击杀": 30, "治愈": 15, "经过": 15 }

@export var effect_weights: Dictionary
# 汲取者: { "治愈": 100 }
```

BOTH components (e.g., 治愈) appear in both trigger_weights and effect_weights.

Stronger enemies have exclusive access to rarer components — weaker enemies simply don't list those IDs in their weights.

**Phase modifiers** — defined in PhaseData, applied multiplicatively:

```gdscript
@export var component_weight_modifiers: Dictionary
# Phase 1: {}  (empty = no modification)
# Phase 5: { "受击": 0.25, "完成圈数": 2.0 }
```

Final weight = `enemy_data.trigger_weights[id] × phase_data.component_weight_modifiers.get(id, 1.0)`

### 3.3 Values — DropPreset System

Each component's trigger_value and effect_value are rolled from ranges defined in a **DropPreset** resource.

```gdscript
class_name DropPreset extends Resource

@export var preset_name: String
@export var component_ranges: Dictionary
# {
#   "受击": { "trigger": Vector2(2, 3) },
#   "击杀": { "trigger": Vector2(2, 3) },
#   "治愈": { "trigger": Vector2(2, 3), "effect": Vector2(5, 10) },
# }
```

**File structure:**

```
data/drop_presets/
├── drop_tier_01.tres    # weakest drops
├── drop_tier_02.tres
├── drop_tier_03.tres
├── ...
```

**Enemy → Preset mapping** — EnemyData references a DropPreset per phase:

```gdscript
@export var phase_drop_presets: Dictionary  # { int: DropPreset }
# { 1: <drop_tier_01.tres>, 3: <drop_tier_02.tres>, 7: <drop_tier_03.tres> }
```

If current phase has no exact mapping, use the closest lower phase entry. For example, if phase_drop_presets has keys [1, 3, 7] and current phase is 5, use the entry for phase 3.

**Roll logic:**

```gdscript
var preset: DropPreset = enemy_data.phase_drop_presets[current_phase]
var ranges = preset.component_ranges[component_id]

if component.slot_type in [SlotType.TRIGGER_ONLY, SlotType.BOTH]:
    component.trigger_value = randf_range(ranges.trigger.x, ranges.trigger.y)
if component.slot_type in [SlotType.EFFECT_ONLY, SlotType.BOTH]:
    component.effect_value = randf_range(ranges.effect.x, ranges.effect.y)
```

---

## 4. Effect System

The effect system reads trigger_value / effect_value from the component instance and executes the appropriate formula. It has no knowledge of the drop system.

### Trigger Evaluation (RuleEngine)

RuleEngine connects to EventBus signals and evaluates all active rule slots on each event:

| Signal | Triggers Evaluated |
|--------|--------------------|
| player_hit | 受击, 治愈(T) |
| enemy_killed | 击杀 |
| loop_completed | 完成圈数 |
| tile_passed | 经过 |

For count-based triggers (`fires_every`):
1. Increment `component.trigger_count`
2. If `trigger_count >= trigger_value` → fire paired effect → reset trigger_count to 0

A rule slot only evaluates when BOTH T and E sub-slots are filled.

### Effect Execution (Phase 2)

Phase 2 implements two effects:

```gdscript
"heal":
    GameState.hp = min(GameState.hp + int(component.effect_value), GameState.hp_max)
    EventBus.rule_fired.emit(slot_idx, "治愈", component.effect_value)

"reflect":
    GameState.pending_reflect_ratio = component.effect_value
    EventBus.rule_fired.emit(slot_idx, "反射", component.effect_value)
```

Reflect works with CombatSystem: when player takes damage and `pending_reflect_ratio > 0`, the enemy receives `damage × pending_reflect_ratio` back, then the ratio resets to 0.

GameState addition: `var pending_reflect_ratio: float = 0.0`

---

## 5. Scene Structure

```
main.tscn
├── GameLoop (Node)
├── World (Node2D)
│   ├── Track (Path2D)
│   │   └── PlayerFollow (PathFollow2D)
│   │       └── [player.tscn]
│   ├── TilesContainer (Node2D)
│   └── EnemiesContainer (Node2D)
├── Systems (Node)
│   ├── CombatSystem (Node)
│   ├── [rule_engine.tscn]
│   └── [strip_manager.tscn]
└── UI (CanvasLayer)
    ├── [hud.tscn]
    ├── [strip_panel.tscn]
    └── [inventory_panel.tscn]
```

### New Scenes

| Scene | Script | Responsibility |
|-------|--------|---------------|
| rule_engine.tscn | RuleEngine.gd | Connect to EventBus, evaluate triggers, execute effects |
| strip_manager.tscn | StripManager.gd | Listen to enemy_killed, show strip panel, emit combat_resolved when done |
| strip_panel.tscn | StripPanel.gd | Display enemy components in 2-col grid, handle take/skip |
| inventory_panel.tscn | InventoryPanel.gd | Display inventory + rule slots, handle equip/unequip/delete |

---

## 6. GameState Additions

```gdscript
# New fields
var inventory: Array[ComponentData] = []
var rule_slots: Array = []  # Array of { "trigger": ComponentData|null, "effect": ComponentData|null }

# Read from config
var inventory_cap: int       # from GameConfig.inventory_cap (12)
var rule_slot_count: int     # from GameConfig.rule_slot_count_base (2)

# Helpers
func inventory_has_space() -> bool
func add_to_inventory(c: ComponentData) -> void
func remove_from_inventory(c: ComponentData) -> void
func delete_component(c: ComponentData) -> void        # free deletion in Phase 2
func equip(c: ComponentData, slot_idx: int) -> void    # moves from inventory to rule slot sub-slot
func unequip(slot_idx: int, is_trigger: bool) -> void  # moves from rule slot to inventory

func reset() -> void:
    # existing reset + clear inventory, rule_slots, all trigger_counts
```

### Config Additions (GameConfig.tres)

```gdscript
@export var inventory_cap: int = 12
@export var rule_slot_count_base: int = 2
@export var rule_slot_count_max: int = 5
@export var low_hp_threshold: float = 0.3
```

---

## 7. EventBus Additions

```gdscript
# Changed signature
signal enemy_killed(enemy: Enemy)           # was (enemy_id: String)

# New signals
signal player_hit(damage: int)              # emitted by CombatSystem
signal tile_passed(tile_idx: int)           # emitted by Main._check_player_tile()
signal rule_fired(slot_idx: int, effect_id: String, value: float)  # emitted by RuleEngine
```

---

## 8. CombatSystem Changes

```gdscript
func _apply_enemy_attack(enemy: Enemy) -> void:
    var dmg := enemy.dmg
    GameState.take_damage(dmg)
    EventBus.player_hit.emit(dmg)              # NEW

func _finish_combat(enemy: Enemy) -> void:
    stop()
    GameState.enemies_killed += 1
    EventBus.enemy_killed.emit(enemy)          # changed: pass Enemy node, not string
    # EventBus.combat_resolved.emit()          # REMOVED — StripManager now owns this
```

---

## 9. Tile Passed Detection

Extend `Main._check_player_tile()` to detect passing any tile, not just enemy tiles.

### Tile.gd Addition

```gdscript
var visited_this_loop: bool = false
```

### Main.gd Change

```gdscript
func _check_player_tile() -> void:
    var player_pos = player.global_position
    for tile in tiles_container.get_children():
        if player_pos.distance_to(tile.global_position) < 30.0:
            if tile.has_enemy():
                game_loop.check_tile_for_enemy(tile)
                return
            if not tile.visited_this_loop:
                tile.visited_this_loop = true
                EventBus.tile_passed.emit(tile.tile_index)
```

Reset all `visited_this_loop` flags on `loop_completed`.

---

## 10. Enemy Component Assignment

### Enemy.gd Addition

```gdscript
var components: Array[ComponentData] = []
```

### GameLoop.spawn_enemies() Addition

After `enemy.init(enemy_id)`, call `_assign_components(enemy)`:

```gdscript
func _assign_components(enemy: Enemy) -> void:
    var enemy_data = DataTables.get_enemy(enemy.enemy_id)
    var phase_data = DataTables.get_phase(GameState.current_phase)
    var preset = enemy_data.phase_drop_presets.get(GameState.current_phase)

    var pairs = randi_range(
        enemy_data.component_pair_min + phase_data.component_count_bonus,
        enemy_data.component_pair_max + phase_data.component_count_bonus
    )

    for i in pairs:
        var t_id = _weighted_pick_with_modifiers(enemy_data.trigger_weights, phase_data)
        var e_id = _weighted_pick_with_modifiers(enemy_data.effect_weights, phase_data)

        var t_comp = _create_component(t_id, preset)
        var e_comp = _create_component(e_id, preset)

        enemy.components.append(t_comp)
        enemy.components.append(e_comp)

func _create_component(id: String, preset: DropPreset) -> ComponentData:
    var base: ComponentData = DataTables.get_component(id)
    var comp: ComponentData = base.duplicate()
    var ranges = preset.component_ranges.get(id, {})

    if comp.slot_type in [ComponentData.SlotType.TRIGGER_ONLY, ComponentData.SlotType.BOTH]:
        var t_range = ranges.get("trigger", Vector2(1, 1))
        comp.trigger_value = randf_range(t_range.x, t_range.y)
    if comp.slot_type in [ComponentData.SlotType.EFFECT_ONLY, ComponentData.SlotType.BOTH]:
        var e_range = ranges.get("effect", Vector2(0, 0))
        comp.effect_value = randf_range(e_range.x, e_range.y)

    return comp
```

---

## 11. Strip Flow

```
CombatSystem: enemy HP <= 0
  → emit enemy_killed(enemy)
  → StripManager receives signal

StripManager:
  → reads enemy.components
  → if empty → emit combat_resolved immediately
  → if not empty → show StripPanel with components

StripPanel:
  → 2-column grid, each component as a card
  → TRIGGER = orange border, EFFECT = green border, BOTH = blue border
  → Each card shows: type, display_name, trigger_value and/or effect_value
  → "Take" button per card (disabled if inventory full)
  → "[B] Open Bag" button → shows InventoryPanel overlay (delete to free space)
  → "Continue →" button → hide panel

Player clicks "Continue →":
  → StripPanel hides
  → Components NOT taken are discarded (lost permanently)
  → StripManager emits combat_resolved
  → GameLoop receives signal, frees enemy, resumes walking
```

---

## 12. Inventory & Rule Slot Management

### Inventory Panel (Tab / button toggle)

Accessible at any time during walking (pauses game).

**Layout:**
- Rule slots section: 2 slots, each with T sub-slot + E sub-slot
- Inventory grid: 4 columns, up to 12 cells
- Each cell shows: component type indicator, display_name, trigger_value/effect_value

**Operations:**

| Action | Flow |
|--------|------|
| Equip | Click inventory component (selected) → click matching rule sub-slot → component moves |
| Swap | Equip to occupied sub-slot → old component returns to inventory (net neutral) |
| Unequip | Click rule slot component → returns to inventory (requires space) |
| Delete | Click component → delete button → removed permanently (free in Phase 2) |

Type enforcement: TRIGGER_ONLY goes only in T sub-slot, EFFECT_ONLY goes only in E sub-slot, BOTH goes in either.

### Rule Slot Structure

```gdscript
# GameState.rule_slots
[
    { "trigger": ComponentData | null, "effect": ComponentData | null },
    { "trigger": ComponentData | null, "effect": ComponentData | null },
]
```

A rule slot fires only when both trigger and effect are non-null.

---

## 13. HUD Update

### Bottom Bar (always visible)

| Element | Display |
|---------|---------|
| HP | current / max |
| Loops | count |
| Phase | number + name |
| Rule slots | compact summary: "受击→治愈 / 空" |
| Bag button | "Bag [B]" + usage count "3/12" |

### Floating Text

When `rule_fired` signal emits, HUD shows floating text near player: "+10 治愈" (fades after 1s).

---

## 14. Data Files

### New Resource Classes

| Class | File |
|-------|------|
| ComponentData | `src/resources/ComponentData.gd` |
| DropPreset | `src/resources/DropPreset.gd` |

### New Data Files

```
data/
├── components/
│   ├── trigger_受击.tres       # TRIGGER_ONLY
│   ├── trigger_击杀.tres       # TRIGGER_ONLY
│   ├── trigger_完成圈数.tres   # TRIGGER_ONLY
│   ├── trigger_经过.tres       # TRIGGER_ONLY
│   ├── both_治愈.tres          # BOTH — effect implemented
│   └── both_反射.tres          # BOTH — effect implemented
├── drop_presets/
│   ├── drop_tier_01.tres
│   ├── drop_tier_02.tres
│   └── drop_tier_03.tres
└── game_config.tres          # updated with inventory_cap, rule_slot_count_base, etc.
```

### Modified Data Files

- `data/enemies/enemy_汲取者.tres` — add trigger_weights, effect_weights, component_pair_min/max, phase_drop_presets
- `data/enemies/enemy_守卫者.tres` — same
- `data/phases/phase_1.tres` — add component_count_bonus, component_weight_modifiers
- `data/phases/phase_2.tres` — same

---

## 15. Out of Scope for Phase 2

- Gold economy (earning from kills, spending to delete)
- Tile rule placement and pass_count scaling
- Altar and phase advancement mechanics
- World pressure system
- Effect implementations: 护盾, 加速, 蓄能
- Trigger: 低血 (state-based)
- Enemy types: 急袭者, 复制者, 先驱者
- Component growth_rate / scale_exponent (tile-only, Phase 3)
