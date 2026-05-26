# Combat Log Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a right-side sliding combat log panel toggled by a "日志" button in the HUD, recording up to N configurable entries for player damage, rule fires, kills, gold gains, and phase changes.

**Architecture:** Self-contained LogPanel (PanelContainer) that connects to EventBus signals in `_ready()`, maintains a ring buffer of Label entries, and slides in/out from the right via Tween on `position.x`. HUD only wires the toggle button; all log logic lives in LogPanel.

**Tech Stack:** GDScript 4, Godot 4 scene system, GUT (unit tests).

---

## File Map

| File | Change |
|------|--------|
| `src/resources/GameConfig.gd` | Add `combat_log_max_entries: int = 50` |
| `data/game_config.tres` | Set `combat_log_max_entries = 50` |
| `src/ui/LogPanel.gd` | New — ring buffer + EventBus wiring + slide toggle |
| `scenes/ui/log_panel.tscn` | New — PanelContainer with VBox/Header/Scroll/Entries |
| `tests/unit/test_log_panel.gd` | New — 2 GUT tests for ring buffer and gold delta |
| `scenes/ui/hud.tscn` | Add LogPanel instance + LogButton node |
| `src/ui/HUD.gd` | Add log_panel / log_btn @onready + button wiring |

---

## Task 1: GameConfig — combat_log_max_entries

**Files:**
- Modify: `src/resources/GameConfig.gd`
- Modify: `data/game_config.tres`

- [ ] **Step 1: Add field to GameConfig.gd**

Append after `deletion_cost_multiplier`:

```gdscript
@export var combat_log_max_entries: int = 50
```

Full file:

```gdscript
class_name GameConfig
extends Resource

# stat = base × (1 + (phase - 1) × stat_scale_factor)
@export var stat_scale_factor: float = 0.3
@export var inventory_cap: int = 12
@export var rule_slot_count_base: int = 2
@export var rule_slot_count_max: int = 5
@export var low_hp_threshold: float = 0.3
@export var deletion_cost_sequence: Array[int] = [20, 50, 100]
@export var deletion_cost_multiplier: float = 2.0
@export var verdict_trigger_phase: int = 10
@export var verdict_survive_loops: int = 5
@export var verdict_enemy_phase: int = 10
@export var verdict_spawn_phase: int = 11
@export var combat_log_max_entries: int = 50
```

- [ ] **Step 2: Add value to game_config.tres**

Open `data/game_config.tres`. Under `[resource]`, add after the last line:

```
combat_log_max_entries = 50
```

- [ ] **Step 3: Run tests**

```powershell
cd "S:/attribute-loop" && powershell -NoProfile -File scripts/self-test.ps1
```

Expected: 140/140 passed.

- [ ] **Step 4: Commit**

```bash
git add src/resources/GameConfig.gd data/game_config.tres
git commit -m "feat: GameConfig combat_log_max_entries"
```

---

## Task 2: LogPanel — scene, script, tests

**Files:**
- Create: `scenes/ui/log_panel.tscn`
- Create: `src/ui/LogPanel.gd`
- Create: `tests/unit/test_log_panel.gd`

- [ ] **Step 1: Write the failing tests**

Create `tests/unit/test_log_panel.gd` using PowerShell with **tab** indentation:

```powershell
$tab = "`t"
$lf = "`n"
$lines = @(
    "extends GutTest",
    "",
    "func test_add_entry_trims_oldest_when_over_max() -> void:",
    "${tab}DataTables.config.combat_log_max_entries = 3",
    "${tab}var panel = preload(`"res://scenes/ui/log_panel.tscn`").instantiate()",
    "${tab}add_child_autofree(panel)",
    "${tab}await get_tree().process_frame",
    "${tab}panel._add_entry(`"a`", Color.WHITE)",
    "${tab}panel._add_entry(`"b`", Color.WHITE)",
    "${tab}panel._add_entry(`"c`", Color.WHITE)",
    "${tab}panel._add_entry(`"d`", Color.WHITE)",
    "${tab}var entries = panel.get_node(`"VBox/Scroll/Entries`")",
    "${tab}assert_eq(entries.get_child_count(), 3)",
    "${tab}assert_eq(entries.get_child(entries.get_child_count() - 1).text, `"d`")",
    "${tab}DataTables.config.combat_log_max_entries = 50",
    "",
    "func test_gold_entry_only_added_on_increase() -> void:",
    "${tab}var panel = preload(`"res://scenes/ui/log_panel.tscn`").instantiate()",
    "${tab}add_child_autofree(panel)",
    "${tab}await get_tree().process_frame",
    "${tab}panel._last_gold = 100",
    "${tab}panel._on_gold_changed(80)",
    "${tab}panel._on_gold_changed(120)",
    "${tab}var entries = panel.get_node(`"VBox/Scroll/Entries`")",
    "${tab}assert_eq(entries.get_child_count(), 1)",
    "${tab}assert_eq(entries.get_child(0).text, `"+40 金`")",
    ""
)
$content = $lines -join $lf
[System.IO.File]::WriteAllText("S:/attribute-loop/tests/unit/test_log_panel.gd", $content, [System.Text.UTF8Encoding]::new($false))
```

- [ ] **Step 2: Run tests to verify they fail**

```powershell
cd "S:/attribute-loop" && powershell -NoProfile -File scripts/self-test.ps1
```

Expected: 2 tests FAIL (scene file not found).

- [ ] **Step 3: Create log_panel.tscn**

```powershell
$lf = "`n"
$tscn = '[gd_scene load_steps=2 format=3 uid="uid://log_panel_001"]' + $lf +
$lf +
'[ext_resource type="Script" path="res://src/ui/LogPanel.gd" id="1_logpanel"]' + $lf +
$lf +
'[node name="LogPanel" type="PanelContainer"]' + $lf +
'anchor_left = 1.0' + $lf +
'anchor_right = 1.0' + $lf +
'anchor_top = 0.0' + $lf +
'anchor_bottom = 1.0' + $lf +
'offset_left = -280.0' + $lf +
'offset_right = 0.0' + $lf +
'script = ExtResource("1_logpanel")' + $lf +
$lf +
'[node name="VBox" type="VBoxContainer" parent="."]' + $lf +
'anchor_right = 1.0' + $lf +
'anchor_bottom = 1.0' + $lf +
'theme_override_constants/separation = 4' + $lf +
$lf +
'[node name="Header" type="HBoxContainer" parent="VBox"]' + $lf +
'layout_mode = 2' + $lf +
$lf +
'[node name="Title" type="Label" parent="VBox/Header"]' + $lf +
'layout_mode = 2' + $lf +
'size_flags_horizontal = 3' + $lf +
'text = "战斗日志"' + $lf +
$lf +
'[node name="CloseBtn" type="Button" parent="VBox/Header"]' + $lf +
'layout_mode = 2' + $lf +
'text = "×"' + $lf +
$lf +
'[node name="Divider" type="HSeparator" parent="VBox"]' + $lf +
'layout_mode = 2' + $lf +
$lf +
'[node name="Scroll" type="ScrollContainer" parent="VBox"]' + $lf +
'layout_mode = 2' + $lf +
'size_flags_vertical = 3' + $lf +
$lf +
'[node name="Entries" type="VBoxContainer" parent="VBox/Scroll"]' + $lf +
'layout_mode = 2' + $lf +
'size_flags_horizontal = 3' + $lf +
'theme_override_constants/separation = 2' + $lf
[System.IO.File]::WriteAllText("S:/attribute-loop/scenes/ui/log_panel.tscn", $tscn, [System.Text.UTF8Encoding]::new($false))
```

- [ ] **Step 4: Create LogPanel.gd**

```powershell
$tab = "`t"
$lf = "`n"
$lines = @(
    "class_name LogPanel",
    "extends PanelContainer",
    "",
    "var _is_open: bool = false",
    "var _last_gold: int = 0",
    "",
    "@onready var _entries: VBoxContainer = `$VBox/Scroll/Entries",
    "@onready var _scroll: ScrollContainer = `$VBox/Scroll",
    "@onready var _close_btn: Button = `$VBox/Header/CloseBtn",
    "",
    "func _ready() -> void:",
    "${tab}position.x = 280.0",
    "${tab}hide()",
    "${tab}_close_btn.pressed.connect(toggle)",
    "${tab}EventBus.player_hit.connect(_on_player_hit)",
    "${tab}EventBus.rule_fired.connect(_on_rule_fired)",
    "${tab}EventBus.enemy_killed.connect(_on_enemy_killed)",
    "${tab}EventBus.gold_changed.connect(_on_gold_changed)",
    "${tab}EventBus.phase_changed.connect(_on_phase_changed)",
    "${tab}EventBus.verdict_loop_entered.connect(_on_verdict_loop_entered)",
    "",
    "func toggle() -> void:",
    "${tab}if _is_open:",
    "${tab}${tab}_close()",
    "${tab}else:",
    "${tab}${tab}_open()",
    "",
    "func _open() -> void:",
    "${tab}_is_open = true",
    "${tab}show()",
    "${tab}var tw = create_tween()",
    "${tab}tw.tween_property(self, `"position:x`", 0.0, 0.15)",
    "",
    "func _close() -> void:",
    "${tab}_is_open = false",
    "${tab}var tw = create_tween()",
    "${tab}tw.tween_property(self, `"position:x`", 280.0, 0.15)",
    "${tab}await tw.finished",
    "${tab}hide()",
    "",
    "func _add_entry(text: String, color: Color) -> void:",
    "${tab}var label := Label.new()",
    "${tab}label.text = text",
    "${tab}label.add_theme_color_override(`"font_color`", color)",
    "${tab}label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART",
    "${tab}_entries.add_child(label)",
    "${tab}var max_entries: int = DataTables.config.combat_log_max_entries",
    "${tab}while _entries.get_child_count() > max_entries:",
    "${tab}${tab}var oldest = _entries.get_child(0)",
    "${tab}${tab}_entries.remove_child(oldest)",
    "${tab}${tab}oldest.queue_free()",
    "${tab}call_deferred(`"_scroll_to_bottom`")",
    "",
    "func _scroll_to_bottom() -> void:",
    "${tab}_scroll.scroll_vertical = 99999",
    "",
    "func _on_player_hit(damage: int) -> void:",
    "${tab}_add_entry(`"受击 −%d HP`" % damage, Color.RED)",
    "",
    "func _on_rule_fired(_slot_idx: int, effect_id: String, value: float) -> void:",
    "${tab}_add_entry(`"规则: %s +%.1f`" % [effect_id, value], Color.GREEN)",
    "",
    "func _on_enemy_killed(enemy: Enemy) -> void:",
    "${tab}_add_entry(`"击杀 %s`" % enemy.enemy_id, Color.YELLOW)",
    "",
    "func _on_gold_changed(new_amount: int) -> void:",
    "${tab}if new_amount > _last_gold:",
    "${tab}${tab}_add_entry(`"+%d 金`" % (new_amount - _last_gold), Color(1.0, 0.8, 0.0))",
    "${tab}_last_gold = new_amount",
    "",
    "func _on_phase_changed(n: int) -> void:",
    "${tab}_add_entry(`"→ Phase %d`" % n, Color.CYAN)",
    "",
    "func _on_verdict_loop_entered() -> void:",
    "${tab}_add_entry(`"进入裁决圈`", Color(0.7, 0.4, 1.0))",
    ""
)
$content = $lines -join $lf
[System.IO.File]::WriteAllText("S:/attribute-loop/src/ui/LogPanel.gd", $content, [System.Text.UTF8Encoding]::new($false))
```

- [ ] **Step 5: Run tests to verify they pass**

```powershell
cd "S:/attribute-loop" && powershell -NoProfile -File scripts/self-test.ps1
```

Expected: 142/142 passed.

- [ ] **Step 6: Commit**

```bash
git add src/ui/LogPanel.gd scenes/ui/log_panel.tscn tests/unit/test_log_panel.gd
git commit -m "feat: LogPanel — ring buffer, EventBus wiring, slide toggle"
```

---

## Task 3: HUD — wire LogButton + LogPanel

**Files:**
- Modify: `scenes/ui/hud.tscn`
- Modify: `src/ui/HUD.gd`

- [ ] **Step 1: Add LogPanel ext_resource to hud.tscn**

```powershell
$f = "S:/attribute-loop/scenes/ui/hud.tscn"
$c = [System.IO.File]::ReadAllText($f)
$old = '[ext_resource type="Script" uid="uid://tkq53wp5xvx5" path="res://src/ui/HUD.gd" id="1_hud"]'
$new = '[ext_resource type="Script" uid="uid://tkq53wp5xvx5" path="res://src/ui/HUD.gd" id="1_hud"]
[ext_resource type="PackedScene" uid="uid://log_panel_001" path="res://scenes/ui/log_panel.tscn" id="2_logpanel"]'
[System.IO.File]::WriteAllText($f, $c.Replace($old, $new), [System.Text.UTF8Encoding]::new($false))
```

- [ ] **Step 2: Add LogButton + LogPanel nodes to hud.tscn**

```powershell
$f = "S:/attribute-loop/scenes/ui/hud.tscn"
$c = [System.IO.File]::ReadAllText($f)
$old = '[node name="FloatLabel" type="Label" parent="." unique_id=249889570]'
$new = '[node name="LogButton" type="Button" parent="BottomBar/HContent" unique_id=999000001]
layout_mode = 2
text = "日志"

[node name="LogPanel" parent="." instance=ExtResource("2_logpanel")]

[node name="FloatLabel" type="Label" parent="." unique_id=249889570]'
[System.IO.File]::WriteAllText($f, $c.Replace($old, $new), [System.Text.UTF8Encoding]::new($false))
```

- [ ] **Step 3: Update HUD.gd**

Add @onready vars and button connection. Replace the two existing onready vars block + `_ready()` method with:

```powershell
$f = "S:/attribute-loop/src/ui/HUD.gd"
$c = [System.IO.File]::ReadAllText($f)
$old = '@onready var altar_btn: Button = $BottomBar/HContent/AltarButton'
$new = '@onready var altar_btn: Button = $BottomBar/HContent/AltarButton
@onready var log_btn: Button = $BottomBar/HContent/LogButton
@onready var log_panel: LogPanel = $LogPanel'
[System.IO.File]::WriteAllText($f, $c.Replace($old, $new), [System.Text.UTF8Encoding]::new($false))
```

Then add `log_btn.pressed.connect(log_panel.toggle)` in `_ready()`:

```powershell
$f = "S:/attribute-loop/src/ui/HUD.gd"
$c = [System.IO.File]::ReadAllText($f)
$old = "	bag_btn.pressed.connect(_on_bag_pressed)"
$new = "	bag_btn.pressed.connect(_on_bag_pressed)`n	log_btn.pressed.connect(log_panel.toggle)"
[System.IO.File]::WriteAllText($f, $c.Replace($old, $new), [System.Text.UTF8Encoding]::new($false))
```

- [ ] **Step 4: Run tests**

```powershell
cd "S:/attribute-loop" && powershell -NoProfile -File scripts/self-test.ps1
```

Expected: 142/142 passed.

- [ ] **Step 5: Commit**

```bash
git add scenes/ui/hud.tscn src/ui/HUD.gd
git commit -m "feat: HUD — 日志 button wired to LogPanel slide toggle"
```
