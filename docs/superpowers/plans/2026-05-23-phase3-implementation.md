# Phase 3 — 永久的地块 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add permanent tile rules with pass_count scaling, an Altar that converts sacrificed E components into permanent global bonuses and advances Phase, and a gold economy that enforces escalating deletion costs.

**Architecture:** Resources gain new scaling/altar fields; GameState gains gold/deletion/altar state; a new EconomyManager node handles gold drops; RuleEngine is extended to evaluate tile rules and apply altar bonuses; two new UI panels (TileRulePanel, AltarPanel) let the player configure tiles; Main handles tile click detection.

**Tech Stack:** GDScript 4, GUT (tests/unit/), Godot MCP (scene/resource edits), headless self-test via `powershell -NoProfile -File scripts/self-test.ps1`

---

## File Map

| Action | File | What changes |
|--------|------|-------------|
| Modify | `src/resources/ComponentData.gd` | Add `growth_rate`, `scale_exponent`, `max_scale`, `altar_ratio` |
| Modify | `src/resources/EnemyData.gd` | Add `gold_scale` |
| Modify | `src/resources/GameConfig.gd` | Add `deletion_cost_sequence`, `deletion_cost_multiplier` |
| Modify | `src/autoloads/DataTables.gd` | Add `TILE_MAX_RULES` array |
| Modify | `src/autoloads/EventBus.gd` | Add `gold_changed`, `phase_changed` signals |
| Modify | `src/autoloads/GameState.gd` | Add `gold`, `deletion_count`, `altar_bonuses`, helpers |
| Create | `src/systems/EconomyManager.gd` | Gold drop on kill |
| Modify | `src/entities/Tile.gd` | Add `pass_count`, `rule_slots`, `is_altar`, `altar_slots`, `_ready` |
| Modify | `src/systems/RuleEngine.gd` | Tile rule eval, altar bonus, pass_count scaling |
| Modify | `src/Main.gd` | pass_count increment, tile click, reset_tiles, wire new nodes |
| Create | `src/ui/TileRulePanel.gd` | Tile rule placement / removal UI |
| Create | `src/ui/AltarPanel.gd` | Altar E-slot placement and activation UI |
| Modify | `src/ui/HUD.gd` | Add gold label |
| Modify | `src/ui/InventoryPanel.gd` | Cost display on delete, pay deletion cost |
| Create | `scenes/ui/tile_rule_panel.tscn` | New scene |
| Create | `scenes/ui/altar_panel.tscn` | New scene |
| Modify | `scenes/main.tscn` | Add EconomyManager, TileRulePanel, AltarPanel nodes |
| Modify | `data/components/both_治愈.tres` | Set growth_rate=0.15, altar_ratio=0.1 |
| Modify | `data/components/both_反射.tres` | Set growth_rate=0.1, altar_ratio=0.05 |
| Create | `tests/unit/test_economy_manager.gd` | New tests |
| Create | `tests/unit/test_tile_system.gd` | New tests |
| Modify | `tests/unit/test_rule_engine.gd` | Add tile rule + altar bonus tests |
| Modify | `tests/unit/test_game_state.gd` | Add gold/deletion/altar tests |

---

## Task 1: ComponentData — add scaling and altar fields

**Files:**
- Modify: `src/resources/ComponentData.gd`
- Modify: `data/components/both_治愈.tres`
- Modify: `data/components/both_反射.tres`
- Test: `tests/unit/test_component_data.gd`

- [ ] **Step 1: Write failing tests**

Add to `tests/unit/test_component_data.gd`:

```gdscript
func test_growth_rate_default_zero() -> void:
    var c := ComponentData.new()
    assert_eq(c.growth_rate, 0.0)

func test_scale_exponent_default_one() -> void:
    var c := ComponentData.new()
    assert_eq(c.scale_exponent, 1.0)

func test_max_scale_default_zero() -> void:
    var c := ComponentData.new()
    assert_eq(c.max_scale, 0.0)

func test_altar_ratio_default_zero() -> void:
    var c := ComponentData.new()
    assert_eq(c.altar_ratio, 0.0)
```

- [ ] **Step 2: Run tests — expect failure**

```
powershell -NoProfile -File scripts/self-test.ps1
```

Expected: FAIL — `growth_rate` not found on ComponentData

- [ ] **Step 3: Add fields to ComponentData**

Replace `src/resources/ComponentData.gd` with:

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
@export var trigger_value: float = 0.0
@export var effect_value: float = 0.0
@export var growth_rate: float = 0.0
@export var scale_exponent: float = 1.0
@export var max_scale: float = 0.0
@export var altar_ratio: float = 0.0
var trigger_count: int = 0
```

- [ ] **Step 4: Run tests — expect pass**

```
powershell -NoProfile -File scripts/self-test.ps1
```

Expected: All existing + new tests pass.

- [ ] **Step 5: Update component .tres files with non-default values**

Edit `data/components/both_治愈.tres` — add after `effect_formula = "heal"`:
```
growth_rate = 0.15
altar_ratio = 0.1
```

Edit `data/components/both_反射.tres` — add after `effect_formula = "reflect"`:
```
growth_rate = 0.1
altar_ratio = 0.05
```

(Trigger-only components keep defaults: growth_rate=0.0, altar_ratio=0.0)

- [ ] **Step 6: Commit**

```
git add src/resources/ComponentData.gd data/components/both_治愈.tres data/components/both_反射.tres tests/unit/test_component_data.gd
git commit -m "feat: ComponentData — growth_rate, scale_exponent, max_scale, altar_ratio fields"
```

---

## Task 2: EnemyData + GameConfig — gold_scale and deletion cost config

**Files:**
- Modify: `src/resources/EnemyData.gd`
- Modify: `src/resources/GameConfig.gd`
- Test: `tests/unit/test_data_tables.gd`

- [ ] **Step 1: Write failing tests**

Add to `tests/unit/test_data_tables.gd`:

```gdscript
func test_enemy_has_gold_scale() -> void:
    var ed: EnemyData = DataTables.get_enemy("汲取者")
    assert_eq(ed.gold_scale, 0.3)

func test_config_has_deletion_cost_sequence() -> void:
    assert_eq(DataTables.config.deletion_cost_sequence.size(), 3)
    assert_eq(DataTables.config.deletion_cost_sequence[0], 20)
    assert_eq(DataTables.config.deletion_cost_sequence[1], 50)
    assert_eq(DataTables.config.deletion_cost_sequence[2], 100)

func test_config_has_deletion_cost_multiplier() -> void:
    assert_eq(DataTables.config.deletion_cost_multiplier, 2.0)
```

- [ ] **Step 2: Run tests — expect failure**

```
powershell -NoProfile -File scripts/self-test.ps1
```

- [ ] **Step 3: Add gold_scale to EnemyData**

Add to `src/resources/EnemyData.gd` after `gold_max`:

```gdscript
@export var gold_scale: float = 0.3
```

- [ ] **Step 4: Add deletion cost fields to GameConfig**

Add to `src/resources/GameConfig.gd`:

```gdscript
@export var deletion_cost_sequence: Array[int] = [20, 50, 100]
@export var deletion_cost_multiplier: float = 2.0
```

- [ ] **Step 5: Run tests — expect pass**

```
powershell -NoProfile -File scripts/self-test.ps1
```

- [ ] **Step 6: Commit**

```
git add src/resources/EnemyData.gd src/resources/GameConfig.gd tests/unit/test_data_tables.gd
git commit -m "feat: EnemyData.gold_scale + GameConfig deletion cost config"
```

---

## Task 3: DataTables — TILE_MAX_RULES array

**Files:**
- Modify: `src/autoloads/DataTables.gd`
- Test: `tests/unit/test_data_tables.gd`

- [ ] **Step 1: Write failing tests**

Add to `tests/unit/test_data_tables.gd`:

```gdscript
func test_tile_max_rules_has_13_entries() -> void:
    assert_eq(DataTables.TILE_MAX_RULES.size(), 13)

func test_tile_max_rules_altar_at_index_0() -> void:
    # index 0 is the altar tile — its capacity is irrelevant (use 0 as sentinel)
    assert_eq(DataTables.TILE_MAX_RULES[0], 0)

func test_tile_max_rules_values_in_range() -> void:
    for i in range(1, DataTables.TILE_MAX_RULES.size()):
        var v = DataTables.TILE_MAX_RULES[i]
        assert_true(v >= 1 and v <= 3, "tile %d has invalid max_rules %d" % [i, v])
```

- [ ] **Step 2: Run tests — expect failure**

```
powershell -NoProfile -File scripts/self-test.ps1
```

- [ ] **Step 3: Add TILE_MAX_RULES to DataTables**

Add at the top of `src/autoloads/DataTables.gd` (before `var config`):

```gdscript
# Index 0 = altar (capacity managed by AltarPanel). Indices 1-12 = normal tiles.
const TILE_MAX_RULES: Array[int] = [0, 1, 2, 1, 3, 2, 1, 2, 3, 1, 2, 3, 2]
```

- [ ] **Step 4: Run tests — expect pass**

```
powershell -NoProfile -File scripts/self-test.ps1
```

- [ ] **Step 5: Commit**

```
git add src/autoloads/DataTables.gd tests/unit/test_data_tables.gd
git commit -m "feat: DataTables.TILE_MAX_RULES — per-tile rule slot capacity"
```

---

## Task 4: GameState — gold, deletion_count, altar_bonuses + EventBus signals

**Files:**
- Modify: `src/autoloads/GameState.gd`
- Modify: `src/autoloads/EventBus.gd`
- Test: `tests/unit/test_game_state.gd`

- [ ] **Step 1: Write failing tests**

Add to `tests/unit/test_game_state.gd`:

```gdscript
func test_gold_zero_after_reset() -> void:
    GameState.gold = 50
    GameState.reset()
    assert_eq(GameState.gold, 0)

func test_deletion_count_zero_after_reset() -> void:
    GameState.deletion_count = 3
    GameState.reset()
    assert_eq(GameState.deletion_count, 0)

func test_altar_bonuses_empty_after_reset() -> void:
    GameState.altar_bonuses["治愈"] = 5.0
    GameState.reset()
    assert_eq(GameState.altar_bonuses.size(), 0)

func test_get_deletion_cost_first_deletion() -> void:
    GameState.reset()
    assert_eq(GameState.get_deletion_cost(), 20)

func test_get_deletion_cost_second_deletion() -> void:
    GameState.deletion_count = 1
    assert_eq(GameState.get_deletion_cost(), 50)

func test_get_deletion_cost_third_deletion() -> void:
    GameState.deletion_count = 2
    assert_eq(GameState.get_deletion_cost(), 100)

func test_get_deletion_cost_fourth_uses_multiplier() -> void:
    GameState.deletion_count = 3
    assert_eq(GameState.get_deletion_cost(), 200)

func test_get_deletion_cost_fifth_doubles_again() -> void:
    GameState.deletion_count = 4
    assert_eq(GameState.get_deletion_cost(), 400)

func test_can_afford_deletion_true_when_enough_gold() -> void:
    GameState.gold = 20
    GameState.deletion_count = 0
    assert_true(GameState.can_afford_deletion())

func test_can_afford_deletion_false_when_insufficient() -> void:
    GameState.gold = 19
    GameState.deletion_count = 0
    assert_false(GameState.can_afford_deletion())

func test_pay_deletion_cost_deducts_gold() -> void:
    GameState.gold = 100
    GameState.deletion_count = 0
    GameState.pay_deletion_cost()
    assert_eq(GameState.gold, 80)

func test_pay_deletion_cost_increments_deletion_count() -> void:
    GameState.gold = 100
    GameState.deletion_count = 0
    GameState.pay_deletion_cost()
    assert_eq(GameState.deletion_count, 1)
```

- [ ] **Step 2: Run tests — expect failure**

```
powershell -NoProfile -File scripts/self-test.ps1
```

- [ ] **Step 3: Update GameState.gd**

Replace full content of `src/autoloads/GameState.gd`:

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
var rule_slots: Array = []
var gold: int = 0
var deletion_count: int = 0
var altar_bonuses: Dictionary = {}

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
    gold = 0
    deletion_count = 0
    altar_bonuses = {}
    for i in 2:
        rule_slots.append({"trigger": null, "effect": null})

func inventory_has_space() -> bool:
    return inventory.size() < DataTables.config.inventory_cap

func add_to_inventory(c: ComponentData) -> void:
    inventory.append(c)

func remove_from_inventory(c: ComponentData) -> void:
    inventory.erase(c)

func delete_component(c: ComponentData) -> void:
    inventory.erase(c)

func equip(c: ComponentData, slot_idx: int, as_trigger: bool) -> void:
    for s in rule_slots:
        if s["trigger"] == c:
            s["trigger"] = null
        if s["effect"] == c:
            s["effect"] = null
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

func get_deletion_cost() -> int:
    var seq: Array = DataTables.config.deletion_cost_sequence
    if deletion_count < seq.size():
        return seq[deletion_count]
    var cost: int = seq[-1]
    for i in deletion_count - (seq.size() - 1):
        cost = int(cost * DataTables.config.deletion_cost_multiplier)
    return cost

func can_afford_deletion() -> bool:
    return gold >= get_deletion_cost()

func pay_deletion_cost() -> void:
    gold -= get_deletion_cost()
    deletion_count += 1
    EventBus.gold_changed.emit(gold)
```

- [ ] **Step 4: Add signals to EventBus.gd**

Add two lines to `src/autoloads/EventBus.gd`:

```gdscript
signal gold_changed(new_amount: int)
signal phase_changed(new_phase: int)
```

- [ ] **Step 5: Run tests — expect pass**

```
powershell -NoProfile -File scripts/self-test.ps1
```

- [ ] **Step 6: Commit**

```
git add src/autoloads/GameState.gd src/autoloads/EventBus.gd tests/unit/test_game_state.gd
git commit -m "feat: GameState gold/deletion/altar fields + deletion cost helpers; EventBus new signals"
```

---

## Task 5: EconomyManager — gold drops from kills

**Files:**
- Create: `src/systems/EconomyManager.gd`
- Test: `tests/unit/test_economy_manager.gd`

- [ ] **Step 1: Write failing tests**

Create `tests/unit/test_economy_manager.gd`:

```gdscript
extends GutTest

func before_each() -> void:
    GameState.reset()

func test_calc_gold_drop_phase1_min() -> void:
    var ed := EnemyData.new()
    ed.gold_min = 5
    ed.gold_max = 5
    ed.gold_scale = 0.3
    var amount = EconomyManager.calc_gold_drop(ed, 1)
    assert_eq(amount, 5)

func test_calc_gold_drop_scales_with_phase() -> void:
    var ed := EnemyData.new()
    ed.gold_min = 10
    ed.gold_max = 10
    ed.gold_scale = 0.3
    # phase 3: mult = 1 + (3-1) * 0.3 = 1.6 → 10 * 1.6 = 16
    var amount = EconomyManager.calc_gold_drop(ed, 3)
    assert_eq(amount, 16)

func test_gold_added_to_gamestate_on_enemy_killed() -> void:
    var mgr := EconomyManager.new()
    add_child_autofree(mgr)
    GameState.gold = 0
    # Emit enemy_killed with a real 汲取者 enemy
    var enemy := Enemy.new()
    enemy.init("汲取者")
    # Force deterministic drop by setting fixed range
    DataTables.get_enemy("汲取者").gold_min = 10
    DataTables.get_enemy("汲取者").gold_max = 10
    GameState.current_phase = 1
    EventBus.enemy_killed.emit(enemy)
    assert_eq(GameState.gold, 10)
    # restore
    DataTables.get_enemy("汲取者").gold_min = 5
    DataTables.get_enemy("汲取者").gold_max = 15
```

- [ ] **Step 2: Run tests — expect failure**

```
powershell -NoProfile -File scripts/self-test.ps1
```

- [ ] **Step 3: Create EconomyManager.gd**

Create `src/systems/EconomyManager.gd`:

```gdscript
class_name EconomyManager
extends Node

func _ready() -> void:
    EventBus.enemy_killed.connect(_on_enemy_killed)

func _on_enemy_killed(enemy: Enemy) -> void:
    var ed: EnemyData = DataTables.get_enemy(enemy.enemy_id)
    var amount := calc_gold_drop(ed, GameState.current_phase)
    GameState.gold += amount
    EventBus.gold_changed.emit(GameState.gold)

static func calc_gold_drop(ed: EnemyData, phase: int) -> int:
    var mult := 1.0 + (phase - 1) * ed.gold_scale
    return int(randi_range(ed.gold_min, ed.gold_max) * mult)
```

- [ ] **Step 4: Run tests — expect pass**

```
powershell -NoProfile -File scripts/self-test.ps1
```

- [ ] **Step 5: Commit**

```
git add src/systems/EconomyManager.gd tests/unit/test_economy_manager.gd
git commit -m "feat: EconomyManager — gold drop on enemy kill with phase scaling"
```

---

## Task 6: Tile — pass_count + rule_slots + altar_slots

**Files:**
- Modify: `src/entities/Tile.gd`
- Test: `tests/unit/test_tile_system.gd`

- [ ] **Step 1: Write failing tests**

Create `tests/unit/test_tile_system.gd`:

```gdscript
extends GutTest

func _make_tile(idx: int, altar: bool = false) -> Tile:
    var t := Tile.new()
    t.tile_index = idx
    t.is_altar = altar
    add_child_autofree(t)
    return t

func test_normal_tile_rule_slots_match_config() -> void:
    # tile index 1 has TILE_MAX_RULES[1] = 1 slot
    var t := _make_tile(1)
    assert_eq(t.rule_slots.size(), 1)

func test_normal_tile_index4_has_3_slots() -> void:
    # TILE_MAX_RULES[4] = 3
    var t := _make_tile(4)
    assert_eq(t.rule_slots.size(), 3)

func test_normal_tile_slots_start_empty() -> void:
    var t := _make_tile(1)
    assert_null(t.rule_slots[0]["trigger"])
    assert_null(t.rule_slots[0]["effect"])

func test_pass_count_starts_zero() -> void:
    var t := _make_tile(1)
    assert_eq(t.pass_count, 0)

func test_altar_tile_has_no_rule_slots() -> void:
    var t := _make_tile(0, true)
    assert_eq(t.rule_slots.size(), 0)

func test_altar_slots_size_matches_phase_requirement() -> void:
    GameState.reset()  # current_phase = 1
    var t := _make_tile(0, true)
    var expected := DataTables.get_phase(1).altar_requirement
    assert_eq(t.altar_slots.size(), expected)

func test_altar_slots_start_null() -> void:
    GameState.reset()
    var t := _make_tile(0, true)
    for slot in t.altar_slots:
        assert_null(slot)
```

- [ ] **Step 2: Run tests — expect failure**

```
powershell -NoProfile -File scripts/self-test.ps1
```

- [ ] **Step 3: Replace Tile.gd**

```gdscript
class_name Tile
extends Node2D

var tile_index: int = 0
var enemy: Enemy = null
var visited_this_loop: bool = false
var pass_count: int = 0
var is_altar: bool = false
var rule_slots: Array = []
var altar_slots: Array = []

func _ready() -> void:
    if is_altar:
        var req := DataTables.get_phase(GameState.current_phase).altar_requirement
        altar_slots.resize(req)
        altar_slots.fill(null)
    else:
        var max_rules := DataTables.TILE_MAX_RULES[tile_index] if tile_index < DataTables.TILE_MAX_RULES.size() else 1
        for i in max_rules:
            rule_slots.append({"trigger": null, "effect": null})

func has_enemy() -> bool:
    return enemy != null

func place_enemy(e: Enemy) -> void:
    enemy = e

func clear_enemy() -> void:
    enemy = null

func resize_altar_for_phase(phase: int) -> void:
    var req := DataTables.get_phase(phase).altar_requirement
    altar_slots.resize(req)
    while altar_slots.size() < req:
        altar_slots.append(null)
```

- [ ] **Step 4: Run tests — expect pass**

```
powershell -NoProfile -File scripts/self-test.ps1
```

- [ ] **Step 5: Commit**

```
git add src/entities/Tile.gd tests/unit/test_tile_system.gd
git commit -m "feat: Tile — pass_count, rule_slots (per DataTables), altar_slots"
```

---

## Task 7: RuleEngine — tile rule evaluation + altar bonus + pass_count scaling

**Files:**
- Modify: `src/systems/RuleEngine.gd`
- Test: `tests/unit/test_rule_engine.gd`

- [ ] **Step 1: Write failing tests**

Add to `tests/unit/test_rule_engine.gd`:

```gdscript
func _make_tile_with_rule(tile_idx: int, n: int, effect_id: String, effect_value: float, growth_rate: float = 0.0) -> Tile:
    var tile := Tile.new()
    tile.tile_index = tile_idx
    tile.is_altar = false
    add_child_autofree(tile)

    var t := ComponentData.new()
    t.id = "经过"
    t.slot_type = ComponentData.SlotType.TRIGGER_ONLY
    t.trigger_value = float(n)

    var e := ComponentData.new()
    e.id = effect_id
    e.slot_type = ComponentData.SlotType.EFFECT_ONLY
    e.effect_value = effect_value
    e.growth_rate = growth_rate
    e.scale_exponent = 1.0
    e.max_scale = 0.0
    e.altar_ratio = 0.0

    tile.rule_slots.append({"trigger": t, "effect": e})
    return tile

func test_tile_rule_fires_on_nth_pass() -> void:
    var tile := _make_tile_with_rule(1, 2, "治愈", 10.0)
    engine.set_tiles([null, tile])  # index 0=altar placeholder, index 1=tile
    GameState.hp = 50
    tile.pass_count = 1
    EventBus.tile_passed.emit(1)
    assert_eq(GameState.hp, 50, "should not fire on pass 1 (need 2)")
    tile.pass_count = 2
    EventBus.tile_passed.emit(1)
    assert_eq(GameState.hp, 60, "should fire on pass 2")

func test_tile_rule_does_not_fire_with_incomplete_slot() -> void:
    var tile := Tile.new()
    tile.tile_index = 1
    tile.is_altar = false
    add_child_autofree(tile)
    tile.rule_slots.append({"trigger": null, "effect": null})
    engine.set_tiles([null, tile])
    GameState.hp = 50
    tile.pass_count = 1
    EventBus.tile_passed.emit(1)
    assert_eq(GameState.hp, 50)

func test_tile_rule_scales_with_pass_count() -> void:
    var tile := _make_tile_with_rule(1, 1, "治愈", 10.0, 0.1)
    engine.set_tiles([null, tile])
    GameState.hp = 0
    GameState.hp_max = 9999
    tile.pass_count = 10
    EventBus.tile_passed.emit(1)
    # actual = 10 * (1 + 0.1 * 10) = 10 * 2 = 20
    assert_eq(GameState.hp, 20)

func test_altar_bonus_applied_to_player_rule() -> void:
    _make_rule("受击", 1.0, "治愈", 10.0)
    GameState.altar_bonuses["治愈"] = 5.0
    GameState.hp = 50
    EventBus.player_hit.emit(5)
    assert_eq(GameState.hp, 65, "heal should be 10 base + 5 altar bonus = 15")

func test_altar_bonus_applied_to_tile_rule() -> void:
    var tile := _make_tile_with_rule(1, 1, "治愈", 10.0)
    engine.set_tiles([null, tile])
    GameState.altar_bonuses["治愈"] = 5.0
    GameState.hp = 0
    GameState.hp_max = 9999
    tile.pass_count = 1
    EventBus.tile_passed.emit(1)
    assert_eq(GameState.hp, 15, "heal should be 10 + 5 altar bonus = 15")

func test_max_scale_caps_tile_effect() -> void:
    var tile := _make_tile_with_rule(1, 1, "治愈", 10.0, 1.0)
    tile.rule_slots[0]["effect"].max_scale = 2.0  # cap at 2× base = 20
    engine.set_tiles([null, tile])
    GameState.hp = 0
    GameState.hp_max = 9999
    tile.pass_count = 100  # would be 10*(1+100) = 1010 without cap
    EventBus.tile_passed.emit(1)
    assert_eq(GameState.hp, 20, "should be capped at base * max_scale = 10 * 2 = 20")
```

- [ ] **Step 2: Run tests — expect failure**

```
powershell -NoProfile -File scripts/self-test.ps1
```

- [ ] **Step 3: Rewrite RuleEngine.gd**

```gdscript
class_name RuleEngine
extends Node

var _tiles: Array = []
var _log_file: FileAccess = null

func _ready() -> void:
    _log_file = FileAccess.open("res://tests/rule_debug.log", FileAccess.WRITE)
    EventBus.player_hit.connect(_on_player_hit)
    EventBus.enemy_killed.connect(_on_enemy_killed)
    EventBus.loop_completed.connect(_on_loop_completed)
    EventBus.tile_passed.connect(_on_tile_passed)
    EventBus.rule_fired.connect(_on_rule_fired)

func set_tiles(tiles: Array) -> void:
    _tiles = tiles

func _log(msg: String) -> void:
    if _log_file:
        _log_file.store_line(msg)
        _log_file.flush()
    print(msg)

func _on_player_hit(_damage: int) -> void:
    _evaluate_player_triggers(["受击"])

func _on_rule_fired(_slot_idx: int, effect_id: String, _value: float) -> void:
    if effect_id == "治愈":
        _evaluate_player_triggers(["治愈"])

func _on_enemy_killed(_enemy: Enemy) -> void:
    _evaluate_player_triggers(["击杀"])

func _on_loop_completed() -> void:
    _evaluate_player_triggers(["完成圈数"])

func _on_tile_passed(tile_idx: int) -> void:
    _evaluate_player_triggers(["经过"])
    if tile_idx < _tiles.size() and _tiles[tile_idx] != null:
        _evaluate_tile_rules(_tiles[tile_idx])

func _evaluate_player_triggers(trigger_ids: Array) -> void:
    for i in GameState.rule_slots.size():
        var slot = GameState.rule_slots[i]
        var trigger: ComponentData = slot.get("trigger")
        var effect: ComponentData = slot.get("effect")
        if trigger == null or effect == null:
            continue
        if trigger.id not in trigger_ids:
            continue
        trigger.trigger_count += 1
        _log("[slot%d] T=%s count=%d/%.0f E=%s eff_val=%.2f" % [
            i, trigger.id, trigger.trigger_count, trigger.trigger_value,
            effect.id, effect.effect_value])
        if trigger.trigger_count >= trigger.trigger_value:
            trigger.trigger_count = 0
            _execute_effect(i, effect, 0)

func _evaluate_tile_rules(tile: Tile) -> void:
    for slot in tile.rule_slots:
        var t: ComponentData = slot.get("trigger")
        var e: ComponentData = slot.get("effect")
        if t == null or e == null:
            continue
        var n := int(t.trigger_value)
        if n > 0 and tile.pass_count % n == 0:
            _log("[tile%d] 经过(%d) pass=%d FIRE E=%s" % [tile.tile_index, n, tile.pass_count, e.id])
            _execute_effect(-1, e, tile.pass_count)

func _execute_effect(slot_idx: int, effect: ComponentData, pass_count: int) -> void:
    var exponent := effect.scale_exponent if effect.scale_exponent > 0.0 else 1.0
    var scale_factor := 1.0 + effect.growth_rate * pow(float(pass_count), exponent)
    var scaled := effect.effect_value * scale_factor
    var actual: float
    if effect.max_scale > 0.0:
        actual = min(scaled, effect.effect_value * effect.max_scale)
    else:
        actual = scaled
    var bonus := GameState.altar_bonuses.get(effect.id, 0.0)
    var final_value := actual + bonus

    _log("[FIRE] E=%s pass=%d scale=%.2f actual=%.2f bonus=%.2f final=%.2f hp_before=%d" % [
        effect.id, pass_count, scale_factor, actual, bonus, final_value, GameState.hp])

    match effect.id:
        "治愈":
            GameState.hp = min(GameState.hp + int(final_value), GameState.hp_max)
            EventBus.rule_fired.emit(slot_idx, "治愈", final_value)
        "反射":
            GameState.pending_reflect_ratio = final_value
            EventBus.rule_fired.emit(slot_idx, "反射", final_value)
        _:
            _log("[FIRE] unknown effect id: '" + effect.id + "'")

    _log("[FIRE] hp_after=%d" % GameState.hp)
```

- [ ] **Step 4: Run tests — expect pass**

```
powershell -NoProfile -File scripts/self-test.ps1
```

All prior tests should still pass (player rules unchanged). New tile/altar tests pass.

- [ ] **Step 5: Commit**

```
git add src/systems/RuleEngine.gd tests/unit/test_rule_engine.gd
git commit -m "feat: RuleEngine — tile rule evaluation, altar bonus, pass_count scaling"
```

---

## Task 8: Main — pass_count increment + tile click + reset_tiles

**Files:**
- Modify: `src/Main.gd`

(No unit tests — scene logic; verified in visual integration test in Task 12.)

- [ ] **Step 1: Replace Main.gd**

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
@onready var rule_engine: RuleEngine = $Systems/RuleEngine
@onready var strip_panel: StripPanel = $UI/StripPanel
@onready var inventory_panel: InventoryPanel = $UI/InventoryPanel
@onready var tile_rule_panel = $UI/TileRulePanel
@onready var altar_panel = $UI/AltarPanel
@onready var hud: HUD = $UI/HUD

func _ready() -> void:
    var tiles = _build_tiles()
    player.setup(player_follow, track)
    game_loop.setup(tiles, enemies_container, player, combat_system)
    strip_manager.setup(strip_panel)
    strip_panel.setup(inventory_panel)
    hud.setup(inventory_panel)
    rule_engine.set_tiles(tiles)
    EventBus.player_died.connect(_on_player_died)
    EventBus.phase_changed.connect(_on_phase_changed)

func _build_tiles() -> Array:
    var tiles: Array = []
    var curve = track.curve
    var length = curve.get_baked_length()
    for i in 13:
        var t = float(i) / 12.0
        var pos = curve.sample_baked(t * length)
        var tile: Tile = TILE_SCENE.instantiate()
        tile.tile_index = i
        tile.is_altar = (i == 0)
        tile.position = pos
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
                tile.pass_count += 1
                EventBus.tile_passed.emit(tile.tile_index)
            return

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        var pos = get_global_mouse_position()
        for tile in tiles_container.get_children():
            if pos.distance_to(tile.global_position) < 30.0:
                if tile.is_altar:
                    altar_panel.open(tile)
                else:
                    tile_rule_panel.open(tile)
                return

func reset_tiles() -> void:
    for tile in tiles_container.get_children():
        tile.pass_count = 0
        tile.visited_this_loop = false
        tile.rule_slots.clear()
        if not tile.is_altar:
            var max_rules := DataTables.TILE_MAX_RULES[tile.tile_index] if tile.tile_index < DataTables.TILE_MAX_RULES.size() else 1
            for i in max_rules:
                tile.rule_slots.append({"trigger": null, "effect": null})
        else:
            tile.altar_slots.fill(null)

func _on_player_died() -> void:
    var go = GAME_OVER_SCENE.instantiate()
    add_child(go)

func _on_phase_changed(new_phase: int) -> void:
    # Resize altar slots for new phase requirement
    for tile in tiles_container.get_children():
        if tile.is_altar:
            tile.resize_altar_for_phase(new_phase)
```

- [ ] **Step 2: Run self-test (no regressions)**

```
powershell -NoProfile -File scripts/self-test.ps1
```

- [ ] **Step 3: Commit**

```
git add src/Main.gd
git commit -m "feat: Main — pass_count increment, tile click detection, reset_tiles"
```

---

## Task 9: TileRulePanel — placement and removal UI

**Files:**
- Create: `src/ui/TileRulePanel.gd`
- Create: `scenes/ui/tile_rule_panel.tscn` (via MCP)

- [ ] **Step 1: Create TileRulePanel.gd**

Create `src/ui/TileRulePanel.gd`:

```gdscript
class_name TileRulePanel
extends PanelContainer

var _tile: Tile = null
var _selecting_slot_idx: int = -1
var _selecting_trigger: bool = false

@onready var _title: Label = $VBox/Title
@onready var _slots_container: VBoxContainer = $VBox/Slots
@onready var _inv_picker: VBoxContainer = $VBox/InvPicker
@onready var _inv_label: Label = $VBox/InvPicker/InvLabel
@onready var _inv_grid: GridContainer = $VBox/InvPicker/InvGrid
@onready var _close_btn: Button = $VBox/CloseButton

func _ready() -> void:
    hide()
    _close_btn.pressed.connect(close)

func open(tile: Tile) -> void:
    _tile = tile
    _selecting_slot_idx = -1
    _inv_picker.hide()
    GameState.is_paused = true
    show()
    _refresh()

func close() -> void:
    hide()
    _tile = null
    GameState.is_paused = false

func _refresh() -> void:
    _title.text = "地块 #%d — 经过 %d 次" % [_tile.tile_index, _tile.pass_count]
    _build_slots()

func _build_slots() -> void:
    for child in _slots_container.get_children():
        child.queue_free()

    for i in _tile.rule_slots.size():
        var slot = _tile.rule_slots[i]
        var t: ComponentData = slot["trigger"]
        var e: ComponentData = slot["effect"]

        var hbox := HBoxContainer.new()
        _slots_container.add_child(hbox)

        var t_btn := Button.new()
        t_btn.text = ("%s (%d)" % [t.display_name, int(t.trigger_value)]) if t else "[T 经过]"
        var idx = i
        t_btn.pressed.connect(func(): _on_sub_slot_clicked(idx, true))
        hbox.add_child(t_btn)

        var e_btn := Button.new()
        if e:
            var scale_factor = 1.0 + e.growth_rate * pow(float(_tile.pass_count), e.scale_exponent)
            var val = e.effect_value * scale_factor
            e_btn.text = "%s (%.1f)" % [e.display_name, val]
        else:
            e_btn.text = "[E 空]"
        e_btn.pressed.connect(func(): _on_sub_slot_clicked(idx, false))
        hbox.add_child(e_btn)

        var remove_btn := Button.new()
        var cost = GameState.get_deletion_cost()
        remove_btn.text = "移除 ¥%d" % cost
        remove_btn.disabled = (t == null and e == null) or not GameState.can_afford_deletion()
        remove_btn.pressed.connect(func(): _on_remove_slot(idx))
        hbox.add_child(remove_btn)

func _on_sub_slot_clicked(slot_idx: int, is_trigger: bool) -> void:
    _selecting_slot_idx = slot_idx
    _selecting_trigger = is_trigger
    _show_inv_picker(is_trigger)

func _show_inv_picker(trigger_only: bool) -> void:
    for child in _inv_grid.get_children():
        child.queue_free()
    _inv_label.text = "选择%s组件" % ("经过触发" if trigger_only else "效果")
    for comp in GameState.inventory:
        var ok: bool
        if trigger_only:
            ok = comp.id == "经过"
        else:
            ok = comp.slot_type in [ComponentData.SlotType.EFFECT_ONLY, ComponentData.SlotType.BOTH]
        if not ok:
            continue
        var btn := Button.new()
        btn.text = comp.display_name
        var c = comp
        btn.pressed.connect(func(): _on_inv_pick(c))
        _inv_grid.add_child(btn)
    _inv_picker.show()

func _on_inv_pick(comp: ComponentData) -> void:
    if _selecting_slot_idx < 0:
        return
    var slot = _tile.rule_slots[_selecting_slot_idx]
    var key = "trigger" if _selecting_trigger else "effect"
    var displaced: ComponentData = slot[key]
    if displaced != null:
        GameState.add_to_inventory(displaced)
    slot[key] = comp
    GameState.remove_from_inventory(comp)
    _selecting_slot_idx = -1
    _inv_picker.hide()
    _refresh()

func _on_remove_slot(slot_idx: int) -> void:
    if not GameState.can_afford_deletion():
        return
    GameState.pay_deletion_cost()
    var slot = _tile.rule_slots[slot_idx]
    # Components are destroyed (not returned)
    slot["trigger"] = null
    slot["effect"] = null
    _refresh()
```

- [ ] **Step 2: Create tile_rule_panel.tscn via MCP**

Use `mcp__godot__create_scene` to create `res://scenes/ui/tile_rule_panel.tscn` with this node tree:

```
TileRulePanel (PanelContainer, script=res://src/ui/TileRulePanel.gd)
└── VBox (VBoxContainer)
    ├── Title (Label)
    ├── Slots (VBoxContainer)
    ├── InvPicker (VBoxContainer, visible=false)
    │   ├── InvLabel (Label)
    │   └── InvGrid (GridContainer, columns=3)
    └── CloseButton (Button, text="关闭")
```

Set TileRulePanel minimum size to (400, 300). Position it at center-right of screen (anchors: center).

- [ ] **Step 3: Run self-test (no regressions)**

```
powershell -NoProfile -File scripts/self-test.ps1
```

- [ ] **Step 4: Commit**

```
git add src/ui/TileRulePanel.gd scenes/ui/tile_rule_panel.tscn
git commit -m "feat: TileRulePanel — tile rule placement and removal UI"
```

---

## Task 10: AltarPanel — E-slot placement and activation

**Files:**
- Create: `src/ui/AltarPanel.gd`
- Create: `scenes/ui/altar_panel.tscn` (via MCP)

- [ ] **Step 1: Create AltarPanel.gd**

Create `src/ui/AltarPanel.gd`:

```gdscript
class_name AltarPanel
extends PanelContainer

var _tile: Tile = null

@onready var _title: Label = $VBox/Title
@onready var _progress: Label = $VBox/Progress
@onready var _slots_container: VBoxContainer = $VBox/AltarSlots
@onready var _bonuses_label: Label = $VBox/BonusesLabel
@onready var _activate_btn: Button = $VBox/ActivateButton
@onready var _inv_picker: VBoxContainer = $VBox/InvPicker
@onready var _inv_grid: GridContainer = $VBox/InvPicker/InvGrid
@onready var _close_btn: Button = $VBox/CloseButton

var _selecting_slot_idx: int = -1

func _ready() -> void:
    hide()
    _close_btn.pressed.connect(close)
    _activate_btn.pressed.connect(_on_activate)

func open(tile: Tile) -> void:
    _tile = tile
    _selecting_slot_idx = -1
    _inv_picker.hide()
    GameState.is_paused = true
    show()
    _refresh()

func close() -> void:
    hide()
    _tile = null
    GameState.is_paused = false

func _refresh() -> void:
    var req := _tile.altar_slots.size()
    var filled := 0
    for slot in _tile.altar_slots:
        if slot != null:
            filled += 1

    _title.text = "祭坛 — Phase %d · %s" % [GameState.current_phase, DataTables.get_phase(GameState.current_phase).phase_name]
    _progress.text = "进度 %d / %d" % [filled, req]
    _activate_btn.disabled = filled < req
    _build_altar_slots()
    _build_bonuses_label()

func _build_altar_slots() -> void:
    for child in _slots_container.get_children():
        child.queue_free()

    for i in _tile.altar_slots.size():
        var comp: ComponentData = _tile.altar_slots[i]
        var hbox := HBoxContainer.new()
        _slots_container.add_child(hbox)

        var slot_btn := Button.new()
        if comp:
            var preview_bonus := comp.effect_value * comp.altar_ratio
            slot_btn.text = "%s → +%.2f %s" % [comp.display_name, preview_bonus, comp.id]
        else:
            slot_btn.text = "[空 — 放入E组件]"
        var idx = i
        slot_btn.pressed.connect(func(): _on_altar_slot_clicked(idx))
        hbox.add_child(slot_btn)

        if comp:
            var take_btn := Button.new()
            take_btn.text = "取回"
            take_btn.pressed.connect(func(): _on_take_back(idx))
            hbox.add_child(take_btn)

func _build_bonuses_label() -> void:
    if GameState.altar_bonuses.is_empty():
        _bonuses_label.text = "当前祭坛加成：无"
        return
    var parts := []
    for k in GameState.altar_bonuses:
        parts.append("%s +%.2f" % [k, GameState.altar_bonuses[k]])
    _bonuses_label.text = "当前祭坛加成：" + " / ".join(parts)

func _on_altar_slot_clicked(slot_idx: int) -> void:
    if _tile.altar_slots[slot_idx] != null:
        return
    _selecting_slot_idx = slot_idx
    _show_inv_picker()

func _show_inv_picker() -> void:
    for child in _inv_grid.get_children():
        child.queue_free()
    for comp in GameState.inventory:
        var ok = comp.slot_type in [ComponentData.SlotType.EFFECT_ONLY, ComponentData.SlotType.BOTH]
        if not ok:
            continue
        var btn := Button.new()
        btn.text = "%s (%.1f)" % [comp.display_name, comp.effect_value]
        var c = comp
        btn.pressed.connect(func(): _on_inv_pick(c))
        _inv_grid.add_child(btn)
    _inv_picker.show()

func _on_inv_pick(comp: ComponentData) -> void:
    if _selecting_slot_idx < 0:
        return
    _tile.altar_slots[_selecting_slot_idx] = comp
    GameState.remove_from_inventory(comp)
    _selecting_slot_idx = -1
    _inv_picker.hide()
    _refresh()

func _on_take_back(slot_idx: int) -> void:
    var comp: ComponentData = _tile.altar_slots[slot_idx]
    if comp == null:
        return
    _tile.altar_slots[slot_idx] = null
    GameState.add_to_inventory(comp)
    _refresh()

func _on_activate() -> void:
    for comp in _tile.altar_slots:
        if comp == null:
            continue
        var bonus := comp.effect_value * comp.altar_ratio
        GameState.altar_bonuses[comp.id] = GameState.altar_bonuses.get(comp.id, 0.0) + bonus
    _tile.altar_slots.fill(null)
    GameState.current_phase += 1
    EventBus.phase_changed.emit(GameState.current_phase)
    close()
```

- [ ] **Step 2: Create altar_panel.tscn via MCP**

Use `mcp__godot__create_scene` to create `res://scenes/ui/altar_panel.tscn` with this node tree:

```
AltarPanel (PanelContainer, script=res://src/ui/AltarPanel.gd)
└── VBox (VBoxContainer)
    ├── Title (Label)
    ├── Progress (Label)
    ├── AltarSlots (VBoxContainer)
    ├── BonusesLabel (Label)
    ├── ActivateButton (Button, text="激活祭坛")
    ├── InvPicker (VBoxContainer, visible=false)
    │   └── InvGrid (GridContainer, columns=3)
    └── CloseButton (Button, text="关闭")
```

Set AltarPanel minimum size to (450, 350). Position at center of screen.

- [ ] **Step 3: Run self-test**

```
powershell -NoProfile -File scripts/self-test.ps1
```

- [ ] **Step 4: Commit**

```
git add src/ui/AltarPanel.gd scenes/ui/altar_panel.tscn
git commit -m "feat: AltarPanel — E-slot placement, bonus preview, Phase activation"
```

---

## Task 11: HUD + InventoryPanel — gold display + deletion cost

**Files:**
- Modify: `src/ui/HUD.gd`
- Modify: `src/ui/InventoryPanel.gd`

- [ ] **Step 1: Add gold label to HUD**

In `src/ui/HUD.gd`, add after the `@onready var bag_btn` line:

```gdscript
@onready var gold_label: Label = $BottomBar/HContent/GoldPill/GoldLabel
```

In `_process()`, add after the `bag_btn.text` line:

```gdscript
gold_label.text = "金: %d" % GameState.gold
```

- [ ] **Step 2: Add GoldPill node to hud.tscn via MCP**

Use `mcp__godot__create_node` to add a `GoldPill` (PanelContainer) with a child `GoldLabel` (Label) inside the existing `$BottomBar/HContent`, positioned between `PhasePill` and `RulePanel0`. Set GoldLabel text to "金: 0".

- [ ] **Step 3: Update InventoryPanel deletion to cost gold**

In `src/ui/InventoryPanel.gd`, replace `_on_delete()`:

```gdscript
func _on_delete() -> void:
    if _selected == null:
        return
    if not GameState.can_afford_deletion():
        return
    for i in GameState.rule_slots.size():
        var slot = GameState.rule_slots[i]
        if slot["trigger"] == _selected:
            slot["trigger"] = null
        if slot["effect"] == _selected:
            slot["effect"] = null
    GameState.pay_deletion_cost()
    GameState.delete_component(_selected)
    _selected = null
    _delete_btn.hide()
    _refresh()
```

Also update `_select()` to show cost on delete button:

```gdscript
func _select(comp: ComponentData) -> void:
    _selected = comp
    var cost = GameState.get_deletion_cost()
    _delete_btn.text = "删除 ¥%d" % cost
    _delete_btn.disabled = not GameState.can_afford_deletion()
    _delete_btn.show()
    _refresh()
```

- [ ] **Step 4: Run self-test**

```
powershell -NoProfile -File scripts/self-test.ps1
```

- [ ] **Step 5: Commit**

```
git add src/ui/HUD.gd src/ui/InventoryPanel.gd
git commit -m "feat: HUD gold display; InventoryPanel deletion costs gold with affordability check"
```

---

## Task 12: Wire up main.tscn + update .tres data

**Files:**
- Modify: `scenes/main.tscn` (via MCP)
- Modify: `data/game_config.tres`
- Modify: `data/enemies/enemy_汲取者.tres`
- Modify: `data/enemies/enemy_守卫者.tres`

- [ ] **Step 1: Add EconomyManager to main.tscn**

Use `mcp__godot__create_node` to add an `EconomyManager` node (script=`res://src/systems/EconomyManager.gd`) as a child of `$Systems` in main.tscn.

- [ ] **Step 2: Add TileRulePanel and AltarPanel to main.tscn**

Use `mcp__godot__create_node` to add:
- `TileRulePanel` (scene instance of `res://scenes/ui/tile_rule_panel.tscn`) as child of `$UI`
- `AltarPanel` (scene instance of `res://scenes/ui/altar_panel.tscn`) as child of `$UI`

- [ ] **Step 3: Update game_config.tres with deletion cost defaults**

Edit `data/game_config.tres` — add fields (the GDScript defaults already apply, but make them explicit):

```
deletion_cost_sequence = Array[int]([20, 50, 100])
deletion_cost_multiplier = 2.0
```

- [ ] **Step 4: Add gold_scale to enemy .tres files**

Edit `data/enemies/enemy_汲取者.tres` — add:
```
gold_scale = 0.3
```

Edit `data/enemies/enemy_守卫者.tres` — add:
```
gold_scale = 0.3
```

- [ ] **Step 5: Run full self-test**

```
powershell -NoProfile -File scripts/self-test.ps1
```

All tests must pass.

- [ ] **Step 6: Visual integration test**

Follow CLAUDE.md Step 3: create `tests/.test_mode`, play main scene via MCP, poll for screenshot, verify no errors, delete `tests/.test_mode`.

- [ ] **Step 7: Write module docs**

Write `docs/modules/tile-system.md` covering Tile, TileRulePanel, AltarPanel, EconomyManager responsibilities and data flow.

- [ ] **Step 8: Final commit**

```
git add scenes/main.tscn data/game_config.tres data/enemies/enemy_汲取者.tres data/enemies/enemy_守卫者.tres docs/modules/tile-system.md
git commit -m "feat: Phase 3 complete — tile rules, altar, gold economy wired to main.tscn"
```

---

## Self-Review Checklist

| Spec requirement | Covered by |
|-----------------|-----------|
| Tile T slot only 经过(N) | Task 9 — TileRulePanel filters trigger picker to `id == "经过"` |
| Tile E slot any effect | Task 9 — filter `EFFECT_ONLY \| BOTH` |
| Max rules per tile from DataTables | Task 3 + Task 6 |
| pass_count increments per visit | Task 8 |
| pass_count scaling formula with exponent + cap | Task 1 (fields) + Task 7 (RuleEngine) |
| Tile click opens panel | Task 8 (_unhandled_input) |
| Altar E-only | Task 10 — picker filters E only |
| Altar bonus formula base_value × altar_ratio | Task 10 (_on_activate) |
| Altar bonus applied to all effects | Task 7 (RuleEngine._execute_effect) |
| Phase advances on altar activation | Task 10 (_on_activate emits phase_changed) |
| Enemy rescales after phase change | Implicit — GameLoop.spawn_enemies() reads current_phase at spawn time |
| Gold drops from kills with gold_scale | Task 5 (EconomyManager) |
| Deletion costs gold, escalating | Task 4 (GameState helpers) + Task 11 |
| Tile rule removal costs gold | Task 9 (TileRulePanel._on_remove_slot) |
| HUD gold display | Task 11 |
| DataTables TILE_MAX_RULES configurable | Task 3 |
| GameConfig deletion_cost_sequence configurable | Task 2 |
| reset_tiles on game over | Task 8 (reset_tiles defined; called from existing _on_player_died path — wire in Task 12) |
