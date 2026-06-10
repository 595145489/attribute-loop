# New Components (3 Triggers + 3 Effects) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add triggers 低血/满血/规则触发 and effects 护盾/减速/吸血 to the component system, wiring them through data files, GameState, CombatSystem, RuleEngine, icons, and HUD.

**Architecture:** Time-based triggers (低血, 满血) use a 1-second `_process()` timer in RuleEngine. 规则触发 listens to the existing `rule_fired` signal with a `_firing_rule_trigger` guard to prevent cascade loops. Three new stats (`shield`, `slow_stacks`, `lifesteal_ratio`) live in GameState and are consumed by CombatSystem per-attack.

**Tech Stack:** Godot 4 GDScript, GUT test framework (`extends GutTest`), `.tres` resource files

---

### Task 1: Data files + DataTables registration

**Files:**
- Create: `data/components/trigger_低血.tres`
- Create: `data/components/trigger_满血.tres`
- Create: `data/components/trigger_规则触发.tres`
- Create: `data/components/effect_护盾.tres`
- Create: `data/components/effect_减速.tres`
- Create: `data/components/effect_吸血.tres`
- Modify: `src/autoloads/DataTables.gd`

- [ ] **Step 1: Create trigger_低血.tres**

Write `data/components/trigger_低血.tres`:
```
[gd_resource type="Resource" script_class="ComponentData" format=3 uid="uid://bxktw5d7vym11"]

[ext_resource type="Script" uid="uid://7v3b3h3e3hi4" path="res://src/resources/ComponentData.gd" id="1_new01"]

[resource]
script = ExtResource("1_new01")
id = "低血"
display_name = "低血"
description = "低血时每N秒触发"
trigger_formula = "fires_every"
```

- [ ] **Step 2: Create trigger_满血.tres**

Write `data/components/trigger_满血.tres`:
```
[gd_resource type="Resource" script_class="ComponentData" format=3 uid="uid://dx3r8c9f2jqp5"]

[ext_resource type="Script" uid="uid://7v3b3h3e3hi4" path="res://src/resources/ComponentData.gd" id="1_new02"]

[resource]
script = ExtResource("1_new02")
id = "满血"
display_name = "满血"
description = "满血时每N秒触发"
trigger_formula = "fires_every"
```

- [ ] **Step 3: Create trigger_规则触发.tres**

Write `data/components/trigger_规则触发.tres`:
```
[gd_resource type="Resource" script_class="ComponentData" format=3 uid="uid://cpqm7v4h5snw8"]

[ext_resource type="Script" uid="uid://7v3b3h3e3hi4" path="res://src/resources/ComponentData.gd" id="1_new03"]

[resource]
script = ExtResource("1_new03")
id = "规则触发"
display_name = "规则触发"
description = "每N次规则触发后触发"
trigger_formula = "fires_every"
```

- [ ] **Step 4: Create effect_护盾.tres**

Write `data/components/effect_护盾.tres`:
```
[gd_resource type="Resource" script_class="ComponentData" format=3 uid="uid://bfyr3e6k9tzw2"]

[ext_resource type="Script" uid="uid://7v3b3h3e3hi4" path="res://src/resources/ComponentData.gd" id="1_new04"]

[resource]
script = ExtResource("1_new04")
id = "护盾"
display_name = "护盾"
description = "触发时获得吸伤护盾"
slot_type = 1
effect_formula = "shield"
growth_rate = 0.2
altar_ratio = 0.1
```

- [ ] **Step 5: Create effect_减速.tres**

Write `data/components/effect_减速.tres`:
```
[gd_resource type="Resource" script_class="ComponentData" format=3 uid="uid://dhms4p7n2xvc6"]

[ext_resource type="Script" uid="uid://7v3b3h3e3hi4" path="res://src/resources/ComponentData.gd" id="1_new05"]

[resource]
script = ExtResource("1_new05")
id = "减速"
display_name = "减速"
description = "触发时叠加减速层，每层减少敌人10%伤害"
slot_type = 1
effect_formula = "slow"
growth_rate = 0.0
altar_ratio = 0.05
```

- [ ] **Step 6: Create effect_吸血.tres**

Write `data/components/effect_吸血.tres`:
```
[gd_resource type="Resource" script_class="ComponentData" format=3 uid="uid://ck8j5q3r1btu4"]

[ext_resource type="Script" uid="uid://7v3b3h3e3hi4" path="res://src/resources/ComponentData.gd" id="1_new06"]

[resource]
script = ExtResource("1_new06")
id = "吸血"
display_name = "吸血"
description = "触发时获得吸血比率，攻击后回血"
slot_type = 1
effect_formula = "lifesteal"
growth_rate = 0.1
altar_ratio = 0.05
```

- [ ] **Step 7: Register in DataTables**

In `src/autoloads/DataTables.gd`, replace `_load_components()`:

```gdscript
func _load_components() -> void:
	var paths = [
		"res://data/components/trigger_受击.tres",
		"res://data/components/trigger_击杀.tres",
		"res://data/components/trigger_完成圈数.tres",
		"res://data/components/trigger_经过.tres",
		"res://data/components/both_治愈.tres",
		"res://data/components/both_反射.tres",
		"res://data/components/trigger_低血.tres",
		"res://data/components/trigger_满血.tres",
		"res://data/components/trigger_规则触发.tres",
		"res://data/components/effect_护盾.tres",
		"res://data/components/effect_减速.tres",
		"res://data/components/effect_吸血.tres",
	]
	for path in paths:
		var c: ComponentData = load(path)
		components[c.id] = c
```

- [ ] **Step 8: Run tests**

```bash
cd "S:/attribute-loop" && powershell -NoProfile -File scripts/self-test.ps1
```

Expected: All tests pass (DataTables test verifies load without crash)

- [ ] **Step 9: Commit**

```bash
git add data/components/trigger_低血.tres data/components/trigger_满血.tres data/components/trigger_规则触发.tres data/components/effect_护盾.tres data/components/effect_减速.tres data/components/effect_吸血.tres src/autoloads/DataTables.gd
git commit -m "feat: add 6 new component data files and register in DataTables"
```

---

### Task 2: GameState — shield, slow_stacks, lifesteal_ratio

**Files:**
- Modify: `src/autoloads/GameState.gd`
- Modify: `tests/unit/test_game_state.gd`

- [ ] **Step 1: Write failing tests**

Append to `tests/unit/test_game_state.gd`:

```gdscript
func test_shield_absorbs_damage_before_hp() -> void:
	GameState.shield = 30
	var hp_before = GameState.hp
	GameState.take_damage(20)
	assert_eq(GameState.shield, 10)
	assert_eq(GameState.hp, hp_before)

func test_shield_depletes_then_overflow_hits_hp() -> void:
	GameState.shield = 10
	var hp_before = GameState.hp
	GameState.take_damage(20)
	assert_eq(GameState.shield, 0)
	assert_eq(GameState.hp, hp_before - 10)

func test_shield_resets_to_zero_on_reset() -> void:
	GameState.shield = 50
	GameState.reset()
	assert_eq(GameState.shield, 0)

func test_slow_stacks_resets_to_zero_on_reset() -> void:
	GameState.slow_stacks = 5
	GameState.reset()
	assert_eq(GameState.slow_stacks, 0)

func test_lifesteal_ratio_resets_to_zero_on_reset() -> void:
	GameState.lifesteal_ratio = 0.5
	GameState.reset()
	assert_almost_eq(GameState.lifesteal_ratio, 0.0, 0.001)
```

- [ ] **Step 2: Run to confirm FAIL**

```bash
cd "S:/attribute-loop" && powershell -NoProfile -File scripts/self-test.ps1
```

Expected: Tests fail with "Invalid get index 'shield' on base 'Node'"

- [ ] **Step 3: Add new vars to GameState**

In `src/autoloads/GameState.gd`, add three vars after `pending_reflect_ratio`:

```gdscript
var pending_reflect_ratio: float = 0.0
var shield: int = 0
var slow_stacks: int = 0
var lifesteal_ratio: float = 0.0
```

- [ ] **Step 4: Update reset()**

In `reset()`, add after `pending_reflect_ratio = 0.0`:

```gdscript
pending_reflect_ratio = 0.0
shield = 0
slow_stacks = 0
lifesteal_ratio = 0.0
```

- [ ] **Step 5: Update take_damage() for shield absorption**

Replace `take_damage()`:

```gdscript
func take_damage(amount: int) -> void:
	if shield > 0:
		var absorbed := mini(shield, amount)
		shield -= absorbed
		amount -= absorbed
	if amount > 0:
		hp = max(0, hp - amount)
		if hp == 0:
			EventBus.player_died.emit()
```

- [ ] **Step 6: Run to confirm PASS**

```bash
cd "S:/attribute-loop" && powershell -NoProfile -File scripts/self-test.ps1
```

Expected: All tests pass

- [ ] **Step 7: Commit**

```bash
git add src/autoloads/GameState.gd tests/unit/test_game_state.gd
git commit -m "feat: add shield, slow_stacks, lifesteal_ratio to GameState with shield damage absorption"
```

---

### Task 3: CombatSystem — slow reduction + lifesteal heal

**Files:**
- Modify: `src/systems/CombatSystem.gd`
- Modify: `tests/unit/test_combat_system.gd`

- [ ] **Step 1: Write failing tests**

Append to `tests/unit/test_combat_system.gd`:

```gdscript
func test_slow_stacks_reduce_enemy_damage() -> void:
	GameState.slow_stacks = 3
	var enemy = Enemy.new()
	enemy.init("汲取者")
	var hp_before = GameState.hp
	combat._apply_enemy_attack(enemy)
	var expected_dmg = int(enemy.dmg * (1.0 - 0.3))
	assert_eq(GameState.hp, hp_before - expected_dmg)

func test_slow_stacks_capped_at_80_percent_reduction() -> void:
	GameState.slow_stacks = 10
	var enemy = Enemy.new()
	enemy.init("汲取者")
	var hp_before = GameState.hp
	combat._apply_enemy_attack(enemy)
	var expected_dmg = int(enemy.dmg * 0.2)
	assert_eq(GameState.hp, hp_before - expected_dmg)

func test_lifesteal_heals_after_player_attack() -> void:
	GameState.lifesteal_ratio = 0.5
	GameState.hp = 100
	var enemy = Enemy.new()
	enemy.init("汲取者")
	combat._apply_player_attack(enemy)
	var expected_heal = int(DataTables.player.dmg_base * 0.5)
	assert_eq(GameState.hp, min(100 + expected_heal, GameState.hp_max))

func test_lifesteal_capped_at_hp_max() -> void:
	GameState.lifesteal_ratio = 99.0
	GameState.hp = GameState.hp_max - 1
	var enemy = Enemy.new()
	enemy.init("汲取者")
	combat._apply_player_attack(enemy)
	assert_eq(GameState.hp, GameState.hp_max)

func test_no_lifesteal_when_ratio_zero() -> void:
	GameState.lifesteal_ratio = 0.0
	GameState.hp = 100
	var enemy = Enemy.new()
	enemy.init("汲取者")
	combat._apply_player_attack(enemy)
	assert_eq(GameState.hp, 100)
```

- [ ] **Step 2: Run to confirm FAIL**

```bash
cd "S:/attribute-loop" && powershell -NoProfile -File scripts/self-test.ps1
```

Expected: New combat tests fail — slow/lifesteal not yet applied

- [ ] **Step 3: Implement**

In `src/systems/CombatSystem.gd`, replace `_apply_player_attack` and `_apply_enemy_attack`:

```gdscript
func _apply_player_attack(enemy: Enemy) -> void:
	enemy.take_damage(DataTables.player.dmg_base)
	if GameState.lifesteal_ratio > 0.0:
		var heal := int(DataTables.player.dmg_base * GameState.lifesteal_ratio)
		GameState.hp = min(GameState.hp + heal, GameState.hp_max)
	if enemy.is_dead():
		_finish_combat(enemy)

func _apply_enemy_attack(enemy: Enemy) -> void:
	var dmg := enemy.dmg
	if GameState.slow_stacks > 0:
		var reduction := minf(GameState.slow_stacks * 0.1, 0.8)
		dmg = int(dmg * (1.0 - reduction))
	GameState.take_damage(dmg)
	EventBus.player_hit.emit(dmg)
	if GameState.pending_reflect_ratio > 0.0:
		enemy.take_damage(int(dmg * GameState.pending_reflect_ratio))
		GameState.pending_reflect_ratio = 0.0
```

- [ ] **Step 4: Run to confirm PASS**

```bash
cd "S:/attribute-loop" && powershell -NoProfile -File scripts/self-test.ps1
```

Expected: All tests pass

- [ ] **Step 5: Commit**

```bash
git add src/systems/CombatSystem.gd tests/unit/test_combat_system.gd
git commit -m "feat: apply slow damage reduction and lifesteal heal in CombatSystem"
```

---

### Task 4: RuleEngine — time-based triggers (低血, 满血)

**Files:**
- Modify: `src/systems/RuleEngine.gd`
- Modify: `tests/unit/test_rule_engine.gd`

- [ ] **Step 1: Write failing tests**

Append to `tests/unit/test_rule_engine.gd`:

```gdscript
func test_low_hp_trigger_counts_when_hp_below_threshold() -> void:
	_make_rule("低血", 3.0, "治愈", 10.0)
	GameState.hp = int(GameState.hp_max * 0.29)
	var t = GameState.rule_slots[0]["trigger"]
	engine._check_state_triggers()
	assert_eq(t.trigger_count, 1)

func test_low_hp_trigger_does_not_count_at_normal_hp() -> void:
	_make_rule("低血", 3.0, "治愈", 10.0)
	GameState.hp = int(GameState.hp_max * 0.5)
	var t = GameState.rule_slots[0]["trigger"]
	engine._check_state_triggers()
	assert_eq(t.trigger_count, 0)

func test_low_hp_trigger_fires_after_n_checks() -> void:
	_make_rule("低血", 2.0, "治愈", 20.0)
	GameState.hp_max = 9999
	GameState.hp = 50
	engine._check_state_triggers()
	engine._check_state_triggers()
	assert_eq(GameState.hp, 70)

func test_full_hp_trigger_counts_when_at_max() -> void:
	_make_rule("满血", 2.0, "治愈", 10.0)
	GameState.hp = GameState.hp_max
	var t = GameState.rule_slots[0]["trigger"]
	engine._check_state_triggers()
	assert_eq(t.trigger_count, 1)

func test_full_hp_trigger_does_not_count_below_max() -> void:
	_make_rule("满血", 2.0, "治愈", 10.0)
	GameState.hp = GameState.hp_max - 1
	var t = GameState.rule_slots[0]["trigger"]
	engine._check_state_triggers()
	assert_eq(t.trigger_count, 0)
```

- [ ] **Step 2: Run to confirm FAIL**

```bash
cd "S:/attribute-loop" && powershell -NoProfile -File scripts/self-test.ps1
```

Expected: Tests fail with "Invalid call. Nonexistent function '_check_state_triggers'"

- [ ] **Step 3: Implement**

In `src/systems/RuleEngine.gd`, add two new class-level vars after `var _tiles: Array = []`:

```gdscript
var _tiles: Array = []
var _state_timer: float = 0.0
const _STATE_INTERVAL: float = 1.0
```

Then add `_process()` and `_check_state_triggers()` after `set_tiles()`:

```gdscript
func _process(delta: float) -> void:
	_state_timer += delta
	if _state_timer >= _STATE_INTERVAL:
		_state_timer = 0.0
		_check_state_triggers()

func _check_state_triggers() -> void:
	if float(GameState.hp) / float(GameState.hp_max) < 0.3:
		_evaluate_player_triggers(["低血"])
	if GameState.hp >= GameState.hp_max:
		_evaluate_player_triggers(["满血"])
```

- [ ] **Step 4: Run to confirm PASS**

```bash
cd "S:/attribute-loop" && powershell -NoProfile -File scripts/self-test.ps1
```

Expected: All tests pass

- [ ] **Step 5: Commit**

```bash
git add src/systems/RuleEngine.gd tests/unit/test_rule_engine.gd
git commit -m "feat: add time-based triggers 低血 and 满血 to RuleEngine"
```

---

### Task 5: RuleEngine — 规则触发 trigger

**Files:**
- Modify: `src/systems/RuleEngine.gd`
- Modify: `tests/unit/test_rule_engine.gd`

- [ ] **Step 1: Write failing tests**

Append to `tests/unit/test_rule_engine.gd`:

```gdscript
func test_rule_fire_trigger_counts_on_rule_fire() -> void:
	_make_rule("受击", 1.0, "治愈", 10.0)
	_make_rule_slot1("规则触发", 2.0, "反射", 0.3)
	var t = GameState.rule_slots[1]["trigger"]
	GameState.hp = 50
	EventBus.player_hit.emit(5)
	assert_eq(t.trigger_count, 1, "should count 1 after one rule fire")
	assert_almost_eq(GameState.pending_reflect_ratio, 0.0, 0.001, "should not fire yet")

func test_rule_fire_trigger_fires_at_threshold() -> void:
	_make_rule("受击", 1.0, "治愈", 10.0)
	_make_rule_slot1("规则触发", 2.0, "反射", 0.3)
	GameState.hp = 50
	EventBus.player_hit.emit(5)
	EventBus.player_hit.emit(5)
	assert_almost_eq(GameState.pending_reflect_ratio, 0.3, 0.001, "should fire after 2 rule fires")

func test_rule_fire_trigger_no_infinite_loop() -> void:
	_make_rule("规则触发", 1.0, "治愈", 10.0)
	_make_rule_slot1("受击", 1.0, "反射", 0.1)
	GameState.hp = 50
	EventBus.player_hit.emit(5)
	assert_eq(GameState.hp, 60, "heal fired once, no infinite loop")
```

- [ ] **Step 2: Run to confirm FAIL**

```bash
cd "S:/attribute-loop" && powershell -NoProfile -File scripts/self-test.ps1
```

Expected: 规则触发 tests fail — trigger count stays 0

- [ ] **Step 3: Implement**

In `src/systems/RuleEngine.gd`, add `_firing_rule_trigger` to the class-level vars section (alongside `_tiles`, `_state_timer`):

```gdscript
var _tiles: Array = []
var _state_timer: float = 0.0
var _firing_rule_trigger: bool = false
const _STATE_INTERVAL: float = 1.0
```

Replace `_on_rule_fired`:

```gdscript
func _on_rule_fired(_slot_idx: int, effect_id: String, _value: float) -> void:
	if effect_id == "治愈":
		_evaluate_player_triggers(["治愈"])
	if not _firing_rule_trigger:
		_firing_rule_trigger = true
		_evaluate_player_triggers(["规则触发"])
		_firing_rule_trigger = false
```

- [ ] **Step 4: Run to confirm PASS**

```bash
cd "S:/attribute-loop" && powershell -NoProfile -File scripts/self-test.ps1
```

Expected: All tests pass

- [ ] **Step 5: Commit**

```bash
git add src/systems/RuleEngine.gd tests/unit/test_rule_engine.gd
git commit -m "feat: add 规则触发 trigger with cascade guard to RuleEngine"
```

---

### Task 6: RuleEngine — new effect cases (护盾, 减速, 吸血)

**Files:**
- Modify: `src/systems/RuleEngine.gd`
- Modify: `tests/unit/test_rule_engine.gd`

- [ ] **Step 1: Write failing tests**

Append to `tests/unit/test_rule_engine.gd`:

```gdscript
func test_shield_effect_adds_to_gamestate_shield() -> void:
	_make_rule("受击", 1.0, "护盾", 50.0)
	EventBus.player_hit.emit(5)
	assert_eq(GameState.shield, 50)

func test_shield_effect_accumulates() -> void:
	_make_rule("受击", 1.0, "护盾", 30.0)
	EventBus.player_hit.emit(5)
	EventBus.player_hit.emit(5)
	assert_eq(GameState.shield, 60)

func test_slow_effect_adds_slow_stacks() -> void:
	_make_rule("受击", 1.0, "减速", 2.0)
	EventBus.player_hit.emit(5)
	assert_eq(GameState.slow_stacks, 2)

func test_slow_effect_accumulates() -> void:
	_make_rule("受击", 1.0, "减速", 1.0)
	EventBus.player_hit.emit(5)
	EventBus.player_hit.emit(5)
	assert_eq(GameState.slow_stacks, 2)

func test_lifesteal_effect_adds_to_lifesteal_ratio() -> void:
	_make_rule("受击", 1.0, "吸血", 0.1)
	EventBus.player_hit.emit(5)
	assert_almost_eq(GameState.lifesteal_ratio, 0.1, 0.001)

func test_rule_fired_signal_emitted_for_shield() -> void:
	watch_signals(EventBus)
	_make_rule("受击", 1.0, "护盾", 30.0)
	EventBus.player_hit.emit(5)
	assert_signal_emitted(EventBus, "rule_fired")
```

- [ ] **Step 2: Run to confirm FAIL**

```bash
cd "S:/attribute-loop" && powershell -NoProfile -File scripts/self-test.ps1
```

Expected: New effect tests fail — shield/slow/lifesteal stay 0

- [ ] **Step 3: Implement**

In `src/systems/RuleEngine.gd`, replace the `match effect.id` block in `_execute_effect()`:

```gdscript
	match effect.id:
		"治愈":
			GameState.hp = min(GameState.hp + int(final_value), GameState.hp_max)
			EventBus.rule_fired.emit(slot_idx, "治愈", final_value)
		"反射":
			GameState.pending_reflect_ratio = final_value
			EventBus.rule_fired.emit(slot_idx, "反射", final_value)
		"护盾":
			GameState.shield += int(final_value)
			EventBus.rule_fired.emit(slot_idx, "护盾", final_value)
		"减速":
			GameState.slow_stacks += int(final_value)
			EventBus.rule_fired.emit(slot_idx, "减速", final_value)
		"吸血":
			GameState.lifesteal_ratio += final_value
			EventBus.rule_fired.emit(slot_idx, "吸血", final_value)
```

- [ ] **Step 4: Run to confirm PASS**

```bash
cd "S:/attribute-loop" && powershell -NoProfile -File scripts/self-test.ps1
```

Expected: All tests pass

- [ ] **Step 5: Commit**

```bash
git add src/systems/RuleEngine.gd tests/unit/test_rule_engine.gd
git commit -m "feat: add 护盾, 减速, 吸血 effect cases to RuleEngine"
```

---

### Task 7: ComponentIcons + HUD shield display + effect labels

**Files:**
- Modify: `src/ui/ComponentIcons.gd`
- Modify: `src/ui/HUD.gd`
- Modify: `tests/unit/test_component_icons.gd`

- [ ] **Step 1: Write failing icon test**

In `tests/unit/test_component_icons.gd`, replace `test_all_implemented_components_have_icons`:

```gdscript
func test_all_implemented_components_have_icons() -> void:
	for id in ["受击", "击杀", "完成圈数", "经过", "治愈", "反射",
			   "低血", "满血", "规则触发", "护盾", "减速", "吸血"]:
		assert_not_null(ComponentIcons.get_icon(id), "Missing icon for '%s'" % id)
```

- [ ] **Step 2: Run to confirm FAIL**

```bash
cd "S:/attribute-loop" && powershell -NoProfile -File scripts/self-test.ps1
```

Expected: `test_all_implemented_components_have_icons` fails for the 6 new IDs

- [ ] **Step 3: Add icon mappings**

In `src/ui/ComponentIcons.gd`, replace `_ICON_MAP`:

```gdscript
const _ICON_MAP: Dictionary = {
	"受击":    "res://resources/icons/trigger_hit.png",
	"击杀":    "res://resources/icons/trigger_kill.png",
	"完成圈数": "res://resources/icons/trigger_loop.png",
	"经过":    "res://resources/icons/trigger_pass.png",
	"治愈":    "res://resources/icons/effect_heal.png",
	"反射":    "res://resources/icons/effect_reflect.png",
	"低血":    "res://resources/icons/trigger_low_hp.png",
	"满血":    "res://resources/icons/trigger_full_hp.png",
	"规则触发": "res://resources/icons/trigger_rule_fire.png",
	"护盾":    "res://resources/icons/effect_shield.png",
	"减速":    "res://resources/icons/effect_slow.png",
	"吸血":    "res://resources/icons/effect_lifesteal.png",
}
```

- [ ] **Step 4: Run to confirm icons PASS**

```bash
cd "S:/attribute-loop" && powershell -NoProfile -File scripts/self-test.ps1
```

Expected: All tests pass

- [ ] **Step 5: Add shield label to HUD**

In `src/ui/HUD.gd`:

After the last `@onready` declaration, add:
```gdscript
var shield_label: Label = null
```

In `_ready()`, after `float_label.hide()`, add:
```gdscript
var vbox := hp_label.get_parent()
shield_label = Label.new()
shield_label.name = "ShieldLabel"
shield_label.add_theme_color_override("font_color", Color(0.5, 0.7, 1.0))
vbox.add_child(shield_label)
shield_label.hide()
```

In `_process()`, after `hp_bar.value = GameState.hp`, add:
```gdscript
if shield_label != null:
    if GameState.shield > 0:
        shield_label.text = "护盾: %d" % GameState.shield
        shield_label.show()
    else:
        shield_label.hide()
```

- [ ] **Step 6: Update rule panel display for new effects**

In `_update_rule_panel()`, replace the `match e.id` block:

```gdscript
	match e.id:
		"治愈":
			_e_value[i].text = "+%d" % int(e.effect_value)
		"反射":
			_e_value[i].text = "%d%%" % int(e.effect_value * 100)
		"护盾":
			_e_value[i].text = "+%d" % int(e.effect_value)
		"减速":
			_e_value[i].text = "×%d层" % int(e.effect_value)
		"吸血":
			_e_value[i].text = "%d%%" % int(e.effect_value * 100)
		_:
			_e_value[i].text = ""
```

- [ ] **Step 7: Update floating label for new effects**

In `src/ui/HUD.gd`, replace `_on_rule_fired`:

```gdscript
func _on_rule_fired(_slot_idx: int, effect_id: String, value: float) -> void:
	match effect_id:
		"治愈":
			float_label.text = "+%.0f 治愈" % value
		"反射":
			float_label.text = "反射 %.0f%%" % (value * 100)
		"护盾":
			float_label.text = "+%.0f 护盾" % value
		"减速":
			float_label.text = "减速 ×%.0f层" % value
		"吸血":
			float_label.text = "吸血 %.0f%%" % (value * 100)
		_:
			float_label.text = effect_id
	float_label.show()
	float_label.modulate = Color.WHITE
	if _float_tween:
		_float_tween.kill()
	_float_tween = create_tween()
	_float_tween.tween_property(float_label, "modulate:a", 0.0, 1.0)
	_float_tween.tween_callback(float_label.hide)
```

- [ ] **Step 8: Run all tests**

```bash
cd "S:/attribute-loop" && powershell -NoProfile -File scripts/self-test.ps1
```

Expected: All tests pass

- [ ] **Step 9: Commit**

```bash
git add src/ui/ComponentIcons.gd src/ui/HUD.gd tests/unit/test_component_icons.gd
git commit -m "feat: register new icons, add shield HUD label, update rule panel and float labels"
```
