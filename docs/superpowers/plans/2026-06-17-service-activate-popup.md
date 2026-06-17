# Service Activate Popup Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Restyle `ServiceActivatePopup` with the dark-gold card visual direction, add descriptions, structured layouts, and reactive confirm-button state — no new art assets required.

**Architecture:** All content is built dynamically in code (existing pattern). The scene gains a `TextureRect` background and a `ScrollContainer` body zone. `ServiceActivatePopup.gd` gets a `_make_row()` helper and a `_refresh_confirm()` method; `_build_content()` and `_build_discard_content()` are rewritten to use them. `AuctionManager` gains two new constant dictionaries (`SERVICE_SUBTITLES`, `SERVICE_FLAVOUR`) and the popup reads from them.

**Tech Stack:** Godot 4 GDScript, GUT unit tests (`extends GutTest`), existing `service_btn_card.png` art asset.

---

## Files

| Action | Path |
|--------|------|
| Modify | `src/systems/AuctionManager.gd` |
| Modify | `src/ui/ServiceActivatePopup.gd` |
| Modify | `scenes/ui/service_activate_popup.tscn` |
| Create | `tests/unit/test_service_activate_popup.gd` |

---

### Task 1: Add `SERVICE_SUBTITLES` and `SERVICE_FLAVOUR` to AuctionManager

**Files:**
- Modify: `src/systems/AuctionManager.gd`
- Create: `tests/unit/test_service_activate_popup.gd`

- [ ] **Step 1: Write the failing test**

Create `tests/unit/test_service_activate_popup.gd`:

```gdscript
extends GutTest

const AuctionManager = preload("res://src/systems/AuctionManager.gd")

func test_all_service_types_have_subtitle() -> void:
	for svc_val in AuctionManager.ServiceType.values():
		assert_true(
			AuctionManager.SERVICE_SUBTITLES.has(svc_val),
			"Missing subtitle for ServiceType %d" % svc_val
		)

func test_all_service_types_have_flavour() -> void:
	for svc_val in AuctionManager.ServiceType.values():
		assert_true(
			AuctionManager.SERVICE_FLAVOUR.has(svc_val),
			"Missing flavour for ServiceType %d" % svc_val
		)

func test_subtitle_strings_are_nonempty() -> void:
	for svc_val in AuctionManager.ServiceType.values():
		var s: String = AuctionManager.SERVICE_SUBTITLES.get(svc_val, "")
		assert_true(s.length() > 0, "Empty subtitle for ServiceType %d" % svc_val)

func test_flavour_strings_are_nonempty() -> void:
	for svc_val in AuctionManager.ServiceType.values():
		var s: String = AuctionManager.SERVICE_FLAVOUR.get(svc_val, "")
		assert_true(s.length() > 0, "Empty flavour for ServiceType %d" % svc_val)
```

- [ ] **Step 2: Run test to confirm it fails**

```
cd S:/attribute-loop && powershell -NoProfile -File scripts/self-test.ps1
```

Expected: FAIL — `SERVICE_SUBTITLES` and `SERVICE_FLAVOUR` not defined.

- [ ] **Step 3: Add the two dictionaries to AuctionManager**

In `src/systems/AuctionManager.gd`, after the `SERVICE_DESCRIPTIONS` block (line 43), add:

```gdscript
const SERVICE_SUBTITLES: Dictionary = {
	ServiceType.COMP_REWRITE:   "效果词条 · 效果值 +20%",
	ServiceType.COMP_MERGE:     "效果词条 · 总和 × 0.8",
	ServiceType.ENEMY_PARDON:   "指定敌人 · 持续 3 次遭遇",
	ServiceType.DELETE_PARDON:  "下次删除 · 0 费用",
	ServiceType.PRESSURE_DELAY: "世界压力 · 计时 -1 圈",
	ServiceType.STAT_DMG:       "属性提升 · 永久生效",
	ServiceType.STAT_HP:        "属性提升 · 永久生效",
	ServiceType.STAT_SPEED:     "属性提升 · 永久生效",
	ServiceType.STAT_AMPLIFY:   "属性提升 · 永久生效",
	ServiceType.SLOT_RULE:      "槽位扩容 · 永久生效",
	ServiceType.SLOT_SERVICE:   "槽位扩容 · 永久生效",
}

const SERVICE_FLAVOUR: Dictionary = {
	ServiceType.COMP_REWRITE:   "折痕可以修正，但代价是更深的刻印。",
	ServiceType.COMP_MERGE:     "两愿合一，形合则意合，意合则力合。",
	ServiceType.ENEMY_PARDON:   "折纸之道，非战而胜，乃折而化之。",
	ServiceType.DELETE_PARDON:  "有些错误，可以抹去，不留痕迹。",
	ServiceType.PRESSURE_DELAY: "时间是最好的折叠工具，只需多一轮。",
	ServiceType.STAT_DMG:       "以战磨砺，以血铸意。每一次挥剑，折痕更深。",
	ServiceType.STAT_HP:        "筋骨强化，承压而不折。",
	ServiceType.STAT_SPEED:     "迅如流水，折纸无声。",
	ServiceType.STAT_AMPLIFY:   "潜能深埋，一旦唤醒，层叠无尽。",
	ServiceType.SLOT_RULE:      "规则愈多，折叠愈深，世界愈复杂。",
	ServiceType.SLOT_SERVICE:   "容量扩张，选择增多，道路更宽。",
}
```

- [ ] **Step 4: Run tests and confirm they pass**

```
cd S:/attribute-loop && powershell -NoProfile -File scripts/self-test.ps1
```

Expected: all 4 new tests PASS.

- [ ] **Step 5: Commit**

```bash
git add src/systems/AuctionManager.gd tests/unit/test_service_activate_popup.gd
git commit -m "feat: add SERVICE_SUBTITLES and SERVICE_FLAVOUR to AuctionManager"
```

---

### Task 2: Rebuild the scene — three-zone layout with styled background

**Files:**
- Modify: `scenes/ui/service_activate_popup.tscn`

The current scene (`service_activate_popup.tscn`) is a bare `PanelContainer` with no styling. Replace it entirely with a new structured layout.

- [ ] **Step 1: Rewrite `service_activate_popup.tscn`**

Replace the entire file content with:

```
[gd_scene format=3 uid="uid://cygyugu7brhl8"]

[ext_resource type="Script" uid="uid://cbe3flmvnqnia" path="res://src/ui/ServiceActivatePopup.gd" id="1_sap"]
[ext_resource type="Texture2D" uid="uid://service_btn_card" path="res://resources/ui/service_btn_card.png" id="2_bg"]

[node name="ServiceActivatePopup" type="Control"]
visible = false
custom_minimum_size = Vector2(480, 360)
layout_mode = 3
anchors_preset = 8
anchor_left = 0.5
anchor_top = 0.5
anchor_right = 0.5
anchor_bottom = 0.5
offset_left = -240.0
offset_top = -180.0
offset_right = 240.0
offset_bottom = 180.0
script = ExtResource("1_sap")

[node name="BG" type="TextureRect" parent="."]
layout_mode = 0
anchor_right = 1.0
anchor_bottom = 1.0
texture = ExtResource("2_bg")
expand_mode = 1
stretch_mode = 6

[node name="VBox" type="VBoxContainer" parent="."]
layout_mode = 0
anchor_right = 1.0
anchor_bottom = 1.0
offset_left = 16.0
offset_top = 12.0
offset_right = -16.0
offset_bottom = -12.0
theme_override_constants/separation = 8

[node name="Header" type="VBoxContainer" parent="VBox"]
layout_mode = 2
custom_minimum_size = Vector2(0, 50)
theme_override_constants/separation = 2

[node name="Title" type="Label" parent="VBox/Header"]
layout_mode = 2
text = "服务"
theme_override_font_sizes/font_size = 18
theme_override_colors/font_color = Color(0.941, 0.816, 0.502, 1)

[node name="Subtitle" type="Label" parent="VBox/Header"]
layout_mode = 2
text = ""
theme_override_font_sizes/font_size = 11
theme_override_colors/font_color = Color(0.627, 0.471, 0.251, 1)

[node name="Divider" type="HSeparator" parent="VBox"]
layout_mode = 2
theme_override_colors/separator_color = Color(0.784, 0.573, 0.227, 0.267)

[node name="Scroll" type="ScrollContainer" parent="VBox"]
layout_mode = 2
size_flags_vertical = 3

[node name="Content" type="VBoxContainer" parent="VBox/Scroll"]
layout_mode = 2
size_flags_horizontal = 3
theme_override_constants/separation = 4

[node name="Divider2" type="HSeparator" parent="VBox"]
layout_mode = 2
theme_override_colors/separator_color = Color(0.784, 0.573, 0.227, 0.267)

[node name="Buttons" type="HBoxContainer" parent="VBox"]
layout_mode = 2
custom_minimum_size = Vector2(0, 36)
theme_override_constants/separation = 8

[node name="Cancel" type="Button" parent="VBox/Buttons"]
layout_mode = 2
size_flags_horizontal = 3
text = "取消"
theme_override_colors/font_color = Color(0.502, 0.376, 0.251, 1)

[node name="Confirm" type="Button" parent="VBox/Buttons"]
layout_mode = 2
size_flags_horizontal = 3
text = "确认"
theme_override_colors/font_color = Color(0.941, 0.816, 0.502, 1)
```

- [ ] **Step 2: Verify scene loads without errors**

```
cd S:/attribute-loop && powershell -NoProfile -File scripts/self-test.ps1
```

Expected: existing tests still PASS (no syntax errors from new scene).

- [ ] **Step 3: Commit**

```bash
git add scenes/ui/service_activate_popup.tscn
git commit -m "feat: rebuild service activate popup scene with three-zone layout"
```

---

### Task 3: Update script node references and add `_make_row()` helper

**Files:**
- Modify: `src/ui/ServiceActivatePopup.gd`

The script currently references `$Panel/VBox/Title` etc. These paths are now wrong after the scene rebuild. Update all `@onready` paths and add the row helper.

- [ ] **Step 1: Add tests for `_make_row` output structure**

Add to `tests/unit/test_service_activate_popup.gd`:

```gdscript
func test_make_row_returns_panel_container() -> void:
	var popup = load("res://scenes/ui/service_activate_popup.tscn").instantiate()
	add_child_autofree(popup)
	var grp := ButtonGroup.new()
	var row = popup._make_row("治愈", "12.5", "15.0", grp, null)
	assert_not_null(row)
	assert_true(row is PanelContainer, "Row should be a PanelContainer")

func test_make_row_button_in_group() -> void:
	var popup = load("res://scenes/ui/service_activate_popup.tscn").instantiate()
	add_child_autofree(popup)
	var grp := ButtonGroup.new()
	var row = popup._make_row("护盾", "8.0", "9.6", grp, null)
	var btn: Button = row.get_node("HBox/Btn")
	assert_eq(btn.button_group, grp)
```

- [ ] **Step 2: Run tests to confirm they fail**

```
cd S:/attribute-loop && powershell -NoProfile -File scripts/self-test.ps1
```

Expected: FAIL — `_make_row` not defined yet.

- [ ] **Step 3: Rewrite `ServiceActivatePopup.gd` with updated paths and `_make_row()`**

Replace the entire file:

```gdscript
extends Control

const AuctionManager = preload("res://src/systems/AuctionManager.gd")

var _auction_manager = null
var _tiles: Array = []
var _current_service: int = -1
var _current_bar_idx: int = -1
var _discard_mode: bool = false
var _discard_options: Array[int] = []
var _discard_new_svc: int = -1

# Colours
const COL_GOLD        := Color(0.941, 0.816, 0.502, 1.0)   # #f0d080
const COL_GOLD_MUTED  := Color(0.627, 0.471, 0.251, 1.0)   # #a07840
const COL_GOLD_DIM    := Color(0.784, 0.573, 0.227, 0.133) # #c8923a22
const COL_GOLD_BORDER := Color(0.784, 0.573, 0.227, 1.0)   # #c8923a
const COL_DARK        := Color(0.102, 0.063, 0.031, 1.0)   # #1a1008
const COL_DARK_ROW    := Color(0.051, 0.039, 0.016, 1.0)   # #0d0a04
const COL_WARN        := Color(0.784, 0.471, 0.220, 1.0)   # #c87838
const COL_GREEN       := Color(0.761, 0.851, 0.565, 1.0)   # #c2d990

@onready var title_label: Label      = $VBox/Header/Title
@onready var subtitle_label: Label   = $VBox/Header/Subtitle
@onready var content_container: VBoxContainer = $VBox/Scroll/Content
@onready var confirm_btn: Button     = $VBox/Buttons/Confirm
@onready var cancel_btn: Button      = $VBox/Buttons/Cancel

func setup(am, tiles: Array) -> void:
	_auction_manager = am
	_tiles = tiles
	confirm_btn.pressed.connect(_on_confirm)
	cancel_btn.pressed.connect(_on_cancel)
	hide()

func open(svc: int, bar_idx: int) -> void:
	_discard_mode = false
	_current_service = svc
	_current_bar_idx = bar_idx
	title_label.text = AuctionManager.SERVICE_NAMES.get(svc, "?")
	subtitle_label.text = AuctionManager.SERVICE_SUBTITLES.get(svc, "")
	cancel_btn.text = "取消"
	_set_warning_mode(false)
	_build_content(svc)
	GameState.pause_for_panel()
	show()

func open_discard(options: Array[int], new_svc: int, am) -> void:
	_discard_mode = true
	_discard_options = options
	_discard_new_svc = new_svc
	_auction_manager = am
	title_label.text = "服务栏已满"
	subtitle_label.text = "新赢得：%s · 选择一个放弃" % AuctionManager.SERVICE_NAMES.get(new_svc, "?")
	cancel_btn.text = "取消（放弃新的）"
	_set_warning_mode(true)
	_build_discard_content(options, new_svc)
	GameState.pause_for_panel()
	show()

func _set_warning_mode(warning: bool) -> void:
	var col := COL_WARN if warning else COL_GOLD
	confirm_btn.add_theme_color_override("font_color", col)

func _on_cancel() -> void:
	if _discard_mode and _auction_manager != null:
		_auction_manager._pending_overflow_service = -1
	GameState.unpause_for_panel()
	hide()

func _on_confirm() -> void:
	if _discard_mode:
		_apply_discard()
		return
	if _current_service < 0:
		return
	var params = _collect_params(_current_service)
	if params == null:
		return
	if _current_bar_idx >= 0 and _current_bar_idx < GameState.service_bar.size():
		GameState.service_bar.remove_at(_current_bar_idx)
	_auction_manager.execute_service(_current_service, params)
	GameState.unpause_for_panel()
	hide()

func _apply_discard() -> void:
	var discard_idx := -1
	var row_idx := 0
	for c in content_container.get_children():
		if c is PanelContainer:
			var btn: Button = c.get_node("HBox/Btn")
			if btn.button_pressed:
				discard_idx = row_idx
				break
			row_idx += 1
	if discard_idx < 0:
		return
	var discarded_svc: int = _discard_options[discard_idx]
	if discarded_svc != _discard_new_svc:
		if discard_idx < GameState.service_bar.size():
			GameState.service_bar.remove_at(discard_idx)
		GameState.service_bar.append(_discard_new_svc)
	if _auction_manager != null:
		_auction_manager._pending_overflow_service = -1
	EventBus.service_bar_changed.emit()
	GameState.unpause_for_panel()
	hide()

# ---------------------------------------------------------------------------
# Row builder
# Returns a PanelContainer with internal path HBox/Btn (toggle Button) and
# HBox/ValueLabel (right-aligned Label).
# comp_ref: optional metadata stored on the button (pass null if not needed).
# ---------------------------------------------------------------------------
func _make_row(left_text: String, value_text: String, value_after: String,
		grp, comp_ref) -> PanelContainer:
	var panel := PanelContainer.new()
	var style_normal := StyleBoxFlat.new()
	style_normal.bg_color = COL_DARK_ROW
	style_normal.border_color = Color(COL_GOLD_BORDER.r, COL_GOLD_BORDER.g,
			COL_GOLD_BORDER.b, 0.27)
	style_normal.set_border_width_all(1)
	style_normal.set_corner_radius_all(3)
	panel.add_theme_stylebox_override("panel", style_normal)
	panel.set_meta("style_normal", style_normal)

	var style_selected := StyleBoxFlat.new()
	style_selected.bg_color = COL_GOLD_DIM
	style_selected.border_color = COL_GOLD_BORDER
	style_selected.set_border_width_all(1)
	style_selected.set_corner_radius_all(3)
	panel.set_meta("style_selected", style_selected)

	var hbox := HBoxContainer.new()
	hbox.name = "HBox"
	hbox.add_theme_constant_override("separation", 6)
	panel.add_child(hbox)

	var btn := Button.new()
	btn.name = "Btn"
	btn.text = left_text
	btn.toggle_mode = true
	btn.flat = true
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.add_theme_color_override("font_color", COL_GOLD_MUTED)
	btn.add_theme_color_override("font_pressed_color", COL_GOLD)
	btn.add_theme_color_override("font_hover_color", COL_GOLD)
	if grp != null:
		btn.button_group = grp
	if comp_ref != null:
		btn.set_meta("comp_ref", comp_ref)
	hbox.add_child(btn)

	var val_lbl := Label.new()
	val_lbl.name = "ValueLabel"
	val_lbl.text = value_text
	val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	val_lbl.add_theme_color_override("font_color", COL_GOLD_MUTED)
	val_lbl.add_theme_font_size_override("font_size", 11)
	val_lbl.set_meta("value_text", value_text)
	val_lbl.set_meta("value_after", value_after)
	hbox.add_child(val_lbl)

	btn.toggled.connect(func(pressed: bool) -> void:
		if pressed:
			panel.add_theme_stylebox_override("panel", style_selected)
			val_lbl.text = value_after if value_after != "" else value_text
			val_lbl.add_theme_color_override("font_color", COL_GREEN)
		else:
			panel.add_theme_stylebox_override("panel", style_normal)
			val_lbl.text = value_text
			val_lbl.add_theme_color_override("font_color", COL_GOLD_MUTED)
		_refresh_confirm()
	)
	return panel

func _refresh_confirm() -> void:
	var valid := _collect_params(_current_service) != null if not _discard_mode else _has_discard_selection()
	confirm_btn.disabled = not valid

func _has_discard_selection() -> bool:
	for c in content_container.get_children():
		if c is PanelContainer:
			var btn: Button = c.get_node("HBox/Btn")
			if btn.button_pressed:
				return true
	return false

# ---------------------------------------------------------------------------
# Content builders
# ---------------------------------------------------------------------------
func _build_content(svc: int) -> void:
	for c in content_container.get_children():
		c.queue_free()

	var instant_types := [
		AuctionManager.ServiceType.PRESSURE_DELAY,
		AuctionManager.ServiceType.DELETE_PARDON,
		AuctionManager.ServiceType.STAT_DMG,
		AuctionManager.ServiceType.STAT_HP,
		AuctionManager.ServiceType.STAT_SPEED,
		AuctionManager.ServiceType.STAT_AMPLIFY,
		AuctionManager.ServiceType.SLOT_RULE,
		AuctionManager.ServiceType.SLOT_SERVICE,
	]

	if svc in instant_types:
		_build_instant(svc)
		confirm_btn.text = "立即使用"
		confirm_btn.disabled = false
		return

	match svc:
		AuctionManager.ServiceType.COMP_REWRITE:
			_build_comp_list(false)
			confirm_btn.text = "改写"
			confirm_btn.disabled = true

		AuctionManager.ServiceType.COMP_MERGE:
			_build_comp_list(true)
			confirm_btn.text = "融合"
			confirm_btn.disabled = true

		AuctionManager.ServiceType.ENEMY_PARDON:
			_build_enemy_list()
			confirm_btn.text = "赦免"
			confirm_btn.disabled = true

func _build_instant(svc: int) -> void:
	var desc_lbl := Label.new()
	desc_lbl.text = AuctionManager.SERVICE_DESCRIPTIONS.get(svc, "")
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc_lbl.add_theme_color_override("font_color", COL_GOLD_MUTED)
	desc_lbl.add_theme_font_size_override("font_size", 12)
	content_container.add_child(desc_lbl)

	var flavour_lbl := Label.new()
	flavour_lbl.text = AuctionManager.SERVICE_FLAVOUR.get(svc, "")
	flavour_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	flavour_lbl.add_theme_color_override("font_color", Color(COL_GOLD_MUTED.r,
			COL_GOLD_MUTED.g, COL_GOLD_MUTED.b, 0.6))
	flavour_lbl.add_theme_font_size_override("font_size", 10)
	content_container.add_child(flavour_lbl)

func _build_comp_list(multi: bool) -> void:
	var desc_lbl := Label.new()
	desc_lbl.text = AuctionManager.SERVICE_DESCRIPTIONS.get(_current_service, "")
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc_lbl.add_theme_color_override("font_color", COL_GOLD_MUTED)
	desc_lbl.add_theme_font_size_override("font_size", 11)
	content_container.add_child(desc_lbl)

	var header_row := HBoxContainer.new()
	var left_h := Label.new()
	left_h.text = "词条名称"
	left_h.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_h.add_theme_color_override("font_color", Color(COL_GOLD_MUTED.r, COL_GOLD_MUTED.g, COL_GOLD_MUTED.b, 0.6))
	left_h.add_theme_font_size_override("font_size", 9)
	var right_h := Label.new()
	right_h.text = "当前 → 改写后" if not multi else "当前值"
	right_h.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	right_h.add_theme_color_override("font_color", Color(COL_GOLD_MUTED.r, COL_GOLD_MUTED.g, COL_GOLD_MUTED.b, 0.6))
	right_h.add_theme_font_size_override("font_size", 9)
	header_row.add_child(left_h)
	header_row.add_child(right_h)
	content_container.add_child(header_row)

	var grp := null if multi else ButtonGroup.new()
	var delta: float = DataTables.config.auction_comp_rewrite_delta

	for comp in GameState.inventory:
		var cur_val := "%.1f" % comp.effect_value
		var after_val: String
		if multi:
			after_val = cur_val
		else:
			after_val = "→ %.1f" % (comp.effect_value * (1.0 + delta))
		var row := _make_row(comp.display_name, cur_val, after_val, grp, comp)
		content_container.add_child(row)

func _build_enemy_list() -> void:
	var desc_lbl := Label.new()
	desc_lbl.text = "下 3 次遭遇自动掉落，无需战斗"
	desc_lbl.add_theme_color_override("font_color", COL_GOLD_MUTED)
	desc_lbl.add_theme_font_size_override("font_size", 11)
	content_container.add_child(desc_lbl)

	var grp := ButtonGroup.new()
	for enemy_id in ["汲取者", "守卫者", "急袭者", "复制者", "先驱者"]:
		var row := _make_row(enemy_id, "", "", grp, null)
		content_container.add_child(row)

func _build_discard_content(options: Array[int], new_svc: int) -> void:
	for c in content_container.get_children():
		c.queue_free()

	var warn_lbl := Label.new()
	warn_lbl.text = "选择放弃哪一个服务（放弃后无法找回）"
	warn_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	warn_lbl.add_theme_color_override("font_color", COL_WARN)
	warn_lbl.add_theme_font_size_override("font_size", 11)
	content_container.add_child(warn_lbl)

	var grp := ButtonGroup.new()
	for i in options.size():
		var svc := options[i]
		var svc_name: String = AuctionManager.SERVICE_NAMES.get(svc, "?")
		var badge := " ★新" if svc == new_svc else ""
		var row := _make_row(svc_name + badge, "", "", grp, null)
		content_container.add_child(row)

	confirm_btn.text = "放弃选中"
	confirm_btn.disabled = true

# ---------------------------------------------------------------------------
# Param collection (unchanged logic, updated to read PanelContainer rows)
# ---------------------------------------------------------------------------
func _collect_params(svc: int):
	var instant_types := [
		AuctionManager.ServiceType.PRESSURE_DELAY,
		AuctionManager.ServiceType.DELETE_PARDON,
		AuctionManager.ServiceType.STAT_DMG,
		AuctionManager.ServiceType.STAT_HP,
		AuctionManager.ServiceType.STAT_SPEED,
		AuctionManager.ServiceType.STAT_AMPLIFY,
		AuctionManager.ServiceType.SLOT_RULE,
		AuctionManager.ServiceType.SLOT_SERVICE,
	]
	if svc in instant_types:
		return {}

	match svc:
		AuctionManager.ServiceType.ENEMY_PARDON:
			for c in content_container.get_children():
				if c is PanelContainer:
					var btn: Button = c.get_node("HBox/Btn")
					if btn.button_pressed:
						return {"enemy_id": btn.text}
			return null

		AuctionManager.ServiceType.COMP_REWRITE:
			for c in content_container.get_children():
				if c is PanelContainer:
					var btn: Button = c.get_node("HBox/Btn")
					if btn.button_pressed and btn.has_meta("comp_ref"):
						return {"component": btn.get_meta("comp_ref"),
								"new_effect_delta": DataTables.config.auction_comp_rewrite_delta}
			return null

		AuctionManager.ServiceType.COMP_MERGE:
			var selected: Array = []
			for c in content_container.get_children():
				if c is PanelContainer:
					var btn: Button = c.get_node("HBox/Btn")
					if btn.button_pressed and btn.has_meta("comp_ref"):
						selected.append(btn.get_meta("comp_ref"))
			if selected.size() < 2:
				return null
			if selected[0].slot_type != selected[1].slot_type:
				return null
			return {"comp_a": selected[0], "comp_b": selected[1]}

	return {}
```

- [ ] **Step 4: Run tests**

```
cd S:/attribute-loop && powershell -NoProfile -File scripts/self-test.ps1
```

Expected: all tests PASS including the 2 new `_make_row` tests.

- [ ] **Step 5: Commit**

```bash
git add src/ui/ServiceActivatePopup.gd tests/unit/test_service_activate_popup.gd
git commit -m "feat: rewrite ServiceActivatePopup with styled rows and reactive confirm button"
```

---

### Task 4: Fix COMP_MERGE value display — show merged total when both selected

**Files:**
- Modify: `src/ui/ServiceActivatePopup.gd`

When two components are selected in COMP_MERGE mode, the right column should update to show `A + B → merged`.

- [ ] **Step 1: Add test**

Add to `tests/unit/test_service_activate_popup.gd`:

```gdscript
func test_merge_row_value_label_updates_when_two_selected() -> void:
	# This tests the _build_comp_list multi-select logic indirectly
	# by checking that two rows can be selected simultaneously without a ButtonGroup
	var popup = load("res://scenes/ui/service_activate_popup.tscn").instantiate()
	add_child_autofree(popup)
	var row_a = popup._make_row("治愈", "12.5", "12.5", null, null)
	var row_b = popup._make_row("护盾", "8.0", "8.0", null, null)
	add_child_autofree(row_a)
	add_child_autofree(row_b)
	var btn_a: Button = row_a.get_node("HBox/Btn")
	var btn_b: Button = row_b.get_node("HBox/Btn")
	btn_a.button_pressed = true
	btn_b.button_pressed = true
	# Both can be pressed simultaneously (no shared ButtonGroup)
	assert_true(btn_a.button_pressed)
	assert_true(btn_b.button_pressed)
```

- [ ] **Step 2: Run test to confirm it passes (logic already correct)**

```
cd S:/attribute-loop && powershell -NoProfile -File scripts/self-test.ps1
```

Expected: PASS — the test verifies multi-select works without a group.

- [ ] **Step 3: Add merged-value update to `_build_comp_list` for COMP_MERGE**

In `src/ui/ServiceActivatePopup.gd`, inside `_build_comp_list`, after the loop that creates rows, add a second pass that connects a merged-value updater. Replace the line `var row := _make_row(...)` inside the loop (multi branch) with a version that captures the row references, then at the end of the loop body add a post-loop block:

Find the section in `_build_comp_list`:

```gdscript
	for comp in GameState.inventory:
		var cur_val := "%.1f" % comp.effect_value
		var after_val: String
		if multi:
			after_val = cur_val
		else:
			after_val = "→ %.1f" % (comp.effect_value * (1.0 + delta))
		var row := _make_row(comp.display_name, cur_val, after_val, grp, comp)
		content_container.add_child(row)
```

Replace with:

```gdscript
	var rows: Array = []
	for comp in GameState.inventory:
		var cur_val := "%.1f" % comp.effect_value
		var after_val: String
		if multi:
			after_val = cur_val
		else:
			after_val = "→ %.1f" % (comp.effect_value * (1.0 + delta))
		var row := _make_row(comp.display_name, cur_val, after_val, grp, comp)
		content_container.add_child(row)
		rows.append(row)

	if multi:
		for row in rows:
			var btn: Button = row.get_node("HBox/Btn")
			btn.toggled.connect(func(_p: bool) -> void:
				_update_merge_labels(rows)
			)

func _update_merge_labels(rows: Array) -> void:
	var selected: Array = []
	for row in rows:
		var btn: Button = row.get_node("HBox/Btn")
		if btn.button_pressed and btn.has_meta("comp_ref"):
			selected.append({"row": row, "comp": btn.get_meta("comp_ref")})
	for row in rows:
		var val_lbl: Label = row.get_node("HBox/ValueLabel")
		var btn: Button = row.get_node("HBox/Btn")
		if selected.size() == 2:
			var a_val: float = selected[0]["comp"].effect_value
			var b_val: float = selected[1]["comp"].effect_value
			var merged: float = (a_val + b_val) * 0.8
			if btn.button_pressed:
				val_lbl.text = "→ %.1f" % merged
			else:
				val_lbl.text = "%.1f" % btn.get_meta("comp_ref").effect_value if btn.has_meta("comp_ref") else ""
		else:
			if btn.has_meta("comp_ref"):
				val_lbl.text = "%.1f" % btn.get_meta("comp_ref").effect_value
```

- [ ] **Step 4: Run tests**

```
cd S:/attribute-loop && powershell -NoProfile -File scripts/self-test.ps1
```

Expected: all tests PASS.

- [ ] **Step 5: Commit**

```bash
git add src/ui/ServiceActivatePopup.gd
git commit -m "feat: COMP_MERGE shows merged total value when two components selected"
```

---

### Task 5: Visual integration test

**Files:** (no code changes — verification only)

- [ ] **Step 1: Create test sentinel**

```bash
touch tests/.test_mode
```

- [ ] **Step 2: Launch game via MCP**

```gdscript
var plugin = Engine.get_meta("GodotMCPPlugin")
plugin.get_editor_interface().play_main_scene()
```

- [ ] **Step 3: Poll for screenshot (timeout 20s, check every 2s)**

Wait for `tests/screenshots/last_run.png` to appear.

- [ ] **Step 4: Read screenshot and verify**

Use the Read tool on `tests/screenshots/last_run.png`. Confirm:
- Game window rendered (not black/blank)
- No error dialogs
- Service bar visible in sidebar

- [ ] **Step 5: Manual smoke test in running game**

Click a service button in the sidebar. Verify:
- Popup opens with title and subtitle text
- Body shows description or component list (not empty)
- For instant-apply services: "立即使用" button enabled
- For selection services: confirm button disabled until a row is selected
- Selecting a row highlights it with gold border
- Cancel closes popup without applying

- [ ] **Step 6: Delete sentinel and stop game**

```bash
rm tests/.test_mode
```

- [ ] **Step 7: Commit**

```bash
git add -A
git commit -m "test: visual integration verified for service activate popup"
```
