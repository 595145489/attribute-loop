# Rule Slots Panel — Right Side Migration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Move the hardcoded 2-slot rule display from the bottom HUD bar to a dynamic right-side panel that supports 2–5 slots as the player purchases upgrades.

**Architecture:** Create `RuleSlotEntry.tscn` (single slot prefab) and `RuleSlotsPanel.tscn` (right-side container). `RuleSlotsPanel` listens to `EventBus.rule_slots_changed` and rebuilds its children by instantiating `RuleSlotEntry` per slot. All visual config (sizes, spacing, colors) lives in Inspector, zero magic numbers in script. Remove RulePanel0/1 from hud.tscn and strip their backing arrays from HUD.gd.

**Tech Stack:** Godot 4 GDScript, GUT unit tests, MCP execute_editor_script for visual check

---

## File Map

| Action | Path |
|--------|------|
| Create | `scenes/ui/rule_slot_entry.tscn` |
| Create | `src/ui/RuleSlotEntry.gd` |
| Create | `scenes/ui/rule_slots_panel.tscn` |
| Create | `src/ui/RuleSlotsPanel.gd` |
| Modify | `src/autoloads/EventBus.gd` — add `rule_slots_changed` signal |
| Modify | `src/systems/AuctionManager.gd` — emit `rule_slots_changed` after SLOT_RULE purchase |
| Modify | `scenes/ui/hud.tscn` — remove RulePanel0/1, add RuleSlotsPanel instance |
| Modify | `src/ui/HUD.gd` — remove slot arrays and `_update_rule_panel()` |
| Modify | `tests/unit/test_auction_manager.gd` — verify signal emitted on slot purchase |

---

## Task 1: Add `rule_slots_changed` signal to EventBus

**Files:**
- Modify: `src/autoloads/EventBus.gd`

- [ ] **Step 1: Add signal**

In `src/autoloads/EventBus.gd`, append after the last signal line (currently `signal altar_activated`):

```gdscript
signal rule_slots_changed
```

- [ ] **Step 2: Verify syntax check passes**

Confirm the PostToolUse hook reports no errors for `EventBus.gd`.

- [ ] **Step 3: Commit**

```bash
git add src/autoloads/EventBus.gd
git commit -m "feat: add rule_slots_changed signal to EventBus"
```

---

## Task 2: Emit `rule_slots_changed` in AuctionManager after slot purchase

**Files:**
- Modify: `src/systems/AuctionManager.gd:170-174`
- Modify: `tests/unit/test_auction_manager.gd`

- [ ] **Step 1: Write failing test**

Append to `tests/unit/test_auction_manager.gd`:

```gdscript
func test_slot_rule_purchase_emits_rule_slots_changed() -> void:
	watch_signals(EventBus)
	AuctionManager.apply_service(AuctionManager.ServiceType.SLOT_RULE)
	assert_signal_emitted(EventBus, "rule_slots_changed")
```

- [ ] **Step 2: Run test to verify it fails**

```bash
cd "S:/attribute-loop" && powershell -NoProfile -File scripts/self-test.ps1
```

Expected: FAIL — `rule_slots_changed` not emitted.

- [ ] **Step 3: Update AuctionManager to emit the signal**

In `src/systems/AuctionManager.gd`, find the `SLOT_RULE` branch (around line 170–174):

```gdscript
ServiceType.SLOT_RULE:
    GameState.rule_slots.append({"trigger": null, "effect": null})
```

Replace the full `apply_service` emit block (lines 170–174) with:

```gdscript
		ServiceType.SLOT_RULE:
			GameState.rule_slots.append({"trigger": null, "effect": null})
			EventBus.rule_slots_changed.emit()
	EventBus.service_bar_changed.emit()
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
cd "S:/attribute-loop" && powershell -NoProfile -File scripts/self-test.ps1
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add src/systems/AuctionManager.gd tests/unit/test_auction_manager.gd
git commit -m "feat: emit rule_slots_changed when SLOT_RULE service purchased"
```

---

## Task 3: Create `RuleSlotEntry` script and scene

**Files:**
- Create: `src/ui/RuleSlotEntry.gd`
- Create: `scenes/ui/rule_slot_entry.tscn`

This is the prefab for one rule slot row. All visual properties (font size, colors, padding) are set in Inspector — the script only populates text.

- [ ] **Step 1: Create the script**

Create `src/ui/RuleSlotEntry.gd`:

```gdscript
class_name RuleSlotEntry
extends PanelContainer

@onready var _t_name: Label = $VBox/TRow/TName
@onready var _t_count: Label = $VBox/TRow/TCount
@onready var _e_name: Label = $VBox/ERow/EName
@onready var _e_value: Label = $VBox/ERow/EValue

func refresh(slot: Dictionary) -> void:
	var t: ComponentData = slot.get("trigger")
	var e: ComponentData = slot.get("effect")
	if t == null or e == null:
		_t_name.text = "— 空槽 —"
		_t_count.text = ""
		_e_name.text = ""
		_e_value.text = ""
		return
	_t_name.text = t.display_name
	_t_count.text = "%d/%d" % [t.trigger_count, int(t.trigger_value)]
	_e_name.text = e.display_name
	match e.id:
		"治愈":
			_e_value.text = "+%d" % int(e.effect_value)
		"反射":
			_e_value.text = "%d%%" % int(e.effect_value * 100)
		"护盾":
			_e_value.text = "+%d" % int(e.effect_value)
		"减伤":
			_e_value.text = "×%d层" % int(e.effect_value)
		"吸血":
			_e_value.text = "%d%%" % int(e.effect_value * 100)
		"强化":
			_e_value.text = "×%d/%d" % [GameState.amplify_stacks, GameState.amplify_max_stacks]
		"增伤":
			_e_value.text = "×%d层" % int(e.effect_value)
		"蓄能":
			var potential := GameState.charge_stacks * DataTables.player.dmg_base
			_e_value.text = "%d层 (%d)" % [GameState.charge_stacks, potential]
		"灼烧":
			_e_value.text = "×%d层" % int(e.effect_value)
		"侵蚀":
			_e_value.text = "-%d" % int(e.effect_value)
		_:
			_e_value.text = ""
```

- [ ] **Step 2: Create the scene via MCP**

Run in Godot editor via `execute_editor_script`:

```gdscript
var scene = PackedScene.new()
var root = PanelContainer.new()
root.name = "RuleSlotEntry"

var vbox = VBoxContainer.new()
vbox.name = "VBox"
root.add_child(vbox)
vbox.owner = root

var t_row = HBoxContainer.new()
t_row.name = "TRow"
vbox.add_child(t_row)
t_row.owner = root

var t_name = Label.new()
t_name.name = "TName"
t_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
t_row.add_child(t_name)
t_name.owner = root

var t_count = Label.new()
t_count.name = "TCount"
t_row.add_child(t_count)
t_count.owner = root

var e_row = HBoxContainer.new()
e_row.name = "ERow"
vbox.add_child(e_row)
e_row.owner = root

var e_name = Label.new()
e_name.name = "EName"
e_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
e_row.add_child(e_name)
e_name.owner = root

var e_value = Label.new()
e_value.name = "EValue"
e_row.add_child(e_value)
e_value.owner = root

var script = load("res://src/ui/RuleSlotEntry.gd")
root.set_script(script)

scene.pack(root)
ResourceSaver.save(scene, "res://scenes/ui/rule_slot_entry.tscn")
print("saved rule_slot_entry.tscn")
```

- [ ] **Step 3: Verify syntax check passes**

Confirm PostToolUse hook reports no errors for `RuleSlotEntry.gd`.

- [ ] **Step 4: Commit**

```bash
git add src/ui/RuleSlotEntry.gd scenes/ui/rule_slot_entry.tscn
git commit -m "feat: add RuleSlotEntry prefab for dynamic rule slot display"
```

---

## Task 4: Create `RuleSlotsPanel` script and scene

**Files:**
- Create: `src/ui/RuleSlotsPanel.gd`
- Create: `scenes/ui/rule_slots_panel.tscn`

This is the right-side container. On `_ready` it populates from `GameState.rule_slots`. It also subscribes to `EventBus.rule_slots_changed` and `EventBus.rule_fired` to stay current.

- [ ] **Step 1: Create the script**

Create `src/ui/RuleSlotsPanel.gd`:

```gdscript
class_name RuleSlotsPanel
extends PanelContainer

const ENTRY = preload("res://scenes/ui/rule_slot_entry.tscn")

@onready var _container: VBoxContainer = $VBox/SlotsContainer

func _ready() -> void:
	EventBus.rule_slots_changed.connect(_rebuild)
	EventBus.rule_fired.connect(_on_rule_fired)
	EventBus.rule_equipped.connect(_rebuild)
	_rebuild()

func _rebuild(_ignored = null) -> void:
	for child in _container.get_children():
		child.queue_free()
	for slot in GameState.rule_slots:
		var entry: RuleSlotEntry = ENTRY.instantiate()
		_container.add_child(entry)
		entry.refresh(slot)

func _on_rule_fired(_slot_idx: int, _effect_id: String, _value: float) -> void:
	_refresh_all()

func _refresh_all() -> void:
	var children := _container.get_children()
	for i in children.size():
		if i < GameState.rule_slots.size():
			children[i].refresh(GameState.rule_slots[i])

func _process(_delta: float) -> void:
	_refresh_all()
```

- [ ] **Step 2: Create the scene via MCP**

Run in Godot editor via `execute_editor_script`:

```gdscript
var scene = PackedScene.new()
var root = PanelContainer.new()
root.name = "RuleSlotsPanel"

var vbox = VBoxContainer.new()
vbox.name = "VBox"
root.add_child(vbox)
vbox.owner = root

var title = Label.new()
title.name = "Title"
title.text = "装备规则"
vbox.add_child(title)
title.owner = root

var slots_container = VBoxContainer.new()
slots_container.name = "SlotsContainer"
vbox.add_child(slots_container)
slots_container.owner = root

var script = load("res://src/ui/RuleSlotsPanel.gd")
root.set_script(script)

scene.pack(root)
ResourceSaver.save(scene, "res://scenes/ui/rule_slots_panel.tscn")
print("saved rule_slots_panel.tscn")
```

- [ ] **Step 3: Verify syntax check passes**

Confirm PostToolUse hook reports no errors for `RuleSlotsPanel.gd`.

- [ ] **Step 4: Commit**

```bash
git add src/ui/RuleSlotsPanel.gd scenes/ui/rule_slots_panel.tscn
git commit -m "feat: add RuleSlotsPanel dynamic right-side container"
```

---

## Task 5: Wire RuleSlotsPanel into hud.tscn and remove old RulePanel0/1

**Files:**
- Modify: `scenes/ui/hud.tscn`
- Modify: `src/ui/HUD.gd`

This task removes the hardcoded bottom-bar rule panels and adds the new RuleSlotsPanel anchored to the right side of the screen.

- [ ] **Step 1: Add RuleSlotsPanel to hud.tscn via MCP**

Run in Godot editor via `execute_editor_script`:

```gdscript
var editor = Engine.get_meta("GodotMCPPlugin").get_editor_interface()
var scene_root = editor.get_edited_scene_root()
var hud = scene_root

# Load and instance RuleSlotsPanel
var packed = load("res://scenes/ui/rule_slots_panel.tscn")
var panel = packed.instantiate()
panel.name = "RuleSlotsPanel"
hud.add_child(panel)
panel.owner = hud

# Anchor to right side, vertically centered
panel.anchors_preset = -1
panel.anchor_left = 1.0
panel.anchor_top = 0.0
panel.anchor_right = 1.0
panel.anchor_bottom = 0.5
panel.offset_left = -160.0
panel.offset_top = 60.0
panel.offset_right = -8.0
panel.offset_bottom = -8.0
panel.grow_horizontal = 0
panel.grow_vertical = 2

editor.save_scene()
print("RuleSlotsPanel added and scene saved")
```

- [ ] **Step 2: Remove RulePanel0 and RulePanel1 via MCP**

Run in Godot editor via `execute_editor_script`:

```gdscript
var editor = Engine.get_meta("GodotMCPPlugin").get_editor_interface()
var scene_root = editor.get_edited_scene_root()
var bottom_content = scene_root.get_node("BottomBar/HContent")

for name in ["RulePanel0", "RulePanel1"]:
	var node = bottom_content.get_node_or_null(name)
	if node:
		node.queue_free()
		print("removed ", name)

editor.save_scene()
print("scene saved")
```

- [ ] **Step 3: Strip the hardcoded arrays from HUD.gd**

In `src/ui/HUD.gd`, remove lines 32–47 (the four `@onready var` arrays):

```gdscript
@onready var _t_name: Array[Label] = [
	$BottomBar/HContent/RulePanel0/RuleVBox0/TGroup0/TName0,
	$BottomBar/HContent/RulePanel1/RuleVBox1/TGroup1/TName1,
]
@onready var _t_count: Array[Label] = [
	$BottomBar/HContent/RulePanel0/RuleVBox0/TGroup0/TCount0,
	$BottomBar/HContent/RulePanel1/RuleVBox1/TGroup1/TCount1,
]
@onready var _e_name: Array[Label] = [
	$BottomBar/HContent/RulePanel0/RuleVBox0/EGroup0/EName0,
	$BottomBar/HContent/RulePanel1/RuleVBox1/EGroup1/EName1,
]
@onready var _e_value: Array[Label] = [
	$BottomBar/HContent/RulePanel0/RuleVBox0/EGroup0/EValue0,
	$BottomBar/HContent/RulePanel1/RuleVBox1/EGroup1/EValue1,
]
```

Also remove `_update_rule_panel()` method (lines 96–132) and its two call sites in `_process()` (the two `for i in GameState.rule_slots.size(): _update_rule_panel(i)` blocks at lines 87–88 and 93–94).

- [ ] **Step 4: Verify syntax check passes**

Confirm PostToolUse hook reports no errors for `HUD.gd`.

- [ ] **Step 5: Run unit tests**

```bash
cd "S:/attribute-loop" && powershell -NoProfile -File scripts/self-test.ps1
```

Expected: all tests PASS.

- [ ] **Step 6: Commit**

```bash
git add scenes/ui/hud.tscn src/ui/HUD.gd
git commit -m "feat: replace hardcoded bottom rule panels with dynamic RuleSlotsPanel on right side"
```

---

## Task 6: Visual integration test and Inspector tuning

**Files:**
- Modify: `scenes/ui/rule_slot_entry.tscn` (Inspector tuning only)
- Modify: `scenes/ui/rule_slots_panel.tscn` (Inspector tuning only)

- [ ] **Step 1: Create sentinel and run game**

```bash
# Create sentinel
New-Item -ItemType File -Force "S:/attribute-loop/tests/.test_mode"
```

Then via MCP `execute_editor_script`:
```gdscript
var plugin = Engine.get_meta("GodotMCPPlugin")
plugin.get_editor_interface().play_main_scene()
```

- [ ] **Step 2: Poll for screenshot**

Poll every 2 seconds for up to 20 seconds for `tests/screenshots/last_run.png` to appear.

- [ ] **Step 3: Read and verify screenshot**

Use Read tool on `tests/screenshots/last_run.png`. Verify:
- Game window renders (not black/blank)
- Right-side panel is visible with rule slot entries
- Bottom bar no longer shows rule panels
- No error dialogs

- [ ] **Step 4: Tune Inspector values in editor**

Open `scenes/ui/rule_slot_entry.tscn` and `scenes/ui/rule_slots_panel.tscn` in the Godot editor and set appropriate values via Inspector:

For `RuleSlotEntry` (`PanelContainer`):
- `custom_minimum_size` = `Vector2(150, 0)` (adjust to fit content)
- `theme_override_styles/panel` = StyleBoxFlat with subtle background color

For `RuleSlotEntry` labels:
- `TName`, `EName`: `theme_override_font_sizes/font_size = 10`
- `TCount`, `EValue`: `theme_override_font_sizes/font_size = 10`, secondary color

For `RuleSlotsPanel` (`VBox/SlotsContainer` VBoxContainer):
- `theme_override_constants/separation = 4`

For `RuleSlotsPanel` title `Label`:
- `theme_override_font_sizes/font_size = 11`
- `horizontal_alignment = CENTER`

- [ ] **Step 5: Delete sentinel**

```bash
Remove-Item -Force "S:/attribute-loop/tests/.test_mode"
```

- [ ] **Step 6: Commit**

```bash
git add scenes/ui/rule_slot_entry.tscn scenes/ui/rule_slots_panel.tscn
git commit -m "feat: tune RuleSlotEntry and RuleSlotsPanel inspector config"
```

---

## Task 7: Write module documentation

**Files:**
- Create: `docs/modules/rule-slots-panel.md`

- [ ] **Step 1: Write doc**

Create `docs/modules/rule-slots-panel.md`:

```markdown
# Rule Slots Panel

## Responsibility
Displays the player's active rule slots (trigger + effect pairs) as a persistent right-side panel during gameplay. Supports 2–5 slots dynamically as the player purchases expansions.

## Key Nodes / Scripts
- `scenes/ui/rule_slots_panel.tscn` / `src/ui/RuleSlotsPanel.gd` — right-side container; rebuilds children on `rule_slots_changed`
- `scenes/ui/rule_slot_entry.tscn` / `src/ui/RuleSlotEntry.gd` — single slot row; `refresh(slot: Dictionary)` updates labels

## Signals Consumed
- `EventBus.rule_slots_changed` — triggers full rebuild (slot added via shop)
- `EventBus.rule_equipped` — triggers full rebuild (component equipped/removed)
- `EventBus.rule_fired` — triggers refresh of all entry values

## Execution Flow
1. `RuleSlotsPanel._ready()` connects signals and calls `_rebuild()`
2. `_rebuild()` clears `SlotsContainer`, then instantiates one `RuleSlotEntry` per `GameState.rule_slots` entry
3. `_process()` calls `_refresh_all()` every frame to keep trigger counts and stack values current
4. On slot purchase, `AuctionManager` appends to `GameState.rule_slots` and emits `rule_slots_changed`

## Dependencies
- `GameState.rule_slots` — source of truth for slot data
- `DataTables.player.dmg_base` — used by 蓄能 effect value calculation
- `GameState.amplify_stacks / amplify_max_stacks` — used by 强化 effect display
```

- [ ] **Step 2: Commit**

```bash
git add docs/modules/rule-slots-panel.md
git commit -m "docs: add rule-slots-panel module documentation"
```
