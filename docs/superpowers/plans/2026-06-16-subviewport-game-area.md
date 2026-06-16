# SubViewport Game Area Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Constrain the game world (tiles, background, player, enemies) to the left 80% of the screen using a SubViewport, so the right 20% is a solid sidebar panel that never overlaps game content.

**Architecture:** Wrap the game world nodes inside a `SubViewport` (922×600px) hosted by a `SubViewportContainer` (left side). The existing `RightSidebarPanel` moves to a plain `Control` node (not CanvasLayer) on the right side. The `UI` CanvasLayer (HUD, panels, overlays) stays outside the SubViewport so it continues to cover the full screen. A new root scene `AppShell` (or restructured `main.tscn`) holds: `[SubViewportContainer + SubViewport + Main] | [RightSidebarPanel]` side by side, with `UI` CanvasLayer on top.

**Tech Stack:** Godot 4 GDScript, SubViewport, SubViewportContainer, HBoxContainer layout.

---

## Dimensions

| Area | Width | Height |
|---|---|---|
| Full window | 1152 | 648 |
| Game SubViewport | 922 | 600 |
| Right sidebar | 230 | 600 |
| Bottom HUD | 1152 | 48 |

The bottom HUD (`BottomBar` in `hud.tscn`) covers the full 1152px width — it sits in the `UI` CanvasLayer above everything.

---

## Architecture Diagram

```
AppShell (Node — new root of main.tscn)
├── GameRow (HBoxContainer, anchors full screen minus bottom 48px)
│   ├── SubViewportContainer (922px wide, expand_fill vertical)
│   │   └── GameViewport (SubViewport, 922×600, own_world_3d=false, physics_object_picking=true)
│   │       └── Main (Node2D — existing game logic, unchanged node paths internally)
│   │           ├── Background
│   │           ├── TrackLine
│   │           ├── Track / PlayerFollow / Player
│   │           ├── TilesContainer
│   │           ├── EnemiesContainer
│   │           └── Systems / ...
│   └── RightSidebarPanel (230px wide, expand_fill vertical) ← moved OUT of CanvasLayer
└── UI (CanvasLayer — full screen overlay)
    ├── HUD (covers full 1152px bottom bar)
    ├── StripPanel, InventoryPanel, TileRulePanel, AltarPanel
    ├── AuctionPanel, ServiceActivatePopup
    └── TutorialOverlay (CanvasLayer layer=20)
```

---

## Key Design Decisions

1. **`Main.gd` node paths don't change.** `$Track`, `$TilesContainer`, `$EnemiesContainer`, `$Systems/*` are all still children of Main — Main just lives inside the SubViewport. No script changes inside Main are needed for node path resolution.

2. **`get_viewport()` inside Main and its children returns the SubViewport.** This means `get_viewport().physics_object_picking = true` sets it on the correct viewport. Tile click detection works via the SubViewport's input.

3. **`TutorialOverlay` uses `get_viewport().get_visible_rect().size`.** Since TutorialOverlay is in the `UI` CanvasLayer (outside SubViewport), its `get_viewport()` returns the root viewport (1152×648). Its dark overlay panels cover the full screen — this is correct behavior.

4. **`Tooltip.gd` uses `get_viewport().get_mouse_position()`.** Tooltip panel lives in UI CanvasLayer → root viewport → mouse position is in 1152×648 space. Correct.

5. **`RightSidebarPanel` moves from `UI` CanvasLayer to `GameRow` HBoxContainer.** It becomes a regular Control node sized 230px wide. Its internal scripts (`ServiceBar.gd`, `RuleSlotsPanel.gd`) have no viewport dependencies.

6. **`Main.gd` `$UI` references must update.** `Main.gd` currently has `@onready var hud = $UI/HUD` etc. These paths break because `UI` is no longer a child of `Main`. Instead, `Main.gd` will receive these as `setup()` parameters from the new shell script.

7. **Input events to tiles.** `SubViewportContainer` with `stretch=true` forwards input to the SubViewport automatically. Tile click detection via `_input` in `Tile.gd` works correctly.

8. **`service_activate_popup.setup(auction_manager, _tiles)` passes tiles.** Tiles are Node2D objects inside the SubViewport. The popup uses their positions only indirectly (passed by reference). No coordinate transform issues.

---

## File Map

| File | Change |
|---|---|
| `scenes/main.tscn` | **Major restructure** — add AppShell root, GameRow HBoxContainer, SubViewportContainer, GameViewport SubViewport; move Main node inside; move UI CanvasLayer outside SubViewport |
| `src/Main.gd` | **Modify** — remove `$UI/*` onready vars; add `setup_ui()` method to receive UI node refs from shell |
| `scenes/ui/right_sidebar_panel.tscn` | **Modify** — remove CanvasLayer-style anchors (`anchor_left=1` etc.); use `size_flags_horizontal = SIZE_EXPAND_FILL` to fill 230px column |
| `src/ui/RightSidebarPanel.gd` | **No change** — logic unchanged |

---

### Task 1: Restructure `main.tscn` — add SubViewport wrapper

**Files:**
- Modify: `scenes/main.tscn`

This is the core structural change. We rewrite `main.tscn` to wrap game world nodes in a SubViewport.

- [ ] **Step 1: Read current main.tscn to get all node UIDs**

```bash
cat S:/attribute-loop/scenes/main.tscn
```

Note all unique_ids and ext_resource ids — you will reuse them exactly.

- [ ] **Step 2: Rewrite main.tscn with new structure**

Replace the entire content of `S:/attribute-loop/scenes/main.tscn` with the following. Preserve all existing ext_resource declarations and unique_ids exactly. The only structural change is: add `AppShell`, `GameRow`, `SubViewportContainer`, `GameViewport` above `Main`, and move `RightSidebarPanel` from `UI` into `GameRow`.

**New structure** (replace the node declarations section, keep all ext_resource and sub_resource lines identical):

```
[node name="AppShell" type="Node"]

[node name="GameRow" type="HBoxContainer" parent="."]
anchor_right = 1.0
anchor_bottom = 1.0
offset_bottom = -48.0
grow_horizontal = 2
grow_vertical = 2

[node name="SubViewportContainer" type="SubViewportContainer" parent="GameRow"]
layout_mode = 2
size_flags_horizontal = 3
size_flags_vertical = 3
size_flags_stretch_ratio = 4.0
stretch = true

[node name="GameViewport" type="SubViewport" parent="GameRow/SubViewportContainer"]
own_world_2d = false
size = Vector2i(922, 600)
render_target_update_mode = 3

[node name="Main" type="Node2D" parent="GameRow/SubViewportContainer/GameViewport" unique_id=1791836967]
script = ExtResource("1_main")

[node name="Background" type="Sprite2D" parent="GameRow/SubViewportContainer/GameViewport/Main" unique_id=1100000001]
position = Vector2(585.99994, 320)
scale = Vector2(1.140625, 0.844)
texture = ExtResource("14_bg")

[node name="TrackLine" type="Line2D" parent="GameRow/SubViewportContainer/GameViewport/Main" unique_id=1620710]
points = PackedVector2Array(576, 70, 1066, 70, 1066, 530, 86, 530, 86, 70, 576, 70)
width = 64.0
texture = SubResource("GradientTexture2D_track")
texture_mode = 1
joint_mode = 2

[node name="Track" type="Path2D" parent="GameRow/SubViewportContainer/GameViewport/Main" unique_id=1999103066]
curve = SubResource("Curve2D_track")

[node name="PlayerFollow" type="PathFollow2D" parent="GameRow/SubViewportContainer/GameViewport/Main/Track" unique_id=1624764954]
position = Vector2(576, 70)
rotates = false

[node name="Player" parent="GameRow/SubViewportContainer/GameViewport/Main/Track/PlayerFollow" unique_id=714067380 instance=ExtResource("6_player")]

[node name="TilesContainer" type="Node2D" parent="GameRow/SubViewportContainer/GameViewport/Main" unique_id=1696837434]

[node name="EnemiesContainer" type="Node2D" parent="GameRow/SubViewportContainer/GameViewport/Main" unique_id=1702795812]

[node name="Systems" type="Node" parent="GameRow/SubViewportContainer/GameViewport/Main" unique_id=53247820]

[node name="CombatSystem" type="Node" parent="GameRow/SubViewportContainer/GameViewport/Main/Systems" unique_id=673235025]
script = ExtResource("2_combat")

[node name="GameLoop" type="Node" parent="GameRow/SubViewportContainer/GameViewport/Main/Systems" unique_id=1869171208]
script = ExtResource("3_gameloop")

[node name="RuleEngine" type="Node" parent="GameRow/SubViewportContainer/GameViewport/Main/Systems" unique_id=688364042]
script = ExtResource("4_re")

[node name="StripManager" type="Node" parent="GameRow/SubViewportContainer/GameViewport/Main/Systems" unique_id=999074985]
script = ExtResource("5_sm")

[node name="EconomyManager" type="Node" parent="GameRow/SubViewportContainer/GameViewport/Main/Systems" unique_id=1456410390]
script = ExtResource("7_choun")

[node name="AuctionManager" type="Node" parent="GameRow/SubViewportContainer/GameViewport/Main/Systems" unique_id=1996440489]
script = ExtResource("15_am")

[node name="RightSidebarPanel" parent="GameRow" unique_id=200000001 instance=ExtResource("19_rsp")]
layout_mode = 2
size_flags_horizontal = 0
custom_minimum_size = Vector2(230, 0)
size_flags_vertical = 3

[node name="UI" type="CanvasLayer" parent="."]

[node name="HUD" parent="UI" unique_id=1040373391 instance=ExtResource("7_hud")]

[node name="StripPanel" parent="UI" unique_id=285933306 instance=ExtResource("8_strip")]

[node name="InventoryPanel" parent="UI" unique_id=388834648 instance=ExtResource("9_inv")]

[node name="TileRulePanel" parent="UI" unique_id=1901766401 instance=ExtResource("11_trceg")]
visible = false
custom_minimum_size = Vector2(400, 300)
offset_top = -209.0

[node name="AltarPanel" parent="UI" unique_id=524408031 instance=ExtResource("13_jkv2x")]
custom_minimum_size = Vector2(450, 350)

[node name="AuctionPanel" parent="UI" unique_id=833979863 instance=ExtResource("16_ap")]

[node name="ServiceActivatePopup" parent="UI" unique_id=547909871 instance=ExtResource("18_sap")]
grow_horizontal = 2
grow_vertical = 2

[node name="TutorialOverlay" type="CanvasLayer" parent="." unique_id=549234134 instance=ExtResource("18_0ld40")]
layer = 20
visible = false
script = ExtResource("19_gqmmt")
```

**IMPORTANT:** Keep the file header (format, uid, ext_resource lines, sub_resource lines) exactly as they are. Only replace the `[node ...]` section.

- [ ] **Step 3: Verify file is syntactically valid**

```bash
grep -c "^\[node" S:/attribute-loop/scenes/main.tscn
```

Expected: at least 25 node blocks.

- [ ] **Step 4: Commit**

```bash
git add S:/attribute-loop/scenes/main.tscn
git commit -m "feat: wrap game world in SubViewport, add GameRow HBoxContainer layout"
```

---

### Task 2: Update `Main.gd` — remove `$UI/*` onready vars, add `setup_ui()` method

**Files:**
- Modify: `src/Main.gd`

`Main` now lives inside the SubViewport. It can no longer use `$UI/HUD` etc. because `UI` is a sibling of `SubViewportContainer`, not a child of `Main`. We give `Main` a `setup_ui()` method that receives all UI node references from outside.

- [ ] **Step 1: Rewrite src/Main.gd**

Replace the entire content of `S:/attribute-loop/src/Main.gd`:

```gdscript
extends Node2D

const TILE_SCENE = preload("res://scenes/entities/tile.tscn")
const GAME_OVER_SCENE = preload("res://scenes/ui/game_over.tscn")
const GAME_WIN_SCENE = preload("res://scenes/ui/game_win.tscn")
const PHASE_TRANSITION_SCENE = preload("res://scenes/ui/phase_transition.tscn")
const ENEMY_INSPECT_SCENE = preload("res://scenes/ui/enemy_inspect_panel.tscn")

@onready var track: Path2D = $Track
@onready var player_follow: PathFollow2D = $Track/PlayerFollow
@onready var player: Player = $Track/PlayerFollow/Player
@onready var tiles_container: Node2D = $TilesContainer
@onready var enemies_container: Node2D = $EnemiesContainer
@onready var combat_system: CombatSystem = $Systems/CombatSystem
@onready var game_loop: GameLoop = $Systems/GameLoop
@onready var strip_manager: StripManager = $Systems/StripManager
@onready var rule_engine: RuleEngine = $Systems/RuleEngine
@onready var auction_manager = $Systems/AuctionManager

var _strip_panel = null
var _inventory_panel = null
var _tile_rule_panel = null
var _altar_panel = null
var _hud: HUD = null
var _auction_panel = null
var _right_sidebar: RightSidebarPanel = null
var _service_activate_popup = null
var _ui_node: Node = null

var _initialized: bool = false
var _phase_transition = null
var _enemy_inspect = null
var _tiles: Array = []

func setup_ui(ui_refs: Dictionary) -> void:
	_strip_panel = ui_refs.strip_panel
	_inventory_panel = ui_refs.inventory_panel
	_tile_rule_panel = ui_refs.tile_rule_panel
	_altar_panel = ui_refs.altar_panel
	_hud = ui_refs.hud
	_auction_panel = ui_refs.auction_panel
	_right_sidebar = ui_refs.right_sidebar
	_service_activate_popup = ui_refs.service_activate_popup
	_ui_node = ui_refs.ui_node
	_finish_setup()

func _finish_setup() -> void:
	get_viewport().physics_object_picking = true
	_tiles = _build_tiles()
	player.setup(player_follow, track)
	game_loop.setup(_tiles, enemies_container, player, combat_system)
	strip_manager.setup(_strip_panel)
	_strip_panel.setup(_inventory_panel)
	_hud.setup(_inventory_panel)
	_hud.setup_altar(_altar_panel, _tiles[0])
	rule_engine.set_tiles(_tiles)
	game_loop.setup_auction(auction_manager)
	_auction_panel.setup(auction_manager)
	_service_activate_popup.setup(auction_manager, _tiles)
	_right_sidebar.setup(auction_manager, _service_activate_popup)
	_hud.setup_auction(_auction_panel)
	EventBus.player_died.connect(_on_player_died)
	EventBus.phase_changed.connect(_on_phase_changed)
	EventBus.game_won.connect(_on_game_won)
	EventBus.tutorial_spawn_enemies.connect(_spawn_tutorial_enemies)
	EventBus.tutorial_setup_altar.connect(_setup_tutorial_altar)
	EventBus.tutorial_setup_auction.connect(_setup_tutorial_auction)
	EventBus.tutorial_setup_altar_gift.connect(_setup_tutorial_altar_gift)
	_initialized = true
	_phase_transition = PHASE_TRANSITION_SCENE.instantiate()
	_ui_node.add_child(_phase_transition)
	if not GameState.is_tutorial:
		_phase_transition.show_for_phase(1)
	_enemy_inspect = ENEMY_INSPECT_SCENE.instantiate()
	_ui_node.add_child(_enemy_inspect)
	if GameState.is_tutorial:
		var overlay = _ui_node.get_parent().get_node("TutorialOverlay")
		TutorialManager.start(overlay)

func _process(_delta: float) -> void:
	if not _initialized or GameState.is_paused:
		return
	_check_player_tile()

func _check_player_tile() -> void:
	var player_pos = player.global_position
	for tile in tiles_container.get_children():
		if tile.has_enemy() and player_pos.distance_to(tile.guard_position) < 70.0:
			game_loop.check_tile_for_enemy(tile)
			return
		if not tile.has_enemy() and player_pos.distance_to(tile.global_position) < 55.0:
			if not tile.visited_this_loop:
				tile.visited_this_loop = true
				tile.pass_count += 1
				EventBus.tile_passed.emit(tile.tile_index)
			return

func _on_tile_clicked(tile: Tile) -> void:
	if tile.is_altar:
		_altar_panel.open(tile)
	elif tile.has_enemy():
		_enemy_inspect.open(tile.enemy)
	else:
		_tile_rule_panel.open(tile)

func reset_tiles() -> void:
	for tile in tiles_container.get_children():
		tile.pass_count = 0
		tile.visited_this_loop = false
		tile.rule_slots.clear()
		if not tile.is_altar:
			var max_rules := DataTables.TILE_MAX_RULES[tile.tile_index] if tile.tile_index < DataTables.TILE_MAX_RULES.size() else 1
			for i in max_rules:
				tile.rule_slots.append({"trigger": null, "effect": null})
		else:
			tile.altar_slots.fill(null)

func _on_player_died() -> void:
	_ui_node.add_child(GAME_OVER_SCENE.instantiate())

func _on_game_won() -> void:
	_ui_node.add_child(GAME_WIN_SCENE.instantiate())

func _on_phase_changed(new_phase: int) -> void:
	_phase_transition.show_for_phase(new_phase)
	for tile in tiles_container.get_children():
		if tile.is_altar:
			tile.resize_altar_for_phase(new_phase)

const TILE_POSITIONS: Array[Vector2] = [
	Vector2(576, 115),
	Vector2(739, 115),
	Vector2(903, 115),
	Vector2(1021, 223),
	Vector2(1021, 377),
	Vector2(870, 485),
	Vector2(674, 485),
	Vector2(478, 485),
	Vector2(282, 485),
	Vector2(131, 377),
	Vector2(131, 223),
	Vector2(249, 115),
	Vector2(413, 115),
]

const GUARD_POSITIONS: Array[Vector2] = [
	Vector2(576,  70),
	Vector2(674,  70),
	Vector2(838,  70),
	Vector2(1066, 158),
	Vector2(1066, 312),
	Vector2(935,  530),
	Vector2(739,  530),
	Vector2(543,  530),
	Vector2(347,  530),
	Vector2(86,   442),
	Vector2(86,   288),
	Vector2(184,  70),
	Vector2(348,  70),
]

func _build_tiles() -> Array:
	var tiles: Array = []
	for i in TILE_POSITIONS.size():
		var tile: Tile = TILE_SCENE.instantiate()
		tile.tile_index = i
		tile.name = "tile_%d" % i
		tile.is_altar = (i == 0)
		tile.position = TILE_POSITIONS[i]
		tile.guard_position = GUARD_POSITIONS[i]
		tile.clicked.connect(_on_tile_clicked)
		tiles_container.add_child(tile)
		tiles.append(tile)
	return tiles

func _spawn_tutorial_enemies() -> void:
	for child in enemies_container.get_children():
		child.queue_free()
	for tile in _tiles:
		tile.clear_enemy()
	var enemy_scene: PackedScene = load("res://scenes/entities/enemy.tscn")
	var preset: DropPreset = DataTables.get_drop_preset(1)
	for idx in [3]:
		if idx >= _tiles.size():
			continue
		var enemy: Enemy = enemy_scene.instantiate()
		enemies_container.add_child(enemy)
		enemy.init("汲取者", 1)
		enemy.components.append(GameLoop._create_component("经过", preset))
		enemy.components.append(GameLoop._create_component("治愈", preset))
		enemy.components.append(GameLoop._create_component("经过", preset))
		enemy.components.append(GameLoop._create_component("治愈", preset))
		enemy.position = _tiles[idx].guard_position
		_tiles[idx].place_enemy(enemy)

func _setup_tutorial_altar() -> void:
	var altar: Tile = _tiles[0]
	altar.altar_slots.resize(1)
	altar.altar_slots[0] = null

func _setup_tutorial_altar_gift() -> void:
	var preset: DropPreset = DataTables.get_drop_preset(1)
	for i in 2:
		GameState.add_to_inventory(GameLoop._create_component("治愈", preset))

func _setup_tutorial_auction() -> void:
	auction_manager.phantom_a.gold = 45
	auction_manager.phantom_b.gold = 45
```

- [ ] **Step 2: Run self-test**

```powershell
cd "S:/attribute-loop"; powershell -NoProfile -File scripts/self-test.ps1
```

Expected: same 16 pre-existing failures, zero new failures.

- [ ] **Step 3: Commit**

```bash
git add S:/attribute-loop/src/Main.gd
git commit -m "feat: Main.gd receives UI refs via setup_ui() — decoupled from scene tree path"
```

---

### Task 3: Create `AppShell.gd` — new root script that wires everything together

**Files:**
- Create: `src/AppShell.gd`

`AppShell` is the new root node script. It holds references to all UI nodes (which are its children) and passes them into `Main` after `Main` is ready inside the SubViewport.

- [ ] **Step 1: Create src/AppShell.gd**

```gdscript
extends Node

@onready var _main: Node2D = $GameRow/SubViewportContainer/GameViewport/Main
@onready var _hud: HUD = $UI/HUD
@onready var _strip_panel: StripPanel = $UI/StripPanel
@onready var _inventory_panel: InventoryPanel = $UI/InventoryPanel
@onready var _tile_rule_panel = $UI/TileRulePanel
@onready var _altar_panel = $UI/AltarPanel
@onready var _auction_panel = $UI/AuctionPanel
@onready var _right_sidebar: RightSidebarPanel = $GameRow/RightSidebarPanel
@onready var _service_activate_popup = $UI/ServiceActivatePopup
@onready var _ui: Node = $UI

func _ready() -> void:
	_main.setup_ui({
		"strip_panel": _strip_panel,
		"inventory_panel": _inventory_panel,
		"tile_rule_panel": _tile_rule_panel,
		"altar_panel": _altar_panel,
		"hud": _hud,
		"auction_panel": _auction_panel,
		"right_sidebar": _right_sidebar,
		"service_activate_popup": _service_activate_popup,
		"ui_node": _ui,
	})
```

- [ ] **Step 2: Attach AppShell.gd to AppShell root node in main.tscn**

In `scenes/main.tscn`, find the `[node name="AppShell" type="Node"]` line and add the script reference. First add the ext_resource:

```
[ext_resource type="Script" path="res://src/AppShell.gd" id="20_shell"]
```

Then update the node line to:

```
[node name="AppShell" type="Node"]
script = ExtResource("20_shell")
```

- [ ] **Step 3: Also remove the `script` line from `Main` node in main.tscn**

The `Main` node still uses `src/Main.gd` — that's correct and unchanged. The `AppShell` node gets `AppShell.gd`. Verify the `Main` node line still reads:

```
[node name="Main" type="Node2D" parent="GameRow/SubViewportContainer/GameViewport" unique_id=1791836967]
script = ExtResource("1_main")
```

- [ ] **Step 4: Run self-test**

```powershell
cd "S:/attribute-loop"; powershell -NoProfile -File scripts/self-test.ps1
```

Expected: same 16 pre-existing failures, zero new failures.

- [ ] **Step 5: Commit**

```bash
git add S:/attribute-loop/src/AppShell.gd S:/attribute-loop/scenes/main.tscn
git commit -m "feat: add AppShell root script that wires UI refs into Main via setup_ui()"
```

---

### Task 4: Fix `RightSidebarPanel` anchors for HBoxContainer layout

**Files:**
- Modify: `scenes/ui/right_sidebar_panel.tscn`

The sidebar currently uses CanvasLayer-style anchors (`anchor_left=1.0` etc.) to float at the right edge. Inside an HBoxContainer, anchors don't work — size is controlled by `size_flags` and `custom_minimum_size`.

- [ ] **Step 1: Read current right_sidebar_panel.tscn**

```bash
cat S:/attribute-loop/scenes/ui/right_sidebar_panel.tscn
```

- [ ] **Step 2: Replace the root node properties**

Find the `[node name="RightSidebarPanel" type="PanelContainer"]` block and replace its properties:

**Current:**
```
[node name="RightSidebarPanel" type="PanelContainer"]
anchor_left = 1.0
anchor_right = 1.0
anchor_bottom = 1.0
offset_left = -160.0
offset_bottom = -48.0
grow_horizontal = 0
theme_override_styles/panel = SubResource("StyleBoxFlat_sidebar")
script = ExtResource("1_rsp")
```

**Replace with:**
```
[node name="RightSidebarPanel" type="PanelContainer"]
layout_mode = 2
size_flags_horizontal = 0
size_flags_vertical = 3
custom_minimum_size = Vector2(230, 0)
theme_override_styles/panel = SubResource("StyleBoxFlat_sidebar")
script = ExtResource("1_rsp")
```

- [ ] **Step 3: Run self-test**

```powershell
cd "S:/attribute-loop"; powershell -NoProfile -File scripts/self-test.ps1
```

Expected: same 16 pre-existing failures, zero new failures.

- [ ] **Step 4: Commit**

```bash
git add S:/attribute-loop/scenes/ui/right_sidebar_panel.tscn
git commit -m "feat: RightSidebarPanel uses HBoxContainer size_flags instead of float anchors"
```

---

### Task 5: Visual integration test

- [ ] **Step 1: Open main.tscn and play current scene**

Use MCP execute_editor_script:
```gdscript
var plugin = Engine.get_meta("GodotMCPPlugin")
plugin.get_editor_interface().open_scene_from_path("res://scenes/main.tscn")
```

Then:
```gdscript
var plugin = Engine.get_meta("GodotMCPPlugin")
plugin.get_editor_interface().play_current_scene()
```

- [ ] **Step 2: Screenshot the game window**

Wait 5 seconds, then use PowerShell to find and screenshot the game window:

```powershell
Start-Sleep -Seconds 5
$proc = Get-Process | Where-Object { $_.MainWindowTitle -match "DEBUG" } | Select-Object -First 1
Add-Type @"
using System; using System.Runtime.InteropServices;
public class WinSnap {
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
    [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h, int n);
    [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out RECT r);
    public struct RECT { public int Left,Top,Right,Bottom; }
}
"@
[WinSnap]::ShowWindow($proc.MainWindowHandle, 9)
[WinSnap]::SetForegroundWindow($proc.MainWindowHandle)
Start-Sleep -Milliseconds 800
$r = New-Object WinSnap+RECT
[WinSnap]::GetWindowRect($proc.MainWindowHandle, [ref]$r)
$w = $r.Right - $r.Left; $h = $r.Bottom - $r.Top
Add-Type -AssemblyName System.Drawing
$bmp = New-Object System.Drawing.Bitmap -ArgumentList @($w, $h)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.CopyFromScreen($r.Left, $r.Top, 0, 0, (New-Object System.Drawing.Size -ArgumentList @($w,$h)))
$bmp.Save("S:\attribute-loop\tests\screenshots\subviewport_check.png")
$g.Dispose(); $bmp.Dispose()
Write-Output "saved ${w}x${h}"
```

- [ ] **Step 3: Read screenshot and verify**

Read `tests/screenshots/subviewport_check.png`. Verify:
- Left ~80% shows game world (background, track, tiles)
- Right ~20% shows solid sidebar (dark background, 装备规则 section, 服务栏 section)
- No game world content visible behind sidebar
- Bottom HUD spans full width

- [ ] **Step 4: If game crashes on startup, check for these common issues**

**Issue: `@onready` fails because Main._ready() fires before setup_ui() is called**
→ Solution: In `Main.gd`, guard `_finish_setup()` — only call it from `setup_ui()`, not `_ready()`. This is already done in the plan (Main has no `_ready()` that calls setup).

**Issue: `SubViewport` not rendering**
→ Check `render_target_update_mode = 3` (ALWAYS) is set on `GameViewport`.

**Issue: Tile clicks not working**
→ Verify `SubViewportContainer` has `stretch = true` and `GameViewport` has `own_world_2d = false`.

- [ ] **Step 5: Final commit**

```bash
git add -A
git commit -m "feat: subviewport layout complete — game world constrained to left 80%"
```
