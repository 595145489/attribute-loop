# BOTH Components Expansion Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Upgrade 15 components from TRIGGER_ONLY / EFFECT_ONLY to BOTH, giving each a meaningful behavior in both slots.

**Architecture:** Three layers of change — (1) new EventBus signals for effect-as-trigger events, (2) new `_execute_effect()` branches in RuleEngine for the 6 new E behaviors, (3) `.tres` slot_type updates and new trigger_formula/trigger_value fields. RuleEngine already routes all effect execution; no structural changes needed.

**Tech Stack:** Godot 4.x GDScript, GUT test framework, headless unit tests

---

## File Map

| File | Change |
|------|--------|
| `src/autoloads/EventBus.gd` | Add 5 new signals: `shield_absorbed`, `slow_applied`, `lifesteal_healed`, `amplify_consumed`, `dmg_boost_consumed` |
| `src/autoloads/GameState.gd` | Emit `shield_absorbed` in `take_damage()`; add `current_tile_index: int` field |
| `src/systems/CombatSystem.gd` | Emit `slow_applied`, `lifesteal_healed`, `dmg_boost_consumed` at correct sites |
| `src/systems/RuleEngine.gd` | Wire new signals to `_evaluate_player_triggers()`; add 6 new E cases; add `_any_rule_fire_count` for 规则触发(E) |
| `data/components/*.tres` | Set `slot_type = 2` on 15 files; add `trigger_formula = "fires_every"` + `trigger_value` where missing |
| `tests/unit/test_rule_engine.gd` | New tests for all 6 new E behaviors + all 8 new T behaviors |
| `tests/unit/test_combat_system.gd` | New tests for new signal emissions |

---

## Task 1: Add new EventBus signals

**Files:**
- Modify: `src/autoloads/EventBus.gd`

- [ ] **Step 1: Add 5 signals after `rule_fired`**

Open `src/autoloads/EventBus.gd` and add after `signal rule_fired(slot_idx: int, effect_id: String, value: float)`:

```gdscript
signal shield_absorbed(amount: int)
signal slow_applied(stacks: int)
signal lifesteal_healed(amount: int)
signal amplify_consumed()
signal dmg_boost_consumed(stacks_used: int)
```

- [ ] **Step 2: Commit**

```bash
git add src/autoloads/EventBus.gd
git commit -m "feat: add effect-event signals for BOTH trigger wiring"
```

---

## Task 2: Emit shield_absorbed in GameState.take_damage()

**Files:**
- Modify: `src/autoloads/GameState.gd`

- [ ] **Step 1: Write failing test**

In `tests/unit/test_game_state.gd`, add:

```gdscript
func test_shield_absorbed_signal_emitted_when_shield_absorbs() -> void:
    watch_signals(EventBus)
    GameState.shield = 50
    GameState.take_damage(20)
    assert_signal_emitted(EventBus, "shield_absorbed")

func test_shield_absorbed_signal_not_emitted_without_shield() -> void:
    watch_signals(EventBus)
    GameState.shield = 0
    GameState.take_damage(20)
    assert_signal_not_emitted(EventBus, "shield_absorbed")
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
"S:/Godot_v4.6.2-stable_mono_win64/Godot_v4.6.2-stable_mono_win64.exe" --path "S:/attribute-loop" --headless --quit --scene res://tests/unit/test_game_state.tscn
```

Expected: FAIL

- [ ] **Step 3: Emit signal in take_damage()**

In `src/autoloads/GameState.gd`, update `take_damage()`:

```gdscript
func take_damage(amount: int) -> void:
    if shield > 0:
        var absorbed := mini(shield, amount)
        shield -= absorbed
        amount -= absorbed
        EventBus.shield_absorbed.emit(absorbed)
    if amount > 0:
        hp = max(0, hp - amount)
        if hp == 0:
            EventBus.player_died.emit()
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
"S:/Godot_v4.6.2-stable_mono_win64/Godot_v4.6.2-stable_mono_win64.exe" --path "S:/attribute-loop" --headless --quit --scene res://tests/unit/test_game_state.tscn
```

Expected: PASS

- [ ] **Step 5: Add current_tile_index field**

In `src/autoloads/GameState.gd`, add after `var in_boss_circle: bool = false`:

```gdscript
var current_tile_index: int = -1
```

In `reset()`, add:

```gdscript
current_tile_index = -1
```

- [ ] **Step 6: Commit**

```bash
git add src/autoloads/GameState.gd tests/unit/test_game_state.gd
git commit -m "feat: emit shield_absorbed signal; add current_tile_index to GameState"
```

---

## Task 3: Emit slow_applied, lifesteal_healed, dmg_boost_consumed in CombatSystem

**Files:**
- Modify: `src/systems/CombatSystem.gd`
- Modify: `tests/unit/test_combat_system.gd`

- [ ] **Step 1: Write failing tests**

In `tests/unit/test_combat_system.gd`, add:

```gdscript
func test_slow_applied_emitted_when_slow_reduces_damage() -> void:
    watch_signals(EventBus)
    var enemy = Enemy.new()
    enemy.init("汲取者")
    GameState.slow_stacks = 3
    combat._apply_enemy_attack(enemy)
    assert_signal_emitted(EventBus, "slow_applied")

func test_slow_applied_not_emitted_without_slow_stacks() -> void:
    watch_signals(EventBus)
    var enemy = Enemy.new()
    enemy.init("汲取者")
    GameState.slow_stacks = 0
    combat._apply_enemy_attack(enemy)
    assert_signal_not_emitted(EventBus, "slow_applied")

func test_lifesteal_healed_emitted_when_lifesteal_heals() -> void:
    watch_signals(EventBus)
    var enemy = Enemy.new()
    enemy.init("汲取者")
    enemy.hp = 9999
    GameState.lifesteal_ratio = 0.5
    GameState.hp = 100
    combat._apply_player_attack(enemy)
    assert_signal_emitted(EventBus, "lifesteal_healed")

func test_dmg_boost_consumed_emitted_when_boost_used() -> void:
    watch_signals(EventBus)
    var enemy = Enemy.new()
    enemy.init("汲取者")
    enemy.hp = 9999
    GameState.dmg_boost_stacks = 2
    combat._apply_player_attack(enemy)
    assert_signal_emitted(EventBus, "dmg_boost_consumed")

func test_dmg_boost_consumed_not_emitted_without_boost() -> void:
    watch_signals(EventBus)
    var enemy = Enemy.new()
    enemy.init("汲取者")
    enemy.hp = 9999
    GameState.dmg_boost_stacks = 0
    combat._apply_player_attack(enemy)
    assert_signal_not_emitted(EventBus, "dmg_boost_consumed")
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
"S:/Godot_v4.6.2-stable_mono_win64/Godot_v4.6.2-stable_mono_win64.exe" --path "S:/attribute-loop" --headless --quit --scene res://tests/unit/test_combat_system.tscn
```

Expected: FAIL

- [ ] **Step 3: Emit slow_applied in _apply_enemy_attack()**

In `src/systems/CombatSystem.gd`, in `_apply_enemy_attack()`, after the slow_stacks block:

```gdscript
func _apply_enemy_attack(enemy: Enemy) -> void:
    var dmg := enemy.dmg
    if _enrage_stacks > 0:
        dmg = int(dmg * pow(DataTables.config.combat_enrage_multiplier, _enrage_stacks))
    if GameState.slow_stacks > 0:
        var stack_cap := mini(GameState.current_phase + 1, 8)
        var capped := mini(GameState.slow_stacks, stack_cap)
        dmg = int(dmg * (1.0 - capped * 0.1))
        EventBus.slow_applied.emit(capped)
    GameState.take_damage(dmg)
    # ... rest unchanged
```

- [ ] **Step 4: Emit lifesteal_healed and dmg_boost_consumed in _apply_player_attack()**

In `src/systems/CombatSystem.gd`, in `_calc_player_dmg()`, capture whether boost was used. Instead, emit directly in `_apply_player_attack()`:

```gdscript
func _apply_player_attack(enemy: Enemy) -> void:
    var dmg := _calc_player_dmg()
    var had_boost := GameState.dmg_boost_stacks > 0
    var charge_bonus := _calc_charge_bonus()
    GameState.charge_stacks = 0
    if enemy.slow_stacks > 0:
        var stack_cap := mini(GameState.current_phase + 1, 8)
        var capped := mini(enemy.slow_stacks, stack_cap)
        dmg = int(dmg * (1.0 - capped * 0.1))
    if enemy.shield > 0:
        var absorbed := mini(enemy.shield, dmg)
        enemy.shield -= absorbed
        dmg -= absorbed
    if dmg > 0:
        enemy.take_damage(dmg)
    if charge_bonus > 0:
        enemy.take_damage(charge_bonus)
        EventBus.rule_fired.emit(-1, "蓄能释放", float(charge_bonus))
    if GameState.lifesteal_ratio > 0.0:
        var heal := int(dmg * GameState.lifesteal_ratio)
        if heal > 0:
            GameState.hp = min(GameState.hp + heal, GameState.hp_max)
            EventBus.lifesteal_healed.emit(heal)
    if had_boost:
        EventBus.dmg_boost_consumed.emit(GameState.dmg_boost_stacks)
    if enemy.pending_reflect_ratio > 0.0:
        var reflected := int(dmg * enemy.pending_reflect_ratio)
        GameState.take_damage(reflected)
        enemy.pending_reflect_ratio = 0.0
    if enemy.is_dead():
        _finish_combat(enemy)
        return
    _evaluate_enemy_triggers(["受击"])
    if enemy.is_dead():
        _finish_combat(enemy)
```

- [ ] **Step 5: Run tests to verify they pass**

```bash
"S:/Godot_v4.6.2-stable_mono_win64/Godot_v4.6.2-stable_mono_win64.exe" --path "S:/attribute-loop" --headless --quit --scene res://tests/unit/test_combat_system.tscn
```

Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add src/systems/CombatSystem.gd tests/unit/test_combat_system.gd
git commit -m "feat: emit slow_applied, lifesteal_healed, dmg_boost_consumed signals"
```

---

## Task 4: Emit amplify_consumed in RuleEngine

**Files:**
- Modify: `src/systems/RuleEngine.gd`
- Modify: `tests/unit/test_rule_engine.gd`

- [ ] **Step 1: Write failing test**

In `tests/unit/test_rule_engine.gd`, add:

```gdscript
func test_amplify_consumed_emitted_when_amplify_used() -> void:
    watch_signals(EventBus)
    GameState.amplify_stacks = 1
    _make_rule("完成圈数", 1.0, "治愈", 10.0)
    GameState.hp = 50
    EventBus.loop_completed.emit()
    assert_signal_emitted(EventBus, "amplify_consumed")

func test_amplify_consumed_not_emitted_without_amplify() -> void:
    watch_signals(EventBus)
    GameState.amplify_stacks = 0
    _make_rule("完成圈数", 1.0, "治愈", 10.0)
    GameState.hp = 50
    EventBus.loop_completed.emit()
    assert_signal_not_emitted(EventBus, "amplify_consumed")
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
"S:/Godot_v4.6.2-stable_mono_win64/Godot_v4.6.2-stable_mono_win64.exe" --path "S:/attribute-loop" --headless --quit --scene res://tests/unit/test_rule_engine.tscn
```

Expected: FAIL

- [ ] **Step 3: Emit amplify_consumed in _execute_effect()**

In `src/systems/RuleEngine.gd`, in `_execute_effect()`, find the amplify consumption block:

```gdscript
if effect.id != "强化" and GameState.amplify_stacks > 0:
    final_value *= 1.0 + GameState.amplify_stacks * 0.5
    GameState.amplify_stacks = 0
    EventBus.amplify_consumed.emit()
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
"S:/Godot_v4.6.2-stable_mono_win64/Godot_v4.6.2-stable_mono_win64.exe" --path "S:/attribute-loop" --headless --quit --scene res://tests/unit/test_rule_engine.tscn
```

Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add src/systems/RuleEngine.gd tests/unit/test_rule_engine.gd
git commit -m "feat: emit amplify_consumed when amplify stacks are used"
```

---

## Task 5: Wire new signals to RuleEngine trigger evaluation

**Files:**
- Modify: `src/systems/RuleEngine.gd`

Wire the 8 new T event signals to `_evaluate_player_triggers()`. Also update `_on_tile_passed` to track `GameState.current_tile_index`.

- [ ] **Step 1: Write failing tests**

In `tests/unit/test_rule_engine.gd`, add:

```gdscript
func test_shield_trigger_counts_on_shield_absorbed() -> void:
    _make_rule("护盾", 2.0, "治愈", 10.0)
    var t = GameState.rule_slots[0]["trigger"]
    EventBus.shield_absorbed.emit(20)
    assert_eq(t.trigger_count, 1)

func test_slow_trigger_counts_on_slow_applied() -> void:
    _make_rule("减伤", 2.0, "治愈", 10.0)
    var t = GameState.rule_slots[0]["trigger"]
    EventBus.slow_applied.emit(2)
    assert_eq(t.trigger_count, 1)

func test_lifesteal_trigger_counts_on_lifesteal_healed() -> void:
    _make_rule("吸血", 2.0, "治愈", 10.0)
    var t = GameState.rule_slots[0]["trigger"]
    EventBus.lifesteal_healed.emit(5)
    assert_eq(t.trigger_count, 1)

func test_amplify_trigger_counts_on_amplify_consumed() -> void:
    _make_rule("强化", 2.0, "治愈", 10.0)
    var t = GameState.rule_slots[0]["trigger"]
    EventBus.amplify_consumed.emit()
    assert_eq(t.trigger_count, 1)

func test_dmg_boost_trigger_counts_on_dmg_boost_consumed() -> void:
    _make_rule("增伤", 2.0, "治愈", 10.0)
    var t = GameState.rule_slots[0]["trigger"]
    EventBus.dmg_boost_consumed.emit(2)
    assert_eq(t.trigger_count, 1)

func test_charge_trigger_counts_on_charge_release() -> void:
    _make_rule("蓄能", 2.0, "治愈", 10.0)
    var t = GameState.rule_slots[0]["trigger"]
    EventBus.rule_fired.emit(-1, "蓄能释放", 10.0)
    assert_eq(t.trigger_count, 1)

func test_burn_trigger_counts_on_burn_rule_fired() -> void:
    _make_rule("灼烧", 2.0, "治愈", 10.0)
    var t = GameState.rule_slots[0]["trigger"]
    EventBus.rule_fired.emit(-1, "灼烧", 3.0)
    assert_eq(t.trigger_count, 1)

func test_erode_trigger_counts_on_erode_rule_fired() -> void:
    _make_rule("侵蚀", 2.0, "治愈", 10.0)
    var t = GameState.rule_slots[0]["trigger"]
    EventBus.rule_fired.emit(-1, "侵蚀", 10.0)
    assert_eq(t.trigger_count, 1)
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
"S:/Godot_v4.6.2-stable_mono_win64/Godot_v4.6.2-stable_mono_win64.exe" --path "S:/attribute-loop" --headless --quit --scene res://tests/unit/test_rule_engine.tscn
```

Expected: FAIL

- [ ] **Step 3: Connect new signals in _ready() and update _on_rule_fired()**

In `src/systems/RuleEngine.gd`, update `_ready()`:

```gdscript
func _ready() -> void:
    EventBus.player_hit.connect(_on_player_hit)
    EventBus.enemy_killed.connect(_on_enemy_killed)
    EventBus.loop_completed.connect(_on_loop_completed)
    EventBus.tile_passed.connect(_on_tile_passed)
    EventBus.rule_fired.connect(_on_rule_fired)
    EventBus.shield_absorbed.connect(func(_a): _evaluate_player_triggers(["护盾"]))
    EventBus.slow_applied.connect(func(_s): _evaluate_player_triggers(["减伤"]))
    EventBus.lifesteal_healed.connect(func(_a): _evaluate_player_triggers(["吸血"]))
    EventBus.amplify_consumed.connect(func(): _evaluate_player_triggers(["强化"]))
    EventBus.dmg_boost_consumed.connect(func(_s): _evaluate_player_triggers(["增伤"]))
```

Update `_on_rule_fired()` to also evaluate 蓄能/灼烧/侵蚀 triggers:

```gdscript
func _on_rule_fired(_slot_idx: int, effect_id: String, _value: float) -> void:
    if effect_id == "治愈":
        _evaluate_player_triggers(["治愈"])
    if effect_id == "反射":
        _evaluate_player_triggers(["反射"])
    if effect_id == "蓄能释放":
        _evaluate_player_triggers(["蓄能"])
    if effect_id == "灼烧":
        _evaluate_player_triggers(["灼烧"])
    if effect_id == "侵蚀":
        _evaluate_player_triggers(["侵蚀"])
    if effect_id in ["强化", "增伤", "蓄能", "蓄能释放", "灼烧", "侵蚀"]:
        return
    if not _firing_rule_trigger:
        _firing_rule_trigger = true
        _evaluate_player_triggers(["规则触发"])
        _firing_rule_trigger = false
```

Update `_on_tile_passed()` to track current tile:

```gdscript
func _on_tile_passed(tile_idx: int) -> void:
    GameState.current_tile_index = tile_idx
    _evaluate_player_triggers(["经过"])
    if tile_idx < _tiles.size() and _tiles[tile_idx] != null:
        _evaluate_tile_rules(_tiles[tile_idx])
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
"S:/Godot_v4.6.2-stable_mono_win64/Godot_v4.6.2-stable_mono_win64.exe" --path "S:/attribute-loop" --headless --quit --scene res://tests/unit/test_rule_engine.tscn
```

Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add src/systems/RuleEngine.gd tests/unit/test_rule_engine.gd
git commit -m "feat: wire 8 new trigger events to RuleEngine evaluation"
```

---

## Task 6: Implement 6 new E behaviors in RuleEngine._execute_effect()

**Files:**
- Modify: `src/systems/RuleEngine.gd`
- Modify: `tests/unit/test_rule_engine.gd`

- [ ] **Step 1: Write failing tests**

In `tests/unit/test_rule_engine.gd`, add:

```gdscript
func test_effect_受击_deals_self_damage() -> void:
    _make_rule("完成圈数", 1.0, "受击", 20.0)
    GameState.hp = 100
    EventBus.loop_completed.emit()
    assert_eq(GameState.hp, 80)

func test_effect_受击_does_not_kill() -> void:
    _make_rule("完成圈数", 1.0, "受击", 9999.0)
    GameState.hp = 50
    EventBus.loop_completed.emit()
    assert_eq(GameState.hp, 1)

func test_effect_受击_emits_player_hit() -> void:
    watch_signals(EventBus)
    _make_rule("完成圈数", 1.0, "受击", 10.0)
    GameState.hp = 100
    EventBus.loop_completed.emit()
    assert_signal_emitted(EventBus, "player_hit")

func test_effect_低血_deals_self_damage() -> void:
    _make_rule("完成圈数", 1.0, "低血", 20.0)
    GameState.hp = 100
    EventBus.loop_completed.emit()
    assert_eq(GameState.hp, 80)

func test_effect_低血_does_not_kill() -> void:
    _make_rule("完成圈数", 1.0, "低血", 9999.0)
    GameState.hp = 50
    EventBus.loop_completed.emit()
    assert_eq(GameState.hp, 1)

func test_effect_低血_does_not_emit_player_hit() -> void:
    watch_signals(EventBus)
    _make_rule("完成圈数", 1.0, "低血", 10.0)
    GameState.hp = 100
    EventBus.loop_completed.emit()
    assert_signal_not_emitted(EventBus, "player_hit")

func test_effect_满血_adds_one_to_each_nonzero_stack() -> void:
    _make_rule("完成圈数", 1.0, "满血", 1.0)
    GameState.charge_stacks = 2
    GameState.dmg_boost_stacks = 1
    GameState.amplify_stacks = 0
    EventBus.loop_completed.emit()
    assert_eq(GameState.charge_stacks, 3)
    assert_eq(GameState.dmg_boost_stacks, 2)
    assert_eq(GameState.amplify_stacks, 0)

func test_effect_规则触发_increments_all_trigger_counts() -> void:
    _make_rule("受击", 5.0, "治愈", 10.0)
    _make_rule_slot1("完成圈数", 1.0, "规则触发", 1.0)
    var t0 = GameState.rule_slots[0]["trigger"]
    EventBus.loop_completed.emit()
    assert_eq(t0.trigger_count, 1, "slot 0 trigger count should be incremented")

func test_effect_规则触发_does_not_fire_rules() -> void:
    _make_rule("受击", 2.0, "治愈", 10.0)
    _make_rule_slot1("完成圈数", 1.0, "规则触发", 1.0)
    GameState.hp = 50
    EventBus.loop_completed.emit()
    assert_eq(GameState.hp, 50, "heal should not fire — count only reached 1 of 2")
```

Note: 击杀(E) and 经过(E) require a live enemy / tile respectively — test in test_combat_system.gd and a manual integration pass.

- [ ] **Step 2: Run tests to verify they fail**

```bash
"S:/Godot_v4.6.2-stable_mono_win64/Godot_v4.6.2-stable_mono_win64.exe" --path "S:/attribute-loop" --headless --quit --scene res://tests/unit/test_rule_engine.tscn
```

Expected: FAIL

- [ ] **Step 3: Add 6 new match arms to _execute_effect()**

In `src/systems/RuleEngine.gd`, in the `match effect.id:` block, add:

```gdscript
"受击":
    var dmg := maxi(1, int(final_value))
    GameState.hp = maxi(1, GameState.hp - dmg)
    EventBus.rule_fired.emit(slot_idx, "受击", float(dmg))
    EventBus.player_hit.emit(dmg)
"低血":
    var dmg := maxi(1, int(final_value))
    GameState.hp = maxi(1, GameState.hp - dmg)
    EventBus.rule_fired.emit(slot_idx, "低血", float(dmg))
"满血":
    if GameState.charge_stacks > 0:
        GameState.charge_stacks += 1
    if GameState.dmg_boost_stacks > 0:
        GameState.dmg_boost_stacks += 1
    if GameState.amplify_stacks > 0:
        GameState.amplify_stacks = mini(GameState.amplify_stacks + 1, GameState.amplify_max_stacks)
    EventBus.rule_fired.emit(slot_idx, "满血", 1.0)
"规则触发":
    for s in GameState.rule_slots:
        var t: ComponentData = s.get("trigger")
        if t != null:
            t.trigger_count += 1
    EventBus.rule_fired.emit(slot_idx, "规则触发", 1.0)
"击杀":
    var engine_ref := self
    var target := engine_ref._get_active_enemy()
    if target != null and not target.is_dead():
        var bonus := int(target.hp * final_value / 100.0)
        if bonus > 0:
            target.take_damage(bonus)
    EventBus.rule_fired.emit(slot_idx, "击杀", final_value)
"经过":
    var idx := GameState.current_tile_index
    if idx >= 0 and idx < _tiles.size() and _tiles[idx] != null:
        _evaluate_tile_rules(_tiles[idx])
    EventBus.rule_fired.emit(slot_idx, "经过", 1.0)
```

- [ ] **Step 4: Add _get_active_enemy() helper**

RuleEngine needs to reach the active enemy for 击杀(E). Add a stored reference updated by CombatSystem:

In `src/systems/RuleEngine.gd`, add field and method:

```gdscript
var _active_enemy: Enemy = null

func set_active_enemy(e: Enemy) -> void:
    _active_enemy = e

func _get_active_enemy() -> Enemy:
    return _active_enemy
```

In `src/systems/CombatSystem.gd`, in `start()`, after getting the engine reference — look up the RuleEngine via the scene. Since CombatSystem and RuleEngine are siblings under Main, pass the reference explicitly. In `src/Main.gd`, after wiring combat:

```gdscript
_rule_engine.set_active_enemy(null)  # cleared at start
```

In `CombatSystem.start()`, emit a signal or use a direct ref. The simplest approach: give CombatSystem a `rule_engine` property and set it in Main.

In `src/systems/CombatSystem.gd`, add:

```gdscript
var rule_engine: RuleEngine = null
```

In `start()`, add:

```gdscript
if rule_engine != null:
    rule_engine.set_active_enemy(enemy)
```

In `stop()`, add:

```gdscript
if rule_engine != null:
    rule_engine.set_active_enemy(null)
```

- [ ] **Step 5: Wire rule_engine reference in Main.gd**

In `src/Main.gd`, in `_finish_setup()`, after `rule_engine.set_tiles(_tiles)`:

```gdscript
combat_system.rule_engine = rule_engine
```

- [ ] **Step 6: Run tests to verify they pass**

```bash
"S:/Godot_v4.6.2-stable_mono_win64/Godot_v4.6.2-stable_mono_win64.exe" --path "S:/attribute-loop" --headless --quit --scene res://tests/unit/test_rule_engine.tscn
```

Expected: PASS

- [ ] **Step 7: Commit**

```bash
git add src/systems/RuleEngine.gd src/systems/CombatSystem.gd src/Main.gd tests/unit/test_rule_engine.gd
git commit -m "feat: implement 6 new E behaviors (受击, 低血, 满血, 规则触发, 击杀, 经过)"
```

---

## Task 7: Update .tres files — slot_type = 2 for 15 components

**Files:**
- Modify: `data/components/trigger_受击.tres`
- Modify: `data/components/trigger_击杀.tres`
- Modify: `data/components/trigger_经过.tres`
- Modify: `data/components/trigger_低血.tres`
- Modify: `data/components/trigger_满血.tres`
- Modify: `data/components/trigger_规则触发.tres`
- Modify: `data/components/effect_护盾.tres`
- Modify: `data/components/effect_减伤.tres`
- Modify: `data/components/effect_吸血.tres`
- Modify: `data/components/effect_强化.tres`
- Modify: `data/components/effect_增伤.tres`
- Modify: `data/components/effect_蓄能.tres`
- Modify: `data/components/effect_灼烧.tres`
- Modify: `data/components/effect_侵蚀.tres`

- [ ] **Step 1: Set slot_type = 2 on all 14 former trigger/effect-only files**

For each of the 14 files above, change `slot_type = 0` or `slot_type = 1` to `slot_type = 2`.

For the 6 former effect-only files that currently have no `trigger_formula` or `trigger_value`, add:

```
trigger_formula = "fires_every"
trigger_value = 2.0
```

The 8 former trigger-only files already have `trigger_formula = "fires_every"` and a `trigger_value`. Only `slot_type` needs changing.

- [ ] **Step 2: Verify with a quick grep**

```bash
grep -r "slot_type" data/components/
```

Expected: all files show `slot_type = 2` except `trigger_完成圈数.tres` which stays `slot_type = 0`.

- [ ] **Step 3: Commit**

```bash
git add data/components/
git commit -m "feat: upgrade 14 components to BOTH slot_type"
```

---

## Task 8: Run full test suite and verify

- [ ] **Step 1: Run all unit tests**

```bash
cd "S:/attribute-loop" && powershell -NoProfile -File scripts/self-test.ps1
```

Expected: all tests pass (80+)

- [ ] **Step 2: Verify InventoryPanel still filters correctly**

The slot enforcement in `InventoryPanel._make_slot_handler()` checks `EFFECT_ONLY` and `TRIGGER_ONLY` to block wrong-slot placement. With everything now `BOTH`, all components will be freely placeable in either slot — which is the intended design. No code change needed; confirm the existing check:

```gdscript
var wrong_type = (is_trigger and _selected.slot_type == ComponentData.SlotType.EFFECT_ONLY) or \
                 (not is_trigger and _selected.slot_type == ComponentData.SlotType.TRIGGER_ONLY)
```

This still works correctly for `完成圈数` (slot_type = 0, TRIGGER_ONLY) — it cannot be placed in an E slot.

- [ ] **Step 3: Commit final**

```bash
git add .
git commit -m "feat: BOTH components expansion — all 15 components upgraded"
```
