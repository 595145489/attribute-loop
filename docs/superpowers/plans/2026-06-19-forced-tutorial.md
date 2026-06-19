# Forced Tutorial (First-Launch) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Force first-launch players through the tutorial once, persist completion to disk, then let them start the game freely on later launches.

**Architecture:** A new `OnboardingState` autoload owns a `ConfigFile`-backed `tutorial_completed` flag at `user://onboarding.cfg`. `LoadingScreen` gates the "开始游戏" button on that flag (exempting test mode). `TutorialManager` marks completion on both the natural finish and a new "跳过教程" button added to `TutorialOverlay`.

**Tech Stack:** Godot 4.6 GDScript, ConfigFile persistence, GUT unit tests, existing self-test protocol.

**Spec:** `docs/superpowers/specs/2026-06-19-forced-tutorial-design.md`

---

## File Structure

- **Create:** `src/autoloads/OnboardingState.gd` — autoload owning onboarding persistence (ConfigFile at `user://onboarding.cfg`).
- **Modify:** `project.godot` — register `OnboardingState` autoload before `TutorialManager`.
- **Modify:** `src/ui/LoadingScreen.gd` — gate `_on_start_pressed()` on completion; add prompt dialog; extract pure `_should_block_start()` for testing.
- **Modify:** `src/autoloads/TutorialManager.gd` — mark completion on finish + add `skip()`; extract `_mark_completed()` (no scene change) for testing.
- **Modify:** `scenes/tutorial/tutorial_overlay.tscn` — add `SkipButton` node.
- **Modify:** `src/tutorial/TutorialOverlay.gd` — wire skip button → confirmation dialog → `TutorialManager.skip()`.
- **Create:** `tests/unit/test_onboarding_state.gd` — GUT tests for OnboardingState.
- **Create:** `tests/unit/test_loading_screen_gate.gd` — GUT tests for the gate decision.
- **Modify:** `tests/unit/test_tutorial_manager.gd` — add tests for completion marking.
- **Create:** `docs/modules/onboarding.md` — module doc (per CLAUDE.md Step 4).

---

## Task 1: OnboardingState autoload (TDD)

**Files:**
- Create: `src/autoloads/OnboardingState.gd`
- Test: `tests/unit/test_onboarding_state.gd`

- [ ] **Step 1: Write the failing test**

Create `tests/unit/test_onboarding_state.gd`:

```gdscript
extends GutTest

const CONFIG_PATH := "user://onboarding.cfg"

func before_each() -> void:
	# Ensure a clean slate on disk and in memory before every test.
	DirAccess.remove_absolute(CONFIG_PATH)
	OnboardingState.reload()

func after_all() -> void:
	# Do not pollute the dev machine between runs.
	DirAccess.remove_absolute(CONFIG_PATH)

func test_not_completed_when_no_config_file() -> void:
	assert_false(OnboardingState.is_tutorial_completed())

func test_mark_completed_flips_flag_in_memory() -> void:
	OnboardingState.mark_tutorial_completed()
	assert_true(OnboardingState.is_tutorial_completed())

func test_completion_persists_across_reload() -> void:
	OnboardingState.mark_tutorial_completed()
	OnboardingState.reload()
	assert_true(OnboardingState.is_tutorial_completed())

func test_reload_false_after_file_deleted() -> void:
	OnboardingState.mark_tutorial_completed()
	DirAccess.remove_absolute(CONFIG_PATH)
	OnboardingState.reload()
	assert_false(OnboardingState.is_tutorial_completed())
```

- [ ] **Step 2: Run test to verify it fails**

Run:
```
powershell -NoProfile -File scripts/self-test.ps1
```
Expected: FAIL / parse error — `OnboardingState` autoload does not exist yet (`Identifier "OnboardingState" not declared` or similar). GUT may also report the script failed to load.

- [ ] **Step 3: Write minimal implementation**

Create `src/autoloads/OnboardingState.gd`:

```gdscript
extends Node

const CONFIG_PATH := "user://onboarding.cfg"
const SECTION := "onboarding"
const KEY := "tutorial_completed"

var _completed: bool = false

func _ready() -> void:
	reload()

func reload() -> void:
	var cfg := ConfigFile.new()
	var err := cfg.load(CONFIG_PATH)
	if err == OK:
		_completed = bool(cfg.get_value(SECTION, KEY, false))
	else:
		_completed = false

func is_tutorial_completed() -> bool:
	return _completed

func mark_tutorial_completed() -> void:
	_completed = true
	var cfg := ConfigFile.new()
	cfg.set_value(SECTION, KEY, true)
	var err := cfg.save(CONFIG_PATH)
	if err != OK:
		push_warning("OnboardingState: failed to save tutorial completion (code %d)" % err)
```

- [ ] **Step 4: Register the autoload (required before tests can pass)**

Edit `project.godot`. In the `[autoload]` section, insert the `OnboardingState` line directly after the `GameState` line so the final order is `TestHelper, EventBus, GameState, OnboardingState, DataTables, Tooltip, TutorialManager, AudioManager`:

```
[autoload]

TestHelper="*res://src/autoloads/TestHelper.gd"
EventBus="*res://src/autoloads/EventBus.gd"
GameState="*res://src/autoloads/GameState.gd"
OnboardingState="*res://src/autoloads/OnboardingState.gd"
DataTables="*res://src/autoloads/DataTables.gd"
Tooltip="*res://src/autoloads/Tooltip.gd"
TutorialManager="*res://src/autoloads/TutorialManager.gd"
AudioManager="*res://src/autoloads/AudioManager.gd"
```

- [ ] **Step 5: Run test to verify it passes**

Run:
```
powershell -NoProfile -File scripts/self-test.ps1
```
Expected: PASS — "All tests passed." (The 4 new OnboardingState tests pass alongside existing tests.)

- [ ] **Step 6: Commit**

```bash
git add src/autoloads/OnboardingState.gd tests/unit/test_onboarding_state.gd project.godot
git commit -m "feat(onboarding): add OnboardingState autoload with tutorial completion persistence"
```

---

## Task 2: LoadingScreen start gate (TDD)

**Files:**
- Modify: `src/ui/LoadingScreen.gd`
- Test: `tests/unit/test_loading_screen_gate.gd`

- [ ] **Step 1: Write the failing test**

Create `tests/unit/test_loading_screen_gate.gd`:

```gdscript
extends GutTest

const CONFIG_PATH := "user://onboarding.cfg"
const SENTINEL := "res://tests/.test_mode"

func before_each() -> void:
	DirAccess.remove_absolute(CONFIG_PATH)
	OnboardingState.reload()
	DirAccess.remove_absolute(SENTINEL)

func after_all() -> void:
	DirAccess.remove_absolute(CONFIG_PATH)
	DirAccess.remove_absolute(SENTINEL)

# LoadingScreen.new() does NOT run _ready (node never enters tree), so the
# @onready children stay null and preload never fires. _should_block_start()
# only touches OnboardingState + the sentinel file, so this is safe.
func _make_screen() -> LoadingScreen:
	return LoadingScreen.new()

func test_blocks_when_not_completed_and_not_test_mode() -> void:
	var screen := _make_screen()
	assert_true(screen._should_block_start())

func test_does_not_block_when_completed() -> void:
	OnboardingState.mark_tutorial_completed()
	var screen := _make_screen()
	assert_false(screen._should_block_start())

func test_does_not_block_in_test_mode_even_if_not_completed() -> void:
	var f := FileAccess.open(SENTINEL, FileAccess.WRITE)
	f.close()
	var screen := _make_screen()
	assert_false(screen._should_block_start())
```

- [ ] **Step 2: Run test to verify it fails**

Run:
```
powershell -NoProfile -File scripts/self-test.ps1
```
Expected: FAIL — `LoadingScreen` has no method `_should_block_start`.

- [ ] **Step 3: Add the gate decision method + prompt**

Modify `src/ui/LoadingScreen.gd`. Add the pure decision method and a prompt helper after `_on_progress`. First, replace the existing `_on_start_pressed`:

Current (lines 31-35):
```gdscript
func _on_start_pressed() -> void:
	GameState.reset()
	GameState.is_tutorial = false
	_start_button.disabled = true
	get_tree().change_scene_to_file("res://scenes/main.tscn")
```

New:
```gdscript
func _on_start_pressed() -> void:
	if _should_block_start():
		_show_must_play_tutorial_prompt()
		return
	GameState.reset()
	GameState.is_tutorial = false
	_start_button.disabled = true
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _should_block_start() -> bool:
	return not OnboardingState.is_tutorial_completed() \
		and not FileAccess.file_exists("res://tests/.test_mode")

func _show_must_play_tutorial_prompt() -> void:
	var dialog := AcceptDialog.new()
	dialog.title = "提示"
	dialog.dialog_text = "请先完成教程后再开始游戏"
	dialog.ok_button_text = "知道了"
	dialog.confirmed.connect(dialog.queue_free)
	dialog.canceled.connect(dialog.queue_free)
	add_child(dialog)
	dialog.popup_centered()
```

- [ ] **Step 4: Run test to verify it passes**

Run:
```
powershell -NoProfile -File scripts/self-test.ps1
```
Expected: PASS — all tests pass including the 3 new gate tests.

- [ ] **Step 5: Commit**

```bash
git add src/ui/LoadingScreen.gd tests/unit/test_loading_screen_gate.gd
git commit -m "feat(loading): gate 开始游戏 on first-launch tutorial completion"
```

---

## Task 3: TutorialManager marks completion on finish + skip (TDD)

**Files:**
- Modify: `src/autoloads/TutorialManager.gd`
- Test: `tests/unit/test_tutorial_manager.gd`

- [ ] **Step 1: Write the failing tests**

Append to `tests/unit/test_tutorial_manager.gd` (keep existing tests). Add cleanup of OnboardingState to the existing `before_each` and add new tests:

Replace the existing `before_each` (lines 3-7):
```gdscript
func before_each() -> void:
	GameState.reset()
	GameState.is_tutorial = false
	TutorialManager.is_active = false
	TutorialManager.current_step = 0
	DirAccess.remove_absolute("user://onboarding.cfg")
	OnboardingState.reload()
```

Append these tests at the end of the file:
```gdscript
func test_mark_completed_sets_onboarding_state() -> void:
	assert_false(OnboardingState.is_tutorial_completed())
	TutorialManager._mark_completed()
	assert_true(OnboardingState.is_tutorial_completed())

func test_skip_method_exists_and_marks_completed() -> void:
	# skip() routes through _mark_completed(); we test _mark_completed directly
	# because skip()'s scene change is unsafe inside the GUT runner.
	assert_true(TutorialManager.has_method("skip"))
	TutorialManager._mark_completed()
	assert_true(OnboardingState.is_tutorial_completed())
```

- [ ] **Step 2: Run test to verify it fails**

Run:
```
powershell -NoProfile -File scripts/self-test.ps1
```
Expected: FAIL — `TutorialManager` has no method `_mark_completed` and no method `skip`.

- [ ] **Step 3: Implement completion marking, finish, and skip**

Modify `src/autoloads/TutorialManager.gd`. Replace the existing `_on_confirm_pressed` (lines 89-91):

Current:
```gdscript
func _on_confirm_pressed() -> void:
	stop()
	get_tree().change_scene_to_file("res://scenes/ui/loading_screen.tscn")
```

New:
```gdscript
func _on_confirm_pressed() -> void:
	_complete_and_exit()

func skip() -> void:
	_complete_and_exit()

func _complete_and_exit() -> void:
	_mark_completed()
	stop()
	get_tree().change_scene_to_file("res://scenes/ui/loading_screen.tscn")

func _mark_completed() -> void:
	OnboardingState.mark_tutorial_completed()
```

- [ ] **Step 4: Run test to verify it passes**

Run:
```
powershell -NoProfile -File scripts/self-test.ps1
```
Expected: PASS — all tests pass including the 2 new TutorialManager tests.

- [ ] **Step 5: Commit**

```bash
git add src/autoloads/TutorialManager.gd tests/unit/test_tutorial_manager.gd
git commit -m "feat(tutorial): mark tutorial complete on finish and skip"
```

---

## Task 4: Add SkipButton to TutorialOverlay scene

**Files:**
- Modify: `scenes/tutorial/tutorial_overlay.tscn`

- [ ] **Step 1: Add the SkipButton node**

Edit `scenes/tutorial/tutorial_overlay.tscn`. After the `ConfirmButton` node (the last node in the file, lines 46-51), append a new `SkipButton` node as a sibling:

```
[node name="SkipButton" type="Button" parent="." unique_id=1992001001]
custom_minimum_size = Vector2(120, 36)
offset_left = 8.0
offset_top = 8.0
offset_right = 128.0
offset_bottom = 44.0
size_flags_horizontal = 0
size_flags_vertical = 0
text = "跳过教程"
```

- [ ] **Step 2: Verify the scene parses**

Run:
```
powershell -NoProfile -File scripts/syntax-check.ps1
```
Expected: no errors for `tutorial_overlay.tscn`. (If `syntax-check.ps1` only checks `.gd` files, open the scene via MCP `open_scene` instead and confirm no parse error is returned.)

- [ ] **Step 3: Commit**

```bash
git add scenes/tutorial/tutorial_overlay.tscn
git commit -m "feat(tutorial): add SkipButton node to tutorial overlay"
```

---

## Task 5: Wire SkipButton in TutorialOverlay script

**Files:**
- Modify: `src/tutorial/TutorialOverlay.gd`

- [ ] **Step 1: Add the @onready ref and connect the signal**

Modify `src/tutorial/TutorialOverlay.gd`. Add the `@onready` ref after the `_confirm_btn` line (line 14):

Current (line 14):
```gdscript
@onready var _confirm_btn: Button = $ConfirmButton
```

New:
```gdscript
@onready var _confirm_btn: Button = $ConfirmButton
@onready var _skip_btn: Button = $SkipButton
```

- [ ] **Step 2: Connect skip in `_ready` and position the button**

In `_ready()` (lines 29-43), add skip wiring and viewport-based positioning. After the `_confirm_btn.pressed.connect(...)` line (line 32) and its following `_confirm_btn.hide()` (line 33), insert skip setup. Also hide the skip button by default until a step is shown.

Current (lines 32-33):
```gdscript
	_confirm_btn.pressed.connect(func(): confirm_pressed.emit())
	_confirm_btn.hide()
```

New:
```gdscript
	_confirm_btn.pressed.connect(func(): confirm_pressed.emit())
	_confirm_btn.hide()
	_skip_btn.pressed.connect(_on_skip_pressed)
	_skip_btn.hide()
```

- [ ] **Step 3: Show/hide skip in step lifecycle**

In `show_step()` (line 63), after `visible = true` (line 77), show the skip button and pin it to the top-right of the viewport. Insert before the final `if _highlight_node_path == ""` block (line 78):

```gdscript
	_skip_btn.show()
	var vp := get_viewport().get_visible_rect().size
	_skip_btn.position = Vector2(vp.x - _skip_btn.size.x - 16.0, 16.0)
	_skip_btn.size = Vector2(120, 36)
```

In `show_complete()` (line 83), hide the skip button (the complete screen has its own "开始冒险 →" exit). After `_border.visible = false` (line 102) add:

```gdscript
	_skip_btn.hide()
```

In `hide_overlay()` (line 118), hide the skip button. After `_confirm_btn`/overlay visibility handling — add near the end, after `set_process(false)` (line 123):

```gdscript
	_skip_btn.hide()
```

- [ ] **Step 4: Implement the skip pressed handler**

Add a new method at the end of the file (after `_input`):

```gdscript
func _on_skip_pressed() -> void:
	var dialog := ConfirmationDialog.new()
	dialog.title = "跳过教程"
	dialog.dialog_text = "确定跳过教程？\n跳过后将返回主菜单。"
	dialog.ok_button_text = "跳过"
	dialog.cancel_button_text = "继续教程"
	dialog.confirmed.connect(_on_skip_confirmed)
	dialog.canceled.connect(dialog.queue_free)
	add_child(dialog)
	dialog.popup_centered()

func _on_skip_confirmed() -> void:
	# The confirmation dialog is freed by the caller path; queue_free the dialog.
	for child in get_children():
		if child is ConfirmationDialog:
			child.queue_free()
	TutorialManager.skip()
```

- [ ] **Step 5: Verify syntax**

Run:
```
powershell -NoProfile -File scripts/syntax-check.ps1
```
Expected: no errors for `TutorialOverlay.gd`.

- [ ] **Step 6: Run unit tests (unchanged behavior, must still pass)**

Run:
```
powershell -NoProfile -File scripts/self-test.ps1
```
Expected: PASS — all tests still pass (no new test here; the wiring is verified by the integration screenshot in Task 6).

- [ ] **Step 7: Commit**

```bash
git add src/tutorial/TutorialOverlay.gd
git commit -m "feat(tutorial): wire skip button to confirmation + TutorialManager.skip"
```

---

## Task 6: Integration verification (CLAUDE.md self-test protocol)

**Files:**
- Create: `docs/modules/onboarding.md`

- [ ] **Step 1: Confirm syntax checks passed**

Confirm the PostToolUse hook reported no syntax errors for all modified `.gd` files (`OnboardingState.gd`, `LoadingScreen.gd`, `TutorialManager.gd`, `TutorialOverlay.gd`). Fix any before continuing.

- [ ] **Step 2: Run headless unit tests**

Run:
```
powershell -NoProfile -File scripts/self-test.ps1
```
Expected: "All tests passed." Do not proceed until green.

- [ ] **Step 3: Visual integration test (requires Godot editor open)**

1. Create sentinel: write an empty file to `tests/.test_mode`.
2. Use MCP `execute_editor_script` to play the main scene:
```gdscript
var plugin = Engine.get_meta("GodotMCPPlugin")
plugin.get_editor_interface().play_main_scene()
```
3. Poll every 2 seconds until `tests/screenshots/last_run.png` appears (timeout 20s).
4. Read the screenshot with the Read tool and verify:
   - Game window rendered (not black/blank) — the loading screen auto-started (test mode bypasses the gate) and reached `main.tscn`.
   - No error dialogs.
5. Delete `tests/.test_mode`.

Also do a **manual gate check** (editor not in test mode):
1. Ensure `user://onboarding.cfg` does NOT exist (delete via `execute_editor_script`: `DirAccess.remove_absolute("user://onboarding.cfg")`).
2. Run the main scene without the sentinel; on the loading screen click "开始游戏" and confirm the "请先完成教程后再开始游戏" dialog appears and the scene does not change.
3. Click "教程", then in the tutorial click "跳过教程" → confirm → confirm it returns to the loading screen.
4. Click "开始游戏" again — it should now start the game (completion was persisted).
5. Delete `user://onboarding.cfg` to restore a clean state.

If any step fails: stop the game, investigate, fix, re-run.

- [ ] **Step 4: Write module documentation**

Create `docs/modules/onboarding.md`:

```markdown
# Onboarding

## Responsibility
Tracks whether the player has completed the tutorial at least once, persisted to disk so the first-launch forced-tutorial gate only triggers once per machine.

## Key API
- `OnboardingState.is_tutorial_completed() -> bool` — true after the tutorial has been finished or skipped.
- `OnboardingState.mark_tutorial_completed() -> void` — writes `tutorial_completed=true` to `user://onboarding.cfg`.
- `OnboardingState.reload() -> void` — re-reads the config file (used by `_ready` and tests).

## Flow
1. On boot, `OnboardingState._ready()` calls `reload()`, reading `user://onboarding.cfg`.
2. `LoadingScreen._on_start_pressed()` checks `_should_block_start()`: if not completed and not in test mode, it shows an `AcceptDialog` and refuses to start.
3. The player enters the tutorial via the "教程" button. On finish (`TutorialManager._on_confirm_pressed`) or skip (`TutorialManager.skip`), `_mark_completed()` calls `OnboardingState.mark_tutorial_completed()`, then returns to the loading screen.
4. On subsequent launches the gate passes and "开始游戏" starts the game directly.

## Dependencies
- `LoadingScreen` (reads the flag).
- `TutorialManager` + `TutorialOverlay` (write the flag via the skip/finish paths).
- Config file at `user://onboarding.cfg` (created on first completion).

## Test Mode
`tests/.test_mode` sentinel exempts the gate so the self-test screenshot flow auto-starts the game.
```

- [ ] **Step 5: Commit**

```bash
git add docs/modules/onboarding.md
git commit -m "docs(onboarding): document forced first-launch tutorial module"
```

---

## Self-Review

**Spec coverage:**
- New `OnboardingState` autoload (ConfigFile, `user://onboarding.cfg`, `is_tutorial_completed`, `mark_tutorial_completed`) → Task 1. ✓
- Registration before `TutorialManager` → Task 1 Step 4. ✓
- LoadingScreen gate with test-mode exemption + AcceptDialog prompt → Task 2. ✓
- TutorialManager marks completion on finish + skip, shared exit path → Task 3. ✓
- SkipButton node in `tutorial_overlay.tscn` → Task 4. ✓
- SkipButton wiring + confirmation dialog → Task 5. ✓
- Skip hidden on complete screen → Task 5 Step 3. ✓
- ESC path unchanged (no mark) → preserved (not touched). ✓
- Error handling (load failure → false; save failure → warning) → Task 1 Step 3. ✓
- Three-layer self-test + module doc → Task 6. ✓

**Placeholder scan:** None — every code step contains the full code; no TBD/TODO.

**Type/name consistency:** `_should_block_start()` (Task 2 test + impl), `_mark_completed()` / `skip()` / `_complete_and_exit()` (Task 3 test + impl), `_skip_btn` / `_on_skip_pressed` / `_on_skip_confirmed` (Task 5) — consistent across tasks. `OnboardingState.reload()` used in tests (Tasks 1-3) matches the impl in Task 1.
