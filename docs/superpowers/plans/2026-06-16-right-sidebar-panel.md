# Right Sidebar Panel Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the floating `RuleSlotsPanel` and top-anchored `ServiceBar` with a fixed 160px right sidebar panel that contains both, eliminating overlap with the game world.

**Architecture:** Add a new `RightSidebarPanel` scene (PanelContainer, 160px wide, anchored right) to `main.tscn`. Move `RuleSlotsPanel` and `ServiceBar` inside it as children. Reroute setup calls in `Main.gd` to reference the sidebar instead of the old float positions.

**Tech Stack:** Godot 4 GDScript, `.tscn` scene files, existing `RuleSlotsPanel` and `ServiceBar` scripts (unchanged logic).

---

## File Map

| File | Change |
|---|---|
| `scenes/ui/right_sidebar_panel.tscn` | **Create** — new container scene |
| `src/ui/RightSidebarPanel.gd` | **Create** — setup passthrough script |
| `scenes/main.tscn` | **Modify** — add sidebar, remove old ServiceBar top anchor |
| `scenes/ui/hud.tscn` | **Modify** — remove RuleSlotsPanel float node |
| `scenes/ui/service_bar.tscn` | **Modify** — change HBoxContainer → VBoxContainer |
| `src/ui/ServiceBar.gd` | **Modify** — button min size for vertical layout |
| `src/Main.gd` | **Modify** — wire sidebar setup |

---

### Task 1: Create `RightSidebarPanel` scene and script

**Files:**
- Create: `scenes/ui/right_sidebar_panel.tscn`
- Create: `src/ui/RightSidebarPanel.gd`

- [ ] **Step 1: Create the script**

Create `src/ui/RightSidebarPanel.gd`:

```gdscript
class_name RightSidebarPanel
extends PanelContainer

@onready var rule_slots_panel: RuleSlotsPanel = $VBox/RuleSlotsPanel
@onready var service_bar = $VBox/ServiceBar

func setup(auction_manager, service_activate_popup) -> void:
	service_bar.setup(auction_manager, service_activate_popup)
```

- [ ] **Step 2: Create the scene file**

Create `scenes/ui/right_sidebar_panel.tscn`:

```
[gd_scene format=3 uid="uid://right_sidebar_panel"]

[ext_resource type="Script" path="res://src/ui/RightSidebarPanel.gd" id="1_rsp"]
[ext_resource type="PackedScene" path="res://scenes/ui/rule_slots_panel.tscn" id="2_rsp"]
[ext_resource type="PackedScene" path="res://scenes/ui/service_bar.tscn" id="3_rsp"]

[sub_resource type="StyleBoxFlat" id="StyleBoxFlat_sidebar"]
content_margin_left = 8.0
content_margin_top = 8.0
content_margin_right = 8.0
content_margin_bottom = 8.0
bg_color = Color(0.071, 0.063, 0.055, 0.95)
border_width_left = 1
border_color = Color(0.588, 0.451, 0.196, 0.5)

[node name="RightSidebarPanel" type="PanelContainer"]
anchor_left = 1.0
anchor_right = 1.0
anchor_bottom = 1.0
offset_left = -160.0
offset_bottom = -48.0
grow_horizontal = 0
theme_override_styles/panel = SubResource("StyleBoxFlat_sidebar")
script = ExtResource("1_rsp")

[node name="VBox" type="VBoxContainer" parent="."]
layout_mode = 2
theme_override_constants/separation = 8

[node name="RuleSlotsPanel" parent="VBox" instance=ExtResource("2_rsp")]
layout_mode = 2

[node name="HSep" type="HSeparator" parent="VBox"]
layout_mode = 2
theme_override_colors/separator_color = Color(0.588, 0.451, 0.196, 0.3)

[node name="ServiceBar" parent="VBox" instance=ExtResource("3_rsp")]
layout_mode = 2
```

- [ ] **Step 3: Commit**

```bash
git add scenes/ui/right_sidebar_panel.tscn src/ui/RightSidebarPanel.gd
git commit -m "feat: add RightSidebarPanel scene and script"
```

---

### Task 2: Change `ServiceBar` to vertical layout

**Files:**
- Modify: `scenes/ui/service_bar.tscn`
- Modify: `src/ui/ServiceBar.gd`

- [ ] **Step 1: Update the scene root to VBoxContainer**

Replace the entire content of `scenes/ui/service_bar.tscn`:

```
[gd_scene format=3 uid="uid://cp4m8nb3r5yot"]

[ext_resource type="Script" uid="uid://cpalthb6l3pcc" path="res://src/ui/ServiceBar.gd" id="1_sb"]

[node name="ServiceBar" type="VBoxContainer"]
script = ExtResource("1_sb")
```

- [ ] **Step 2: Update button minimum size for vertical layout**

In `src/ui/ServiceBar.gd`, change the button `custom_minimum_size` from horizontal to vertical-friendly. Find this line in `_refresh()`:

```gdscript
btn.custom_minimum_size = Vector2(70, 28)
```

Change to:

```gdscript
btn.custom_minimum_size = Vector2(144, 28)
btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
```

- [ ] **Step 3: Run self-test to confirm no regressions**

```powershell
cd "S:/attribute-loop" && powershell -NoProfile -File scripts/self-test.ps1
```

Expected: all tests pass (ServiceBar has no unit tests — visual only).

- [ ] **Step 4: Commit**

```bash
git add scenes/ui/service_bar.tscn src/ui/ServiceBar.gd
git commit -m "feat: change ServiceBar to vertical layout for sidebar"
```

---

### Task 3: Remove `RuleSlotsPanel` from `hud.tscn`

**Files:**
- Modify: `scenes/ui/hud.tscn`

The `RuleSlotsPanel` is currently an instance node in `hud.tscn` with float anchors. It will now live inside `RightSidebarPanel`, so remove it from here.

- [ ] **Step 1: Open hud.tscn and delete the RuleSlotsPanel node**

In `scenes/ui/hud.tscn`, find and remove these lines (around line 311-319):

```
[ext_resource type="PackedScene" uid="uid://urf1lkq8h276" path="res://scenes/ui/rule_slots_panel.tscn" id="14_gonto"]
```

and:

```
[node name="RuleSlotsPanel" parent="." unique_id=1371514495 instance=ExtResource("14_gonto")]
anchors_preset = -1
anchor_left = 1.0
anchor_right = 1.0
anchor_bottom = 0.5
offset_left = -160.0
offset_top = 60.0
offset_right = -8.0
offset_bottom = -8.0
grow_horizontal = 0
grow_vertical = 2
```

Use the Godot MCP to delete the node, or edit the file directly. If editing directly, also remove the `ext_resource` line for `14_gonto`.

- [ ] **Step 2: Verify HUD.gd has no reference to RuleSlotsPanel**

```bash
grep -n "RuleSlotsPanel\|rule_slots_panel" src/ui/HUD.gd
```

Expected: no output. If any references exist, remove them.

- [ ] **Step 3: Run self-test**

```powershell
cd "S:/attribute-loop" && powershell -NoProfile -File scripts/self-test.ps1
```

Expected: all tests pass.

- [ ] **Step 4: Commit**

```bash
git add scenes/ui/hud.tscn
git commit -m "feat: remove floating RuleSlotsPanel from hud.tscn"
```

---

### Task 4: Add `RightSidebarPanel` to `main.tscn` and remove old `ServiceBar`

**Files:**
- Modify: `scenes/main.tscn`

- [ ] **Step 1: Add ext_resource for RightSidebarPanel**

In `scenes/main.tscn`, add a new ext_resource line after the existing ones (e.g. after the `18_sap` line):

```
[ext_resource type="PackedScene" path="res://scenes/ui/right_sidebar_panel.tscn" id="19_rsp"]
```

- [ ] **Step 2: Add the RightSidebarPanel node under UI**

After the `[node name="AuctionPanel" ...]` line, add:

```
[node name="RightSidebarPanel" parent="UI" unique_id=200000001 instance=ExtResource("19_rsp")]
```

- [ ] **Step 3: Remove the old ServiceBar node**

Find and delete these lines:

```
[node name="ServiceBar" parent="UI" unique_id=900275950 instance=ExtResource("17_sb")]
offset_top = 36.0
```

Also remove the ext_resource for the standalone ServiceBar if it's no longer referenced:

```
[ext_resource type="PackedScene" uid="uid://cp4m8nb3r5yot" path="res://scenes/ui/service_bar.tscn" id="17_sb"]
```

Note: `service_bar.tscn` is still referenced inside `right_sidebar_panel.tscn`, so the scene file stays — just remove the top-level reference in `main.tscn`.

- [ ] **Step 4: Commit**

```bash
git add scenes/main.tscn
git commit -m "feat: add RightSidebarPanel to main scene, remove old ServiceBar"
```

---

### Task 5: Wire up `RightSidebarPanel` in `Main.gd`

**Files:**
- Modify: `src/Main.gd`

- [ ] **Step 1: Add onready var for the sidebar**

In `src/Main.gd`, add this line alongside the other `@onready` declarations:

```gdscript
@onready var right_sidebar: RightSidebarPanel = $UI/RightSidebarPanel
```

- [ ] **Step 2: Replace service_bar setup with sidebar setup**

Find these two lines in `_ready()`:

```gdscript
service_bar.setup(auction_manager, service_activate_popup)
hud.setup_auction(auction_panel, service_bar)
```

Replace with:

```gdscript
right_sidebar.setup(auction_manager, service_activate_popup)
hud.setup_auction(auction_panel, null)
```

- [ ] **Step 3: Remove the old service_bar onready**

Delete this line:

```gdscript
@onready var service_bar = $UI/ServiceBar
```

- [ ] **Step 4: Run self-test**

```powershell
cd "S:/attribute-loop" && powershell -NoProfile -File scripts/self-test.ps1
```

Expected: all tests pass.

- [ ] **Step 5: Commit**

```bash
git add src/Main.gd
git commit -m "feat: wire RightSidebarPanel setup in Main.gd"
```

---

### Task 6: Visual integration test

- [ ] **Step 1: Play the main scene**

Use MCP execute_editor_script:
```gdscript
var plugin = Engine.get_meta("GodotMCPPlugin")
plugin.get_editor_interface().play_main_scene()
```

- [ ] **Step 2: Screenshot after 4 seconds**

```powershell
Start-Sleep -Seconds 4
Add-Type -AssemblyName System.Windows.Forms, System.Drawing
$screen = [System.Windows.Forms.Screen]::PrimaryScreen
$bmp = New-Object System.Drawing.Bitmap($screen.Bounds.Width, $screen.Bounds.Height)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.CopyFromScreen($screen.Bounds.Location, [System.Drawing.Point]::Empty, $screen.Bounds.Size)
$bmp.Save("S:\attribute-loop\tests\screenshots\sidebar_check.png")
$g.Dispose(); $bmp.Dispose()
```

- [ ] **Step 3: Read and verify screenshot**

Read `tests/screenshots/sidebar_check.png`. Verify:
- Right sidebar is visible with dark background
- Rule slots section shows at top of sidebar
- Service bar shows below separator
- No floating panels overlapping the game world
- Bottom HUD unchanged

- [ ] **Step 4: If anything looks wrong, fix and re-screenshot**

Common issues:
- Sidebar not visible → check anchor values in `right_sidebar_panel.tscn` (`anchor_left=1`, `offset_left=-160`)
- ServiceBar buttons too wide/narrow → adjust `custom_minimum_size` in `ServiceBar.gd`
- Gap at bottom → `offset_bottom = -48.0` matches BottomBar height (48px)

- [ ] **Step 5: Final commit**

```bash
git add -A
git commit -m "feat: right sidebar panel complete — rules + services no longer float over game"
```
