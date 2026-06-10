# Component Icons UI Integration Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Wire up the 14 generated component icon PNGs into StripPanel and InventoryPanel so icons appear next to component names.

**Architecture:** Add a `ComponentIcons` static utility that maps component ID strings → cached `Texture2D`. StripPanel adds a `TextureRect` at the top of each card. InventoryPanel sets `Button.icon` on inventory and rule-slot buttons. HUD is out of scope (requires scene file edits).

**Tech Stack:** Godot 4 GDScript, ResourceLoader, TextureRect, Button.icon property

---

## Files

| Action | Path | Responsibility |
|--------|------|---------------|
| Create | `src/ui/ComponentIcons.gd` | ID → Texture2D mapping + cache |
| Modify | `src/ui/StripPanel.gd` | Add TextureRect icon to card VBox |
| Modify | `src/ui/InventoryPanel.gd` | Set icon on inventory + rule-slot buttons |
| Create | `tests/test_component_icons.gd` | LOG test: mapping + cache |
| Create | `tests/test_component_icons.tscn` | Scene for headless run |

---

## Task 1: ComponentIcons utility + LOG test (RED)

**Files:**
- Create: `src/ui/ComponentIcons.gd`
- Create: `tests/test_component_icons.gd`
- Create: `tests/test_component_icons.tscn`

- [ ] **Step 1: Write the failing test**

Create `tests/test_component_icons.gd`:

```gdscript
extends Node

func _ready() -> void:
    _run_tests()
    get_tree().quit(0)

func _run_tests() -> void:
    const CI = preload("res://src/ui/ComponentIcons.gd")

    # Known ID returns a non-null texture
    var tex: Texture2D = CI.get_icon("受击")
    assert(tex != null, "Expected Texture2D for '受击', got null")

    # Unknown ID returns null
    var none: Texture2D = CI.get_icon("不存在")
    assert(none == null, "Expected null for unknown id, got %s" % none)

    # Cache returns the exact same object
    var tex2: Texture2D = CI.get_icon("受击")
    assert(tex == tex2, "Expected cached texture to be the same object")

    # All six implemented components have icons
    for id in ["受击", "击杀", "完成圈数", "经过", "治愈", "反射"]:
        assert(CI.get_icon(id) != null, "Missing icon for '%s'" % id)

    Log.info("PASS: test_component_icons", "TEST")
```

Create `tests/test_component_icons.tscn` as a Node scene with the script attached:

```
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://tests/test_component_icons.gd" id="1"]

[node name="TestComponentIcons" type="Node"]
script = ExtResource("1")
```

- [ ] **Step 2: Run test to confirm it fails**

```powershell
& "S:/Godot_v4.6.2-stable_mono_win64/Godot_v4.6.2-stable_mono_win64.exe" `
  --path "S:/attribute-loop" --headless --quit `
  --scene res://tests/test_component_icons.tscn
```

Expected: non-zero exit (preload fails — file doesn't exist yet).

---

## Task 2: Implement ComponentIcons (GREEN)

**Files:**
- Create: `src/ui/ComponentIcons.gd`

- [ ] **Step 3: Write ComponentIcons**

Create `src/ui/ComponentIcons.gd`:

```gdscript
class_name ComponentIcons
extends RefCounted

const _ICON_MAP: Dictionary = {
    "受击":   "res://resources/icons/trigger_hit.png",
    "击杀":   "res://resources/icons/trigger_kill.png",
    "完成圈数": "res://resources/icons/trigger_loop.png",
    "经过":   "res://resources/icons/trigger_pass.png",
    "治愈":   "res://resources/icons/effect_heal.png",
    "反射":   "res://resources/icons/effect_reflect.png",
}

static var _cache: Dictionary = {}

static func get_icon(id: String) -> Texture2D:
    if _cache.has(id):
        return _cache[id]
    if not _ICON_MAP.has(id):
        _cache[id] = null
        return null
    var tex: Texture2D = ResourceLoader.load(_ICON_MAP[id])
    _cache[id] = tex
    return tex
```

- [ ] **Step 4: Run test to confirm it passes**

```powershell
& "S:/Godot_v4.6.2-stable_mono_win64/Godot_v4.6.2-stable_mono_win64.exe" `
  --path "S:/attribute-loop" --headless --quit `
  --scene res://tests/test_component_icons.tscn
```

Expected: exit code 0, log line `PASS: test_component_icons`.

- [ ] **Step 5: Commit**

```bash
git add src/ui/ComponentIcons.gd tests/test_component_icons.gd tests/test_component_icons.tscn
git commit -m "feat: add ComponentIcons utility with ID→texture mapping"
```

---

## Task 3: StripPanel icons

**Files:**
- Modify: `src/ui/StripPanel.gd` — `_make_card()` function (lines 37–69)

- [ ] **Step 6: Add icon to `_make_card()`**

In `_make_card()`, after `var vbox := VBoxContainer.new()` and before adding `name_lbl`, insert the icon block:

```gdscript
func _make_card(comp: ComponentData) -> PanelContainer:
    var card := PanelContainer.new()
    var style := StyleBoxFlat.new()
    style.border_color = SLOT_TYPE_COLORS.get(comp.slot_type, Color.WHITE)
    style.border_width_left = 2
    style.border_width_right = 2
    style.border_width_top = 2
    style.border_width_bottom = 2
    card.add_theme_stylebox_override("panel", style)
    var vbox := VBoxContainer.new()
    card.add_child(vbox)
    var icon_tex := ComponentIcons.get_icon(comp.id)
    if icon_tex != null:
        var icon_rect := TextureRect.new()
        icon_rect.texture = icon_tex
        icon_rect.custom_minimum_size = Vector2i(48, 48)
        icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        vbox.add_child(icon_rect)
    var name_lbl := Label.new()
    name_lbl.text = comp.display_name
    vbox.add_child(name_lbl)
    var val_lbl := Label.new()
    if comp.slot_type == ComponentData.SlotType.TRIGGER_ONLY:
        val_lbl.text = "每 %.0f 次" % comp.trigger_value
    elif comp.slot_type == ComponentData.SlotType.EFFECT_ONLY:
        val_lbl.text = "值: %.1f" % comp.effect_value
    else:
        val_lbl.text = "T:%.0f E:%.1f" % [comp.trigger_value, comp.effect_value]
    vbox.add_child(val_lbl)
    var take_btn := Button.new()
    take_btn.text = "取走"
    take_btn.disabled = not GameState.inventory_has_space()
    take_btn.pressed.connect(func():
        GameState.add_to_inventory(comp)
        take_btn.disabled = true
        take_btn.text = "已取"
        _refresh_take_buttons()
    )
    vbox.add_child(take_btn)
    return card
```

- [ ] **Step 7: Run self-test suite to confirm no regressions**

```powershell
cd "S:/attribute-loop"; powershell -NoProfile -File scripts/self-test.ps1
```

Expected: all tests pass.

- [ ] **Step 8: Commit**

```bash
git add src/ui/StripPanel.gd
git commit -m "feat: show component icon in StripPanel cards"
```

---

## Task 4: InventoryPanel icons

**Files:**
- Modify: `src/ui/InventoryPanel.gd` — `_build_inventory_grid()` (lines 70–86) and `_build_rule_slots()` (lines 39–55)

- [ ] **Step 9: Add icon to inventory grid buttons**

Replace `_build_inventory_grid()`:

```gdscript
func _build_inventory_grid() -> void:
    for child in _inv_grid.get_children():
        child.queue_free()
    for comp in GameState.inventory:
        var btn := Button.new()
        var label = comp.display_name
        if comp.slot_type == ComponentData.SlotType.TRIGGER_ONLY:
            label += " (T:%.0f)" % comp.trigger_value
        elif comp.slot_type == ComponentData.SlotType.EFFECT_ONLY:
            label += " (E:%.1f)" % comp.effect_value
        else:
            label += " (T:%.0f/E:%.1f)" % [comp.trigger_value, comp.effect_value]
        btn.text = label
        btn.custom_minimum_size = Vector2i(120, 40)
        var icon_tex := ComponentIcons.get_icon(comp.id)
        if icon_tex != null:
            btn.icon = icon_tex
        var c = comp
        btn.pressed.connect(func(): _select(c))
        _inv_grid.add_child(btn)
```

- [ ] **Step 10: Add icon to rule slot buttons**

Replace `_build_rule_slots()`:

```gdscript
func _build_rule_slots() -> void:
    for child in _rule_slot_container.get_children():
        child.queue_free()
    for i in GameState.rule_slots.size():
        var slot = GameState.rule_slots[i]
        var hbox := HBoxContainer.new()
        _rule_slot_container.add_child(hbox)
        var t_comp: ComponentData = slot["trigger"]
        var t_btn := Button.new()
        t_btn.text = (t_comp.display_name + " [%d/%.0f]" % [t_comp.trigger_count, t_comp.trigger_value]) if t_comp else "[T 空]"
        if t_comp != null:
            var t_tex := ComponentIcons.get_icon(t_comp.id)
            if t_tex != null:
                t_btn.icon = t_tex
        t_btn.pressed.connect(_make_slot_handler(i, true, t_comp))
        hbox.add_child(t_btn)
        var e_comp: ComponentData = slot["effect"]
        var e_btn := Button.new()
        e_btn.text = (e_comp.display_name + " [%.1f]" % e_comp.effect_value) if e_comp else "[E 空]"
        if e_comp != null:
            var e_tex := ComponentIcons.get_icon(e_comp.id)
            if e_tex != null:
                e_btn.icon = e_tex
        e_btn.pressed.connect(_make_slot_handler(i, false, e_comp))
        hbox.add_child(e_btn)
```

- [ ] **Step 11: Run self-test suite**

```powershell
cd "S:/attribute-loop"; powershell -NoProfile -File scripts/self-test.ps1
```

Expected: all tests pass.

- [ ] **Step 12: Commit**

```bash
git add src/ui/InventoryPanel.gd
git commit -m "feat: show component icons in InventoryPanel buttons"
```

---

## Task 5: Visual integration test

- [ ] **Step 13: Run the game and verify icons appear**

Follow CLAUDE.md Step 3: create `tests/.test_mode`, play main scene via MCP, wait for screenshot, read `tests/screenshots/last_run.png`, verify icon textures visible in strip panel and inventory.

- [ ] **Step 14: Write module doc**

Create `docs/modules/component-icons.md` covering what ComponentIcons does, how to extend the mapping, and which UI panels consume it.
