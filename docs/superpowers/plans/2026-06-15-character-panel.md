# Character Panel Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a player attribute panel (角色面板) opened by pressing C, showing 8 combat stats in two grouped sections with per-row tooltips.

**Architecture:** New `CharacterPanel` scene + script mirrors the existing `InventoryPanel` pattern — `PanelContainer` with a `toggle()` method, opened from HUD via button + key shortcut, mutually exclusive with inventory. Stats read from `GameState` and `DataTables.player` once on open; no per-frame updates.

**Tech Stack:** Godot 4, GDScript, GUT (unit tests), existing `Tooltip` autoload, existing `ui_theme.tres`.

---

## File Map

| File | Action | Responsibility |
|------|--------|---------------|
| `scenes/ui/character_panel.tscn` | Create | Panel scene — PanelContainer with VBox, two stat groups |
| `src/ui/CharacterPanel.gd` | Create | Panel logic — `toggle()`, `_refresh()`, stat rows with tooltips |
| `scenes/ui/hud.tscn` | Modify | Add CharButton node next to BagButton; add CharacterPanel instance |
| `src/ui/HUD.gd` | Modify | Wire CharButton + C key; add mutual-exclusion with inventory panel |
| `tests/unit/test_character_panel.gd` | Create | Unit tests for `CharacterPanel` |

---

## Task 1: Create `CharacterPanel.gd` script

**Files:**
- Create: `src/ui/CharacterPanel.gd`
- Test: `tests/unit/test_character_panel.gd`

- [ ] **Step 1: Write the failing tests**

Create `tests/unit/test_character_panel.gd`:

```gdscript
extends GutTest

var panel: CharacterPanel

func before_each() -> void:
	GameState.reset()
	DataTables._load_all()
	panel = preload("res://scenes/ui/character_panel.tscn").instantiate()
	add_child_autofree(panel)
	await get_tree().process_frame

func test_panel_hidden_by_default() -> void:
	assert_false(panel.visible)

func test_toggle_shows_panel() -> void:
	panel.toggle()
	assert_true(panel.visible)

func test_toggle_twice_hides_panel() -> void:
	panel.toggle()
	panel.toggle()
	assert_false(panel.visible)

func test_toggle_open_pauses_game() -> void:
	var before = GameState._panel_pause_count
	panel.toggle()
	assert_eq(GameState._panel_pause_count, before + 1)

func test_toggle_close_unpauses_game() -> void:
	panel.toggle()
	var mid = GameState._panel_pause_count
	panel.toggle()
	assert_eq(GameState._panel_pause_count, mid - 1)

func test_refresh_shows_correct_hp() -> void:
	GameState.hp = 42
	GameState.hp_max = 200
	panel.toggle()
	var hp_val: Label = panel.get_node("Margin/VBox/SurvivalGroup/HP/Value")
	assert_eq(hp_val.text, "42 / 200")

func test_refresh_shows_dash_when_shield_zero() -> void:
	GameState.shield = 0
	panel.toggle()
	var val: Label = panel.get_node("Margin/VBox/SurvivalGroup/Shield/Value")
	assert_eq(val.text, "—")

func test_refresh_shows_shield_value_when_nonzero() -> void:
	GameState.shield = 150
	panel.toggle()
	var val: Label = panel.get_node("Margin/VBox/SurvivalGroup/Shield/Value")
	assert_eq(val.text, "150")

func test_refresh_shows_dash_when_lifesteal_zero() -> void:
	GameState.lifesteal_ratio = 0.0
	panel.toggle()
	var val: Label = panel.get_node("Margin/VBox/OffenseGroup/Lifesteal/Value")
	assert_eq(val.text, "—")

func test_refresh_shows_lifesteal_percent_when_nonzero() -> void:
	GameState.lifesteal_ratio = 0.15
	panel.toggle()
	var val: Label = panel.get_node("Margin/VBox/OffenseGroup/Lifesteal/Value")
	assert_eq(val.text, "15%")
```

- [ ] **Step 2: Run tests to verify they fail**

```
cd "S:/attribute-loop" && powershell -NoProfile -File scripts/self-test.ps1
```

Expected: FAIL — `CharacterPanel` class and scene do not exist yet.

- [ ] **Step 3: Create the script**

Create `src/ui/CharacterPanel.gd`:

```gdscript
class_name CharacterPanel
extends PanelContainer

func _ready() -> void:
	hide()
	$Margin/VBox/CloseButton.pressed.connect(toggle)

func toggle() -> void:
	if visible:
		hide()
		GameState.unpause_for_panel()
	else:
		_refresh()
		show()
		GameState.pause_for_panel()

func _refresh() -> void:
	var pd: PlayerData = DataTables.player

	_set_row("SurvivalGroup/HP",       "%d / %d" % [GameState.hp, GameState.hp_max])
	_set_row("SurvivalGroup/Shield",   _int_or_dash(GameState.shield))
	_set_row("SurvivalGroup/SlowStacks", _stacks_or_dash(GameState.slow_stacks))
	_set_row("SurvivalGroup/Reflect",  _pct_or_dash(GameState.pending_reflect_ratio))
	_set_row("OffenseGroup/Dmg",       "%d" % (pd.dmg_base + GameState.dmg_bonus))
	_set_row("OffenseGroup/Interval",  "%.2g 秒" % maxf(0.1, pd.attack_interval - GameState.attack_interval_bonus))
	_set_row("OffenseGroup/Amplify",   _stacks_or_dash(GameState.amplify_stacks))
	_set_row("OffenseGroup/Lifesteal", _pct_or_dash(GameState.lifesteal_ratio))

func _set_row(path: String, value: String) -> void:
	var val_label: Label = $Margin/VBox.get_node(path + "/Value")
	val_label.text = value
	if value == "—":
		val_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	else:
		val_label.remove_theme_color_override("font_color")

static func _int_or_dash(v: int) -> String:
	return "—" if v == 0 else "%d" % v

static func _stacks_or_dash(v: int) -> String:
	return "—" if v == 0 else "×%d 层" % v

static func _pct_or_dash(v: float) -> String:
	return "—" if v == 0.0 else "%d%%" % int(v * 100.0)
```

- [ ] **Step 4: Run tests again — still fail (scene missing)**

```
cd "S:/attribute-loop" && powershell -NoProfile -File scripts/self-test.ps1
```

Expected: scene preload error. Proceed to Task 2.

---

## Task 2: Create `character_panel.tscn` scene

**Files:**
- Create: `scenes/ui/character_panel.tscn`

- [ ] **Step 1: Build the scene via editor script**

Run in Godot MCP `execute_editor_script`:

```gdscript
var ei = Engine.get_meta("GodotMCPPlugin").get_editor_interface()

# --- scene root ---
var root := PanelContainer.new()
root.name = "CharacterPanel"
root.set_script(load("res://src/ui/CharacterPanel.gd"))
root.custom_minimum_size = Vector2(320, 0)

# --- margin ---
var margin := MarginContainer.new()
margin.name = "Margin"
for side in ["left","right","top","bottom"]:
	margin.add_theme_constant_override("margin_" + side, 12)
root.add_child(margin)
margin.owner = root

# --- outer vbox ---
var vbox := VBoxContainer.new()
vbox.name = "VBox"
vbox.add_theme_constant_override("separation", 8)
margin.add_child(vbox)
vbox.owner = root

# helper: section label
func _add_section(parent, label_text):
	var lbl := Label.new()
	lbl.text = label_text
	lbl.add_theme_font_size_override("font_size", 11)
	lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	parent.add_child(lbl)
	lbl.owner = root

# helper: stat row  (name, node_name, tooltip_text)
func _add_row(parent, display: String, node_name: String, tip: String):
	var hbox := HBoxContainer.new()
	hbox.name = node_name
	parent.add_child(hbox)
	hbox.owner = root
	var name_lbl := Label.new()
	name_lbl.name = "Name"
	name_lbl.text = display
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(name_lbl)
	name_lbl.owner = root
	var val_lbl := Label.new()
	val_lbl.name = "Value"
	val_lbl.text = "—"
	hbox.add_child(val_lbl)
	val_lbl.owner = root
	# tooltip wiring
	hbox.mouse_entered.connect(func(): Tooltip.show_tip(tip))
	hbox.mouse_exited.connect(Tooltip.hide_tip)

# --- title ---
var title := Label.new()
title.name = "Title"
title.text = "角色属性"
title.add_theme_font_size_override("font_size", 16)
vbox.add_child(title)
title.owner = root

var sep0 := HSeparator.new()
vbox.add_child(sep0)
sep0.owner = root

# --- survival group ---
var sg := VBoxContainer.new()
sg.name = "SurvivalGroup"
sg.add_theme_constant_override("separation", 6)
vbox.add_child(sg)
sg.owner = root

_add_section(sg, "— 生存 —")
_add_row(sg, "生命",   "HP",         "当前生命 / 上限，归零即游戏结束")
_add_row(sg, "护盾",   "Shield",     "先于生命值承受伤害，耗尽后不再生效")
_add_row(sg, "减伤",   "SlowStacks", "每层降低你对敌人造成的伤害")
_add_row(sg, "反射",   "Reflect",    "将受到伤害的一定比例反弹给攻击者")

var sep1 := HSeparator.new()
vbox.add_child(sep1)
sep1.owner = root

# --- offense group ---
var og := VBoxContainer.new()
og.name = "OffenseGroup"
og.add_theme_constant_override("separation", 6)
vbox.add_child(og)
og.owner = root

_add_section(og, "— 攻击 —")
_add_row(og, "攻击力",   "Dmg",      "每次攻击造成的基础伤害")
_add_row(og, "攻击间隔", "Interval", "两次攻击之间的间隔（秒），越低越快")
_add_row(og, "强化",     "Amplify",  "每层提升你对敌人造成的伤害")
_add_row(og, "吸血",     "Lifesteal","每次造成伤害时按比例回复生命")

var sep2 := HSeparator.new()
vbox.add_child(sep2)
sep2.owner = root

# --- close button ---
var close_btn := Button.new()
close_btn.name = "CloseButton"
close_btn.text = "关闭"
vbox.add_child(close_btn)
close_btn.owner = root

# --- save ---
var packed := PackedScene.new()
packed.pack(root)
ResourceSaver.save(packed, "res://scenes/ui/character_panel.tscn")
print("character_panel.tscn saved")
```

- [ ] **Step 2: Verify scene file exists**

```powershell
Test-Path "S:/attribute-loop/scenes/ui/character_panel.tscn"
```

Expected: `True`

- [ ] **Step 3: Run tests — should now pass**

```
cd "S:/attribute-loop" && powershell -NoProfile -File scripts/self-test.ps1
```

Expected: all `test_character_panel` tests PASS.

- [ ] **Step 4: Commit**

```bash
git add scenes/ui/character_panel.tscn src/ui/CharacterPanel.gd tests/unit/test_character_panel.gd
git commit -m "feat: add CharacterPanel scene and script"
```

---

## Task 3: Wire CharacterPanel into HUD

**Files:**
- Modify: `scenes/ui/hud.tscn` — add CharButton next to BagButton; instantiate CharacterPanel
- Modify: `src/ui/HUD.gd` — add `_char_panel` ref, wire button + C key, mutual-exclusion

- [ ] **Step 1: Add CharButton and CharacterPanel to hud.tscn via editor script**

Run in Godot MCP `execute_editor_script`:

```gdscript
var ei = Engine.get_meta("GodotMCPPlugin").get_editor_interface()
var scene = ei.get_edited_scene_root()  # expects hud.tscn to be open

# 1. Add CharButton after BagButton in HContent
var hcontent = scene.get_node("BottomBar/HContent")
var bag_btn = hcontent.get_node("BagButton")

var char_btn := Button.new()
char_btn.name = "CharButton"
char_btn.text = "角色 [C]"
hcontent.add_child(char_btn)
char_btn.owner = scene
# Move CharButton to be immediately after BagButton
var bag_idx = bag_btn.get_index()
hcontent.move_child(char_btn, bag_idx + 1)

# 2. Instantiate CharacterPanel as sibling of InventoryPanel
var char_panel_scene = load("res://scenes/ui/character_panel.tscn")
var char_panel = char_panel_scene.instantiate()
char_panel.name = "CharacterPanel"
scene.add_child(char_panel)
char_panel.owner = scene

ei.save_scene()
print("hud.tscn updated")
```

- [ ] **Step 2: Verify hud.tscn saved correctly**

Open `scenes/ui/hud.tscn` and confirm `CharButton` and `CharacterPanel` nodes are present.

- [ ] **Step 3: Update `HUD.gd`**

Add the following to `src/ui/HUD.gd`:

After the existing `@onready var auction_btn` line, add:
```gdscript
@onready var char_btn: Button = $BottomBar/HContent/CharButton
@onready var _char_panel: CharacterPanel = $CharacterPanel
```

In `_ready()`, after `bag_btn.pressed.connect(_on_bag_pressed)`, add:
```gdscript
	char_btn.pressed.connect(_on_char_pressed)
```

Add new methods at the end of the file:
```gdscript
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_C:
			_on_char_pressed()
			get_viewport().set_input_as_handled()

func _on_char_pressed() -> void:
	if _char_panel == null:
		return
	if _inventory_panel != null and _inventory_panel.visible:
		_inventory_panel.toggle()
	_char_panel.toggle()
```

- [ ] **Step 4: Run full test suite**

```
cd "S:/attribute-loop" && powershell -NoProfile -File scripts/self-test.ps1
```

Expected: all tests PASS (no HUD unit tests break).

- [ ] **Step 5: Commit**

```bash
git add scenes/ui/hud.tscn src/ui/HUD.gd
git commit -m "feat: wire CharacterPanel into HUD with C-key toggle and mutual exclusion"
```

---

## Task 4: Visual integration test

**Files:** (read-only verification)

- [ ] **Step 1: Create sentinel and launch game**

```gdscript
# Write empty sentinel
FileAccess.open("res://tests/.test_mode", FileAccess.WRITE).close()

# Launch via MCP
var plugin = Engine.get_meta("GodotMCPPlugin")
plugin.get_editor_interface().play_main_scene()
```

- [ ] **Step 2: Poll for screenshot (timeout 20s)**

Poll every 2 seconds for `tests/screenshots/last_run.png` to appear.

- [ ] **Step 3: Read screenshot and verify**

Use `Read` tool on `tests/screenshots/last_run.png`. Confirm:
- HUD bottom bar renders
- 「角色 [C]」 button is visible next to 「背包」
- No error dialogs

- [ ] **Step 4: Delete sentinel**

```powershell
Remove-Item "S:/attribute-loop/tests/.test_mode" -ErrorAction SilentlyContinue
```

- [ ] **Step 5: Stop game and commit docs**

```bash
git add docs/modules/character-panel.md
git commit -m "docs: add character-panel module documentation"
```

---

## Self-Review

**Spec coverage check:**
- ✅ Button placement (next to 背包, C key) — Task 3
- ✅ Mutual exclusion with inventory — Task 3 `_on_char_pressed()`
- ✅ Grouped list layout (生存 / 攻击) — Task 2 scene builder
- ✅ All 8 stats with correct sources and format — Task 1 `_refresh()`
- ✅ Zero-value dash rendering — Task 1 `_int_or_dash` / `_stacks_or_dash` / `_pct_or_dash`
- ✅ Tooltips via existing `Tooltip` autoload — Task 2 scene builder `_add_row`
- ✅ Open-once refresh (no `_process`) — Task 1 `toggle()` calls `_refresh()` on show only

**Placeholder scan:** None found.

**Type consistency:**
- `CharacterPanel` class used in HUD.gd `@onready` — matches `class_name` in script ✅
- Node paths `SurvivalGroup/HP/Value` used in tests match scene builder paths ✅
- `DataTables.player` returns `PlayerData` with `dmg_base`, `attack_interval` — confirmed in `PlayerData.gd` ✅
- `GameState.dmg_bonus` and `GameState.attack_interval_bonus` confirmed in `GameState.gd` ✅
