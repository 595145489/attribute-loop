# UI Asset Integration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace hardcoded StyleBoxFlat colors with parchment-style texture assets across HUD, StripPanel, and InventoryPanel.

**Architecture:** Create a central `ui_theme.tres` (Panel + Button styles only). Apply it to StripPanel and InventoryPanel via `self.theme`. For the HUD, apply textures programmatically in `_ready()` because hud.tscn has extensive per-node StyleBoxFlat overrides that would silently win over a theme. StripPanel card backgrounds are set in `_make_card()`. Note: `hp_bar_bg/fill` are deferred — there is no HP ProgressBar in the HUD yet (HP is shown as a Label).

**Tech Stack:** Godot 4, GDScript, MCP execute_editor_script, StyleBoxTexture

---

## File Map

| File | Action |
|------|--------|
| `resources/ui_theme.tres` | **Create** — Theme with Panel + Button texture styles |
| `src/ui/HUD.gd` | **Modify** — apply parchment overrides to all HUD pills, gold icon, phase badge |
| `src/ui/StripPanel.gd` | **Modify** — apply theme, use card_trigger/effect textures in _make_card() |
| `src/ui/InventoryPanel.gd` | **Modify** — apply theme in _ready() |
| `tests/screenshot_ui_skin.gd` | **Create** — screenshot test |
| `tests/screenshot_ui_skin.tscn` | **Create** — test scene |

---

## Task 1: Write screenshot test (RED baseline)

**Files:**
- Create: `tests/screenshot_ui_skin.gd`
- Create: `tests/screenshot_ui_skin.tscn`

- [ ] **Step 1: Create screenshot test script**

Write `tests/screenshot_ui_skin.gd`:

```gdscript
extends Node

const OUT_FILE := "res://tests/screenshots/current_ui_skin.png"

func _ready():
    DirAccess.make_dir_recursive_absolute(
        ProjectSettings.globalize_path("res://tests/screenshots"))
    add_child(preload("res://scenes/ui/hud.tscn").instantiate())
    await get_tree().process_frame
    await get_tree().process_frame
    var img := get_viewport().get_texture().get_image()
    img.save_png(ProjectSettings.globalize_path(OUT_FILE))
    Log.info("Screenshot saved: " + OUT_FILE, "TEST")
    get_tree().quit(0)
```

- [ ] **Step 2: Create test scene**

Write `tests/screenshot_ui_skin.tscn`:

```
[gd_scene format=3]
[ext_resource type="Script" path="res://tests/screenshot_ui_skin.gd" id="1"]
[node name="Root" type="Node"]
script = ExtResource("1")
```

- [ ] **Step 3: Run to capture baseline**

```powershell
& "S:/Godot_v4.6.2-stable_mono_win64/Godot_v4.6.2-stable_mono_win64.exe" --path "S:/attribute-loop" --scene res://tests/screenshot_ui_skin.tscn
```

- [ ] **Step 4: Read the screenshot and record baseline**

Read `tests/screenshots/current_ui_skin.png`. Confirm it shows the HUD bottom bar with **solid dark colors** (no parchment texture). This is the RED state.

Visual assertions to check GREEN later:
- [ ] BottomBar has parchment/paper texture (not solid dark color)
- [ ] AltarButton and LogButton show parchment button texture
- [ ] Gold section shows a coin icon to the left of the gold number
- [ ] Phase pill shows badge texture (visually distinct from other pills)

---

## Task 2: Create ui_theme.tres via editor script

**Files:**
- Create: `resources/ui_theme.tres`

- [ ] **Step 1: Run editor script to generate the theme**

Use MCP `execute_editor_script` with this GDScript:

```gdscript
var theme = Theme.new()

var panel_style = StyleBoxTexture.new()
panel_style.texture = load("res://resources/ui/panel_bg.png")
panel_style.content_margin_left = 8.0
panel_style.content_margin_top = 4.0
panel_style.content_margin_right = 8.0
panel_style.content_margin_bottom = 4.0
theme.set_stylebox("panel", "Panel", panel_style)
theme.set_stylebox("panel", "PanelContainer", panel_style)

var btn_normal = StyleBoxTexture.new()
btn_normal.texture = load("res://resources/ui/btn_normal.png")
btn_normal.content_margin_left = 10.0
btn_normal.content_margin_top = 4.0
btn_normal.content_margin_right = 10.0
btn_normal.content_margin_bottom = 4.0

var btn_hover = StyleBoxTexture.new()
btn_hover.texture = load("res://resources/ui/btn_hover.png")
btn_hover.content_margin_left = 10.0
btn_hover.content_margin_top = 4.0
btn_hover.content_margin_right = 10.0
btn_hover.content_margin_bottom = 4.0

var btn_pressed = StyleBoxTexture.new()
btn_pressed.texture = load("res://resources/ui/btn_pressed.png")
btn_pressed.content_margin_left = 10.0
btn_pressed.content_margin_top = 4.0
btn_pressed.content_margin_right = 10.0
btn_pressed.content_margin_bottom = 4.0

theme.set_stylebox("normal", "Button", btn_normal)
theme.set_stylebox("hover", "Button", btn_hover)
theme.set_stylebox("pressed", "Button", btn_pressed)
theme.set_stylebox("focus", "Button", btn_normal)
theme.set_stylebox("disabled", "Button", btn_normal)

ResourceSaver.save(theme, "res://resources/ui_theme.tres")
print("ui_theme.tres saved OK")
```

Expected output: `ui_theme.tres saved OK`

- [ ] **Step 2: Verify file exists**

```powershell
Test-Path "S:/attribute-loop/resources/ui_theme.tres"
```

Expected: `True`

- [ ] **Step 3: Commit**

```powershell
cd "S:/attribute-loop"
git add resources/ui_theme.tres
git commit -m "feat: create ui_theme.tres with parchment Panel and Button styles"
```

---

## Task 3: Apply parchment textures to HUD

**Files:**
- Modify: `src/ui/HUD.gd`

The HUD scene has per-node `StyleBoxFlat` overrides on every pill/button. Per-node overrides beat theme values, so the theme won't help here. Instead, apply textures programmatically in `_ready()` by calling `add_theme_stylebox_override()` on each node, which replaces the existing overrides at runtime.

- [ ] **Step 1: Update HUD.gd _ready()**

Replace the entire `_ready()` method in `src/ui/HUD.gd`:

```gdscript
func _ready() -> void:
    bag_btn.pressed.connect(_on_bag_pressed)
    log_btn.pressed.connect(log_panel.toggle)
    altar_btn.pressed.connect(_on_altar_pressed)
    float_label.hide()
    EventBus.rule_fired.connect(_on_rule_fired)
    _apply_ui_skin()

func _apply_ui_skin() -> void:
    var ui_theme = load("res://resources/ui_theme.tres")
    var panel_tex = load("res://resources/ui/panel_bg.png")
    var badge_tex = load("res://resources/ui/phase_badge_bg.png")
    var gold_icon_tex = load("res://resources/ui/gold_icon.png")

    if panel_tex:
        var s := StyleBoxTexture.new()
        s.texture = panel_tex
        s.content_margin_left = 8.0
        s.content_margin_top = 4.0
        s.content_margin_right = 8.0
        s.content_margin_bottom = 4.0
        for node in [
            $BottomBar,
            $BottomBar/HContent/HPPill,
            $BottomBar/HContent/LoopPill,
            $BottomBar/HContent/GoldPill,
            $BottomBar/HContent/PressurePill,
            $BottomBar/HContent/RulePanel0,
            $BottomBar/HContent/RulePanel1,
        ]:
            node.add_theme_stylebox_override("panel", s)

    if badge_tex:
        var bs := StyleBoxTexture.new()
        bs.texture = badge_tex
        bs.content_margin_left = 8.0
        bs.content_margin_top = 2.0
        bs.content_margin_right = 8.0
        bs.content_margin_bottom = 2.0
        $BottomBar/HContent/PhasePill.add_theme_stylebox_override("panel", bs)

    if ui_theme:
        $BottomBar.theme = ui_theme
        bag_btn.remove_theme_stylebox_override("normal")

    if gold_icon_tex:
        var gold_pill := $BottomBar/HContent/GoldPill
        var gold_lbl := gold_label
        gold_pill.remove_child(gold_lbl)
        var hbox := HBoxContainer.new()
        hbox.add_theme_constant_override("separation", 3)
        var icon_rect := TextureRect.new()
        icon_rect.texture = gold_icon_tex
        icon_rect.custom_minimum_size = Vector2(16, 16)
        icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        hbox.add_child(icon_rect)
        hbox.add_child(gold_lbl)
        gold_pill.add_child(hbox)
```

- [ ] **Step 2: Run headless tests to confirm no regressions**

```powershell
cd "S:/attribute-loop"; powershell -NoProfile -File scripts/self-test.ps1
```

Expected: all tests pass.

- [ ] **Step 3: Commit**

```powershell
cd "S:/attribute-loop"
git add src/ui/HUD.gd
git commit -m "feat: apply parchment skin to HUD panels and buttons"
```

---

## Task 4: Apply theme to StripPanel and InventoryPanel

**Files:**
- Modify: `src/ui/StripPanel.gd`
- Modify: `src/ui/InventoryPanel.gd`

StripPanel and InventoryPanel have no per-node style overrides, so assigning the theme on self is enough.

- [ ] **Step 1: Apply theme in StripPanel.gd**

In `src/ui/StripPanel.gd`, update `_ready()`:

```gdscript
func _ready() -> void:
    hide()
    _continue_btn.pressed.connect(_on_continue)
    _bag_btn.pressed.connect(_on_open_bag)
    var ui_theme = load("res://resources/ui_theme.tres")
    if ui_theme:
        theme = ui_theme
```

- [ ] **Step 2: Apply theme in InventoryPanel.gd**

In `src/ui/InventoryPanel.gd`, update `_ready()`:

```gdscript
func _ready() -> void:
    hide()
    _delete_btn.hide()
    _delete_btn.pressed.connect(_on_delete)
    _close_btn.pressed.connect(toggle)
    var ui_theme = load("res://resources/ui_theme.tres")
    if ui_theme:
        theme = ui_theme
```

- [ ] **Step 3: Run headless tests**

```powershell
cd "S:/attribute-loop"; powershell -NoProfile -File scripts/self-test.ps1
```

Expected: all tests pass.

- [ ] **Step 4: Commit**

```powershell
cd "S:/attribute-loop"
git add src/ui/StripPanel.gd src/ui/InventoryPanel.gd
git commit -m "feat: apply ui theme to StripPanel and InventoryPanel"
```

---

## Task 5: Update StripPanel card backgrounds

**Files:**
- Modify: `src/ui/StripPanel.gd` — `_make_card()` and remove `SLOT_TYPE_COLORS`

- [ ] **Step 1: Replace _make_card() and remove unused SLOT_TYPE_COLORS**

In `src/ui/StripPanel.gd`, remove the `SLOT_TYPE_COLORS` constant and replace the entire `_make_card()` method:

```gdscript
func _make_card(comp: ComponentData) -> PanelContainer:
    var card := PanelContainer.new()
    var bg_path := "res://resources/ui/card_effect_bg.png" \
        if comp.slot_type != ComponentData.SlotType.TRIGGER_ONLY \
        else "res://resources/ui/card_trigger_bg.png"
    var bg_tex = load(bg_path)
    if bg_tex:
        var style := StyleBoxTexture.new()
        style.texture = bg_tex
        style.content_margin_left = 6.0
        style.content_margin_top = 6.0
        style.content_margin_right = 6.0
        style.content_margin_bottom = 6.0
        card.add_theme_stylebox_override("panel", style)
    var vbox := VBoxContainer.new()
    card.add_child(vbox)
    var hbox := HBoxContainer.new()
    vbox.add_child(hbox)
    var icon_tex := ComponentIcons.get_icon(comp.id)
    if icon_tex != null:
        var icon_rect := TextureRect.new()
        icon_rect.texture = icon_tex
        icon_rect.custom_minimum_size = Vector2i(32, 32)
        icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        hbox.add_child(icon_rect)
    var info_lbl := Label.new()
    var val_str: String
    if comp.slot_type == ComponentData.SlotType.TRIGGER_ONLY:
        val_str = " (T:%.0f)" % comp.trigger_value
    elif comp.slot_type == ComponentData.SlotType.EFFECT_ONLY:
        val_str = " (E:%.1f)" % comp.effect_value
    else:
        val_str = " (T:%.0f/E:%.1f)" % [comp.trigger_value, comp.effect_value]
    info_lbl.text = comp.display_name + val_str
    hbox.add_child(info_lbl)
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

- [ ] **Step 2: Run headless tests**

```powershell
cd "S:/attribute-loop"; powershell -NoProfile -File scripts/self-test.ps1
```

Expected: all tests pass.

- [ ] **Step 3: Commit**

```powershell
cd "S:/attribute-loop"
git add src/ui/StripPanel.gd
git commit -m "feat: use card_trigger/effect bg textures in StripPanel cards"
```

---

## Task 6: Screenshot test (GREEN verification)

- [ ] **Step 1: Run the screenshot test**

```powershell
& "S:/Godot_v4.6.2-stable_mono_win64/Godot_v4.6.2-stable_mono_win64.exe" --path "S:/attribute-loop" --scene res://tests/screenshot_ui_skin.tscn
```

- [ ] **Step 2: Read screenshot and verify all assertions pass**

Read `tests/screenshots/current_ui_skin.png`:

- [ ] BottomBar has parchment/paper texture (not solid dark color)
- [ ] AltarButton and LogButton show parchment button texture
- [ ] Gold section shows a coin icon to the left of the gold number
- [ ] Phase pill shows badge texture (visually distinct from other pills)

Any FAIL → investigate and fix before continuing.

- [ ] **Step 3: Commit test files**

```powershell
cd "S:/attribute-loop"
git add tests/screenshot_ui_skin.gd tests/screenshot_ui_skin.tscn
git commit -m "test: add screenshot test for UI skin"
```
