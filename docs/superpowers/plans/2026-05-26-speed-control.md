# Speed Control Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a persistent ⏸/1×/2×/3× speed control panel to the top-left corner of the HUD, using `Engine.time_scale` as the single time authority.

**Architecture:** `GameState` gains a `speed_multiplier` property (with a setter that calls `_apply_time_scale()`) and converts `is_paused` to use the same setter pattern, so both pause sources funnel into one `Engine.time_scale` write. A new self-contained `SpeedControl` HBoxContainer creates its own four toggle buttons in `_ready()` and calls `GameState.speed_multiplier = value` on press. No changes to Player, CombatSystem, or any other game system.

**Tech Stack:** Godot 4, GDScript, GUT (unit tests), Godot MCP

---

### Task 1: GameState — speed_multiplier + _apply_time_scale (TDD)

**Files:**
- Modify: `src/autoloads/GameState.gd`
- Create: `tests/unit/test_speed_control_state.gd`

- [ ] **Step 1: Write the failing tests**

Create `tests/unit/test_speed_control_state.gd`:

```gdscript
extends GutTest

func after_each() -> void:
    GameState.is_paused = false
    GameState.speed_multiplier = 1.0

func test_speed_multiplier_default_is_one() -> void:
    assert_eq(GameState.speed_multiplier, 1.0)

func test_set_speed_multiplier_updates_time_scale() -> void:
    GameState.is_paused = false
    GameState.speed_multiplier = 2.0
    assert_eq(Engine.time_scale, 2.0)

func test_set_speed_multiplier_zero_pauses_time() -> void:
    GameState.is_paused = false
    GameState.speed_multiplier = 0.0
    assert_eq(Engine.time_scale, 0.0)

func test_is_paused_true_overrides_speed_multiplier() -> void:
    GameState.speed_multiplier = 3.0
    GameState.is_paused = true
    assert_eq(Engine.time_scale, 0.0)

func test_unpause_restores_speed_multiplier() -> void:
    GameState.speed_multiplier = 2.0
    GameState.is_paused = true
    GameState.is_paused = false
    assert_eq(Engine.time_scale, 2.0)

func test_reset_restores_speed_to_one() -> void:
    GameState.speed_multiplier = 3.0
    GameState.reset()
    assert_eq(GameState.speed_multiplier, 1.0)

func test_reset_restores_time_scale_to_one() -> void:
    GameState.speed_multiplier = 3.0
    GameState.reset()
    assert_eq(Engine.time_scale, 1.0)
```

- [ ] **Step 2: Run tests to verify they fail**

```powershell
cd "S:/attribute-loop" && powershell -NoProfile -File scripts/self-test.ps1
```

Expected: failures mentioning `speed_multiplier` not found.

- [ ] **Step 3: Implement speed_multiplier + _apply_time_scale in GameState.gd**

Replace the two existing plain var declarations for `is_paused` and add `speed_multiplier`. In `src/autoloads/GameState.gd`, change:

```gdscript
var is_paused: bool = false
```

to:

```gdscript
var is_paused: bool = false:
    set(value):
        is_paused = value
        _apply_time_scale()

var speed_multiplier: float = 1.0:
    set(value):
        speed_multiplier = value
        _apply_time_scale()
```

Add the `_apply_time_scale` method anywhere in the file (e.g., after `reset()`):

```gdscript
func _apply_time_scale() -> void:
    Engine.time_scale = 0.0 if is_paused else speed_multiplier
```

In `reset()`, add `speed_multiplier = 1.0` **after** `is_paused = false` (so the setter fires in the right order):

```gdscript
func reset() -> void:
    hp = hp_max
    loops_completed = 0
    enemies_killed = 0
    current_phase = 1
    is_paused = false
    speed_multiplier = 1.0        # ← add this line
    pending_reflect_ratio = 0.0
    inventory = []
    rule_slots = []
    gold = 0
    deletion_count = 0
    altar_bonuses = {}
    loops_in_phase = 0
    in_verdict_loop = false
    verdict_loops_survived = 0
    for i in 2:
        rule_slots.append({"trigger": null, "effect": null})
```

- [ ] **Step 4: Run tests to verify they pass**

```powershell
cd "S:/attribute-loop" && powershell -NoProfile -File scripts/self-test.ps1
```

Expected: all `test_speed_control_state` tests PASS; no regressions in other suites.

- [ ] **Step 5: Commit**

```bash
git add src/autoloads/GameState.gd tests/unit/test_speed_control_state.gd
git commit -m "feat: GameState speed_multiplier + _apply_time_scale via Engine.time_scale"
```

---

### Task 2: SpeedControl script

**Files:**
- Create: `src/ui/SpeedControl.gd`

- [ ] **Step 1: Create SpeedControl.gd**

Create `src/ui/SpeedControl.gd`:

```gdscript
class_name SpeedControl
extends HBoxContainer

const SPEEDS: Array[float] = [0.0, 1.0, 2.0, 3.0]
const LABELS: Array[String] = ["⏸", "1×", "2×", "3×"]

var _buttons: Array[Button] = []

func _ready() -> void:
    var group := ButtonGroup.new()
    for i in SPEEDS.size():
        var btn := Button.new()
        btn.text = LABELS[i]
        btn.toggle_mode = true
        btn.button_group = group
        btn.pressed.connect(_on_speed_pressed.bind(i))
        add_child(btn)
        _buttons.append(btn)
    _buttons[1].button_pressed = true

func _on_speed_pressed(index: int) -> void:
    GameState.speed_multiplier = SPEEDS[index]
```

- [ ] **Step 2: Commit**

```bash
git add src/ui/SpeedControl.gd
git commit -m "feat: SpeedControl UI script — 4-button speed toggle"
```

---

### Task 3: SpeedControl scene (Godot MCP)

**Files:**
- Create: `scenes/ui/speed_control.tscn`

- [ ] **Step 1: Create the scene via MCP**

Use `mcp__godot__create_scene`:
```
scene_path: "res://scenes/ui/speed_control.tscn"
root_node_type: "HBoxContainer"
root_node_name: "SpeedControl"
```

- [ ] **Step 2: Attach the script via MCP**

Use `mcp__godot__update_node_property` on the root node:
```
scene_path: "res://scenes/ui/speed_control.tscn"
node_path: "."
property: "script"
value: "res://src/ui/SpeedControl.gd"
```

- [ ] **Step 3: Save the scene via MCP**

Use `mcp__godot__save_scene`:
```
scene_path: "res://scenes/ui/speed_control.tscn"
```

- [ ] **Step 4: Commit**

```bash
git add scenes/ui/speed_control.tscn
git commit -m "feat: SpeedControl scene"
```

---

### Task 4: HUD — wire SpeedControl in top-left

**Files:**
- Modify: `scenes/ui/hud.tscn`

The SpeedControl is self-contained — HUD.gd needs **no changes**. We only add the scene instance to the HUD scene tree.

- [ ] **Step 1: Open the HUD scene via MCP**

Use `mcp__godot__open_scene`:
```
scene_path: "res://scenes/ui/hud.tscn"
```

- [ ] **Step 2: Inspect the current HUD node tree**

Use `mcp__godot__list_nodes`:
```
scene_path: "res://scenes/ui/hud.tscn"
```

Note the root node name (likely `HUD`).

- [ ] **Step 3: Add a MarginContainer for top-left anchor**

Use `mcp__godot__create_node`:
```
scene_path: "res://scenes/ui/hud.tscn"
parent_node_path: "."
node_type: "MarginContainer"
node_name: "TopLeft"
```

- [ ] **Step 4: Position TopLeft at the top-left corner via MCP**

Use `mcp__godot__update_node_property` for each of the following:

```
node_path: "TopLeft"
property: "anchor_left"    value: 0.0
property: "anchor_top"     value: 0.0
property: "anchor_right"   value: 0.0
property: "anchor_bottom"  value: 0.0
property: "offset_right"   value: 200.0
property: "offset_bottom"  value: 48.0
property: "theme_override_constants/margin_left"   value: 8
property: "theme_override_constants/margin_top"    value: 8
```

- [ ] **Step 5: Instantiate SpeedControl inside TopLeft**

Use `mcp__godot__create_node`:
```
scene_path: "res://scenes/ui/hud.tscn"
parent_node_path: "TopLeft"
node_type: "HBoxContainer"
node_name: "SpeedControl"
```

Then attach script:

Use `mcp__godot__update_node_property`:
```
node_path: "TopLeft/SpeedControl"
property: "script"
value: "res://src/ui/SpeedControl.gd"
```

- [ ] **Step 6: Save the scene**

Use `mcp__godot__save_scene`:
```
scene_path: "res://scenes/ui/hud.tscn"
```

- [ ] **Step 7: Commit**

```bash
git add scenes/ui/hud.tscn
git commit -m "feat: SpeedControl wired into HUD top-left"
```

---

### Task 5: Self-test + visual integration

- [ ] **Step 1: Run headless unit tests**

```powershell
cd "S:/attribute-loop" && powershell -NoProfile -File scripts/self-test.ps1
```

Expected: all tests pass; no regressions.

- [ ] **Step 2: Create test sentinel**

Write an empty file to `tests/.test_mode`.

- [ ] **Step 3: Play main scene via MCP**

Use `mcp__godot__execute_editor_script`:
```gdscript
var plugin = Engine.get_meta("GodotMCPPlugin")
plugin.get_editor_interface().play_main_scene()
```

- [ ] **Step 4: Poll for screenshot**

Wait up to 20 s, checking every 2 s whether `tests/screenshots/last_run.png` exists.

- [ ] **Step 5: Read screenshot and verify**

Use the Read tool on `tests/screenshots/last_run.png`. Verify:
- Game window rendered (not black/blank)
- Four speed buttons visible in top-left (⏸ 1× 2× 3×)
- `1×` button appears highlighted/active by default
- No error dialogs

- [ ] **Step 6: Delete sentinel**

Delete `tests/.test_mode`.

- [ ] **Step 7: Write module documentation**

Create `docs/modules/speed-control.md`:

```markdown
# Speed Control

## Responsibility
Lets the player choose game speed: Pause / 1× / 2× / 3×. Affects all game systems uniformly via `Engine.time_scale`.

## Key pieces
- `GameState.speed_multiplier` (float, 0/1/2/3) — player's chosen speed
- `GameState._apply_time_scale()` — single writer for `Engine.time_scale`; formula: `0.0 if is_paused else speed_multiplier`
- `SpeedControl` (HBoxContainer) — self-contained UI; creates 4 toggle buttons in `_ready()`, calls `GameState.speed_multiplier = v` on press
- `scenes/ui/hud.tscn > TopLeft/SpeedControl` — where it lives in the scene tree

## Execution flow
1. `SpeedControl._ready()` creates buttons + ButtonGroup; sets `1×` active
2. Player clicks a button → `_on_speed_pressed(index)` → `GameState.speed_multiplier = SPEEDS[index]`
3. `speed_multiplier` setter calls `_apply_time_scale()` → `Engine.time_scale` updated
4. All Timers, `_process` delta, and animations scale automatically

## Interaction with panel-pause
When a panel opens, `GameLoop` sets `GameState.is_paused = true`.
`is_paused` setter calls `_apply_time_scale()` → `Engine.time_scale = 0`.
On panel close, `is_paused = false` → `Engine.time_scale` restores to `speed_multiplier`.
SpeedControl button state is unaffected.

## Dependencies
- `GameState` (autoload)
- No dependency on Player, CombatSystem, or any other system
```

- [ ] **Step 8: Final commit**

```bash
git add docs/modules/speed-control.md
git commit -m "docs: speed-control module documentation"
```
