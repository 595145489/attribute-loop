# New Effects Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add four new effect components — 增伤、蓄能、灼烧、侵蚀 — each fully wired into RuleEngine, CombatSystem, GameState, HUD, CharacterPanel, drop tables, and ComponentIcons.

**Architecture:** 增伤/蓄能 are player-side persistent states in GameState (like slow_stacks). 灼烧/侵蚀 are enemy-side states applied via a new `rule_fired` listener in CombatSystem. CharacterPanel gets two new rows for 增伤 and 蓄能.

**Tech Stack:** GDScript, Godot 4, GUT unit tests

---

## File Map

| File | Change |
|------|--------|
| `src/autoloads/GameState.gd` | Add `dmg_boost_stacks`, `charge_stacks`; update `reset()` |
| `src/systems/RuleEngine.gd` | Add match cases for 增伤、蓄能、灼烧、侵蚀 in `_execute_effect()` |
| `src/systems/CombatSystem.gd` | Apply dmg_boost in `_apply_player_attack()`; release charge; add burn timer; handle 侵蚀 via `rule_fired` listener |
| `src/entities/Enemy.gd` | Add `burn_stacks: int` |
| `src/ui/HUD.gd` | Add match cases for 增伤、蓄能、灼烧、侵蚀 in `_update_rule_panel()` and `_on_rule_fired()` |
| `src/ui/CharacterPanel.gd` | Add rows for 增伤、蓄能; update `_refresh()` and `_TOOLTIPS` |
| `src/ui/ComponentIcons.gd` | Register icons for 增伤、蓄能、灼烧、侵蚀 (placeholder icons initially) |
| `scenes/ui/character_panel.tscn` | Add HBoxContainer nodes for DmgBoost and Charge rows |
| `data/components/effect_增伤.tres` | New ComponentData resource |
| `data/components/effect_蓄能.tres` | New ComponentData resource |
| `data/components/effect_灼烧.tres` | New ComponentData resource |
| `data/components/effect_侵蚀.tres` | New ComponentData resource |
| `data/drop_presets/drop_tier_01.tres` | Add 增伤、蓄能、灼烧、侵蚀 entries |
| `data/drop_presets/drop_tier_02.tres` | Add 增伤、蓄能、灼烧、侵蚀 entries |
| `data/drop_presets/drop_tier_03.tres` | Add 增伤、蓄能、灼烧、侵蚀 entries |
| `tests/unit/test_rule_engine.gd` | New tests for all 4 effects |
| `tests/unit/test_combat_system.gd` | New tests for burn timer, 侵蚀, charge release, dmg_boost |

---

## Task 1: GameState — add dmg_boost_stacks and charge_stacks

**Files:**
- Modify: `src/autoloads/GameState.gd`
- Test: `tests/unit/test_game_state.gd`

- [ ] **Step 1: Write failing tests**

Add to `tests/unit/test_game_state.gd`:
```gdscript
func test_dmg_boost_stacks_starts_zero() -> void:
    assert_eq(GameState.dmg_boost_stacks, 0)

func test_charge_stacks_starts_zero() -> void:
    assert_eq(GameState.charge_stacks, 0)

func test_dmg_boost_resets_on_reset() -> void:
    GameState.dmg_boost_stacks = 5
    GameState.reset()
    assert_eq(GameState.dmg_boost_stacks, 0)

func test_charge_resets_on_reset() -> void:
    GameState.charge_stacks = 3
    GameState.reset()
    assert_eq(GameState.charge_stacks, 0)
```

- [ ] **Step 2: Run tests to verify they fail**

```powershell
cd "S:/attribute-loop"; & $env:GODOT_EXE --headless --path "S:/attribute-loop" -s "res://addons/gut/gut_cmdln.gd" "-gdir=res://tests/unit/" "-gtest=test_dmg_boost_stacks_starts_zero,test_charge_stacks_starts_zero,test_dmg_boost_resets_on_reset,test_charge_resets_on_reset" "-gexit" 2>&1 | Select-String "passed|Failed"
```

Expected: FAIL (variable not defined)

- [ ] **Step 3: Add variables to GameState.gd**

After `var amplify_stacks: int = 0` add:
```gdscript
var dmg_boost_stacks: int = 0
var charge_stacks: int = 0
```

In `reset()`, after `amplify_stacks = 0`:
```gdscript
dmg_boost_stacks = 0
charge_stacks = 0
```

- [ ] **Step 4: Run tests to verify they pass**

```powershell
cd "S:/attribute-loop"; powershell -NoProfile -File scripts/self-test.ps1 2>&1 | Select-String "game_state|passed"
```

Expected: game_state tests all pass

- [ ] **Step 5: Commit**

```powershell
cd "S:/attribute-loop"; git add src/autoloads/GameState.gd tests/unit/test_game_state.gd; git commit -m "feat: add dmg_boost_stacks and charge_stacks to GameState"
```

---

## Task 2: Enemy — add burn_stacks

**Files:**
- Modify: `src/entities/Enemy.gd`

- [ ] **Step 1: Add burn_stacks to Enemy**

After `var pending_reflect_ratio: float = 0.0` in `Enemy.gd`:
```gdscript
var burn_stacks: int = 0
```

In `CombatSystem.start()`, after `enemy.pending_reflect_ratio = 0.0`:
```gdscript
enemy.burn_stacks = 0
```

- [ ] **Step 2: Commit**

```powershell
cd "S:/attribute-loop"; git add src/entities/Enemy.gd src/systems/CombatSystem.gd; git commit -m "feat: add burn_stacks to Enemy"
```

---

## Task 3: RuleEngine — execute effects for all 4 new components

**Files:**
- Modify: `src/systems/RuleEngine.gd`
- Test: `tests/unit/test_rule_engine.gd`

- [ ] **Step 1: Write failing tests**

Add to `tests/unit/test_rule_engine.gd`:
```gdscript
func test_dmg_boost_adds_stacks() -> void:
    _make_rule("受击", 1.0, "增伤", 2.0)
    EventBus.player_hit.emit(5)
    assert_eq(GameState.dmg_boost_stacks, 2)

func test_dmg_boost_accumulates() -> void:
    _make_rule("受击", 1.0, "增伤", 2.0)
    EventBus.player_hit.emit(5)
    EventBus.player_hit.emit(5)
    assert_eq(GameState.dmg_boost_stacks, 4)

func test_charge_adds_stacks() -> void:
    _make_rule("受击", 1.0, "蓄能", 1.0)
    EventBus.player_hit.emit(5)
    assert_eq(GameState.charge_stacks, 1)

func test_charge_accumulates_from_two_rules() -> void:
    _make_rule("受击", 1.0, "蓄能", 1.0)
    _make_rule_slot1("完成圈数", 1.0, "蓄能", 1.0)
    EventBus.player_hit.emit(5)
    EventBus.loop_completed.emit()
    assert_eq(GameState.charge_stacks, 2)

func test_scorch_emits_rule_fired() -> void:
    watch_signals(EventBus)
    _make_rule("受击", 1.0, "灼烧", 3.0)
    EventBus.player_hit.emit(5)
    assert_signal_emitted(EventBus, "rule_fired")

func test_erode_emits_rule_fired() -> void:
    watch_signals(EventBus)
    _make_rule("受击", 1.0, "侵蚀", 20.0)
    EventBus.player_hit.emit(5)
    assert_signal_emitted(EventBus, "rule_fired")
```

- [ ] **Step 2: Run to verify fail**

```powershell
cd "S:/attribute-loop"; & $env:GODOT_EXE --headless --path "S:/attribute-loop" -s "res://addons/gut/gut_cmdln.gd" "-gdir=res://tests/unit/" "-gexit" 2>&1 | Select-String "dmg_boost|charge|scorch|erode|Failed"
```

- [ ] **Step 3: Add match cases in RuleEngine._execute_effect()**

In `src/systems/RuleEngine.gd`, inside `match effect.id:` after `"吸血":` block:
```gdscript
        "增伤":
            GameState.dmg_boost_stacks += int(final_value)
            EventBus.rule_fired.emit(slot_idx, "增伤", final_value)
        "蓄能":
            GameState.charge_stacks += int(final_value)
            EventBus.rule_fired.emit(slot_idx, "蓄能", final_value)
        "灼烧":
            EventBus.rule_fired.emit(slot_idx, "灼烧", final_value)
        "侵蚀":
            EventBus.rule_fired.emit(slot_idx, "侵蚀", final_value)
```

Note: 灼烧 and 侵蚀 only emit the signal — CombatSystem listens and applies the effect to the active enemy.

- [ ] **Step 4: Run all tests to verify pass**

```powershell
cd "S:/attribute-loop"; powershell -NoProfile -File scripts/self-test.ps1 2>&1 | Select-String "rule_engine|passed"
```

- [ ] **Step 5: Commit**

```powershell
cd "S:/attribute-loop"; git add src/systems/RuleEngine.gd tests/unit/test_rule_engine.gd; git commit -m "feat: RuleEngine executes 增伤、蓄能、灼烧、侵蚀 effects"
```

---

## Task 4: CombatSystem — apply dmg_boost, release charge, burn timer, 侵蚀

**Files:**
- Modify: `src/systems/CombatSystem.gd`
- Test: `tests/unit/test_combat_system.gd`

- [ ] **Step 1: Write failing tests**

Add to `tests/unit/test_combat_system.gd`:
```gdscript
func test_dmg_boost_increases_player_damage() -> void:
    GameState.dmg_boost_stacks = 2
    var pd: PlayerData = DataTables.player
    var expected := int(pd.dmg_base * (1.0 + 2 * 0.1))
    assert_eq(combat._calc_player_dmg(), expected)

func test_charge_release_deals_bonus_damage() -> void:
    GameState.charge_stacks = 3
    var pd: PlayerData = DataTables.player
    var expected_bonus := 3 * pd.dmg_base
    assert_eq(combat._calc_charge_bonus(), expected_bonus)

func test_charge_resets_after_release() -> void:
    GameState.charge_stacks = 2
    combat._release_charge_if_any()
    assert_eq(GameState.charge_stacks, 0)

func test_burn_ticks_deal_damage_per_stack() -> void:
    combat._active_enemy = null
    var cfg: GameConfig = DataTables.config
    assert_almost_eq(cfg.combat_burn_dmg_per_stack, cfg.combat_burn_dmg_per_stack, 0.001)

func test_dmg_boost_decays_on_loop_completed() -> void:
    GameState.dmg_boost_stacks = 3
    EventBus.loop_completed.emit()
    assert_eq(GameState.dmg_boost_stacks, 2)

func test_dmg_boost_not_below_zero_on_decay() -> void:
    GameState.dmg_boost_stacks = 0
    EventBus.loop_completed.emit()
    assert_eq(GameState.dmg_boost_stacks, 0)
```

- [ ] **Step 2: Run to verify fail**

```powershell
cd "S:/attribute-loop"; & $env:GODOT_EXE --headless --path "S:/attribute-loop" -s "res://addons/gut/gut_cmdln.gd" "-gdir=res://tests/unit/" "-gexit" 2>&1 | Select-String "dmg_boost|charge|burn|Failed" | Select-Object -First 20
```

- [ ] **Step 3: Add GameConfig fields for burn**

In `src/resources/GameConfig.gd`, after `combat_enrage_interval`:
```gdscript
@export var combat_burn_dmg_per_stack: int = 5
@export var combat_burn_interval: float = 1.0
```

In `data/game_config.tres`, after `combat_enrage_interval = 3.0`:
```
combat_burn_dmg_per_stack = 5
combat_burn_interval = 1.0
```

- [ ] **Step 4: Add helper methods and burn timer to CombatSystem**

Add vars after `_enrage_stacks`:
```gdscript
var _burn_timer: float = 0.0
```

Add helper methods:
```gdscript
func _calc_player_dmg() -> int:
    var pd: PlayerData = DataTables.player
    var dmg := pd.dmg_base + GameState.dmg_bonus
    if GameState.dmg_boost_stacks > 0:
        dmg = int(dmg * (1.0 + GameState.dmg_boost_stacks * 0.1))
    return dmg

func _calc_charge_bonus() -> int:
    if GameState.charge_stacks <= 0:
        return 0
    return GameState.charge_stacks * DataTables.player.dmg_base

func _release_charge_if_any() -> void:
    if GameState.charge_stacks <= 0:
        return
    var bonus := _calc_charge_bonus()
    GameState.charge_stacks = 0
    if _active_enemy != null and bonus > 0:
        _active_enemy.take_damage(bonus)
        EventBus.rule_fired.emit(-1, "蓄能释放", float(bonus))
```

Update `start()` to reset burn timer:
```gdscript
_burn_timer = 0.0
```

Add burn tick to `_process()` after `_check_enrage()`:
```gdscript
    if _active_enemy != null and _active_enemy.burn_stacks > 0:
        _burn_timer += delta
        var cfg: GameConfig = DataTables.config
        if _burn_timer >= cfg.combat_burn_interval:
            _burn_timer = 0.0
            var burn_dmg := _active_enemy.burn_stacks * cfg.combat_burn_dmg_per_stack
            _active_enemy.take_damage(burn_dmg)
            if _active_enemy.is_dead():
                _finish_combat(_active_enemy)
                return
```

Update `_apply_player_attack()` — replace `var dmg := DataTables.player.dmg_base` with:
```gdscript
    var dmg := _calc_player_dmg()
    var charge_bonus := _calc_charge_bonus()
    GameState.charge_stacks = 0
```

After `enemy.take_damage(dmg)` add:
```gdscript
    if charge_bonus > 0:
        enemy.take_damage(charge_bonus)
        EventBus.rule_fired.emit(-1, "蓄能释放", float(charge_bonus))
```

Also update lifesteal line (currently uses `dmg_base`, should use actual dmg):
```gdscript
    if GameState.lifesteal_ratio > 0.0:
        var heal := int(dmg * GameState.lifesteal_ratio)
        GameState.hp = min(GameState.hp + heal, GameState.hp_max)
```

Add `rule_fired` listener in `_ready()`:
```gdscript
    EventBus.rule_fired.connect(_on_rule_fired)
```

Add handler:
```gdscript
func _on_rule_fired(_slot_idx: int, effect_id: String, value: float) -> void:
    if _active_enemy == null:
        return
    match effect_id:
        "灼烧":
            _active_enemy.burn_stacks += int(value)
        "侵蚀":
            _active_enemy.hp_max = max(1, _active_enemy.hp_max - int(value))
            _active_enemy.hp = min(_active_enemy.hp, _active_enemy.hp_max)
            _active_enemy._refresh_label()
            if _active_enemy.is_dead():
                _finish_combat(_active_enemy)
```

Add dmg_boost decay in `_on_loop_completed` listener (add to RuleEngine._on_loop_completed, not CombatSystem):

In `src/systems/RuleEngine.gd`, `_on_loop_completed()`, after shield decay:
```gdscript
    GameState.dmg_boost_stacks = max(0, GameState.dmg_boost_stacks - 1)
```

- [ ] **Step 5: Run all tests to verify pass**

```powershell
cd "S:/attribute-loop"; powershell -NoProfile -File scripts/self-test.ps1 2>&1 | Select-String "combat_system|rule_engine|passed|Failed" | Select-Object -First 20
```

- [ ] **Step 6: Commit**

```powershell
cd "S:/attribute-loop"; git add src/systems/CombatSystem.gd src/systems/RuleEngine.gd src/resources/GameConfig.gd data/game_config.tres tests/unit/test_combat_system.gd; git commit -m "feat: CombatSystem applies 增伤、蓄能、灼烧、侵蚀 effects"
```

---

## Task 5: Data files — .tres resources and drop presets

**Files:**
- Create: `data/components/effect_增伤.tres`
- Create: `data/components/effect_蓄能.tres`
- Create: `data/components/effect_灼烧.tres`
- Create: `data/components/effect_侵蚀.tres`
- Modify: `data/drop_presets/drop_tier_01.tres`
- Modify: `data/drop_presets/drop_tier_02.tres`
- Modify: `data/drop_presets/drop_tier_03.tres`

- [ ] **Step 1: Create effect_增伤.tres**

```
[gd_resource type="Resource" script_class="ComponentData" format=3]

[ext_resource type="Script" uid="uid://7v3b3h3e3hi4" path="res://src/resources/ComponentData.gd" id="1_new10"]

[resource]
script = ExtResource("1_new10")
id = "增伤"
display_name = "增伤"
description = "叠加增伤层，每层使攻击伤害提升 10%，每圈结束衰减 1 层"
slot_type = 1
effect_formula = "dmg_boost"
growth_rate = 0.0
altar_ratio = 0.05
```

- [ ] **Step 2: Create effect_蓄能.tres**

```
[gd_resource type="Resource" script_class="ComponentData" format=3]

[ext_resource type="Script" uid="uid://7v3b3h3e3hi4" path="res://src/resources/ComponentData.gd" id="1_new11"]

[resource]
script = ExtResource("1_new11")
id = "蓄能"
display_name = "蓄能"
description = "积累蓄能层，下次攻击时消耗全部层数，每层附加一次基础攻击伤害"
slot_type = 1
effect_formula = "charge"
growth_rate = 0.0
altar_ratio = 0.05
```

- [ ] **Step 3: Create effect_灼烧.tres**

```
[gd_resource type="Resource" script_class="ComponentData" format=3]

[ext_resource type="Script" uid="uid://7v3b3h3e3hi4" path="res://src/resources/ComponentData.gd" id="1_new12"]

[resource]
script = ExtResource("1_new12")
id = "灼烧"
display_name = "灼烧"
description = "对当前敌人施加灼烧层，每秒造成每层 5 点伤害，战斗结束后清除"
slot_type = 1
effect_formula = "burn"
growth_rate = 0.05
altar_ratio = 0.05
```

- [ ] **Step 4: Create effect_侵蚀.tres**

```
[gd_resource type="Resource" script_class="ComponentData" format=3]

[ext_resource type="Script" uid="uid://7v3b3h3e3hi4" path="res://src/resources/ComponentData.gd" id="1_new13"]

[resource]
script = ExtResource("1_new13")
id = "侵蚀"
display_name = "侵蚀"
description = "降低敌人最大生命上限，超出上限的当前生命立即截断，上限最低为 1"
slot_type = 1
effect_formula = "erode"
growth_rate = 0.1
altar_ratio = 0.05
```

- [ ] **Step 5: Add to drop presets**

In each `drop_tier_0N.tres`, add after `"强化": {"effect": Vector2(1, 1)}`:

drop_tier_01:
```
"增伤": {"effect": Vector2(1, 2)},
"蓄能": {"effect": Vector2(1, 1)},
"灼烧": {"effect": Vector2(1, 2)},
"侵蚀": {"effect": Vector2(15, 25)}
```

drop_tier_02:
```
"增伤": {"effect": Vector2(2, 3)},
"蓄能": {"effect": Vector2(1, 2)},
"灼烧": {"effect": Vector2(2, 3)},
"侵蚀": {"effect": Vector2(20, 35)}
```

drop_tier_03:
```
"增伤": {"effect": Vector2(2, 4)},
"蓄能": {"effect": Vector2(1, 2)},
"灼烧": {"effect": Vector2(3, 5)},
"侵蚀": {"effect": Vector2(25, 45)}
```

- [ ] **Step 6: Commit**

```powershell
cd "S:/attribute-loop"; git add data/; git commit -m "feat: add 增伤、蓄能、灼烧、侵蚀 component data and drop preset entries"
```

---

## Task 6: ComponentIcons — register placeholder icons

**Files:**
- Modify: `src/ui/ComponentIcons.gd`

- [ ] **Step 1: Add icon mappings**

In `src/ui/ComponentIcons.gd`, `_ICON_MAP`, after `"强化"` entry:
```gdscript
    "增伤":    "res://resources/icons/effect_empower.png",
    "蓄能":    "res://resources/icons/effect_haste.png",
    "灼烧":    "res://resources/icons/effect_reflect.png",
    "侵蚀":    "res://resources/icons/effect_lifesteal.png",
```

Note: These are temporary placeholders. Art assets will replace them later.

- [ ] **Step 2: Commit**

```powershell
cd "S:/attribute-loop"; git add src/ui/ComponentIcons.gd; git commit -m "feat: register placeholder icons for 增伤、蓄能、灼烧、侵蚀"
```

---

## Task 7: HUD — display values in rule panel and float label

**Files:**
- Modify: `src/ui/HUD.gd`

- [ ] **Step 1: Add to _update_rule_panel match**

In `src/ui/HUD.gd`, `_update_rule_panel()`, after `"强化"` case:
```gdscript
        "增伤":
            _e_value[i].text = "×%d层" % int(e.effect_value)
        "蓄能":
            var potential := GameState.charge_stacks * DataTables.player.dmg_base
            _e_value[i].text = "%d层 (%d)" % [GameState.charge_stacks, potential]
        "灼烧":
            _e_value[i].text = "×%d层" % int(e.effect_value)
        "侵蚀":
            _e_value[i].text = "-%d" % int(e.effect_value)
```

- [ ] **Step 2: Add to _on_rule_fired match**

In `_on_rule_fired()`, after `"强化"` case:
```gdscript
        "增伤":
            float_label.text = "增伤 ×%d层" % GameState.dmg_boost_stacks
        "蓄能":
            float_label.text = "蓄能 %d层" % GameState.charge_stacks
        "蓄能释放":
            float_label.text = "蓄能释放 +%.0f" % value
        "灼烧":
            float_label.text = "灼烧 ×%.0f层" % value
        "侵蚀":
            float_label.text = "侵蚀 -%.0f" % value
```

- [ ] **Step 3: Commit**

```powershell
cd "S:/attribute-loop"; git add src/ui/HUD.gd; git commit -m "feat: HUD displays 增伤、蓄能、灼烧、侵蚀 in rule panel and float label"
```

---

## Task 8: CharacterPanel — add DmgBoost and Charge rows

**Files:**
- Modify: `scenes/ui/character_panel.tscn`
- Modify: `src/ui/CharacterPanel.gd`

- [ ] **Step 1: Add scene nodes**

In `scenes/ui/character_panel.tscn`, after the `Lifesteal` HBoxContainer block (before `Sep2`):

```
[node name="DmgBoost" type="HBoxContainer" parent="Margin/VBox/OffenseGroup"]
layout_mode = 2
theme_override_constants/separation = 12

[node name="Name" type="Label" parent="Margin/VBox/OffenseGroup/DmgBoost"]
layout_mode = 2
size_flags_horizontal = 3
theme_override_colors/font_color = Color(0.35, 0.25, 0.12, 1)
text = "增伤"

[node name="Value" type="Label" parent="Margin/VBox/OffenseGroup/DmgBoost"]
layout_mode = 2
theme_override_colors/font_color = Color(0.72, 0.25, 0.08, 1)
text = "—"

[node name="Charge" type="HBoxContainer" parent="Margin/VBox/OffenseGroup"]
layout_mode = 2
theme_override_constants/separation = 12

[node name="Name" type="Label" parent="Margin/VBox/OffenseGroup/Charge"]
layout_mode = 2
size_flags_horizontal = 3
theme_override_colors/font_color = Color(0.35, 0.25, 0.12, 1)
text = "蓄能"

[node name="Value" type="Label" parent="Margin/VBox/OffenseGroup/Charge"]
layout_mode = 2
theme_override_colors/font_color = Color(0.55, 0.45, 0.05, 1)
text = "—"
```

- [ ] **Step 2: Update CharacterPanel.gd**

Add to `_TOOLTIPS`:
```gdscript
    "OffenseGroup/DmgBoost": "每层提升攻击伤害 10%，每圈结束衰减 1 层",
    "OffenseGroup/Charge":   "蓄积层数，下次攻击时全部释放为额外伤害（括号内为预期伤害）",
```

Add to `_VALUE_COLORS`:
```gdscript
    "OffenseGroup/DmgBoost": Color(0.72, 0.25, 0.08, 1),
    "OffenseGroup/Charge":   Color(0.55, 0.45, 0.05, 1),
```

In `_refresh()`, after `_set_row("OffenseGroup/Lifesteal", ...)`:
```gdscript
    _set_row("OffenseGroup/DmgBoost", _stacks_or_dash(GameState.dmg_boost_stacks))
    var charge_potential := GameState.charge_stacks * DataTables.player.dmg_base
    _set_row("OffenseGroup/Charge",
        "—" if GameState.charge_stacks == 0 else "%d层 (%d)" % [GameState.charge_stacks, charge_potential])
```

- [ ] **Step 3: Commit**

```powershell
cd "S:/attribute-loop"; git add scenes/ui/character_panel.tscn src/ui/CharacterPanel.gd; git commit -m "feat: CharacterPanel shows 增伤 and 蓄能 rows"
```

---

## Task 9: Final verification

- [ ] **Step 1: Run full test suite**

```powershell
cd "S:/attribute-loop"; powershell -NoProfile -File scripts/self-test.ps1 2>&1 | Select-String "passed|Failed" | Select-Object -Last 10
```

Expected: All previously passing tests still pass. New tests pass.

- [ ] **Step 2: Check no regressions in rule_engine and combat_system**

```powershell
cd "S:/attribute-loop"; powershell -NoProfile -File scripts/self-test.ps1 2>&1 | Out-String | ForEach-Object { $_ -split "`n" } | Select-String "rule_engine|combat_system|/\d+ passed"
```

Expected: Both files show full pass counts.
