# Boss Circle Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** After a pressure circle completes or the altar is activated, the next loop spawns a single boss enemy at the last tile with scaled HP, damage, and sprite size.

**Architecture:** A `boss_circle_pending` flag in GameState is set by two triggers (pressure window hit, altar activated) and consumed at the start of the next `spawn_enemies()` call, which branches into a boss-only spawn path. PhaseData carries per-phase multiplier fields. HUD reads the flag each frame to show a boss indicator.

**Tech Stack:** Godot 4, GDScript, GUT test framework

---

### Task 1: Add `boss_circle_pending` to GameState

**Files:**
- Modify: `src/autoloads/GameState.gd`
- Test: `tests/unit/test_game_state.gd`

- [ ] **Step 1: Write the failing test**

Add to `tests/unit/test_game_state.gd`:

```gdscript
func test_boss_circle_pending_false_after_reset() -> void:
    GameState.boss_circle_pending = true
    GameState.reset()
    assert_false(GameState.boss_circle_pending)
```

- [ ] **Step 2: Run test to verify it fails**

```
cd "S:/attribute-loop" && powershell -NoProfile -File scripts/self-test.ps1
```

Expected: FAIL — `boss_circle_pending` not found on GameState.

- [ ] **Step 3: Add field to GameState.gd**

After line 29 (`var verdict_loops_survived: int = 0`), add:

```gdscript
var boss_circle_pending: bool = false
```

In `reset()`, after `verdict_loops_survived = 0` (line 72), add:

```gdscript
boss_circle_pending = false
```

- [ ] **Step 4: Run test to verify it passes**

```
cd "S:/attribute-loop" && powershell -NoProfile -File scripts/self-test.ps1
```

Expected: PASS.

- [ ] **Step 5: Commit**

```
git add src/autoloads/GameState.gd tests/unit/test_game_state.gd
git commit -m "feat: add boss_circle_pending flag to GameState"
```

---

### Task 2: Add boss multiplier fields to PhaseData

**Files:**
- Modify: `src/resources/PhaseData.gd`

Note: Godot Resource files (`data/phases/phase_X.tres`) automatically use script defaults for unset `@export` fields — no .tres edits are required for default behaviour. To customize per-phase values, open the relevant .tres in a text editor and add the fields.

- [ ] **Step 1: Add three export fields to PhaseData.gd**

After line 17 (`@export var component_weight_modifiers: Dictionary = {}`), add:

```gdscript
@export var boss_hp_multiplier: float = 2.0
@export var boss_damage_multiplier: float = 2.0
@export var boss_scale: float = 1.6
```

- [ ] **Step 2: Verify syntax via self-test**

```
cd "S:/attribute-loop" && powershell -NoProfile -File scripts/self-test.ps1
```

Expected: all existing tests still PASS.

- [ ] **Step 3: Commit**

```
git add src/resources/PhaseData.gd
git commit -m "feat: add boss_hp_multiplier, boss_damage_multiplier, boss_scale to PhaseData"
```

---

### Task 3: Add static boss modifier helper to GameLoop + test

**Files:**
- Modify: `src/systems/GameLoop.gd`
- Test: `tests/unit/test_game_loop.gd`

- [ ] **Step 1: Write the failing tests**

Add to `tests/unit/test_game_loop.gd`:

```gdscript
func test_apply_boss_modifiers_scales_hp() -> void:
    var enemy := Enemy.new()
    enemy.hp_max = 100
    enemy.hp = 100
    enemy.dmg = 20
    var phase_data := PhaseData.new()
    phase_data.boss_hp_multiplier = 3.0
    phase_data.boss_damage_multiplier = 2.0
    phase_data.boss_scale = 1.5
    GameLoop._apply_boss_modifiers(enemy, phase_data)
    assert_eq(enemy.hp_max, 300)
    assert_eq(enemy.hp, 300)
    enemy.free()

func test_apply_boss_modifiers_scales_dmg() -> void:
    var enemy := Enemy.new()
    enemy.hp_max = 100
    enemy.hp = 100
    enemy.dmg = 20
    var phase_data := PhaseData.new()
    phase_data.boss_hp_multiplier = 2.0
    phase_data.boss_damage_multiplier = 2.0
    phase_data.boss_scale = 1.0
    GameLoop._apply_boss_modifiers(enemy, phase_data)
    assert_eq(enemy.dmg, 40)
    enemy.free()

func test_apply_boss_modifiers_sets_scale() -> void:
    var enemy := Enemy.new()
    enemy.hp_max = 100
    enemy.hp = 100
    enemy.dmg = 10
    var phase_data := PhaseData.new()
    phase_data.boss_hp_multiplier = 1.0
    phase_data.boss_damage_multiplier = 1.0
    phase_data.boss_scale = 2.0
    GameLoop._apply_boss_modifiers(enemy, phase_data)
    assert_almost_eq(enemy.scale.x, 2.0, 0.001)
    assert_almost_eq(enemy.scale.y, 2.0, 0.001)
    enemy.free()
```

- [ ] **Step 2: Run tests to verify they fail**

```
cd "S:/attribute-loop" && powershell -NoProfile -File scripts/self-test.ps1
```

Expected: FAIL — `_apply_boss_modifiers` not found.

- [ ] **Step 3: Add static helper to GameLoop.gd**

After the `## Pure functions used by tests` comment (line 196), add:

```gdscript
static func _apply_boss_modifiers(enemy: Enemy, phase_data: PhaseData) -> void:
    enemy.hp_max = int(enemy.hp_max * phase_data.boss_hp_multiplier)
    enemy.hp = enemy.hp_max
    enemy.dmg = int(enemy.dmg * phase_data.boss_damage_multiplier)
    enemy.scale = Vector2.ONE * phase_data.boss_scale
```

- [ ] **Step 4: Run tests to verify they pass**

```
cd "S:/attribute-loop" && powershell -NoProfile -File scripts/self-test.ps1
```

Expected: 3 new tests PASS, all existing tests still PASS.

- [ ] **Step 5: Commit**

```
git add src/systems/GameLoop.gd tests/unit/test_game_loop.gd
git commit -m "feat: add _apply_boss_modifiers static helper to GameLoop"
```

---

### Task 4: Wire boss spawn logic into GameLoop

**Files:**
- Modify: `src/systems/GameLoop.gd`

This task adds the boss spawn path in `spawn_enemies()`, connects the `altar_activated` signal, and sets the flag at the pressure window.

- [ ] **Step 1: Add `_on_altar_activated` handler and connect it in `setup()`**

In `setup()` (line 18), after `EventBus.player_died.connect(_on_player_died)` (line 25), add:

```gdscript
    EventBus.altar_activated.connect(_on_altar_activated)
```

After `_on_player_died()` function (line 134), add:

```gdscript
func _on_altar_activated() -> void:
    GameState.boss_circle_pending = true
```

- [ ] **Step 2: Set flag at pressure window in `_on_loop_completed()`**

In `_on_loop_completed()`, at line 102 (`if GameState.loops_in_phase >= phase_data.world_pressure_window:`), add the flag assignment as the first line inside that block:

```gdscript
                if GameState.loops_in_phase >= phase_data.world_pressure_window:
                    GameState.boss_circle_pending = true
                    if not _altar_is_full(_tiles[0]):
```

- [ ] **Step 3: Add boss spawn path at the top of `spawn_enemies()`**

In `spawn_enemies()`, after the `for tile in _tiles: tile.clear_enemy()` block (after line 35), add the boss path before the `var config` line:

```gdscript
    if GameState.boss_circle_pending:
        GameState.boss_circle_pending = false
        var b_phase := DataTables.config.verdict_spawn_phase if GameState.in_verdict_loop else GameState.current_phase
        var b_phase_data: PhaseData = DataTables.get_phase(b_phase)
        var last_idx := _tiles.size() - 1
        var b_enemy_id := _pick_enemy_id(b_phase_data, b_phase)
        var b_enemy: Enemy = _enemy_scene.instantiate()
        _enemies_container.add_child(b_enemy)
        b_enemy.init(b_enemy_id, b_phase)
        b_enemy.position = _tiles[last_idx].guard_position
        _tiles[last_idx].place_enemy(b_enemy)
        _assign_components(b_enemy, b_phase)
        _apply_boss_modifiers(b_enemy, b_phase_data)
        return
```

- [ ] **Step 4: Run self-test to confirm no regressions**

```
cd "S:/attribute-loop" && powershell -NoProfile -File scripts/self-test.ps1
```

Expected: all tests PASS.

- [ ] **Step 5: Commit**

```
git add src/systems/GameLoop.gd
git commit -m "feat: spawn boss enemy at last tile when boss_circle_pending"
```

---

### Task 5: Show Boss圈 indicator in HUD

**Files:**
- Modify: `src/ui/HUD.gd`

- [ ] **Step 1: Add boss circle display branch in `_process()`**

In `HUD.gd`, the `_process()` function currently has this structure (lines 75–84):

```gdscript
    if GameState.in_verdict_loop:
        var cfg: GameConfig = DataTables.config
        phase_label.text = "裁决圈"
        pressure_label.text = "进度: %d/%d圈" % [GameState.verdict_loops_survived, cfg.verdict_survive_loops]
    else:
        var phase_data: PhaseData = DataTables.get_phase(GameState.current_phase)
        phase_label.text = "阶段%d · %s" % [GameState.current_phase, phase_data.phase_name]
        pressure_label.text = "压力: %d/%d圈" % [GameState.loops_in_phase, phase_data.world_pressure_window]
        for i in GameState.rule_slots.size():
            _update_rule_panel(i)
```

Replace this block with:

```gdscript
    if GameState.in_verdict_loop:
        var cfg: GameConfig = DataTables.config
        phase_label.text = "裁决圈"
        pressure_label.text = "进度: %d/%d圈" % [GameState.verdict_loops_survived, cfg.verdict_survive_loops]
    elif GameState.boss_circle_pending:
        var phase_data: PhaseData = DataTables.get_phase(GameState.current_phase)
        phase_label.text = "阶段%d · %s  Boss圈" % [GameState.current_phase, phase_data.phase_name]
        pressure_label.text = "压力: %d/%d圈" % [GameState.loops_in_phase, phase_data.world_pressure_window]
        for i in GameState.rule_slots.size():
            _update_rule_panel(i)
    else:
        var phase_data: PhaseData = DataTables.get_phase(GameState.current_phase)
        phase_label.text = "阶段%d · %s" % [GameState.current_phase, phase_data.phase_name]
        pressure_label.text = "压力: %d/%d圈" % [GameState.loops_in_phase, phase_data.world_pressure_window]
        for i in GameState.rule_slots.size():
            _update_rule_panel(i)
```

- [ ] **Step 2: Run self-test to confirm no regressions**

```
cd "S:/attribute-loop" && powershell -NoProfile -File scripts/self-test.ps1
```

Expected: all tests PASS.

- [ ] **Step 3: Commit**

```
git add src/ui/HUD.gd
git commit -m "feat: show Boss圈 indicator in HUD phase label"
```
