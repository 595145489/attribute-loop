# HUD Bottom Bar & Starting Tile Spawn Fix Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the vertical HUD stack with a full-width pill-style bottom bar showing real-time rule progress, and fix enemy spawning to exclude the starting tile (index 0).

**Architecture:** Two independent changes: (1) HUD is a pure scene/script rewrite — replace VBoxContainer with a PanelContainer+HBoxContainer bottom bar with styled pill sub-nodes; (2) spawn fix is a two-line code change plus a new test for the static `_pick_tile_indices` function.

**Tech Stack:** Godot 4 GDScript, GUT test framework, .tscn scene format

---

## File Map

| File | Change |
|---|---|
| `tests/unit/test_game_loop.gd` | Add: test asserting index 0 never appears in spawn results |
| `src/systems/GameLoop.gd` | Modify line 155: `range(total)` → `range(1, total)` |
| `src/Main.gd` | Modify line 31: `for i in 12:` → `for i in 13:` |
| `scenes/ui/hud.tscn` | Full rewrite: new node tree with pill containers |
| `src/ui/HUD.gd` | Full rewrite: new `@onready` paths + `_update_rule_panel` method |

---

## Task 1: Spawn Fix (TDD)

**Files:**
- Modify: `tests/unit/test_game_loop.gd`
- Modify: `src/systems/GameLoop.gd:154-157`
- Modify: `src/Main.gd:31`

- [ ] **Step 1.1: Add failing test to `tests/unit/test_game_loop.gd`**

Append to end of file:

```gdscript
func test_pick_tile_indices_never_returns_zero() -> void:
	for i in 200:
		var indices = GameLoop._pick_tile_indices(5, 13)
		assert_false(0 in indices, "Starting tile index 0 must never be in spawn pool")

func test_pick_tile_indices_correct_count_with_13_tiles() -> void:
	var indices = GameLoop._pick_tile_indices(3, 13)
	assert_eq(indices.size(), 3)
```

- [ ] **Step 1.2: Run tests to confirm the new test fails**

```powershell
cd "S:/attribute-loop" && powershell -NoProfile -File scripts/self-test.ps1
```

Expected: `test_pick_tile_indices_never_returns_zero` FAIL (index 0 currently included).

- [ ] **Step 1.3: Fix `_pick_tile_indices` in `src/systems/GameLoop.gd`**

Change line 155:
```gdscript
# Before
var pool = range(total)
# After
var pool = range(1, total)
```

- [ ] **Step 1.4: Fix tile count in `src/Main.gd`**

Change line 31:
```gdscript
# Before
for i in 12:
# After
for i in 13:
```

This keeps 12 spawnable tiles (indices 1–12) while the starting tile (index 0) is never in the pool.

- [ ] **Step 1.5: Run tests to confirm all pass**

```powershell
cd "S:/attribute-loop" && powershell -NoProfile -File scripts/self-test.ps1
```

Expected: all tests PASS including both new tests.

- [ ] **Step 1.6: Commit**

```powershell
git add tests/unit/test_game_loop.gd src/systems/GameLoop.gd src/Main.gd
git commit -m "fix: exclude starting tile (index 0) from enemy spawn pool; add 13th tile to compensate"
```

---

## Task 2: HUD Scene Rewrite

**Files:**
- Rewrite: `scenes/ui/hud.tscn`
- Rewrite: `src/ui/HUD.gd`

### Step 2.1: Write new `scenes/ui/hud.tscn`

- [ ] Replace the entire file with:

```
[gd_scene load_steps=12 format=3 uid="uid://hud_scene_v1"]

[ext_resource type="Script" path="res://src/ui/HUD.gd" id="1_hud"]

[sub_resource type="StyleBoxFlat" id="StyleBoxFlat_bar"]
bg_color = Color(0.031, 0.031, 0.094, 0.94)
border_width_top = 1
border_color = Color(0.2, 0.2, 0.4, 1)
content_margin_left = 8.0
content_margin_right = 8.0
content_margin_top = 4.0
content_margin_bottom = 4.0

[sub_resource type="StyleBoxFlat" id="StyleBoxFlat_hp"]
bg_color = Color(0.165, 0.039, 0.039, 1)
border_width_left = 1
border_width_top = 1
border_width_right = 1
border_width_bottom = 1
border_color = Color(0.663, 0.2, 0.2, 1)
corner_radius_top_left = 10
corner_radius_top_right = 10
corner_radius_bottom_left = 10
corner_radius_bottom_right = 10
content_margin_left = 8.0
content_margin_right = 8.0
content_margin_top = 2.0
content_margin_bottom = 2.0

[sub_resource type="StyleBoxFlat" id="StyleBoxFlat_loop"]
bg_color = Color(0.102, 0.102, 0.165, 1)
border_width_left = 1
border_width_top = 1
border_width_right = 1
border_width_bottom = 1
border_color = Color(0.267, 0.267, 0.4, 1)
corner_radius_top_left = 10
corner_radius_top_right = 10
corner_radius_bottom_left = 10
corner_radius_bottom_right = 10
content_margin_left = 8.0
content_margin_right = 8.0
content_margin_top = 2.0
content_margin_bottom = 2.0

[sub_resource type="StyleBoxFlat" id="StyleBoxFlat_phase"]
bg_color = Color(0.039, 0.125, 0.063, 1)
border_width_left = 1
border_width_top = 1
border_width_right = 1
border_width_bottom = 1
border_color = Color(0.278, 0.455, 0.278, 1)
corner_radius_top_left = 10
corner_radius_top_right = 10
corner_radius_bottom_left = 10
corner_radius_bottom_right = 10
content_margin_left = 8.0
content_margin_right = 8.0
content_margin_top = 2.0
content_margin_bottom = 2.0

[sub_resource type="StyleBoxFlat" id="StyleBoxFlat_rule"]
bg_color = Color(0.039, 0.039, 0.133, 1)
border_width_left = 1
border_width_top = 1
border_width_right = 1
border_width_bottom = 1
border_color = Color(0.267, 0.267, 0.467, 1)
corner_radius_top_left = 8
corner_radius_top_right = 8
corner_radius_bottom_left = 8
corner_radius_bottom_right = 8
content_margin_left = 8.0
content_margin_right = 8.0
content_margin_top = 3.0
content_margin_bottom = 3.0

[sub_resource type="StyleBoxFlat" id="StyleBoxFlat_tbar"]
bg_color = Color(0.102, 0.102, 0.212, 1)
corner_radius_top_left = 3
corner_radius_top_right = 3
corner_radius_bottom_left = 3
corner_radius_bottom_right = 3

[sub_resource type="StyleBoxFlat" id="StyleBoxFlat_tbar_fill"]
bg_color = Color(0.267, 0.267, 1.0, 1)
corner_radius_top_left = 3
corner_radius_top_right = 3
corner_radius_bottom_left = 3
corner_radius_bottom_right = 3

[sub_resource type="StyleBoxFlat" id="StyleBoxFlat_bag"]
bg_color = Color(0.102, 0.165, 0.314, 1)
border_width_left = 1
border_width_top = 1
border_width_right = 1
border_width_bottom = 1
border_color = Color(0.333, 0.333, 0.667, 1)
corner_radius_top_left = 4
corner_radius_top_right = 4
corner_radius_bottom_left = 4
corner_radius_bottom_right = 4
content_margin_left = 10.0
content_margin_right = 10.0
content_margin_top = 2.0
content_margin_bottom = 2.0

[node name="HUD" type="CanvasLayer"]
script = ExtResource("1_hud")

[node name="BottomBar" type="PanelContainer" parent="."]
anchor_left = 0.0
anchor_top = 1.0
anchor_right = 1.0
anchor_bottom = 1.0
offset_top = -44.0
offset_bottom = 0.0
grow_vertical = 0
theme_override_styles/panel = SubResource("StyleBoxFlat_bar")

[node name="HContent" type="HBoxContainer" parent="BottomBar"]
layout_mode = 2
theme_override_constants/separation = 6

[node name="HPPill" type="PanelContainer" parent="BottomBar/HContent"]
theme_override_styles/panel = SubResource("StyleBoxFlat_hp")

[node name="HPLabel" type="Label" parent="BottomBar/HContent/HPPill"]
layout_mode = 2
text = "❤ 100 / 100"
add_theme_color_override("font_color", Color(1.0, 0.533, 0.533, 1))
add_theme_font_size_override("font_size", 11)

[node name="LoopPill" type="PanelContainer" parent="BottomBar/HContent"]
theme_override_styles/panel = SubResource("StyleBoxFlat_loop")

[node name="LoopLabel" type="Label" parent="BottomBar/HContent/LoopPill"]
layout_mode = 2
text = "圈 × 0"
add_theme_color_override("font_color", Color(0.6, 0.6, 0.733, 1))
add_theme_font_size_override("font_size", 11)

[node name="PhasePill" type="PanelContainer" parent="BottomBar/HContent"]
theme_override_styles/panel = SubResource("StyleBoxFlat_phase")

[node name="PhaseLabel" type="Label" parent="BottomBar/HContent/PhasePill"]
layout_mode = 2
text = "阶段 1 · 觉醒"
add_theme_color_override("font_color", Color(0.533, 0.867, 0.533, 1))
add_theme_font_size_override("font_size", 11)

[node name="RulePanel0" type="PanelContainer" parent="BottomBar/HContent"]
size_flags_horizontal = 3
theme_override_styles/panel = SubResource("StyleBoxFlat_rule")

[node name="RuleVBox0" type="VBoxContainer" parent="BottomBar/HContent/RulePanel0"]
layout_mode = 2
theme_override_constants/separation = 2

[node name="TRow0" type="HBoxContainer" parent="BottomBar/HContent/RulePanel0/RuleVBox0"]
layout_mode = 2
theme_override_constants/separation = 4

[node name="TTag0" type="Label" parent="BottomBar/HContent/RulePanel0/RuleVBox0/TRow0"]
layout_mode = 2
text = "T:"
add_theme_color_override("font_color", Color(0.8, 0.8, 1.0, 1))
add_theme_font_size_override("font_size", 10)

[node name="TName0" type="Label" parent="BottomBar/HContent/RulePanel0/RuleVBox0/TRow0"]
layout_mode = 2
text = "—"
add_theme_color_override("font_color", Color(1.0, 1.0, 0.6, 1))
add_theme_font_size_override("font_size", 10)

[node name="TBar0" type="ProgressBar" parent="BottomBar/HContent/RulePanel0/RuleVBox0/TRow0"]
layout_mode = 2
size_flags_horizontal = 3
custom_minimum_size = Vector2(40, 6)
value = 0.0
show_percentage = false
add_theme_stylebox_override("background", SubResource("StyleBoxFlat_tbar"))
add_theme_stylebox_override("fill", SubResource("StyleBoxFlat_tbar_fill"))

[node name="TCount0" type="Label" parent="BottomBar/HContent/RulePanel0/RuleVBox0/TRow0"]
layout_mode = 2
text = "0/0"
add_theme_color_override("font_color", Color(1.0, 1.0, 0.6, 1))
add_theme_font_size_override("font_size", 10)

[node name="ERow0" type="HBoxContainer" parent="BottomBar/HContent/RulePanel0/RuleVBox0"]
layout_mode = 2
theme_override_constants/separation = 4

[node name="ETag0" type="Label" parent="BottomBar/HContent/RulePanel0/RuleVBox0/ERow0"]
layout_mode = 2
text = "E:"
add_theme_color_override("font_color", Color(0.8, 0.8, 1.0, 1))
add_theme_font_size_override("font_size", 10)

[node name="EName0" type="Label" parent="BottomBar/HContent/RulePanel0/RuleVBox0/ERow0"]
layout_mode = 2
text = "—"
add_theme_color_override("font_color", Color(0.533, 0.667, 1.0, 1))
add_theme_font_size_override("font_size", 10)

[node name="EValue0" type="Label" parent="BottomBar/HContent/RulePanel0/RuleVBox0/ERow0"]
layout_mode = 2
text = ""
add_theme_color_override("font_color", Color(0.533, 0.667, 1.0, 1))
add_theme_font_size_override("font_size", 10)

[node name="RulePanel1" type="PanelContainer" parent="BottomBar/HContent"]
size_flags_horizontal = 3
theme_override_styles/panel = SubResource("StyleBoxFlat_rule")

[node name="RuleVBox1" type="VBoxContainer" parent="BottomBar/HContent/RulePanel1"]
layout_mode = 2
theme_override_constants/separation = 2

[node name="TRow1" type="HBoxContainer" parent="BottomBar/HContent/RulePanel1/RuleVBox1"]
layout_mode = 2
theme_override_constants/separation = 4

[node name="TTag1" type="Label" parent="BottomBar/HContent/RulePanel1/RuleVBox1/TRow1"]
layout_mode = 2
text = "T:"
add_theme_color_override("font_color", Color(0.8, 0.8, 1.0, 1))
add_theme_font_size_override("font_size", 10)

[node name="TName1" type="Label" parent="BottomBar/HContent/RulePanel1/RuleVBox1/TRow1"]
layout_mode = 2
text = "—"
add_theme_color_override("font_color", Color(1.0, 1.0, 0.6, 1))
add_theme_font_size_override("font_size", 10)

[node name="TBar1" type="ProgressBar" parent="BottomBar/HContent/RulePanel1/RuleVBox1/TRow1"]
layout_mode = 2
size_flags_horizontal = 3
custom_minimum_size = Vector2(40, 6)
value = 0.0
show_percentage = false
add_theme_stylebox_override("background", SubResource("StyleBoxFlat_tbar"))
add_theme_stylebox_override("fill", SubResource("StyleBoxFlat_tbar_fill"))

[node name="TCount1" type="Label" parent="BottomBar/HContent/RulePanel1/RuleVBox1/TRow1"]
layout_mode = 2
text = "0/0"
add_theme_color_override("font_color", Color(1.0, 1.0, 0.6, 1))
add_theme_font_size_override("font_size", 10)

[node name="ERow1" type="HBoxContainer" parent="BottomBar/HContent/RulePanel1/RuleVBox1"]
layout_mode = 2
theme_override_constants/separation = 4

[node name="ETag1" type="Label" parent="BottomBar/HContent/RulePanel1/RuleVBox1/ERow1"]
layout_mode = 2
text = "E:"
add_theme_color_override("font_color", Color(0.8, 0.8, 1.0, 1))
add_theme_font_size_override("font_size", 10)

[node name="EName1" type="Label" parent="BottomBar/HContent/RulePanel1/RuleVBox1/ERow1"]
layout_mode = 2
text = "—"
add_theme_color_override("font_color", Color(0.533, 0.667, 1.0, 1))
add_theme_font_size_override("font_size", 10)

[node name="EValue1" type="Label" parent="BottomBar/HContent/RulePanel1/RuleVBox1/ERow1"]
layout_mode = 2
text = ""
add_theme_color_override("font_color", Color(0.533, 0.667, 1.0, 1))
add_theme_font_size_override("font_size", 10)

[node name="BagButton" type="Button" parent="BottomBar/HContent"]
text = "背包 [B] 0/12"
add_theme_stylebox_override("normal", SubResource("StyleBoxFlat_bag"))
add_theme_color_override("font_color", Color(0.6, 0.8, 1.0, 1))
add_theme_font_size_override("font_size", 11)

[node name="FloatLabel" type="Label" parent="."]
offset_left = 400.0
offset_top = 260.0
offset_right = 700.0
offset_bottom = 300.0
horizontal_alignment = 1
add_theme_font_size_override("font_size", 14)
```

### Step 2.2: Write new `src/ui/HUD.gd`

- [ ] Replace the entire file with:

```gdscript
class_name HUD
extends CanvasLayer

var _inventory_panel = null
var _float_tween: Tween = null

@onready var hp_label: Label = $BottomBar/HContent/HPPill/HPLabel
@onready var loop_label: Label = $BottomBar/HContent/LoopPill/LoopLabel
@onready var phase_label: Label = $BottomBar/HContent/PhasePill/PhaseLabel
@onready var bag_btn: Button = $BottomBar/HContent/BagButton
@onready var float_label: Label = $FloatLabel

# Rule panel node refs — indexed by slot
@onready var _t_name: Array[Label] = [
	$BottomBar/HContent/RulePanel0/RuleVBox0/TRow0/TName0,
	$BottomBar/HContent/RulePanel1/RuleVBox1/TRow1/TName1,
]
@onready var _t_bar: Array[ProgressBar] = [
	$BottomBar/HContent/RulePanel0/RuleVBox0/TRow0/TBar0,
	$BottomBar/HContent/RulePanel1/RuleVBox1/TRow1/TBar1,
]
@onready var _t_count: Array[Label] = [
	$BottomBar/HContent/RulePanel0/RuleVBox0/TRow0/TCount0,
	$BottomBar/HContent/RulePanel1/RuleVBox1/TRow1/TCount1,
]
@onready var _e_name: Array[Label] = [
	$BottomBar/HContent/RulePanel0/RuleVBox0/ERow0/EName0,
	$BottomBar/HContent/RulePanel1/RuleVBox1/ERow1/EName1,
]
@onready var _e_value: Array[Label] = [
	$BottomBar/HContent/RulePanel0/RuleVBox0/ERow0/EValue0,
	$BottomBar/HContent/RulePanel1/RuleVBox1/ERow1/EValue1,
]

func _ready() -> void:
	bag_btn.pressed.connect(_on_bag_pressed)
	float_label.hide()
	EventBus.rule_fired.connect(_on_rule_fired)

func setup(inv_panel) -> void:
	_inventory_panel = inv_panel

func _process(_delta: float) -> void:
	hp_label.text = "❤ %d / %d" % [GameState.hp, GameState.hp_max]
	loop_label.text = "圈 × %d" % GameState.loops_completed
	var phase_data: PhaseData = DataTables.get_phase(GameState.current_phase)
	phase_label.text = "阶段%d · %s" % [GameState.current_phase, phase_data.phase_name]
	bag_btn.text = "背包 [B] %d/%d" % [GameState.inventory.size(), DataTables.config.inventory_cap]
	for i in GameState.rule_slots.size():
		_update_rule_panel(i)

func _update_rule_panel(i: int) -> void:
	var slot = GameState.rule_slots[i]
	var t: ComponentData = slot.get("trigger")
	var e: ComponentData = slot.get("effect")
	if t == null or e == null:
		_t_name[i].text = "— 空槽 —"
		_t_bar[i].max_value = 1
		_t_bar[i].value = 0
		_t_count[i].text = ""
		_e_name[i].text = ""
		_e_value[i].text = ""
		return
	_t_name[i].text = t.display_name
	_t_bar[i].max_value = t.trigger_value
	_t_bar[i].value = t.trigger_count
	_t_count[i].text = "%d/%d" % [t.trigger_count, int(t.trigger_value)]
	_e_name[i].text = e.display_name
	match e.id:
		"治愈":
			_e_value[i].text = "+%d" % int(e.effect_value)
		"反射":
			_e_value[i].text = "%d%%" % int(e.effect_value * 100)
		_:
			_e_value[i].text = ""

func _on_bag_pressed() -> void:
	if _inventory_panel != null:
		_inventory_panel.toggle()

func _on_rule_fired(_slot_idx: int, effect_id: String, value: float) -> void:
	if effect_id == "治愈":
		float_label.text = "+%.0f 治愈" % value
	elif effect_id == "反射":
		float_label.text = "反射 %.0f%%" % (value * 100)
	else:
		float_label.text = effect_id
	float_label.show()
	float_label.modulate = Color.WHITE
	if _float_tween:
		_float_tween.kill()
	_float_tween = create_tween()
	_float_tween.tween_property(float_label, "modulate:a", 0.0, 1.0)
	_float_tween.tween_callback(float_label.hide)
```

- [ ] **Step 2.3: Run unit tests**

```powershell
cd "S:/attribute-loop" && powershell -NoProfile -File scripts/self-test.ps1
```

Expected: all tests PASS (no HUD unit tests; existing tests unaffected).

- [ ] **Step 2.4: Commit**

```powershell
git add scenes/ui/hud.tscn src/ui/HUD.gd
git commit -m "feat: replace HUD vertical stack with full-width pill bottom bar; rule panels show T/E real-time progress"
```

---

## Task 3: Visual Integration Test

- [ ] **Step 3.1: Run visual integration test** (requires Godot editor open)

Follow CLAUDE.md Step 3: create `tests/.test_mode`, play main scene via MCP, wait for screenshot, verify bottom bar renders correctly with pills visible and no black/blank screen, delete `tests/.test_mode`.

- [ ] **Step 3.2: Write module doc `docs/modules/hud.md`**

Cover: what HUD is responsible for, node structure overview, `_update_rule_panel` flow, signals consumed (`rule_fired`).
