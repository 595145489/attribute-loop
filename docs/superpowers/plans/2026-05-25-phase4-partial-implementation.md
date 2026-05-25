# Phase 4 Partial Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add world pressure (auto Phase advance without buff when altar not filled in time) and complete 急袭者 enemy data.

**Architecture:** GameState gains `loops_in_phase` counter and `force_phase_advance()`. GameLoop checks the counter on every loop completion and triggers forced advance if the altar is not full. AltarPanel resets the counter when the player activates normally. HUD shows a pressure readout.

**Tech Stack:** Godot 4 GDScript, GUT test framework, `.tres` resource files.

---

## File Map

| File | Change |
|------|--------|
| `src/autoloads/GameState.gd` | Add `loops_in_phase`, `force_phase_advance()`, reset in `reset()` |
| `src/systems/GameLoop.gd` | Add `_altar_is_full()`, pressure check in `_on_loop_completed()` |
| `src/ui/AltarPanel.gd` | Reset `loops_in_phase = 0` in `_on_activate()` |
| `src/ui/HUD.gd` | Add `pressure_label` onready, update in `_process` |
| `scenes/ui/hud.tscn` | Add `PressurePill` + `PressureLabel` nodes |
| `data/enemies/enemy_急袭者.tres` | Add missing fields |
| `tests/unit/test_game_state.gd` | New tests for `loops_in_phase` and `force_phase_advance` |
| `tests/unit/test_game_loop.gd` | New tests for `_altar_is_full` |
| `tests/unit/test_data_tables.gd` | New tests for 急袭者 completeness |

---

## Task 1: GameState — loops_in_phase + force_phase_advance

**Files:**
- Modify: `tests/unit/test_game_state.gd`
- Modify: `src/autoloads/GameState.gd`

- [ ] **Step 1: Write failing tests**

Append to `tests/unit/test_game_state.gd`:

```gdscript
func test_loops_in_phase_zero_after_reset() -> void:
	GameState.loops_in_phase = 5
	GameState.reset()
	assert_eq(GameState.loops_in_phase, 0)

func test_force_phase_advance_increments_phase() -> void:
	GameState.current_phase = 1
	GameState.force_phase_advance()
	assert_eq(GameState.current_phase, 2)

func test_force_phase_advance_resets_loops_in_phase() -> void:
	GameState.loops_in_phase = 7
	GameState.force_phase_advance()
	assert_eq(GameState.loops_in_phase, 0)

func test_force_phase_advance_emits_phase_changed() -> void:
	watch_signals(EventBus)
	GameState.force_phase_advance()
	assert_signal_emitted(EventBus, "phase_changed")
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
cd "S:/attribute-loop" && powershell -NoProfile -File scripts/self-test.ps1 2>&1 | tail -10
```

Expected: errors about `loops_in_phase` not found and `force_phase_advance` not found.

- [ ] **Step 3: Add field and method to GameState**

In `src/autoloads/GameState.gd`, add `loops_in_phase` after line 14 (`var altar_bonuses`):

```gdscript
var loops_in_phase: int = 0
```

In `reset()`, add after line 35 (`altar_bonuses = {}`):

```gdscript
loops_in_phase = 0
```

Add new method at the end of the file:

```gdscript
func force_phase_advance() -> void:
	current_phase += 1
	loops_in_phase = 0
	EventBus.phase_changed.emit(current_phase)
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
cd "S:/attribute-loop" && powershell -NoProfile -File scripts/self-test.ps1 2>&1 | tail -10
```

Expected: `All tests passed.`

- [ ] **Step 5: Commit**

```bash
cd "S:/attribute-loop" && git add src/autoloads/GameState.gd tests/unit/test_game_state.gd && git commit -m "feat: GameState loops_in_phase counter + force_phase_advance"
```

---

## Task 2: 急袭者 Data — Complete the .tres

**Files:**
- Modify: `data/enemies/enemy_急袭者.tres`
- Modify: `tests/unit/test_data_tables.gd`

- [ ] **Step 1: Write failing tests**

Append to `tests/unit/test_data_tables.gd`:

```gdscript
func test_急袭者_has_trigger_weights() -> void:
	var e: EnemyData = DataTables.get_enemy("急袭者")
	assert_false(e.trigger_weights.is_empty(), "急袭者 must have trigger_weights")

func test_急袭者_has_effect_weights() -> void:
	var e: EnemyData = DataTables.get_enemy("急袭者")
	assert_false(e.effect_weights.is_empty(), "急袭者 must have effect_weights")

func test_急袭者_has_drop_preset() -> void:
	var e: EnemyData = DataTables.get_enemy("急袭者")
	assert_false(e.phase_drop_presets.is_empty(), "急袭者 must have phase_drop_presets")

func test_急袭者_unlock_phase_is_4() -> void:
	var e: EnemyData = DataTables.get_enemy("急袭者")
	assert_eq(e.unlock_phase, 4)

func test_pick_enemy_id_can_return_急袭者_at_phase_4() -> void:
	var phase: PhaseData = DataTables.get_phase(4)
	var found := false
	for i in 200:
		if GameLoop._pick_enemy_id(phase, 4) == "急袭者":
			found = true
			break
	assert_true(found, "急袭者 must be pickable from phase 4 spawn weights")
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
cd "S:/attribute-loop" && powershell -NoProfile -File scripts/self-test.ps1 2>&1 | tail -10
```

Expected: failures on trigger_weights / effect_weights / phase_drop_presets empty.

- [ ] **Step 3: Complete the .tres file**

Replace the full contents of `data/enemies/enemy_急袭者.tres` with:

```
[gd_resource type="Resource" script_class="EnemyData" format=3 uid="uid://cq6tjscutptne"]

[ext_resource type="Script" uid="uid://c4nlyntn501y2" path="res://src/resources/EnemyData.gd" id="1_0fmkg"]
[ext_resource type="Resource" path="res://data/drop_presets/drop_tier_03.tres" id="2_jirush"]

[resource]
script = ExtResource("1_0fmkg")
id = "急袭者"
hp_base = 25
dmg_base = 10
gold_min = 20
gold_max = 50
gold_scale = 0.3
unlock_phase = 4
attack_interval = 0.4
component_pair_min = 1
component_pair_max = 2
trigger_weights = {
"受击": 35,
"击杀": 35,
"经过": 30
}
effect_weights = {
"治愈": 50,
"反射": 50
}
phase_drop_presets = {
4: ExtResource("2_jirush")
}
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
cd "S:/attribute-loop" && powershell -NoProfile -File scripts/self-test.ps1 2>&1 | tail -10
```

Expected: `All tests passed.`

- [ ] **Step 5: Commit**

```bash
cd "S:/attribute-loop" && git add data/enemies/enemy_急袭者.tres tests/unit/test_data_tables.gd && git commit -m "feat: complete 急袭者 enemy data — weights, drop preset, gold scale"
```

---

## Task 3: GameLoop — Pressure Check

**Files:**
- Modify: `tests/unit/test_game_loop.gd`
- Modify: `src/systems/GameLoop.gd`

- [ ] **Step 1: Write failing tests for _altar_is_full**

Append to `tests/unit/test_game_loop.gd`:

```gdscript
func test_altar_is_full_false_when_empty_array() -> void:
	var tile := Tile.new()
	tile.altar_slots = []
	assert_false(GameLoop._altar_is_full(tile))
	tile.free()

func test_altar_is_full_false_when_any_slot_null() -> void:
	var tile := Tile.new()
	var c := ComponentData.new()
	tile.altar_slots = [c, null]
	assert_false(GameLoop._altar_is_full(tile))
	tile.free()

func test_altar_is_full_true_when_all_slots_filled() -> void:
	var tile := Tile.new()
	var c1 := ComponentData.new()
	var c2 := ComponentData.new()
	tile.altar_slots = [c1, c2]
	assert_true(GameLoop._altar_is_full(tile))
	tile.free()
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
cd "S:/attribute-loop" && powershell -NoProfile -File scripts/self-test.ps1 2>&1 | tail -10
```

Expected: error — `_altar_is_full` not found.

- [ ] **Step 3: Add _altar_is_full helper and pressure check**

In `src/systems/GameLoop.gd`, replace `_on_loop_completed` (lines 53–57):

```gdscript
func _on_loop_completed() -> void:
	if state == State.WALKING:
		GameState.loops_in_phase += 1
		var phase_data: PhaseData = DataTables.get_phase(GameState.current_phase)
		if GameState.loops_in_phase >= phase_data.world_pressure_window:
			if not _altar_is_full(_tiles[0]):
				GameState.force_phase_advance()
		for tile in _tiles:
			tile.visited_this_loop = false
		spawn_enemies()
```

Add static helper at the end of `src/systems/GameLoop.gd` (after `_pick_tile_indices`):

```gdscript
static func _altar_is_full(altar: Tile) -> bool:
	if altar.altar_slots.is_empty():
		return false
	for slot in altar.altar_slots:
		if slot == null:
			return false
	return true
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
cd "S:/attribute-loop" && powershell -NoProfile -File scripts/self-test.ps1 2>&1 | tail -10
```

Expected: `All tests passed.`

- [ ] **Step 5: Commit**

```bash
cd "S:/attribute-loop" && git add src/systems/GameLoop.gd tests/unit/test_game_loop.gd && git commit -m "feat: world pressure check in GameLoop — auto Phase advance when altar not filled"
```

---

## Task 4: AltarPanel — Reset loops_in_phase on Activate

**Files:**
- Modify: `src/ui/AltarPanel.gd`

No unit test needed — the one-line change is covered by manual verification during the visual integration test.

- [ ] **Step 1: Add reset before phase_changed emit**

In `src/ui/AltarPanel.gd`, replace `_on_activate` (lines 107–116):

```gdscript
func _on_activate() -> void:
	for raw in _tile.altar_slots:
		var comp := raw as ComponentData
		if comp == null:
			continue
		var bonus: float = comp.effect_value * comp.altar_ratio
		GameState.altar_bonuses[comp.id] = GameState.altar_bonuses.get(comp.id, 0.0) as float + bonus
	_tile.altar_slots.fill(null)
	GameState.current_phase += 1
	GameState.loops_in_phase = 0
	EventBus.phase_changed.emit(GameState.current_phase)
	close()
```

- [ ] **Step 2: Run tests to confirm nothing broken**

```bash
cd "S:/attribute-loop" && powershell -NoProfile -File scripts/self-test.ps1 2>&1 | tail -10
```

Expected: `All tests passed.`

- [ ] **Step 3: Commit**

```bash
cd "S:/attribute-loop" && git add src/ui/AltarPanel.gd && git commit -m "feat: reset loops_in_phase on altar activation"
```

---

## Task 5: HUD — Pressure Label

**Files:**
- Modify: `scenes/ui/hud.tscn`
- Modify: `src/ui/HUD.gd`

- [ ] **Step 1: Add PressurePill node to hud.tscn**

In `scenes/ui/hud.tscn`, insert after line 290 (`text = "金: 0"`) and before the `[node name="FloatLabel"...]` line:

```
[node name="PressurePill" type="PanelContainer" parent="BottomBar/HContent" unique_id=312987654]
layout_mode = 2

[node name="PressureLabel" type="Label" parent="BottomBar/HContent/PressurePill" unique_id=312987655]
layout_mode = 2
text = "压力: 0/10圈"
```

- [ ] **Step 2: Add onready and update in HUD.gd**

In `src/ui/HUD.gd`, add after line 14 (`@onready var gold_label`):

```gdscript
@onready var pressure_label: Label = $BottomBar/HContent/PressurePill/PressureLabel
```

In `_process`, add after line 57 (`gold_label.text = ...`). Note: `phase_data` is already declared earlier in this function — reuse it directly:

```gdscript
pressure_label.text = "压力: %d/%d圈" % [GameState.loops_in_phase, phase_data.world_pressure_window]
```

- [ ] **Step 3: Run tests to confirm no regressions**

```bash
cd "S:/attribute-loop" && powershell -NoProfile -File scripts/self-test.ps1 2>&1 | tail -10
```

Expected: `All tests passed.`

- [ ] **Step 4: Commit**

```bash
cd "S:/attribute-loop" && git add scenes/ui/hud.tscn src/ui/HUD.gd && git commit -m "feat: HUD pressure counter — shows loops_in_phase / world_pressure_window"
```
