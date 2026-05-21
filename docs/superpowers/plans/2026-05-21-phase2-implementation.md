# Phase 2 — 可剥取的规则 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add the component strip-and-equip system: enemies carry components, players strip them after combat, store in 12-slot inventory, equip into rule slots where trigger+effect pairs fire automatically.

**Architecture:** Data layer (ComponentData/DropPreset resources) → drop assignment at spawn → signal-driven RuleEngine → StripManager/StripPanel post-combat UI → InventoryPanel management UI → HUD rule display.

**Tech Stack:** Godot 4.x GDScript, GUT unit tests, Godot MCP (`execute_editor_script`) for resource/scene creation.

---

## File Map

| Action | Path | Responsibility |
|--------|------|----------------|
| Create | `src/resources/ComponentData.gd` | Component type definition + SlotType enum |
| Create | `src/resources/DropPreset.gd` | Per-tier value ranges for component rolling |
| Create | `src/systems/RuleEngine.gd` | Trigger evaluation + effect execution |
| Create | `src/systems/StripManager.gd` | Bridge: enemy_killed → strip flow → combat_resolved |
| Create | `src/ui/StripPanel.gd` | Post-combat component selection UI |
| Create | `src/ui/InventoryPanel.gd` | Inventory + rule slot management UI |
| Create | `scenes/systems/rule_engine.tscn` | RuleEngine node |
| Create | `scenes/systems/strip_manager.tscn` | StripManager node |
| Create | `scenes/ui/strip_panel.tscn` | StripPanel scene |
| Create | `scenes/ui/inventory_panel.tscn` | InventoryPanel scene |
| Create | `data/components/trigger_受击.tres` | TRIGGER_ONLY component |
| Create | `data/components/trigger_击杀.tres` | TRIGGER_ONLY component |
| Create | `data/components/trigger_完成圈数.tres` | TRIGGER_ONLY component |
| Create | `data/components/trigger_经过.tres` | TRIGGER_ONLY component |
| Create | `data/components/both_治愈.tres` | BOTH component — effect implemented |
| Create | `data/components/both_反射.tres` | BOTH component — effect implemented |
| Create | `data/drop_presets/drop_tier_01.tres` | Tier 1 value ranges |
| Create | `data/drop_presets/drop_tier_02.tres` | Tier 2 value ranges |
| Create | `data/drop_presets/drop_tier_03.tres` | Tier 3 value ranges |
| Create | `tests/unit/test_component_data.gd` | ComponentData unit tests |
| Create | `tests/unit/test_rule_engine.gd` | RuleEngine unit tests |
| Create | `tests/unit/test_strip_manager.gd` | StripManager unit tests |
| Modify | `src/resources/EnemyData.gd` | Add component spawn fields |
| Modify | `src/resources/PhaseData.gd` | Add component_count_bonus, weight modifiers |
| Modify | `src/resources/GameConfig.gd` | Add inventory_cap, rule_slot_count_base/max |
| Modify | `src/autoloads/GameState.gd` | Add inventory, rule_slots, helpers |
| Modify | `src/autoloads/EventBus.gd` | Add signals; change enemy_killed signature |
| Modify | `src/autoloads/DataTables.gd` | Add component loading + get_component() |
| Modify | `src/entities/Enemy.gd` | Add components array |
| Modify | `src/entities/Tile.gd` | Add visited_this_loop flag |
| Modify | `src/systems/GameLoop.gd` | Add drop assignment; reset tile flags on loop |
| Modify | `src/systems/CombatSystem.gd` | Emit player_hit; change enemy_killed arg; remove combat_resolved |
| Modify | `src/ui/HUD.gd` | Add rule summary, bag button, floating text |
| Modify | `src/Main.gd` | Update tile_passed detection; wire new nodes |
| Modify | `data/enemies/enemy_汲取者.tres` | Add component spawn config |
| Modify | `data/enemies/enemy_守卫者.tres` | Add component spawn config |
| Modify | `data/phases/phase_1.tres` | Add component_count_bonus, weight modifiers |
| Modify | `data/phases/phase_2.tres` | Add component_count_bonus, weight modifiers |
| Modify | `data/game_config.tres` | Add inventory/rule-slot fields |
| Modify | `scenes/main.tscn` | Add Systems node; add new scene instances |
| Modify | `scenes/ui/hud.tscn` | Add rule summary labels + bag button |
| Modify | `tests/unit/test_combat_system.gd` | Update for changed signals |
| Modify | `tests/unit/test_game_state.gd` | Add inventory/rule-slot tests |
| Modify | `tests/unit/test_game_loop.gd` | Add drop-assignment tests |
| Modify | `tests/unit/test_data_tables.gd` | Add component loading tests |

---

## Task 1: ComponentData + DropPreset GDScript Classes

**Files:**
- Create: `src/resources/ComponentData.gd`
- Create: `src/resources/DropPreset.gd`
- Create: `tests/unit/test_component_data.gd`

- [ ] **Step 1: Write the failing tests**

Create `tests/unit/test_component_data.gd`:
```gdscript
extends GutTest

func test_slot_type_enum_values() -> void:
    assert_eq(ComponentData.SlotType.TRIGGER_ONLY, 0)
    assert_eq(ComponentData.SlotType.EFFECT_ONLY, 1)
    assert_eq(ComponentData.SlotType.BOTH, 2)

func test_duplicate_preserves_id_and_values() -> void:
    var c := ComponentData.new()
    c.id = "受击"
    c.slot_type = ComponentData.SlotType.TRIGGER_ONLY
    c.trigger_value = 3.0
    c.trigger_count = 2
    var copy := c.duplicate() as ComponentData
    assert_eq(copy.id, "受击")
    assert_eq(copy.slot_type, ComponentData.SlotType.TRIGGER_ONLY)
    assert_eq(copy.trigger_value, 3.0)
    assert_eq(copy.trigger_count, 2)

func test_new_component_has_zero_counts() -> void:
    var c := ComponentData.new()
    assert_eq(c.trigger_count, 0)
    assert_eq(c.trigger_value, 0.0)
    assert_eq(c.effect_value, 0.0)

func test_drop_preset_ranges_dictionary() -> void:
    var dp := DropPreset.new()
    dp.component_ranges["受击"] = {"trigger": Vector2(2, 3)}
    assert_eq(dp.component_ranges["受击"]["trigger"], Vector2(2, 3))
```

- [ ] **Step 2: Run tests to verify they fail**

```
cd "S:/attribute-loop" && powershell -NoProfile -File scripts/self-test.ps1
```
Expected: errors — `ComponentData` and `DropPreset` not defined.

- [ ] **Step 3: Create ComponentData.gd**

Create `src/resources/ComponentData.gd`:
```gdscript
class_name ComponentData
extends Resource

enum SlotType { TRIGGER_ONLY, EFFECT_ONLY, BOTH }

@export var id: String = ""
@export var display_name: String = ""
@export var description: String = ""
@export var slot_type: SlotType = SlotType.TRIGGER_ONLY
@export var trigger_formula: String = ""
@export var effect_formula: String = ""

var trigger_value: float = 0.0
var effect_value: float = 0.0
var trigger_count: int = 0
```

- [ ] **Step 4: Create DropPreset.gd**

Create `src/resources/DropPreset.gd`:
```gdscript
class_name DropPreset
extends Resource

@export var preset_name: String = ""
@export var component_ranges: Dictionary = {}
# Format: { "component_id": { "trigger": Vector2(min,max), "effect": Vector2(min,max) } }
```

- [ ] **Step 5: Add UID entries to Godot class cache**

Run in Godot editor via MCP `execute_editor_script`:
```gdscript
# This forces Godot to scan and register the new scripts
var fs = EditorInterface.get_resource_filesystem()
fs.scan()
```

- [ ] **Step 6: Run tests — expect pass**

```
cd "S:/attribute-loop" && powershell -NoProfile -File scripts/self-test.ps1
```
Expected: test_component_data tests pass.

- [ ] **Step 7: Commit**

```
git add src/resources/ComponentData.gd src/resources/DropPreset.gd tests/unit/test_component_data.gd
git commit -m "feat: add ComponentData and DropPreset resource classes"
```

---

## Task 2: Data Files — Components + Drop Presets

**Files:**
- Create: `data/components/trigger_受击.tres` (and 5 more)
- Create: `data/drop_presets/drop_tier_01.tres` (and 2 more)
- Modify: `src/autoloads/DataTables.gd`
- Modify: `tests/unit/test_data_tables.gd`

- [ ] **Step 1: Write failing tests for DataTables.get_component()**

Append to `tests/unit/test_data_tables.gd`:
```gdscript
func test_get_component_受击_is_trigger_only() -> void:
    var c: ComponentData = DataTables.get_component("受击")
    assert_eq(c.slot_type, ComponentData.SlotType.TRIGGER_ONLY)

func test_get_component_治愈_is_both() -> void:
    var c: ComponentData = DataTables.get_component("治愈")
    assert_eq(c.slot_type, ComponentData.SlotType.BOTH)

func test_get_component_反射_is_both() -> void:
    var c: ComponentData = DataTables.get_component("反射")
    assert_eq(c.slot_type, ComponentData.SlotType.BOTH)

func test_get_drop_preset_tier1_has_受击_range() -> void:
    var dp: DropPreset = DataTables.get_drop_preset(1)
    assert_true(dp.component_ranges.has("受击"))
    var r = dp.component_ranges["受击"]
    assert_true(r.has("trigger"))
```

- [ ] **Step 2: Run — expect fail** (DataTables.get_component not defined)

- [ ] **Step 3: Create component .tres files via editor script**

Run via MCP `execute_editor_script`:
```gdscript
var component_defs = [
    {"id": "受击", "display_name": "受击", "description": "每被攻击N次触发",
     "slot_type": 0, "trigger_formula": "fires_every", "effect_formula": ""},
    {"id": "击杀", "display_name": "击杀", "description": "每击杀N个敌人触发",
     "slot_type": 0, "trigger_formula": "fires_every", "effect_formula": ""},
    {"id": "完成圈数", "display_name": "完成圈数", "description": "每完成N圈触发",
     "slot_type": 0, "trigger_formula": "fires_every", "effect_formula": ""},
    {"id": "经过", "display_name": "经过", "description": "每经过N个地块触发",
     "slot_type": 0, "trigger_formula": "fires_every", "effect_formula": ""},
    {"id": "治愈", "display_name": "治愈", "description": "触发时恢复生命值",
     "slot_type": 2, "trigger_formula": "fires_every", "effect_formula": "heal"},
    {"id": "反射", "display_name": "反射", "description": "触发时反弹伤害",
     "slot_type": 2, "trigger_formula": "fires_every", "effect_formula": "reflect"},
]

DirAccess.make_dir_recursive_absolute("res://data/components")
for def in component_defs:
    var c = ComponentData.new()
    c.id = def["id"]
    c.display_name = def["display_name"]
    c.description = def["description"]
    c.slot_type = def["slot_type"]
    c.trigger_formula = def["trigger_formula"]
    c.effect_formula = def["effect_formula"]
    var prefix = "trigger_" if def["slot_type"] == 0 else "both_"
    ResourceSaver.save(c, "res://data/components/%s%s.tres" % [prefix, def["id"]])

print("Component .tres files created")
```

- [ ] **Step 4: Create drop preset .tres files via editor script**

Run via MCP `execute_editor_script`:
```gdscript
DirAccess.make_dir_recursive_absolute("res://data/drop_presets")

var tier1 = DropPreset.new()
tier1.preset_name = "tier_01"
tier1.component_ranges = {
    "受击":   {"trigger": Vector2(2, 3)},
    "击杀":   {"trigger": Vector2(2, 3)},
    "完成圈数": {"trigger": Vector2(2, 3)},
    "经过":   {"trigger": Vector2(3, 5)},
    "治愈":   {"trigger": Vector2(2, 3), "effect": Vector2(5, 10)},
    "反射":   {"trigger": Vector2(2, 3), "effect": Vector2(0.2, 0.3)},
}
ResourceSaver.save(tier1, "res://data/drop_presets/drop_tier_01.tres")

var tier2 = DropPreset.new()
tier2.preset_name = "tier_02"
tier2.component_ranges = {
    "受击":   {"trigger": Vector2(2, 2)},
    "击杀":   {"trigger": Vector2(2, 2)},
    "完成圈数": {"trigger": Vector2(1, 2)},
    "经过":   {"trigger": Vector2(2, 4)},
    "治愈":   {"trigger": Vector2(2, 2), "effect": Vector2(10, 18)},
    "反射":   {"trigger": Vector2(2, 2), "effect": Vector2(0.3, 0.45)},
}
ResourceSaver.save(tier2, "res://data/drop_presets/drop_tier_02.tres")

var tier3 = DropPreset.new()
tier3.preset_name = "tier_03"
tier3.component_ranges = {
    "受击":   {"trigger": Vector2(1, 2)},
    "击杀":   {"trigger": Vector2(1, 2)},
    "完成圈数": {"trigger": Vector2(1, 2)},
    "经过":   {"trigger": Vector2(2, 3)},
    "治愈":   {"trigger": Vector2(1, 2), "effect": Vector2(15, 25)},
    "反射":   {"trigger": Vector2(1, 2), "effect": Vector2(0.4, 0.6)},
}
ResourceSaver.save(tier3, "res://data/drop_presets/drop_tier_03.tres")

print("Drop preset .tres files created")
```

- [ ] **Step 5: Update DataTables.gd**

Replace `src/autoloads/DataTables.gd` with:
```gdscript
extends Node

var config: GameConfig
var player: PlayerData
var enemies: Dictionary = {}   # String → EnemyData
var phases: Dictionary = {}    # int → PhaseData
var components: Dictionary = {}  # String → ComponentData
var drop_presets: Dictionary = {} # int → DropPreset  (tier number → preset)

func _ready() -> void:
    config = load("res://data/game_config.tres")
    player = load("res://data/player_data.tres")
    _load_enemies()
    _load_phases()
    _load_components()
    _load_drop_presets()

func _load_enemies() -> void:
    var ids = ["汲取者", "守卫者", "急袭者", "复制者", "先驱者"]
    for id in ids:
        enemies[id] = load("res://data/enemies/enemy_%s.tres" % id)

func _load_phases() -> void:
    for i in range(1, 11):
        phases[i] = load("res://data/phases/phase_%d.tres" % i)

func _load_components() -> void:
    var paths = [
        "res://data/components/trigger_受击.tres",
        "res://data/components/trigger_击杀.tres",
        "res://data/components/trigger_完成圈数.tres",
        "res://data/components/trigger_经过.tres",
        "res://data/components/both_治愈.tres",
        "res://data/components/both_反射.tres",
    ]
    for path in paths:
        var c: ComponentData = load(path)
        components[c.id] = c

func _load_drop_presets() -> void:
    for tier in [1, 2, 3]:
        drop_presets[tier] = load("res://data/drop_presets/drop_tier_%02d.tres" % tier)

func get_enemy(id: String) -> EnemyData:
    return enemies[id]

func get_phase(phase_id: int) -> PhaseData:
    return phases[phase_id]

func get_component(id: String) -> ComponentData:
    return components[id]

func get_drop_preset(tier: int) -> DropPreset:
    return drop_presets[tier]

func calc_stat(base: int, phase: int) -> int:
    return int(base * (1.0 + (phase - 1) * config.stat_scale_factor))
```

- [ ] **Step 6: Run tests — expect pass**

```
cd "S:/attribute-loop" && powershell -NoProfile -File scripts/self-test.ps1
```

- [ ] **Step 7: Commit**

```
git add src/autoloads/DataTables.gd data/components/ data/drop_presets/ tests/unit/test_data_tables.gd
git commit -m "feat: add component + drop preset data files and DataTables loading"
```

---

## Task 3: Extend EnemyData, PhaseData, GameConfig + Update .tres Files

**Files:**
- Modify: `src/resources/EnemyData.gd`
- Modify: `src/resources/PhaseData.gd`
- Modify: `src/resources/GameConfig.gd`
- Modify: `data/enemies/enemy_汲取者.tres`, `enemy_守卫者.tres`
- Modify: `data/phases/phase_1.tres`, `phase_2.tres`
- Modify: `data/game_config.tres`
- Modify: `tests/unit/test_data_tables.gd`

- [ ] **Step 1: Write failing tests**

Append to `tests/unit/test_data_tables.gd`:
```gdscript
func test_enemy_汲取者_has_component_pair_range() -> void:
    var e: EnemyData = DataTables.get_enemy("汲取者")
    assert_gte(e.component_pair_max, e.component_pair_min)
    assert_gte(e.component_pair_min, 1)

func test_enemy_汲取者_has_trigger_weights() -> void:
    var e: EnemyData = DataTables.get_enemy("汲取者")
    assert_false(e.trigger_weights.is_empty())

func test_enemy_汲取者_has_phase_drop_preset() -> void:
    var e: EnemyData = DataTables.get_enemy("汲取者")
    assert_true(e.phase_drop_presets.has(1))

func test_phase1_has_component_count_bonus() -> void:
    var p: PhaseData = DataTables.get_phase(1)
    assert_eq(p.component_count_bonus, 0)

func test_config_has_inventory_cap() -> void:
    assert_eq(DataTables.config.inventory_cap, 12)

func test_config_has_rule_slot_count() -> void:
    assert_eq(DataTables.config.rule_slot_count_base, 2)
```

- [ ] **Step 2: Run — expect fail**

- [ ] **Step 3: Update EnemyData.gd**

Replace `src/resources/EnemyData.gd`:
```gdscript
class_name EnemyData
extends Resource

@export var id: String = ""
@export var hp_base: int = 0
@export var dmg_base: int = 0
@export var gold_min: int = 0
@export var gold_max: int = 0
@export var unlock_phase: int = 1
@export var attack_interval: float = 1.0
@export var component_pair_min: int = 1
@export var component_pair_max: int = 2
## Keys: component id (String), Values: weight (int)
@export var trigger_weights: Dictionary = {}
## Keys: component id (String), Values: weight (int)
@export var effect_weights: Dictionary = {}
## Keys: phase number (int), Values: DropPreset resource
@export var phase_drop_presets: Dictionary = {}
```

- [ ] **Step 4: Update PhaseData.gd**

Replace `src/resources/PhaseData.gd`:
```gdscript
class_name PhaseData
extends Resource

@export var phase_id: int = 1
@export var phase_name: String = ""
@export var altar_requirement: int = 0
@export var world_pressure_window: int = 10
@export var spawn_count_min: int = 1
@export var spawn_count_max: int = 3
@export var spawn_weights: Dictionary = {}
@export var enemy_component_count_min: int = 1
@export var enemy_component_count_max: int = 2
@export var component_count_bonus: int = 0
## Keys: component id (String), Values: weight multiplier (float)
@export var component_weight_modifiers: Dictionary = {}
```

- [ ] **Step 5: Update GameConfig.gd**

Replace `src/resources/GameConfig.gd`:
```gdscript
class_name GameConfig
extends Resource

@export var stat_scale_factor: float = 0.3
@export var inventory_cap: int = 12
@export var rule_slot_count_base: int = 2
@export var rule_slot_count_max: int = 5
@export var low_hp_threshold: float = 0.3
```

- [ ] **Step 6: Update enemy and phase .tres files via editor script**

Run via MCP `execute_editor_script`:
```gdscript
var dp1 = load("res://data/drop_presets/drop_tier_01.tres")
var dp2 = load("res://data/drop_presets/drop_tier_02.tres")

# 汲取者
var jq: EnemyData = load("res://data/enemies/enemy_汲取者.tres")
jq.component_pair_min = 1
jq.component_pair_max = 2
jq.trigger_weights = {"受击": 40, "击杀": 30, "治愈": 15, "经过": 15}
jq.effect_weights = {"治愈": 100}
jq.phase_drop_presets = {1: dp1, 3: dp2}
ResourceSaver.save(jq, "res://data/enemies/enemy_汲取者.tres")

# 守卫者
var sg: EnemyData = load("res://data/enemies/enemy_守卫者.tres")
sg.component_pair_min = 1
sg.component_pair_max = 2
sg.trigger_weights = {"受击": 35, "击杀": 25, "完成圈数": 25, "经过": 15}
sg.effect_weights = {"治愈": 60, "反射": 40}
sg.phase_drop_presets = {1: dp1, 3: dp2}
ResourceSaver.save(sg, "res://data/enemies/enemy_守卫者.tres")

# Phase 1
var p1: PhaseData = load("res://data/phases/phase_1.tres")
p1.component_count_bonus = 0
p1.component_weight_modifiers = {}
ResourceSaver.save(p1, "res://data/phases/phase_1.tres")

# Phase 2
var p2: PhaseData = load("res://data/phases/phase_2.tres")
p2.component_count_bonus = 0
p2.component_weight_modifiers = {}
ResourceSaver.save(p2, "res://data/phases/phase_2.tres")

# GameConfig
var cfg: GameConfig = load("res://data/game_config.tres")
cfg.inventory_cap = 12
cfg.rule_slot_count_base = 2
cfg.rule_slot_count_max = 5
cfg.low_hp_threshold = 0.3
ResourceSaver.save(cfg, "res://data/game_config.tres")

print("Data files updated")
```

- [ ] **Step 7: Run tests — expect pass**

```
cd "S:/attribute-loop" && powershell -NoProfile -File scripts/self-test.ps1
```

- [ ] **Step 8: Commit**

```
git add src/resources/EnemyData.gd src/resources/PhaseData.gd src/resources/GameConfig.gd data/
git commit -m "feat: extend EnemyData/PhaseData/GameConfig with component fields; update data files"
```

---

## Task 4: GameState Additions

**Files:**
- Modify: `src/autoloads/GameState.gd`
- Modify: `tests/unit/test_game_state.gd`

- [ ] **Step 1: Write failing tests**

Append to `tests/unit/test_game_state.gd`:
```gdscript
func test_inventory_empty_after_reset() -> void:
    GameState.add_to_inventory(ComponentData.new())
    GameState.reset()
    assert_eq(GameState.inventory.size(), 0)

func test_inventory_has_space_when_empty() -> void:
    assert_true(GameState.inventory_has_space())

func test_inventory_full_at_cap() -> void:
    for i in DataTables.config.inventory_cap:
        var c = ComponentData.new()
        GameState.add_to_inventory(c)
    assert_false(GameState.inventory_has_space())

func test_add_to_inventory_appends() -> void:
    var c = ComponentData.new()
    c.id = "受击"
    GameState.add_to_inventory(c)
    assert_true(GameState.inventory.has(c))

func test_remove_from_inventory() -> void:
    var c = ComponentData.new()
    GameState.add_to_inventory(c)
    GameState.remove_from_inventory(c)
    assert_false(GameState.inventory.has(c))

func test_delete_component_removes_from_inventory() -> void:
    var c = ComponentData.new()
    GameState.add_to_inventory(c)
    GameState.delete_component(c)
    assert_false(GameState.inventory.has(c))

func test_rule_slots_initialized_after_reset() -> void:
    GameState.reset()
    assert_eq(GameState.rule_slots.size(), 2)

func test_equip_trigger_only_into_trigger_sub_slot() -> void:
    var c = ComponentData.new()
    c.id = "受击"
    c.slot_type = ComponentData.SlotType.TRIGGER_ONLY
    GameState.add_to_inventory(c)
    GameState.equip(c, 0, true)
    assert_eq(GameState.rule_slots[0]["trigger"], c)
    assert_false(GameState.inventory.has(c))

func test_equip_effect_only_into_effect_sub_slot() -> void:
    var c = ComponentData.new()
    c.id = "治愈"
    c.slot_type = ComponentData.SlotType.EFFECT_ONLY
    GameState.add_to_inventory(c)
    GameState.equip(c, 0, false)
    assert_eq(GameState.rule_slots[0]["effect"], c)

func test_equip_both_into_either_sub_slot() -> void:
    var c = ComponentData.new()
    c.slot_type = ComponentData.SlotType.BOTH
    GameState.add_to_inventory(c)
    GameState.equip(c, 0, false)
    assert_eq(GameState.rule_slots[0]["effect"], c)

func test_equip_swaps_when_slot_occupied() -> void:
    var old_c = ComponentData.new()
    old_c.id = "受击"
    old_c.slot_type = ComponentData.SlotType.TRIGGER_ONLY
    GameState.add_to_inventory(old_c)
    GameState.equip(old_c, 0, true)

    var new_c = ComponentData.new()
    new_c.id = "击杀"
    new_c.slot_type = ComponentData.SlotType.TRIGGER_ONLY
    GameState.add_to_inventory(new_c)
    GameState.equip(new_c, 0, true)

    assert_eq(GameState.rule_slots[0]["trigger"], new_c)
    assert_true(GameState.inventory.has(old_c))

func test_unequip_moves_to_inventory() -> void:
    var c = ComponentData.new()
    c.slot_type = ComponentData.SlotType.TRIGGER_ONLY
    GameState.add_to_inventory(c)
    GameState.equip(c, 0, true)
    GameState.unequip(0, true)
    assert_eq(GameState.rule_slots[0]["trigger"], null)
    assert_true(GameState.inventory.has(c))

func test_pending_reflect_ratio_zero_after_reset() -> void:
    GameState.pending_reflect_ratio = 0.5
    GameState.reset()
    assert_eq(GameState.pending_reflect_ratio, 0.0)
```

- [ ] **Step 2: Run — expect fail**

- [ ] **Step 3: Rewrite GameState.gd**

Replace `src/autoloads/GameState.gd`:
```gdscript
extends Node

var hp: int
var hp_max: int = 100
var loops_completed: int = 0
var enemies_killed: int = 0
var current_phase: int = 1
var is_paused: bool = false
var pending_reflect_ratio: float = 0.0
var inventory: Array[ComponentData] = []
var rule_slots: Array = []  # Array of {"trigger": ComponentData|null, "effect": ComponentData|null}

func _ready() -> void:
    reset()

func take_damage(amount: int) -> void:
    hp = max(0, hp - amount)
    if hp == 0:
        EventBus.player_died.emit()

func reset() -> void:
    hp = hp_max
    loops_completed = 0
    enemies_killed = 0
    current_phase = 1
    is_paused = false
    pending_reflect_ratio = 0.0
    inventory = []
    rule_slots = []
    for i in 2:
        rule_slots.append({"trigger": null, "effect": null})
    # Clear trigger_count on all rule slot components (none exist at reset, so this is a no-op at start)

func inventory_has_space() -> bool:
    return inventory.size() < DataTables.config.inventory_cap

func add_to_inventory(c: ComponentData) -> void:
    inventory.append(c)

func remove_from_inventory(c: ComponentData) -> void:
    inventory.erase(c)

func delete_component(c: ComponentData) -> void:
    inventory.erase(c)

func equip(c: ComponentData, slot_idx: int, as_trigger: bool) -> void:
    var slot = rule_slots[slot_idx]
    var sub_key = "trigger" if as_trigger else "effect"
    var displaced = slot[sub_key]
    if displaced != null:
        inventory.append(displaced)
    slot[sub_key] = c
    inventory.erase(c)

func unequip(slot_idx: int, as_trigger: bool) -> void:
    var slot = rule_slots[slot_idx]
    var sub_key = "trigger" if as_trigger else "effect"
    var c = slot[sub_key]
    if c != null:
        slot[sub_key] = null
        inventory.append(c)
```

- [ ] **Step 4: Run tests — expect pass**

```
cd "S:/attribute-loop" && powershell -NoProfile -File scripts/self-test.ps1
```

- [ ] **Step 5: Commit**

```
git add src/autoloads/GameState.gd tests/unit/test_game_state.gd
git commit -m "feat: add inventory, rule_slots, and component management to GameState"
```

---

## Task 5: EventBus New Signals + Update Affected Tests

**Files:**
- Modify: `src/autoloads/EventBus.gd`
- Modify: `tests/unit/test_combat_system.gd`

- [ ] **Step 1: Replace EventBus.gd**

Replace `src/autoloads/EventBus.gd`:
```gdscript
extends Node

signal enemy_killed(enemy: Enemy)        # changed: was (enemy_id: String)
signal combat_resolved
signal loop_completed
signal player_died
signal player_hit(damage: int)           # new
signal tile_passed(tile_idx: int)        # new
signal rule_fired(slot_idx: int, effect_id: String, value: float)  # new
```

- [ ] **Step 2: Update test_combat_system.gd**

The existing `test_combat_resolved_emitted_when_enemy_dies` test assumes CombatSystem emits `combat_resolved`. After Task 7, CombatSystem will no longer do this. For now, update the test to avoid the breaking change during this task; Task 7 will fully revise it.

Replace the test in `tests/unit/test_combat_system.gd`:
```gdscript
# OLD test (remove):
# func test_combat_resolved_emitted_when_enemy_dies() -> void:
#     watch_signals(EventBus)
#     var enemy = Enemy.new()
#     enemy.init("汲取者")
#     enemy.hp = 1
#     combat._apply_player_attack(enemy)
#     assert_signal_emitted(EventBus, "combat_resolved")

# NEW — CombatSystem emits enemy_killed when enemy dies (combat_resolved moves to StripManager in Task 7)
func test_enemy_killed_still_emitted_on_death() -> void:
    watch_signals(EventBus)
    var enemy = Enemy.new()
    enemy.init("汲取者")
    enemy.hp = 1
    combat._apply_player_attack(enemy)
    # CombatSystem still emits enemy_killed (and currently also combat_resolved until Task 7)
    assert_signal_emitted(EventBus, "enemy_killed")
```

- [ ] **Step 3: Run tests — expect pass**

```
cd "S:/attribute-loop" && powershell -NoProfile -File scripts/self-test.ps1
```

- [ ] **Step 4: Commit**

```
git add src/autoloads/EventBus.gd tests/unit/test_combat_system.gd
git commit -m "feat: add player_hit, tile_passed, rule_fired signals; change enemy_killed to pass Enemy node"
```

---

## Task 6: Enemy.gd + GameLoop Drop Assignment

**Files:**
- Modify: `src/entities/Enemy.gd`
- Modify: `src/systems/GameLoop.gd`
- Modify: `tests/unit/test_game_loop.gd`

- [ ] **Step 1: Write failing tests**

Append to `tests/unit/test_game_loop.gd`:
```gdscript
func test_weighted_pick_with_modifiers_returns_valid_id() -> void:
    var weights = {"受击": 50, "击杀": 50}
    var phase_data: PhaseData = DataTables.get_phase(1)
    var result = GameLoop._weighted_pick_with_modifiers(weights, phase_data)
    assert_true(result == "受击" or result == "击杀")

func test_weighted_pick_with_modifiers_respects_zero_weight() -> void:
    var weights = {"受击": 100, "击杀": 0}
    var phase_data: PhaseData = DataTables.get_phase(1)
    for i in 20:
        var result = GameLoop._weighted_pick_with_modifiers(weights, phase_data)
        assert_eq(result, "受击")

func test_create_component_trigger_only_sets_trigger_value() -> void:
    var preset: DropPreset = DataTables.get_drop_preset(1)
    var comp = GameLoop._create_component("受击", preset)
    assert_gt(comp.trigger_value, 0.0)
    assert_eq(comp.effect_value, 0.0)

func test_create_component_both_sets_both_values() -> void:
    var preset: DropPreset = DataTables.get_drop_preset(1)
    var comp = GameLoop._create_component("治愈", preset)
    assert_gt(comp.trigger_value, 0.0)
    assert_gt(comp.effect_value, 0.0)

func test_create_component_returns_duplicate_not_original() -> void:
    var preset: DropPreset = DataTables.get_drop_preset(1)
    var original: ComponentData = DataTables.get_component("受击")
    var comp = GameLoop._create_component("受击", preset)
    assert_ne(comp, original)
    assert_eq(comp.id, "受击")
```

- [ ] **Step 2: Run — expect fail**

- [ ] **Step 3: Add components array to Enemy.gd**

Replace `src/entities/Enemy.gd`:
```gdscript
class_name Enemy
extends Node2D

var enemy_id: String = ""
var hp: int = 0
var hp_max: int = 0
var dmg: int = 0
var attack_interval: float = 1.0
var components: Array[ComponentData] = []

@onready var _hp_label: Label = $HPLabel

func init(id: String) -> void:
    enemy_id = id
    var data: EnemyData = DataTables.get_enemy(id)
    var phase = GameState.current_phase
    hp_max = DataTables.calc_stat(data.hp_base, phase)
    hp = hp_max
    dmg = DataTables.calc_stat(data.dmg_base, phase)
    attack_interval = data.attack_interval
    components = []
    _refresh_label()

func take_damage(amount: int) -> void:
    hp = max(0, hp - amount)
    _refresh_label()

func is_dead() -> bool:
    return hp <= 0

func _refresh_label() -> void:
    if _hp_label:
        _hp_label.text = "%d/%d" % [hp, hp_max]
```

- [ ] **Step 4: Add drop assignment to GameLoop.gd**

Replace `src/systems/GameLoop.gd`:
```gdscript
class_name GameLoop
extends Node

enum State { WALKING, COMBAT, GAME_OVER }

var state: State = State.WALKING
var _tiles: Array = []
var _enemies_container: Node
var _player: Player
var _combat_system: CombatSystem
var _enemy_scene: PackedScene = preload("res://scenes/entities/enemy.tscn")
var _combat_tile: Tile = null

func setup(tiles: Array, enemies_container: Node, player: Player, combat: CombatSystem) -> void:
    _tiles = tiles
    _enemies_container = enemies_container
    _player = player
    _combat_system = combat
    EventBus.loop_completed.connect(_on_loop_completed)
    EventBus.combat_resolved.connect(_on_combat_resolved)
    EventBus.player_died.connect(_on_player_died)
    spawn_enemies()

func spawn_enemies() -> void:
    for child in _enemies_container.get_children():
        child.queue_free()
    for tile in _tiles:
        tile.clear_enemy()

    var phase_data: PhaseData = DataTables.get_phase(GameState.current_phase)
    var count = _roll_spawn_count(phase_data)
    var indices = _pick_tile_indices(count, _tiles.size())

    for idx in indices:
        var enemy_id = _pick_enemy_id(phase_data, GameState.current_phase)
        var enemy: Enemy = _enemy_scene.instantiate()
        _enemies_container.add_child(enemy)
        enemy.init(enemy_id)
        enemy.position = _tiles[idx].position
        _tiles[idx].place_enemy(enemy)
        _assign_components(enemy)

func check_tile_for_enemy(tile: Tile) -> void:
    if state != State.WALKING:
        return
    if not tile.has_enemy():
        return
    state = State.COMBAT
    GameState.is_paused = true
    _combat_tile = tile
    _combat_system.start(tile.enemy)

func _on_loop_completed() -> void:
    if state == State.WALKING:
        for tile in _tiles:
            tile.visited_this_loop = false
        spawn_enemies()

func _on_combat_resolved() -> void:
    if state == State.GAME_OVER:
        return
    if _combat_tile != null:
        if _combat_tile.enemy != null:
            _combat_tile.enemy.queue_free()
        _combat_tile.clear_enemy()
        _combat_tile = null
    state = State.WALKING
    GameState.is_paused = false

func _on_player_died() -> void:
    state = State.GAME_OVER
    _combat_system.stop()
    GameState.is_paused = true

func _assign_components(enemy: Enemy) -> void:
    var enemy_data: EnemyData = DataTables.get_enemy(enemy.enemy_id)
    var phase_data: PhaseData = DataTables.get_phase(GameState.current_phase)
    var preset: DropPreset = _resolve_drop_preset(enemy_data, GameState.current_phase)
    if preset == null:
        return

    var pairs = randi_range(
        enemy_data.component_pair_min + phase_data.component_count_bonus,
        enemy_data.component_pair_max + phase_data.component_count_bonus
    )
    for i in pairs:
        var t_id = _weighted_pick_with_modifiers(enemy_data.trigger_weights, phase_data)
        var e_id = _weighted_pick_with_modifiers(enemy_data.effect_weights, phase_data)
        enemy.components.append(_create_component(t_id, preset))
        enemy.components.append(_create_component(e_id, preset))

static func _resolve_drop_preset(enemy_data: EnemyData, current_phase: int) -> DropPreset:
    if enemy_data.phase_drop_presets.is_empty():
        return null
    var best_key = -1
    for key in enemy_data.phase_drop_presets:
        if key <= current_phase and key > best_key:
            best_key = key
    if best_key == -1:
        return null
    return enemy_data.phase_drop_presets[best_key]

static func _weighted_pick_with_modifiers(weights: Dictionary, phase_data: PhaseData) -> String:
    var final_weights: Dictionary = {}
    var total: float = 0.0
    for id in weights:
        var w = weights[id] * phase_data.component_weight_modifiers.get(id, 1.0)
        final_weights[id] = w
        total += w
    var roll = randf() * total
    var acc: float = 0.0
    for id in final_weights:
        acc += final_weights[id]
        if roll <= acc:
            return id
    return final_weights.keys()[0]

static func _create_component(id: String, preset: DropPreset) -> ComponentData:
    var base: ComponentData = DataTables.get_component(id)
    var comp: ComponentData = base.duplicate()
    comp.trigger_count = 0
    var ranges = preset.component_ranges.get(id, {})
    if comp.slot_type in [ComponentData.SlotType.TRIGGER_ONLY, ComponentData.SlotType.BOTH]:
        var t_range: Vector2 = ranges.get("trigger", Vector2(1, 1))
        comp.trigger_value = randf_range(t_range.x, t_range.y)
    if comp.slot_type in [ComponentData.SlotType.EFFECT_ONLY, ComponentData.SlotType.BOTH]:
        var e_range: Vector2 = ranges.get("effect", Vector2(0, 0))
        comp.effect_value = randf_range(e_range.x, e_range.y)
    return comp

## Pure functions used by tests

static func _roll_spawn_count(phase: PhaseData) -> int:
    return randi_range(phase.spawn_count_min, phase.spawn_count_max)

static func _pick_enemy_id(phase: PhaseData, current_phase: int) -> String:
    var eligible: Dictionary = {}
    for id in phase.spawn_weights:
        var data: EnemyData = DataTables.get_enemy(id)
        if data.unlock_phase <= current_phase:
            eligible[id] = phase.spawn_weights[id]
    var total = 0
    for w in eligible.values():
        total += w
    var roll = randi_range(1, total)
    var acc = 0
    for id in eligible:
        acc += eligible[id]
        if roll <= acc:
            return id
    return eligible.keys()[0]

static func _pick_tile_indices(count: int, total: int) -> Array:
    var pool = range(total)
    pool.shuffle()
    return pool.slice(0, count)
```

- [ ] **Step 5: Run tests — expect pass**

```
cd "S:/attribute-loop" && powershell -NoProfile -File scripts/self-test.ps1
```

- [ ] **Step 6: Commit**

```
git add src/entities/Enemy.gd src/systems/GameLoop.gd tests/unit/test_game_loop.gd
git commit -m "feat: add components array to Enemy; add drop assignment to GameLoop"
```

---

## Task 7: CombatSystem Changes

**Files:**
- Modify: `src/systems/CombatSystem.gd`
- Modify: `tests/unit/test_combat_system.gd`

- [ ] **Step 1: Write new tests**

Replace the full `tests/unit/test_combat_system.gd`:
```gdscript
extends GutTest

var combat: CombatSystem

func before_each() -> void:
    GameState.reset()
    combat = CombatSystem.new()
    add_child_autofree(combat)

func test_player_damage_reduces_enemy_hp() -> void:
    var enemy = Enemy.new()
    enemy.init("汲取者")
    var hp_before = enemy.hp
    combat._apply_player_attack(enemy)
    assert_lt(enemy.hp, hp_before)

func test_enemy_damage_reduces_player_hp() -> void:
    var enemy = Enemy.new()
    enemy.init("汲取者")
    var hp_before = GameState.hp
    combat._apply_enemy_attack(enemy)
    assert_lt(GameState.hp, hp_before)

func test_player_damage_uses_player_dmg_base() -> void:
    var enemy = Enemy.new()
    enemy.init("汲取者")
    var hp_before = enemy.hp
    combat._apply_player_attack(enemy)
    assert_eq(enemy.hp, hp_before - DataTables.player.dmg_base)

func test_enemy_damage_uses_phase_scaled_dmg() -> void:
    var enemy = Enemy.new()
    enemy.init("汲取者")
    var expected_dmg = DataTables.calc_stat(DataTables.get_enemy("汲取者").dmg_base, 1)
    assert_eq(enemy.dmg, expected_dmg)

func test_player_hit_emitted_on_enemy_attack() -> void:
    watch_signals(EventBus)
    var enemy = Enemy.new()
    enemy.init("汲取者")
    combat._apply_enemy_attack(enemy)
    assert_signal_emitted(EventBus, "player_hit")

func test_enemy_killed_emitted_when_enemy_dies() -> void:
    watch_signals(EventBus)
    var enemy = Enemy.new()
    enemy.init("汲取者")
    enemy.hp = 1
    combat._apply_player_attack(enemy)
    assert_signal_emitted(EventBus, "enemy_killed")

func test_combat_resolved_not_emitted_by_combat_system() -> void:
    watch_signals(EventBus)
    var enemy = Enemy.new()
    enemy.init("汲取者")
    enemy.hp = 1
    combat._apply_player_attack(enemy)
    assert_signal_not_emitted(EventBus, "combat_resolved")

func test_reflect_damage_applied_when_pending_ratio_set() -> void:
    GameState.pending_reflect_ratio = 0.5
    var enemy = Enemy.new()
    enemy.init("汲取者")
    var enemy_hp_before = enemy.hp
    combat._apply_enemy_attack(enemy)
    assert_lt(enemy.hp, enemy_hp_before)
    assert_eq(GameState.pending_reflect_ratio, 0.0)
```

- [ ] **Step 2: Run — expect some failures** (reflect and combat_resolved tests not yet correct)

- [ ] **Step 3: Rewrite CombatSystem.gd**

Replace `src/systems/CombatSystem.gd`:
```gdscript
class_name CombatSystem
extends Node

var _player_timer: Timer
var _enemy_timer: Timer
var _active_enemy: Enemy = null

func _ready() -> void:
    _player_timer = Timer.new()
    _player_timer.one_shot = false
    _player_timer.timeout.connect(_on_player_attack)
    add_child(_player_timer)

    _enemy_timer = Timer.new()
    _enemy_timer.one_shot = false
    _enemy_timer.timeout.connect(_on_enemy_attack)
    add_child(_enemy_timer)

func start(enemy: Enemy) -> void:
    _active_enemy = enemy
    _player_timer.wait_time = DataTables.player.attack_interval
    _enemy_timer.wait_time = enemy.attack_interval
    _player_timer.start()
    _enemy_timer.start()

func stop() -> void:
    _player_timer.stop()
    _enemy_timer.stop()
    _active_enemy = null

func _on_player_attack() -> void:
    if _active_enemy == null:
        return
    _apply_player_attack(_active_enemy)

func _on_enemy_attack() -> void:
    if _active_enemy == null:
        return
    _apply_enemy_attack(_active_enemy)

func _apply_player_attack(enemy: Enemy) -> void:
    enemy.take_damage(DataTables.player.dmg_base)
    if enemy.is_dead():
        _finish_combat(enemy)

func _apply_enemy_attack(enemy: Enemy) -> void:
    var dmg := enemy.dmg
    GameState.take_damage(dmg)
    EventBus.player_hit.emit(dmg)
    if GameState.pending_reflect_ratio > 0.0:
        enemy.take_damage(int(dmg * GameState.pending_reflect_ratio))
        GameState.pending_reflect_ratio = 0.0

func _finish_combat(enemy: Enemy = null) -> void:
    var resolved := enemy if enemy != null else _active_enemy
    if resolved == null:
        return
    stop()
    GameState.enemies_killed += 1
    EventBus.enemy_killed.emit(resolved)
    # combat_resolved is now emitted by StripManager after strip flow completes
```

- [ ] **Step 4: Run tests — expect pass**

```
cd "S:/attribute-loop" && powershell -NoProfile -File scripts/self-test.ps1
```

- [ ] **Step 5: Commit**

```
git add src/systems/CombatSystem.gd tests/unit/test_combat_system.gd
git commit -m "feat: CombatSystem emits player_hit; passes Enemy node to enemy_killed; StripManager now owns combat_resolved"
```

---

## Task 8: Tile.gd + tile_passed Detection in Main.gd

**Files:**
- Modify: `src/entities/Tile.gd`
- Modify: `src/Main.gd`

- [ ] **Step 1: Update Tile.gd**

Replace `src/entities/Tile.gd`:
```gdscript
class_name Tile
extends Node2D

var tile_index: int = 0
var enemy: Enemy = null
var visited_this_loop: bool = false

func has_enemy() -> bool:
    return enemy != null

func place_enemy(e: Enemy) -> void:
    enemy = e

func clear_enemy() -> void:
    enemy = null
```

- [ ] **Step 2: Update Main.gd**

Replace `src/Main.gd`:
```gdscript
extends Node2D

const TILE_SCENE = preload("res://scenes/entities/tile.tscn")
const GAME_OVER_SCENE = preload("res://scenes/ui/game_over.tscn")

@onready var track: Path2D = $Track
@onready var player_follow: PathFollow2D = $Track/PlayerFollow
@onready var player: Player = $Track/PlayerFollow/Player
@onready var tiles_container: Node2D = $TilesContainer
@onready var enemies_container: Node2D = $EnemiesContainer
@onready var combat_system: CombatSystem = $Systems/CombatSystem
@onready var game_loop: GameLoop = $Systems/GameLoop

func _ready() -> void:
    var tiles = _build_tiles()
    player.setup(player_follow, track)
    game_loop.setup(tiles, enemies_container, player, combat_system)
    EventBus.player_died.connect(_on_player_died)

func _build_tiles() -> Array:
    var tiles: Array = []
    var curve = track.curve
    var length = curve.get_baked_length()
    for i in 12:
        var t = float(i) / 12.0
        var pos = curve.sample_baked(t * length)
        var tile: Tile = TILE_SCENE.instantiate()
        tile.position = pos
        tile.tile_index = i
        tiles_container.add_child(tile)
        tiles.append(tile)
    return tiles

func _process(_delta: float) -> void:
    if GameState.is_paused:
        return
    _check_player_tile()

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
            return

func _on_player_died() -> void:
    var go = GAME_OVER_SCENE.instantiate()
    add_child(go)
```

Note: `combat_system` and `game_loop` paths changed to `$Systems/CombatSystem` and `$Systems/GameLoop` — the main.tscn restructure happens in Task 12. For now, keep the old paths `$CombatSystem` and `$GameLoop` to avoid breaking the current scene:

Actually, keep old @onready paths until Task 12 updates main.tscn. Use:
```gdscript
@onready var combat_system: CombatSystem = $CombatSystem
@onready var game_loop: GameLoop = $GameLoop
```

- [ ] **Step 3: Run tests — expect pass**

```
cd "S:/attribute-loop" && powershell -NoProfile -File scripts/self-test.ps1
```

- [ ] **Step 4: Commit**

```
git add src/entities/Tile.gd src/Main.gd
git commit -m "feat: add visited_this_loop to Tile; emit tile_passed signal in Main"
```

---

## Task 9: RuleEngine

**Files:**
- Create: `src/systems/RuleEngine.gd`
- Create: `scenes/systems/rule_engine.tscn`
- Create: `tests/unit/test_rule_engine.gd`

- [ ] **Step 1: Write failing tests**

Create `tests/unit/test_rule_engine.gd`:
```gdscript
extends GutTest

var engine: RuleEngine

func before_each() -> void:
    GameState.reset()
    engine = RuleEngine.new()
    add_child_autofree(engine)

func _make_rule(trigger_id: String, trigger_value: float, effect_id: String, effect_value: float) -> void:
    var t = ComponentData.new()
    t.id = trigger_id
    t.slot_type = ComponentData.SlotType.TRIGGER_ONLY
    t.trigger_value = trigger_value
    t.trigger_count = 0

    var e = ComponentData.new()
    e.id = effect_id
    e.slot_type = ComponentData.SlotType.EFFECT_ONLY
    e.effect_value = effect_value

    GameState.rule_slots[0]["trigger"] = t
    GameState.rule_slots[0]["effect"] = e

func test_trigger_count_increments_on_player_hit() -> void:
    _make_rule("受击", 3.0, "治愈", 10.0)
    var t = GameState.rule_slots[0]["trigger"]
    EventBus.player_hit.emit(5)
    assert_eq(t.trigger_count, 1)

func test_trigger_count_increments_on_enemy_killed() -> void:
    _make_rule("击杀", 2.0, "治愈", 10.0)
    var t = GameState.rule_slots[0]["trigger"]
    var dummy_enemy = Enemy.new()
    dummy_enemy.init("汲取者")
    EventBus.enemy_killed.emit(dummy_enemy)
    assert_eq(t.trigger_count, 1)

func test_trigger_count_increments_on_loop_completed() -> void:
    _make_rule("完成圈数", 2.0, "治愈", 10.0)
    var t = GameState.rule_slots[0]["trigger"]
    EventBus.loop_completed.emit()
    assert_eq(t.trigger_count, 1)

func test_trigger_count_increments_on_tile_passed() -> void:
    _make_rule("经过", 3.0, "治愈", 10.0)
    var t = GameState.rule_slots[0]["trigger"]
    EventBus.tile_passed.emit(0)
    assert_eq(t.trigger_count, 1)

func test_heal_fires_when_threshold_reached() -> void:
    _make_rule("受击", 1.0, "治愈", 15.0)
    GameState.hp = 50
    EventBus.player_hit.emit(5)
    assert_eq(GameState.hp, 65)

func test_heal_resets_trigger_count() -> void:
    _make_rule("受击", 1.0, "治愈", 10.0)
    var t = GameState.rule_slots[0]["trigger"]
    EventBus.player_hit.emit(5)
    assert_eq(t.trigger_count, 0)

func test_heal_capped_at_hp_max() -> void:
    _make_rule("受击", 1.0, "治愈", 999.0)
    GameState.hp = 90
    EventBus.player_hit.emit(5)
    assert_eq(GameState.hp, GameState.hp_max)

func test_reflect_sets_pending_ratio() -> void:
    _make_rule("受击", 1.0, "反射", 0.5)
    EventBus.player_hit.emit(5)
    assert_eq(GameState.pending_reflect_ratio, 0.5)

func test_rule_fired_signal_emitted_on_effect() -> void:
    watch_signals(EventBus)
    _make_rule("受击", 1.0, "治愈", 10.0)
    GameState.hp = 50
    EventBus.player_hit.emit(5)
    assert_signal_emitted(EventBus, "rule_fired")

func test_no_fire_when_trigger_slot_empty() -> void:
    var e = ComponentData.new()
    e.id = "治愈"
    e.effect_value = 10.0
    GameState.rule_slots[0]["effect"] = e
    GameState.rule_slots[0]["trigger"] = null
    GameState.hp = 50
    EventBus.player_hit.emit(5)
    assert_eq(GameState.hp, 50)  # no heal

func test_no_fire_when_effect_slot_empty() -> void:
    var t = ComponentData.new()
    t.id = "受击"
    t.trigger_value = 1.0
    GameState.rule_slots[0]["trigger"] = t
    GameState.rule_slots[0]["effect"] = null
    GameState.hp = 50
    EventBus.player_hit.emit(5)
    assert_eq(GameState.hp, 50)
```

- [ ] **Step 2: Run — expect fail** (RuleEngine not defined)

- [ ] **Step 3: Create RuleEngine.gd**

Create `src/systems/RuleEngine.gd`:
```gdscript
class_name RuleEngine
extends Node

const TRIGGER_EVENTS = {
    "受击": "player_hit",
    "击杀": "enemy_killed",
    "完成圈数": "loop_completed",
    "经过": "tile_passed",
    "治愈": "player_hit",
}

func _ready() -> void:
    EventBus.player_hit.connect(_on_player_hit)
    EventBus.enemy_killed.connect(_on_enemy_killed)
    EventBus.loop_completed.connect(_on_loop_completed)
    EventBus.tile_passed.connect(_on_tile_passed)

func _on_player_hit(_damage: int) -> void:
    _evaluate_triggers(["受击", "治愈"])

func _on_enemy_killed(_enemy: Enemy) -> void:
    _evaluate_triggers(["击杀"])

func _on_loop_completed() -> void:
    _evaluate_triggers(["完成圈数"])

func _on_tile_passed(_tile_idx: int) -> void:
    _evaluate_triggers(["经过"])

func _evaluate_triggers(trigger_ids: Array) -> void:
    for i in GameState.rule_slots.size():
        var slot = GameState.rule_slots[i]
        var trigger: ComponentData = slot.get("trigger")
        var effect: ComponentData = slot.get("effect")
        if trigger == null or effect == null:
            continue
        if trigger.id not in trigger_ids:
            continue
        trigger.trigger_count += 1
        if trigger.trigger_count >= trigger.trigger_value:
            trigger.trigger_count = 0
            _execute_effect(i, effect)

func _execute_effect(slot_idx: int, effect: ComponentData) -> void:
    match effect.id:
        "治愈":
            GameState.hp = min(GameState.hp + int(effect.effect_value), GameState.hp_max)
            EventBus.rule_fired.emit(slot_idx, "治愈", effect.effect_value)
        "反射":
            GameState.pending_reflect_ratio = effect.effect_value
            EventBus.rule_fired.emit(slot_idx, "反射", effect.effect_value)
        _:
            pass
```

- [ ] **Step 4: Create rule_engine.tscn**

Create `scenes/systems/rule_engine.tscn`:
```
[gd_scene load_steps=2 format=3 uid="uid://rule_engine_v1"]

[ext_resource type="Script" path="res://src/systems/RuleEngine.gd" id="1_re"]

[node name="RuleEngine" type="Node"]
script = ExtResource("1_re")
```

- [ ] **Step 5: Run tests — expect pass**

```
cd "S:/attribute-loop" && powershell -NoProfile -File scripts/self-test.ps1
```

- [ ] **Step 6: Commit**

```
git add src/systems/RuleEngine.gd scenes/systems/ tests/unit/test_rule_engine.gd
git commit -m "feat: add RuleEngine — trigger evaluation and heal/reflect effects"
```

---

## Task 10: StripManager + StripPanel UI

**Files:**
- Create: `src/systems/StripManager.gd`
- Create: `scenes/systems/strip_manager.tscn`
- Create: `src/ui/StripPanel.gd`
- Create: `scenes/ui/strip_panel.tscn`
- Create: `tests/unit/test_strip_manager.gd`

- [ ] **Step 1: Write StripManager tests**

Create `tests/unit/test_strip_manager.gd`:
```gdscript
extends GutTest

func before_each() -> void:
    GameState.reset()

func test_combat_resolved_emitted_immediately_when_no_components() -> void:
    watch_signals(EventBus)
    var manager = StripManager.new()
    add_child_autofree(manager)

    var enemy = Enemy.new()
    enemy.init("汲取者")
    enemy.components = []
    manager._on_enemy_killed(enemy)
    assert_signal_emitted(EventBus, "combat_resolved")

func test_combat_resolved_not_emitted_when_components_present() -> void:
    # Strip panel is not wired in unit tests — just verify the manager holds off
    watch_signals(EventBus)
    var manager = StripManager.new()
    add_child_autofree(manager)

    var enemy = Enemy.new()
    enemy.init("汲取者")
    var c = ComponentData.new()
    c.id = "受击"
    enemy.components = [c]
    manager._on_enemy_killed(enemy)
    assert_signal_not_emitted(EventBus, "combat_resolved")
```

- [ ] **Step 2: Run — expect fail**

- [ ] **Step 3: Create StripManager.gd**

Create `src/systems/StripManager.gd`:
```gdscript
class_name StripManager
extends Node

var _strip_panel: StripPanel = null
var _pending_enemy: Enemy = null

func _ready() -> void:
    EventBus.enemy_killed.connect(_on_enemy_killed)

func setup(panel: StripPanel) -> void:
    _strip_panel = panel

func _on_enemy_killed(enemy: Enemy) -> void:
    _pending_enemy = enemy
    if enemy.components.is_empty():
        _pending_enemy = null
        EventBus.combat_resolved.emit()
        return
    if _strip_panel != null:
        _strip_panel.show_for_enemy(enemy, _on_strip_completed)

func _on_strip_completed() -> void:
    _pending_enemy = null
    EventBus.combat_resolved.emit()
```

- [ ] **Step 4: Create StripPanel.gd**

Create `src/ui/StripPanel.gd`:
```gdscript
class_name StripPanel
extends PanelContainer

var _on_complete: Callable
var _inventory_panel: InventoryPanel = null

@onready var _grid: GridContainer = $VBox/ComponentGrid
@onready var _continue_btn: Button = $VBox/HBox/ContinueButton
@onready var _bag_btn: Button = $VBox/HBox/BagButton

const SLOT_TYPE_COLORS = {
    ComponentData.SlotType.TRIGGER_ONLY: Color(1.0, 0.6, 0.1, 1),  # orange
    ComponentData.SlotType.EFFECT_ONLY:  Color(0.2, 0.9, 0.3, 1),  # green
    ComponentData.SlotType.BOTH:         Color(0.3, 0.6, 1.0, 1),  # blue
}

func _ready() -> void:
    hide()
    _continue_btn.pressed.connect(_on_continue)
    _bag_btn.pressed.connect(_on_open_bag)

func setup(inv_panel: InventoryPanel) -> void:
    _inventory_panel = inv_panel

func show_for_enemy(enemy: Enemy, on_complete: Callable) -> void:
    _on_complete = on_complete
    _build_grid(enemy.components)
    show()
    GameState.is_paused = true

func _build_grid(components: Array[ComponentData]) -> void:
    for child in _grid.get_children():
        child.queue_free()
    for comp in components:
        var card := _make_card(comp)
        _grid.add_child(card)

func _make_card(comp: ComponentData) -> PanelContainer:
    var card := PanelContainer.new()
    var style := StyleBoxFlat.new()
    style.border_color = SLOT_TYPE_COLORS.get(comp.slot_type, Color.WHITE)
    style.border_width_left = 2; style.border_width_right = 2
    style.border_width_top = 2; style.border_width_bottom = 2
    card.add_theme_stylebox_override("panel", style)

    var vbox := VBoxContainer.new()
    card.add_child(vbox)

    var name_lbl := Label.new()
    name_lbl.text = comp.display_name
    vbox.add_child(name_lbl)

    var val_lbl := Label.new()
    if comp.slot_type == ComponentData.SlotType.TRIGGER_ONLY:
        val_lbl.text = "每 %.0f 次" % comp.trigger_value
    elif comp.slot_type == ComponentData.SlotType.EFFECT_ONLY:
        val_lbl.text = "值: %.1f" % comp.effect_value
    else:
        val_lbl.text = "T:%.0f E:%.1f" % [comp.trigger_value, comp.effect_value]
    vbox.add_child(val_lbl)

    var take_btn := Button.new()
    take_btn.text = "取走"
    take_btn.disabled = not GameState.inventory_has_space()
    take_btn.pressed.connect(func():
        GameState.add_to_inventory(comp)
        take_btn.disabled = true
        take_btn.text = "已取"
        # refresh all take buttons after inventory state changes
        _refresh_take_buttons()
    )
    vbox.add_child(take_btn)
    return card

func _refresh_take_buttons() -> void:
    var has_space = GameState.inventory_has_space()
    for card in _grid.get_children():
        var btn: Button = card.get_node_or_null("VBoxContainer/取走")
        if btn and not btn.disabled:
            btn.disabled = not has_space

func _on_continue() -> void:
    hide()
    GameState.is_paused = false
    if _on_complete.is_valid():
        _on_complete.call()

func _on_open_bag() -> void:
    if _inventory_panel != null:
        _inventory_panel.toggle()
```

- [ ] **Step 5: Create strip_panel.tscn**

Create `scenes/ui/strip_panel.tscn`:
```
[gd_scene load_steps=2 format=3 uid="uid://strip_panel_v1"]

[ext_resource type="Script" path="res://src/ui/StripPanel.gd" id="1_sp"]

[node name="StripPanel" type="PanelContainer"]
script = ExtResource("1_sp")
anchors_preset = 8
anchor_left = 0.5
anchor_top = 0.5
anchor_right = 0.5
anchor_bottom = 0.5
offset_left = -200.0
offset_top = -200.0
offset_right = 200.0
offset_bottom = 200.0

[node name="VBox" type="VBoxContainer" parent="."]
layout_mode = 2

[node name="Title" type="Label" parent="VBox"]
text = "拾取零件"
horizontal_alignment = 1

[node name="ComponentGrid" type="GridContainer" parent="VBox"]
columns = 2

[node name="HBox" type="HBoxContainer" parent="VBox"]

[node name="BagButton" type="Button" parent="VBox/HBox"]
text = "[B] 打开背包"

[node name="ContinueButton" type="Button" parent="VBox/HBox"]
text = "继续 →"
```

- [ ] **Step 6: Create strip_manager.tscn**

Create `scenes/systems/strip_manager.tscn`:
```
[gd_scene load_steps=2 format=3 uid="uid://strip_manager_v1"]

[ext_resource type="Script" path="res://src/systems/StripManager.gd" id="1_sm"]

[node name="StripManager" type="Node"]
script = ExtResource("1_sm")
```

- [ ] **Step 7: Run tests — expect pass**

```
cd "S:/attribute-loop" && powershell -NoProfile -File scripts/self-test.ps1
```

- [ ] **Step 8: Commit**

```
git add src/systems/StripManager.gd scenes/systems/strip_manager.tscn src/ui/StripPanel.gd scenes/ui/strip_panel.tscn tests/unit/test_strip_manager.gd
git commit -m "feat: add StripManager and StripPanel — post-combat component selection"
```

---

## Task 11: InventoryPanel + HUD Update

**Files:**
- Create: `src/ui/InventoryPanel.gd`
- Create: `scenes/ui/inventory_panel.tscn`
- Modify: `src/ui/HUD.gd`
- Modify: `scenes/ui/hud.tscn`

- [ ] **Step 1: Create InventoryPanel.gd**

Create `src/ui/InventoryPanel.gd`:
```gdscript
class_name InventoryPanel
extends PanelContainer

var _selected: ComponentData = null

@onready var _rule_slot_container: VBoxContainer = $VBox/RuleSlots
@onready var _inv_grid: GridContainer = $VBox/InventoryGrid
@onready var _delete_btn: Button = $VBox/DeleteButton
@onready var _close_btn: Button = $VBox/CloseButton
@onready var _inv_label: Label = $VBox/InvLabel

func _ready() -> void:
    hide()
    _delete_btn.hide()
    _delete_btn.pressed.connect(_on_delete)
    _close_btn.pressed.connect(toggle)

func _input(event: InputEvent) -> void:
    if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.keycode == KEY_TAB and event.pressed):
        if visible:
            toggle()

func toggle() -> void:
    if visible:
        hide()
        GameState.is_paused = false
    else:
        show()
        GameState.is_paused = true
        _refresh()

func _refresh() -> void:
    _build_rule_slots()
    _build_inventory_grid()
    _inv_label.text = "背包 %d/%d" % [GameState.inventory.size(), DataTables.config.inventory_cap]

func _build_rule_slots() -> void:
    for child in _rule_slot_container.get_children():
        child.queue_free()
    for i in GameState.rule_slots.size():
        var slot = GameState.rule_slots[i]
        var hbox := HBoxContainer.new()
        _rule_slot_container.add_child(hbox)

        var t_btn := Button.new()
        var t_comp: ComponentData = slot["trigger"]
        t_btn.text = t_comp.display_name + (" [%.0f/%d]" % [t_comp.trigger_value, t_comp.trigger_count] if t_comp else "") if t_comp else "[T 空]"
        t_btn.pressed.connect(func():
            if _selected != null and _selected.slot_type != ComponentData.SlotType.EFFECT_ONLY:
                GameState.equip(_selected, i, true)
                _selected = null
                _delete_btn.hide()
                _refresh()
            elif t_comp != null:
                _select(t_comp)
        )
        hbox.add_child(t_btn)

        var e_btn := Button.new()
        var e_comp: ComponentData = slot["effect"]
        e_btn.text = (e_comp.display_name + " [%.1f]" % e_comp.effect_value) if e_comp else "[E 空]"
        e_btn.pressed.connect(func():
            if _selected != null and _selected.slot_type != ComponentData.SlotType.TRIGGER_ONLY:
                GameState.equip(_selected, i, false)
                _selected = null
                _delete_btn.hide()
                _refresh()
            elif e_comp != null:
                _select(e_comp)
        )
        hbox.add_child(e_btn)

func _build_inventory_grid() -> void:
    for child in _inv_grid.get_children():
        child.queue_free()
    for comp in GameState.inventory:
        var btn := Button.new()
        var label = comp.display_name
        if comp.slot_type == ComponentData.SlotType.TRIGGER_ONLY:
            label += " (T:%.0f)" % comp.trigger_value
        elif comp.slot_type == ComponentData.SlotType.EFFECT_ONLY:
            label += " (E:%.1f)" % comp.effect_value
        else:
            label += " (T:%.0f/E:%.1f)" % [comp.trigger_value, comp.effect_value]
        btn.text = label
        btn.custom_minimum_size = Vector2(120, 40)
        btn.pressed.connect(func(): _select(comp))
        _inv_grid.add_child(btn)

func _select(comp: ComponentData) -> void:
    _selected = comp
    _delete_btn.show()
    _refresh()

func _on_delete() -> void:
    if _selected == null:
        return
    GameState.delete_component(_selected)
    # Also unequip if in a rule slot
    for i in GameState.rule_slots.size():
        var slot = GameState.rule_slots[i]
        if slot["trigger"] == _selected:
            slot["trigger"] = null
        if slot["effect"] == _selected:
            slot["effect"] = null
    _selected = null
    _delete_btn.hide()
    _refresh()
```

- [ ] **Step 2: Create inventory_panel.tscn**

Create `scenes/ui/inventory_panel.tscn`:
```
[gd_scene load_steps=2 format=3 uid="uid://inventory_panel_v1"]

[ext_resource type="Script" path="res://src/ui/InventoryPanel.gd" id="1_ip"]

[node name="InventoryPanel" type="PanelContainer"]
script = ExtResource("1_ip")
anchors_preset = 8
anchor_left = 0.5
anchor_top = 0.5
anchor_right = 0.5
anchor_bottom = 0.5
offset_left = -280.0
offset_top = -240.0
offset_right = 280.0
offset_bottom = 240.0

[node name="VBox" type="VBoxContainer" parent="."]
layout_mode = 2

[node name="TitleLabel" type="Label" parent="VBox"]
text = "背包与规则槽"
horizontal_alignment = 1

[node name="RuleSlots" type="VBoxContainer" parent="VBox"]

[node name="InvLabel" type="Label" parent="VBox"]
text = "背包 0/12"

[node name="InventoryGrid" type="GridContainer" parent="VBox"]
columns = 4

[node name="DeleteButton" type="Button" parent="VBox"]
text = "删除"

[node name="CloseButton" type="Button" parent="VBox"]
text = "关闭 [Tab]"
```

- [ ] **Step 3: Update HUD.gd**

Replace `src/ui/HUD.gd`:
```gdscript
class_name HUD
extends CanvasLayer

var _inventory_panel: InventoryPanel = null
var _float_tween: Tween = null

@onready var hp_label: Label = $VBox/HPLabel
@onready var loops_label: Label = $VBox/LoopsLabel
@onready var phase_label: Label = $VBox/PhaseLabel
@onready var rules_label: Label = $VBox/RulesLabel
@onready var bag_btn: Button = $VBox/BagButton
@onready var float_label: Label = $FloatLabel

func _ready() -> void:
    bag_btn.pressed.connect(_on_bag_pressed)
    float_label.hide()
    EventBus.rule_fired.connect(_on_rule_fired)

func setup(inv_panel: InventoryPanel) -> void:
    _inventory_panel = inv_panel

func _process(_delta: float) -> void:
    hp_label.text = "HP: %d / %d" % [GameState.hp, GameState.hp_max]
    loops_label.text = "圈数: %d" % GameState.loops_completed
    var phase_data: PhaseData = DataTables.get_phase(GameState.current_phase)
    phase_label.text = "阶段 %d — %s" % [GameState.current_phase, phase_data.phase_name]
    rules_label.text = _build_rules_summary()
    bag_btn.text = "背包 [B] %d/%d" % [GameState.inventory.size(), DataTables.config.inventory_cap]

func _build_rules_summary() -> String:
    var parts: Array = []
    for slot in GameState.rule_slots:
        var t: ComponentData = slot["trigger"]
        var e: ComponentData = slot["effect"]
        if t != null and e != null:
            parts.append("%s→%s" % [t.display_name, e.display_name])
        else:
            parts.append("空")
    return " / ".join(parts)

func _on_bag_pressed() -> void:
    if _inventory_panel != null:
        _inventory_panel.toggle()

func _on_rule_fired(_slot_idx: int, effect_id: String, value: float) -> void:
    if effect_id == "治愈":
        float_label.text = "+%.0f 治愈" % value
    elif effect_id == "反射":
        float_label.text = "反射 %.0f%%" % (value * 100)
    else:
        float_label.text = effect_id
    float_label.show()
    float_label.modulate = Color.WHITE
    if _float_tween:
        _float_tween.kill()
    _float_tween = create_tween()
    _float_tween.tween_property(float_label, "modulate:a", 0.0, 1.0)
    _float_tween.tween_callback(float_label.hide)
```

- [ ] **Step 4: Update hud.tscn**

Replace `scenes/ui/hud.tscn`:
```
[gd_scene load_steps=2 format=3 uid="uid://hud_scene_v1"]

[ext_resource type="Script" path="res://src/ui/HUD.gd" id="1_hud"]

[node name="HUD" type="CanvasLayer"]
script = ExtResource("1_hud")

[node name="VBox" type="VBoxContainer" parent="."]
offset_left = 16.0
offset_top = 16.0
offset_right = 320.0
offset_bottom = 140.0

[node name="HPLabel" type="Label" parent="VBox"]
text = "HP: 100 / 100"

[node name="LoopsLabel" type="Label" parent="VBox"]
text = "圈数: 0"

[node name="PhaseLabel" type="Label" parent="VBox"]
text = "阶段 1 — 觉醒"

[node name="RulesLabel" type="Label" parent="VBox"]
text = "空 / 空"

[node name="BagButton" type="Button" parent="VBox"]
text = "背包 [B] 0/12"

[node name="FloatLabel" type="Label" parent="."]
offset_left = 500.0
offset_top = 300.0
offset_right = 700.0
offset_bottom = 340.0
horizontal_alignment = 1
```

- [ ] **Step 5: Run tests — expect pass**

```
cd "S:/attribute-loop" && powershell -NoProfile -File scripts/self-test.ps1
```

- [ ] **Step 6: Commit**

```
git add src/ui/InventoryPanel.gd scenes/ui/inventory_panel.tscn src/ui/HUD.gd scenes/ui/hud.tscn
git commit -m "feat: add InventoryPanel; update HUD with rule summary, bag button, floating text"
```

---

## Task 12: Wire main.tscn + Integration

**Files:**
- Modify: `scenes/main.tscn`
- Modify: `src/Main.gd`

- [ ] **Step 1: Update Main.gd with all new node references**

Replace `src/Main.gd`:
```gdscript
extends Node2D

const TILE_SCENE = preload("res://scenes/entities/tile.tscn")
const GAME_OVER_SCENE = preload("res://scenes/ui/game_over.tscn")

@onready var track: Path2D = $Track
@onready var player_follow: PathFollow2D = $Track/PlayerFollow
@onready var player: Player = $Track/PlayerFollow/Player
@onready var tiles_container: Node2D = $TilesContainer
@onready var enemies_container: Node2D = $EnemiesContainer
@onready var combat_system: CombatSystem = $Systems/CombatSystem
@onready var game_loop: GameLoop = $Systems/GameLoop
@onready var strip_manager: StripManager = $Systems/StripManager
@onready var strip_panel: StripPanel = $UI/StripPanel
@onready var inventory_panel: InventoryPanel = $UI/InventoryPanel
@onready var hud: HUD = $UI/HUD

func _ready() -> void:
    var tiles = _build_tiles()
    player.setup(player_follow, track)
    game_loop.setup(tiles, enemies_container, player, combat_system)
    strip_manager.setup(strip_panel)
    strip_panel.setup(inventory_panel)
    hud.setup(inventory_panel)
    EventBus.player_died.connect(_on_player_died)

func _build_tiles() -> Array:
    var tiles: Array = []
    var curve = track.curve
    var length = curve.get_baked_length()
    for i in 12:
        var t = float(i) / 12.0
        var pos = curve.sample_baked(t * length)
        var tile: Tile = TILE_SCENE.instantiate()
        tile.position = pos
        tile.tile_index = i
        tiles_container.add_child(tile)
        tiles.append(tile)
    return tiles

func _process(_delta: float) -> void:
    if GameState.is_paused:
        return
    _check_player_tile()

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
            return

func _on_player_died() -> void:
    var go = GAME_OVER_SCENE.instantiate()
    add_child(go)
```

- [ ] **Step 2: Rewrite main.tscn**

Replace `scenes/main.tscn`:
```
[gd_scene load_steps=10 format=3 uid="uid://main_scene_v1"]

[ext_resource type="Script" path="res://src/Main.gd" id="1_main"]
[ext_resource type="Script" path="res://src/systems/CombatSystem.gd" id="2_combat"]
[ext_resource type="Script" path="res://src/systems/GameLoop.gd" id="3_gameloop"]
[ext_resource type="Script" path="res://src/systems/RuleEngine.gd" id="4_re"]
[ext_resource type="Script" path="res://src/systems/StripManager.gd" id="5_sm"]
[ext_resource type="PackedScene" path="res://scenes/entities/player.tscn" id="6_player"]
[ext_resource type="PackedScene" path="res://scenes/ui/hud.tscn" id="7_hud"]
[ext_resource type="PackedScene" path="res://scenes/ui/strip_panel.tscn" id="8_strip"]
[ext_resource type="PackedScene" path="res://scenes/ui/inventory_panel.tscn" id="9_inv"]

[sub_resource type="Curve2D" id="Curve2D_track"]
_data = {
"points": PackedVector2Array(0, 0, 0, 0, 150, 120, 0, 0, 0, 0, 1130, 120, 0, 0, 0, 0, 1130, 580, 0, 0, 0, 0, 150, 580, 0, 0, 0, 0, 150, 120),
"tilts": PackedFloat32Array(0, 0, 0, 0, 0)
}

[node name="Main" type="Node2D"]
script = ExtResource("1_main")

[node name="Track" type="Path2D" parent="."]
curve = SubResource("Curve2D_track")

[node name="PlayerFollow" type="PathFollow2D" parent="Track"]
rotates = false

[node name="Player" parent="Track/PlayerFollow" instance=ExtResource("6_player")]

[node name="TilesContainer" type="Node2D" parent="."]

[node name="EnemiesContainer" type="Node2D" parent="."]

[node name="TrackLine" type="Line2D" parent="."]
points = PackedVector2Array(150, 120, 1130, 120, 1130, 580, 150, 580, 150, 120)
width = 2.0
default_color = Color(0.4, 0.4, 0.4, 1)

[node name="Systems" type="Node" parent="."]

[node name="CombatSystem" type="Node" parent="Systems"]
script = ExtResource("2_combat")

[node name="GameLoop" type="Node" parent="Systems"]
script = ExtResource("3_gameloop")

[node name="RuleEngine" type="Node" parent="Systems"]
script = ExtResource("4_re")

[node name="StripManager" type="Node" parent="Systems"]
script = ExtResource("5_sm")

[node name="UI" type="CanvasLayer" parent="."]

[node name="HUD" parent="UI" instance=ExtResource("7_hud")]

[node name="StripPanel" parent="UI" instance=ExtResource("8_strip")]

[node name="InventoryPanel" parent="UI" instance=ExtResource("9_inv")]
```

- [ ] **Step 3: Run all tests**

```
cd "S:/attribute-loop" && powershell -NoProfile -File scripts/self-test.ps1
```
Expected: all tests pass.

- [ ] **Step 4: Commit**

```
git add scenes/main.tscn src/Main.gd
git commit -m "feat: wire Phase 2 nodes into main.tscn — Systems/UI hierarchy with RuleEngine, StripManager, StripPanel, InventoryPanel"
```

---

## Task 13: Visual Integration Test + Documentation

**Files:**
- Create: `docs/modules/phase2-systems.md`
- Create: `docs/modules/phase2-ui.md`

- [ ] **Step 1: Visual integration test**

Follow CLAUDE.md Step 3:
1. Create `tests/.test_mode` (empty file)
2. Via MCP `execute_editor_script`: `EditorInterface.play_main_scene()`
3. Poll every 2s until `tests/screenshots/last_run.png` appears (timeout 20s)
4. Read screenshot — verify: game window renders, player moving, HUD shows rule/bag labels, no error dialogs
5. Delete `tests/.test_mode`

If screenshot shows errors: stop game, investigate, fix, re-run.

- [ ] **Step 2: Write phase2-systems.md**

Create `docs/modules/phase2-systems.md` covering:
- ComponentData / DropPreset resource classes
- Drop assignment flow (GameLoop._assign_components)
- RuleEngine trigger evaluation and effect execution
- StripManager flow from enemy_killed to combat_resolved
- Signal chain: enemy_killed → StripManager → StripPanel → combat_resolved → GameLoop

- [ ] **Step 3: Write phase2-ui.md**

Create `docs/modules/phase2-ui.md` covering:
- StripPanel: when shown, card structure, take/skip/continue
- InventoryPanel: rule slots, inventory grid, equip/unequip/delete operations
- HUD additions: rule summary format, bag button, floating text on rule_fired

- [ ] **Step 4: Final commit**

```
git add docs/modules/phase2-systems.md docs/modules/phase2-ui.md
git commit -m "docs: add Phase 2 systems and UI module documentation"
```

---

## Self-Review Checklist

**Spec coverage:**
- [x] ComponentData resource (§2) — Tasks 1-2
- [x] DropPreset + value rolling (§3) — Tasks 2-3, 6
- [x] Effect system + RuleEngine (§4) — Task 9
- [x] Scene structure (§5) — Task 12
- [x] GameState additions (§6) — Task 4
- [x] EventBus additions (§7) — Task 5
- [x] CombatSystem changes (§8) — Task 7
- [x] tile_passed detection (§9) — Task 8
- [x] Enemy component assignment (§10) — Task 6
- [x] Strip flow (§11) — Task 10
- [x] Inventory + rule slot management (§12) — Tasks 4, 11
- [x] HUD update (§13) — Task 11
- [x] Data files (§14) — Tasks 2-3

**Type consistency checks:**
- `ComponentData.SlotType.TRIGGER_ONLY/EFFECT_ONLY/BOTH` used consistently across all tasks
- `GameState.equip(c, slot_idx, as_trigger: bool)` — matches usage in InventoryPanel
- `StripManager._on_enemy_killed(enemy: Enemy)` — matches EventBus signal `enemy_killed(enemy: Enemy)`
- `GameLoop._create_component(id, preset)` returns `ComponentData` — matches Enemy.components type
- `_weighted_pick_with_modifiers(weights, phase_data)` returns `String` — matches enemy_id usage pattern
