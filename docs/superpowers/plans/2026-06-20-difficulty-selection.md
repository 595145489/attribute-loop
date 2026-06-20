# Difficulty Selection Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add an Easy/Hard difficulty choice after clicking "开始游戏"; Easy pre-fills the player's 3 rule slots and 5 of 12 tile rule slots with a starter build, Hard keeps current empty-build behavior.

**Architecture:** A `difficulty` flag on `GameState` (set by `LoadingScreen` before `reset()`) drives slot count and preset application. Preset data (component id pairs + fixed values) lives as constants on `DataTables`, with helper methods that duplicate `ComponentData` resources into slot dicts. `Main._finish_setup()` applies the Easy preset to the player and tiles after `_build_tiles()`. `LoadingScreen` builds a difficulty-selection panel in code and launches the game with the chosen difficulty. Test-mode auto-launches Hard to preserve existing automated tests.

**Tech Stack:** Godot 4, GDScript, GUT unit tests, project self-test protocol (`scripts/self-test.ps1`).

**Spec:** `docs/superpowers/specs/2026-06-20-difficulty-selection-design.md`

---

## File Structure

- **Modify** `src/autoloads/GameState.gd` — add `difficulty` field; make `reset()` create 3 slots for Easy / 2 for Hard; add `apply_easy_player_slots()`.
- **Modify** `src/autoloads/DataTables.gd` — add `EASY_PLAYER_SLOTS` / `EASY_TILE_RULES` constants, `make_easy_slot(spec)`, `apply_easy_tile_rules(tiles)`.
- **Modify** `src/Main.gd` — apply Easy preset in `_finish_setup()` after `_build_tiles()`.
- **Modify** `src/ui/LoadingScreen.gd` — build difficulty panel in code; route Start → panel; launch with chosen difficulty; test-mode auto-launch Hard.
- **Create** `tests/unit/test_difficulty_preset.gd` — GUT tests for preset + apply helpers.
- **Create** `docs/modules/difficulty-selection.md` — module documentation.

No changes needed to `InventoryPanel.gd` (already iterates `GameState.rule_slots.size()` dynamically) or `loading_screen.tscn` (panel built in code).

---

## Task 1: Add `difficulty` to GameState and make reset() difficulty-aware

**Files:**
- Modify: `src/autoloads/GameState.gd` (field near line 28; `reset()` lines 64-103)
- Test: `tests/unit/test_game_state.gd` (update `before_each`; add tests)

- [ ] **Step 1: Write the failing tests**

In `tests/unit/test_game_state.gd`, update `before_each` to reset difficulty and add new tests. Replace the existing `before_each`:

```gdscript
func before_each() -> void:
    GameState.difficulty = "hard"
    GameState.reset()
```

Append these tests at the end of the file:

```gdscript
func test_difficulty_defaults_hard() -> void:
    GameState.difficulty = "hard"
    GameState.reset()
    assert_eq(GameState.difficulty, "hard")

func test_reset_creates_2_slots_for_hard() -> void:
    GameState.difficulty = "hard"
    GameState.reset()
    assert_eq(GameState.rule_slots.size(), 2)

func test_reset_creates_3_slots_for_easy() -> void:
    GameState.difficulty = "easy"
    GameState.reset()
    assert_eq(GameState.rule_slots.size(), 3)

func test_reset_does_not_clear_difficulty() -> void:
    GameState.difficulty = "easy"
    GameState.reset()
    assert_eq(GameState.difficulty, "easy")
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `cd "S:/attribute-loop" && powershell -NoProfile -File scripts/self-test.ps1`
Expected: FAIL — `difficulty` property does not exist; slot count is 2 for both.

- [ ] **Step 3: Add the `difficulty` field**

In `src/autoloads/GameState.gd`, add after line 28 (`var is_tutorial: bool = false`):

```gdscript
var difficulty: String = "hard"
```

- [ ] **Step 4: Make `reset()` create difficulty-aware slot count**

In `src/autoloads/GameState.gd`, replace the block at lines 102-103:

```gdscript
	for i in 2:
		rule_slots.append({"trigger": null, "effect": null})
```

with:

```gdscript
	var slot_count := 3 if difficulty == "easy" else 2
	for i in slot_count:
		rule_slots.append({"trigger": null, "effect": null})
```

Note: `reset()` must NOT assign `difficulty` (it is chosen at game start and persists for the run; `LoadingScreen` sets it before calling `reset()`).

- [ ] **Step 5: Run tests to verify they pass**

Run: `cd "S:/attribute-loop" && powershell -NoProfile -File scripts/self-test.ps1`
Expected: PASS — all tests including the four new ones.

- [ ] **Step 6: Commit**

```bash
git add src/autoloads/GameState.gd tests/unit/test_game_state.gd
git commit -m "feat(state): add difficulty flag and difficulty-aware rule-slot count"
```

---

## Task 2: Add Easy preset constants and `make_easy_slot` to DataTables

**Files:**
- Modify: `src/autoloads/DataTables.gd` (add constants after line 4; add methods near `get_component`)
- Test: `tests/unit/test_difficulty_preset.gd` (create)

- [ ] **Step 1: Write the failing tests**

Create `tests/unit/test_difficulty_preset.gd`:

```gdscript
extends GutTest

func test_easy_player_slots_has_three_entries() -> void:
	assert_eq(DataTables.EASY_PLAYER_SLOTS.size(), 3)

func test_easy_tile_rules_has_five_entries() -> void:
	assert_eq(DataTables.EASY_TILE_RULES.size(), 5)

func test_easy_tile_rules_targets_expected_tiles() -> void:
	assert_true(DataTables.EASY_TILE_RULES.has(1))
	assert_true(DataTables.EASY_TILE_RULES.has(5))
	assert_true(DataTables.EASY_TILE_RULES.has(8))
	assert_true(DataTables.EASY_TILE_RULES.has(9))
	assert_true(DataTables.EASY_TILE_RULES.has(12))

func test_make_easy_slot_sets_ids_and_values() -> void:
	var spec := {"trigger": "受击", "trigger_value": 5, "effect": "治愈", "effect_value": 12}
	var slot: Dictionary = DataTables.make_easy_slot(spec)
	assert_eq(slot["trigger"].id, "受击")
	assert_eq(slot["effect"].id, "治愈")
	assert_eq(slot["trigger"].trigger_value, 5.0)
	assert_eq(slot["effect"].effect_value, 12.0)
	assert_eq(slot["trigger"].trigger_count, 0)
	assert_eq(slot["effect"].trigger_count, 0)

func test_make_easy_slot_duplicates_instances() -> void:
	var spec := {"trigger": "经过", "trigger_value": 6, "effect": "护盾", "effect_value": 15}
	var slot: Dictionary = DataTables.make_easy_slot(spec)
	assert_false(slot["trigger"] == DataTables.get_component("经过"))
	assert_false(slot["effect"] == DataTables.get_component("护盾"))
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `cd "S:/attribute-loop" && powershell -NoProfile -File scripts/self-test.ps1`
Expected: FAIL — `EASY_PLAYER_SLOTS` / `make_easy_slot` do not exist.

- [ ] **Step 3: Add preset constants**

In `src/autoloads/DataTables.gd`, after line 4 (the `TILE_MAX_RULES` const), add:

```gdscript
# Easy difficulty starter build. trigger_value = N for fires_every triggers;
# effect_value = magnitude for the paired effect. Components are duplicated at
# apply time so each slot owns its own instance.
const EASY_PLAYER_SLOTS := [
	{"trigger": "受击", "trigger_value": 5, "effect": "治愈", "effect_value": 12},
	{"trigger": "治愈", "trigger_value": 3, "effect": "灼烧", "effect_value": 2},
	{"trigger": "治愈", "trigger_value": 3, "effect": "护盾", "effect_value": 15},
]

const EASY_TILE_RULES := {
	1: {"trigger": "经过", "trigger_value": 6, "effect": "增伤", "effect_value": 1},
	5: {"trigger": "经过", "trigger_value": 6, "effect": "减伤", "effect_value": 1},
	8: {"trigger": "经过", "trigger_value": 6, "effect": "治愈", "effect_value": 12},
	9: {"trigger": "经过", "trigger_value": 6, "effect": "护盾", "effect_value": 15},
	12: {"trigger": "经过", "trigger_value": 6, "effect": "护盾", "effect_value": 15},
}
```

- [ ] **Step 4: Add `make_easy_slot` method**

In `src/autoloads/DataTables.gd`, after the `get_component` function (line 64-65), add:

```gdscript
func make_easy_slot(spec: Dictionary) -> Dictionary:
	var t: ComponentData = get_component(spec["trigger"]).duplicate()
	t.trigger_value = float(spec["trigger_value"])
	t.trigger_count = 0
	var e: ComponentData = get_component(spec["effect"]).duplicate()
	e.effect_value = float(spec["effect_value"])
	e.trigger_count = 0
	return {"trigger": t, "effect": e}
```

- [ ] **Step 5: Run tests to verify they pass**

Run: `cd "S:/attribute-loop" && powershell -NoProfile -File scripts/self-test.ps1`
Expected: PASS — all tests including the five new ones.

- [ ] **Step 6: Commit**

```bash
git add src/autoloads/DataTables.gd tests/unit/test_difficulty_preset.gd
git commit -m "feat(data): add Easy difficulty preset constants and make_easy_slot helper"
```

---

## Task 3: Add `apply_easy_player_slots` to GameState

**Files:**
- Modify: `src/autoloads/GameState.gd` (add method after `unequip`, ~line 152)
- Test: `tests/unit/test_difficulty_preset.gd` (append tests)

- [ ] **Step 1: Write the failing tests**

Append to `tests/unit/test_difficulty_preset.gd`:

```gdscript
func test_apply_easy_player_slots_fills_three_slots() -> void:
	GameState.difficulty = "easy"
	GameState.reset()
	GameState.apply_easy_player_slots()
	assert_eq(GameState.rule_slots.size(), 3)
	assert_eq(GameState.rule_slots[0]["trigger"].id, "受击")
	assert_eq(GameState.rule_slots[0]["effect"].id, "治愈")
	assert_eq(GameState.rule_slots[1]["trigger"].id, "治愈")
	assert_eq(GameState.rule_slots[1]["effect"].id, "灼烧")
	assert_eq(GameState.rule_slots[2]["trigger"].id, "治愈")
	assert_eq(GameState.rule_slots[2]["effect"].id, "护盾")

func test_apply_easy_player_slots_owns_distinct_instances() -> void:
	GameState.difficulty = "easy"
	GameState.reset()
	GameState.apply_easy_player_slots()
	# Two slots use 治愈 as trigger; they must be separate instances.
	assert_false(GameState.rule_slots[1]["trigger"] == GameState.rule_slots[2]["trigger"])
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `cd "S:/attribute-loop" && powershell -NoProfile -File scripts/self-test.ps1`
Expected: FAIL — `apply_easy_player_slots` does not exist.

- [ ] **Step 3: Add the method**

In `src/autoloads/GameState.gd`, after the `unequip` function (lines 146-152), add:

```gdscript
func apply_easy_player_slots() -> void:
	rule_slots.clear()
	for spec in DataTables.EASY_PLAYER_SLOTS:
		rule_slots.append(DataTables.make_easy_slot(spec))
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `cd "S:/attribute-loop" && powershell -NoProfile -File scripts/self-test.ps1`
Expected: PASS — all tests including the two new ones.

- [ ] **Step 5: Commit**

```bash
git add src/autoloads/GameState.gd tests/unit/test_difficulty_preset.gd
git commit -m "feat(state): apply Easy preset to player rule slots"
```

---

## Task 4: Add `apply_easy_tile_rules` to DataTables

**Files:**
- Modify: `src/autoloads/DataTables.gd` (add method after `make_easy_slot`)
- Test: `tests/unit/test_difficulty_preset.gd` (append tests)

- [ ] **Step 1: Write the failing tests**

Append to `tests/unit/test_difficulty_preset.gd`:

```gdscript
func _make_tile(idx: int, altar: bool = false) -> Tile:
	var t := Tile.new()
	t.tile_index = idx
	t.is_altar = altar
	add_child_autofree(t)
	return t

func test_apply_easy_tile_rules_fills_five_tiles() -> void:
	var tiles: Array = []
	for i in range(13):
		tiles.append(_make_tile(i, i == 0))
	DataTables.apply_easy_tile_rules(tiles)
	var filled: Array = []
	for t in tiles:
		if t.tile_index > 0 and not t.rule_slots.is_empty() and t.rule_slots[0]["trigger"] != null:
			filled.append(t.tile_index)
	assert_eq(filled.size(), 5)
	for idx in [1, 5, 8, 9, 12]:
		assert_true(filled.has(idx), "expected tile %d filled" % idx)

func test_apply_easy_tile_rules_skips_altar() -> void:
	var tiles: Array = []
	for i in range(13):
		tiles.append(_make_tile(i, i == 0))
	DataTables.apply_easy_tile_rules(tiles)
	assert_eq(tiles[0].rule_slots.size(), 0)

func test_apply_easy_tile_rules_tile9_is_护盾() -> void:
	var tiles: Array = []
	for i in range(13):
		tiles.append(_make_tile(i, i == 0))
	DataTables.apply_easy_tile_rules(tiles)
	var t9: Tile = tiles[9]
	assert_eq(t9.rule_slots[0]["trigger"].id, "经过")
	assert_eq(t9.rule_slots[0]["effect"].id, "护盾")

func test_apply_easy_tile_rules_leaves_other_tiles_empty() -> void:
	var tiles: Array = []
	for i in range(13):
		tiles.append(_make_tile(i, i == 0))
	DataTables.apply_easy_tile_rules(tiles)
	var t2: Tile = tiles[2]
	assert_null(t2.rule_slots[0]["trigger"])
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `cd "S:/attribute-loop" && powershell -NoProfile -File scripts/self-test.ps1`
Expected: FAIL — `apply_easy_tile_rules` does not exist.

- [ ] **Step 3: Add the method**

In `src/autoloads/DataTables.gd`, immediately after the `make_easy_slot` method, add:

```gdscript
func apply_easy_tile_rules(tiles: Array) -> void:
	for tile in tiles:
		if not (tile is Tile):
			continue
		if not EASY_TILE_RULES.has(tile.tile_index):
			continue
		if tile.rule_slots.is_empty():
			continue
		tile.rule_slots[0] = make_easy_slot(EASY_TILE_RULES[tile.tile_index])
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `cd "S:/attribute-loop" && powershell -NoProfile -File scripts/self-test.ps1`
Expected: PASS — all tests including the four new ones.

- [ ] **Step 5: Commit**

```bash
git add src/autoloads/DataTables.gd tests/unit/test_difficulty_preset.gd
git commit -m "feat(data): apply Easy preset to tile rule slots"
```

---

## Task 5: Wire Easy preset application into Main

**Files:**
- Modify: `src/Main.gd` (`_finish_setup`, after line 49)

No unit test for this task (it depends on the full scene); the helpers it calls are tested in Tasks 3-4, and the integrated result is verified by the screenshot test in Task 7.

- [ ] **Step 1: Add preset application after `_build_tiles()`**

In `src/Main.gd`, in `_finish_setup()`, replace line 49:

```gdscript
	_tiles = _build_tiles()
```

with:

```gdscript
	_tiles = _build_tiles()
	if GameState.difficulty == "easy":
		GameState.apply_easy_player_slots()
		DataTables.apply_easy_tile_rules(_tiles)
```

- [ ] **Step 2: Run full test suite to confirm no regressions**

Run: `cd "S:/attribute-loop" && powershell -NoProfile -File scripts/self-test.ps1`
Expected: PASS — all tests green (default Hard path is unchanged).

- [ ] **Step 3: Commit**

```bash
git add src/Main.gd
git commit -m "feat(main): apply Easy preset to player and tiles on game setup"
```

---

## Task 6: Add difficulty selection panel to LoadingScreen

**Files:**
- Modify: `src/ui/LoadingScreen.gd` (full rewrite of start flow; add panel builder)

- [ ] **Step 1: Add node references and panel builder**

In `src/ui/LoadingScreen.gd`, replace the `@onready`/var block at the top (lines 4-12) with:

```gdscript
@onready var _progress: ProgressBar = $UI/Progress
@onready var _status: Label = $UI/Status
@onready var _start_button: Button = $UI/StartButton
@onready var _tutorial_button: Button = $UI/TutorialButton
@onready var _particles = $ParticleLayer/Particles
@onready var _difficulty_panel: Control = _build_difficulty_panel()

const TOTAL_STEPS := 6
const HINT_TEXT := "熟悉构筑类玩法的玩家可直接挑战困难；初次接触建议从简单开始，系统会为你预置一套基础构筑。"

var _step := 0
```

- [ ] **Step 2: Add the panel builder method**

In `src/ui/LoadingScreen.gd`, add after `_ready()` (before `_start_loading()`):

```gdscript
func _build_difficulty_panel() -> Control:
	var panel := Control.new()
	panel.name = "DifficultyPanel"
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.visible = false
	add_child(panel)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.add_child(center)

	var frame := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.05, 0.02, 0.9)
	sb.border_color = Color(0.85, 0.65, 0.2, 0.9)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(12)
	sb.content_margin_left = 36.0
	sb.content_margin_right = 36.0
	sb.content_margin_top = 28.0
	sb.content_margin_bottom = 28.0
	frame.add_theme_stylebox_override("panel", sb)
	center.add_child(frame)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 16)
	frame.add_child(vbox)

	var title := Label.new()
	title.text = "选择难度"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color(0.95, 0.88, 0.55, 1))
	vbox.add_child(title)

	var hint := Label.new()
	hint.text = HINT_TEXT
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.custom_minimum_size = Vector2(440, 0)
	hint.add_theme_font_size_override("font_size", 15)
	hint.add_theme_color_override("font_color", Color(0.92, 0.86, 0.72, 1))
	vbox.add_child(hint)

	var easy_btn := _make_difficulty_button("简单")
	easy_btn.pressed.connect(_on_easy_pressed)
	vbox.add_child(easy_btn)

	var hard_btn := _make_difficulty_button("困难")
	hard_btn.pressed.connect(_on_hard_pressed)
	vbox.add_child(hard_btn)

	var back_btn := _make_difficulty_button("返回")
	back_btn.pressed.connect(_on_back_pressed)
	vbox.add_child(back_btn)

	return panel

func _make_difficulty_button(text: String) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(260, 0)
	btn.add_theme_font_size_override("font_size", 22)
	btn.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	btn.add_theme_color_override("font_hover_color", Color(0.95, 0.88, 0.55, 1))
	btn.add_theme_color_override("font_pressed_color", Color(0.7, 0.7, 0.7, 1))
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.18, 0.12, 0.05, 0.85)
	sb.border_color = Color(0.85, 0.65, 0.2, 0.7)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 24.0
	sb.content_margin_right = 24.0
	sb.content_margin_top = 12.0
	sb.content_margin_bottom = 12.0
	btn.add_theme_stylebox_override("normal", sb)
	btn.add_theme_stylebox_override("hover", sb.duplicate())
	btn.add_theme_stylebox_override("pressed", sb.duplicate())
	btn.add_theme_stylebox_override("focus", sb)
	return btn
```

- [ ] **Step 3: Replace the start flow with difficulty-aware routing**

In `src/ui/LoadingScreen.gd`, replace the `_on_start_pressed` function (lines 32-39) with:

```gdscript
func _on_start_pressed() -> void:
	if _should_block_start():
		_show_must_play_tutorial_prompt()
		return
	if FileAccess.file_exists("res://tests/.test_mode"):
		_launch_game("hard")
		return
	_show_difficulty_panel()

func _show_difficulty_panel() -> void:
	_start_button.visible = false
	_tutorial_button.visible = false
	_difficulty_panel.visible = true

func _on_easy_pressed() -> void:
	_launch_game("easy")

func _on_hard_pressed() -> void:
	_launch_game("hard")

func _on_back_pressed() -> void:
	_difficulty_panel.visible = false
	_start_button.visible = true
	_tutorial_button.visible = true

func _launch_game(difficulty: String) -> void:
	GameState.difficulty = difficulty
	GameState.reset()
	GameState.is_tutorial = false
	_start_button.disabled = true
	get_tree().change_scene_to_file("res://scenes/main.tscn")
```

- [ ] **Step 4: Run full test suite to confirm no regressions**

Run: `cd "S:/attribute-loop" && powershell -NoProfile -File scripts/self-test.ps1`
Expected: PASS — all tests green.

- [ ] **Step 5: Commit**

```bash
git add src/ui/LoadingScreen.gd
git commit -m "feat(ui): difficulty selection panel (Easy/Hard) on game start"
```

---

## Task 7: Self-test protocol and module documentation

**Files:**
- Create: `docs/modules/difficulty-selection.md`

- [ ] **Step 1: Confirm syntax checks passed**

Verify the PostToolUse hook reported no syntax errors for the files written in Tasks 1-6. Fix any reported error before continuing.

- [ ] **Step 2: Run headless unit tests**

Run: `cd "S:/attribute-loop" && powershell -NoProfile -File scripts/self-test.ps1`
Expected: All tests pass.

- [ ] **Step 3: Visual integration test (requires Godot editor open)**

1. Create sentinel: write an empty file to `tests/.test_mode`.
2. Use MCP `execute_editor_script`:
```gdscript
var plugin = Engine.get_meta("GodotMCPPlugin")
plugin.get_editor_interface().play_main_scene()
```
3. Poll every 2 seconds until `tests/screenshots/last_run.png` appears (timeout 20s).
4. Read the screenshot and verify: game window rendered, no error dialogs.
   - Note: test-mode auto-launches Hard, so the screenshot validates the Hard path still boots. To visually verify the Easy panel + Easy build, temporarily run without `.test_mode` (skip if editor not open).
5. Delete `tests/.test_mode`.

- [ ] **Step 4: Write module documentation**

Create `docs/modules/difficulty-selection.md`:

```markdown
# Difficulty Selection

## Responsibility

Presents an Easy/Hard choice after the player clicks "开始游戏". Easy starts the
player with a pre-built loadout (3 player rule slots + 5 tile rule slots) so
newcomers begin with a working build; Hard leaves everything empty for the
player to construct themselves. Enemy stats, player HP, and all other balance
are identical between difficulties.

## Key components

- `GameState.difficulty` (`"easy"` / `"hard"`, default `"hard"`) — chosen by
  `LoadingScreen` before `reset()`, persists for the run. Drives rule-slot
  count (3 Easy / 2 Hard).
- `DataTables.EASY_PLAYER_SLOTS` — constant array of 3 `{trigger, effect,
  trigger_value, effect_value}` specs for the player's slots.
- `DataTables.EASY_TILE_RULES` — constant `{tile_index: spec}` for 5 tiles
  (indices 1, 5, 8, 9, 12), one rule each.
- `DataTables.make_easy_slot(spec)` — duplicates `ComponentData` resources into
  a `{"trigger", "effect"}` slot dict with fixed values.
- `DataTables.apply_easy_tile_rules(tiles)` — fills `rule_slots[0]` on the 5
  preset tiles.
- `GameState.apply_easy_player_slots()` — rebuilds the player's `rule_slots`
  from the preset.
- `LoadingScreen` difficulty panel (built in code) — Easy / Hard / Back buttons.

## Execution flow

1. `LoadingScreen._on_start_pressed()` passes the tutorial gate, then shows the
   difficulty panel (test-mode skips the panel and launches Hard directly).
2. Choosing a difficulty calls `_launch_game(difficulty)`, which sets
   `GameState.difficulty`, calls `GameState.reset()` (creating 3 slots for
   Easy / 2 for Hard), then loads `main.tscn`.
3. `Main._finish_setup()` calls `_build_tiles()`; if difficulty is Easy it then
   calls `GameState.apply_easy_player_slots()` and
   `DataTables.apply_easy_tile_rules(_tiles)`. Tiles' `rule_slots` already
   exist from `Tile._ready()`.
4. The rule engine evaluates pre-filled player and tile slots like any
   player-placed rule.

## Dependencies

- `GameState` (autoload) — difficulty flag, player slots, `reset()`.
- `DataTables` (autoload) — preset constants and apply helpers.
- `Main` — applies the preset after tile construction.
- `LoadingScreen` — difficulty selection UI and launch routing.
```

- [ ] **Step 5: Commit**

```bash
git add docs/modules/difficulty-selection.md
git commit -m "docs(module): document difficulty selection module"
```

- [ ] **Step 6: Notify the user for acceptance**

Report: all three self-test layers passed, module doc written. Await user acceptance.
