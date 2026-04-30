# Tile Entry System Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a tile layer along the track where components flow automatically from dead enemies, can be invested by the player, accumulate power per loop, and be harvested back — with strip costs, inventory limits, and empty-shell logic.

**Architecture:** Tile extends Resource (consistent with EntryComponent/Rule). Track owns `Array[Tile]`. Main orchestrates all tile logic (tile tracking, trigger dispatch, drop transfers) since it already holds player, enemies, and track. Visual layer lives in HUD as a Control child (TileOverlay), mirroring EnemyCardOverlay's canvas_transform approach.

**Tech Stack:** GDScript 4, Godot 4.6.2 Mono, no external libs. Validate every task with `"S:/Godot_v4.6.2-stable_mono_win64/Godot_v4.6.2-stable_mono_win64.exe" --path "S:/attribute-loop" --headless --quit` — expect exit code 0, no ERROR lines.

---

## File Map

| Action | Path | Responsibility |
|--------|------|----------------|
| Create | `scripts/core/Tile.gd` | Resource: track_t, components, pass_count, try_fire, strip/add |
| Create | `scenes/ui/TileSlot.gd` | Control: drop target for Player→Tile investment |
| Create | `scenes/ui/TileSlot.tscn` | Scene for TileSlot |
| Create | `scenes/ui/TileOverlay.gd` | Control in HUD: draws dots + tile cards in pause mode |
| Create | `scenes/ui/TileOverlay.tscn` | Scene for TileOverlay |
| Modify | `scenes/track/Track.gd` | Add tile_count export, generate tiles array in _ready |
| Modify | `scripts/systems/Inventory.gd` | Replace MAX_SIZE const with capacity export var (default 8) |
| Modify | `scenes/enemy/Enemy.gd` | Strip retaliation, last-component final attack, is_empty_shell, spawn_t |
| Modify | `scenes/player/Player.gd` | receive_heal(), speed_multiplier, _speed_boost_timer, apply_speed_boost() |
| Modify | `scenes/main/Main.gd` | Enemy spawn_t, death→tile transfer, tile tracking, trigger, empty shell clear, new components |
| Modify | `scenes/ui/ComponentCard.gd` | Add _tile_ref, include tile in drag data |
| Modify | `scenes/ui/InventoryPanel.gd` | Accept tile-source drops, harvest cost, player_ref param |
| Modify | `scenes/ui/RuleSlot.gd` | _drop_data handles tile source |
| Modify | `scenes/ui/HUD.gd` | setup() passes track+player to TileOverlay, set_paused wires overlay |

---

## Task 1: Tile Resource

**Files:**
- Create: `scripts/core/Tile.gd`

- [ ] **Step 1: Create `scripts/core/Tile.gd`**

```gdscript
class_name Tile
extends Resource

const EntryComponent = preload("res://scripts/core/EntryComponent.gd")

signal component_stripped(component: EntryComponent)
signal strip_damage_requested(amount: float)

const MAX_COMPONENTS: int = 3

@export var track_t: float = 0.0
@export var pass_count: int = 0
@export var harvest_threshold: int = 3

var components: Array[EntryComponent] = []

func add_component(component: EntryComponent) -> bool:
	if components.size() >= MAX_COMPONENTS:
		return false
	components.append(component)
	return true

func strip_component(component: EntryComponent) -> void:
	if component in components:
		components.erase(component)
		component_stripped.emit(component)
		strip_damage_requested.emit(float(pass_count * 2))

func try_fire() -> String:
	var has_on_pass_trigger := false
	for comp in components:
		if comp.slot_type == EntryComponent.SlotType.TRIGGER and comp.data.get("event") == "on_pass":
			has_on_pass_trigger = true
			break
	if not has_on_pass_trigger:
		return ""
	for comp in components:
		if comp.slot_type == EntryComponent.SlotType.EFFECT:
			return comp.data.get("type", "")
	return ""

func effect_multiplier() -> float:
	return 1.0 + pass_count * 0.1
```

- [ ] **Step 2: Validate**

```bash
"S:/Godot_v4.6.2-stable_mono_win64/Godot_v4.6.2-stable_mono_win64.exe" --path "S:/attribute-loop" --headless --quit
```

Expected: exit code 0, no ERROR lines.

- [ ] **Step 3: Commit**

```bash
git add scripts/core/Tile.gd
git commit -m "feat: add Tile Resource with components, pass_count, try_fire"
```

---

## Task 2: Track Generates Tiles

**Files:**
- Modify: `scenes/track/Track.gd`

- [ ] **Step 1: Replace full content of `scenes/track/Track.gd`**

```gdscript
class_name Track
extends Node2D

const Tile = preload("res://scripts/core/Tile.gd")

@export var loop_points: Array[Vector2] = []
@export var tile_count: int = 12
@onready var visual: Line2D = $TrackVisual

var tiles: Array = []

func _ready() -> void:
	if loop_points.is_empty():
		_build_default_track()
	_draw_track()
	_generate_tiles()

func _build_default_track() -> void:
	var cx = 640.0
	var cy = 360.0
	var w = 480.0
	var h = 280.0
	var r = 80.0
	loop_points = [
		Vector2(cx - w/2 + r, cy - h/2),
		Vector2(cx + w/2 - r, cy - h/2),
		Vector2(cx + w/2, cy - h/2 + r),
		Vector2(cx + w/2, cy + h/2 - r),
		Vector2(cx + w/2 - r, cy + h/2),
		Vector2(cx - w/2 + r, cy + h/2),
		Vector2(cx - w/2, cy + h/2 - r),
		Vector2(cx - w/2, cy - h/2 + r),
	]

func _draw_track() -> void:
	var pts = loop_points.duplicate()
	pts.append(pts[0])
	visual.points = PackedVector2Array(pts)

func _generate_tiles() -> void:
	tiles.clear()
	for i in tile_count:
		var tile = Tile.new()
		tile.track_t = (float(i) + 0.5) / float(tile_count)
		tiles.append(tile)

func get_position_at(t: float) -> Vector2:
	var total = loop_points.size()
	var scaled = t * total
	var idx = int(scaled) % total
	var next = (idx + 1) % total
	var frac = scaled - int(scaled)
	return loop_points[idx].lerp(loop_points[next], frac)

func get_total_length() -> float:
	var length = 0.0
	for i in loop_points.size():
		var next = (i + 1) % loop_points.size()
		length += loop_points[i].distance_to(loop_points[next])
	return length

func get_tile_index_for_t(t: float) -> int:
	return int(t * tile_count) % tile_count
```

- [ ] **Step 2: Validate**

```bash
"S:/Godot_v4.6.2-stable_mono_win64/Godot_v4.6.2-stable_mono_win64.exe" --path "S:/attribute-loop" --headless --quit
```

Expected: exit code 0.

- [ ] **Step 3: Commit**

```bash
git add scenes/track/Track.gd
git commit -m "feat: Track generates Array[Tile] tiles at _ready via tile_count"
```

---

## Task 3: Inventory Capacity

**Files:**
- Modify: `scripts/systems/Inventory.gd`

- [ ] **Step 1: Replace full content of `scripts/systems/Inventory.gd`**

```gdscript
class_name Inventory
extends Node

const EntryComponent = preload("res://scripts/core/EntryComponent.gd")

signal component_added(component: EntryComponent)
signal component_removed(component: EntryComponent)

@export var capacity: int = 8

var components: Array[EntryComponent] = []

func add(component: EntryComponent) -> bool:
	if components.size() >= capacity:
		return false
	components.append(component)
	component_added.emit(component)
	return true

func remove(component: EntryComponent) -> void:
	components.erase(component)
	component_removed.emit(component)
```

- [ ] **Step 2: Validate**

```bash
"S:/Godot_v4.6.2-stable_mono_win64/Godot_v4.6.2-stable_mono_win64.exe" --path "S:/attribute-loop" --headless --quit
```

- [ ] **Step 3: Commit**

```bash
git add scripts/systems/Inventory.gd
git commit -m "feat: Inventory capacity as export var (default 8), replaces MAX_SIZE=12"
```

---

## Task 4: Enemy Strip Retaliation + Empty Shell

**Files:**
- Modify: `scenes/enemy/Enemy.gd`

- [ ] **Step 1: Replace full content of `scenes/enemy/Enemy.gd`**

```gdscript
class_name Enemy
extends Node2D

const EntryComponent = preload("res://scripts/core/EntryComponent.gd")

signal component_stripped(component: EntryComponent)
signal enemy_defeated

@export var hp: float = 40.0
@export var attack_damage: float = 8.0
@export var attack_interval: float = 2.0

var max_hp: float = 40.0
var components: Array[EntryComponent] = []
var player_ref: Node2D = null
var spawn_t: float = 0.0
var is_empty_shell: bool = false

var _attack_timer: float = 0.0

func _ready() -> void:
	max_hp = hp

func _process(delta: float) -> void:
	if is_empty_shell or player_ref == null:
		return
	_attack_timer += delta
	if _attack_timer >= attack_interval:
		_attack_timer = 0.0
		_attack_player()

func setup_components(comp_list: Array[EntryComponent]) -> void:
	components = comp_list

func _attack_player() -> void:
	if player_ref and player_ref.has_method("receive_damage"):
		player_ref.receive_damage(attack_damage)

func strip_component(component: EntryComponent) -> void:
	if component not in components:
		return
	components.erase(component)
	component_stripped.emit(component)
	Log.info("stripped '%s', remaining=%d" % [component.label, components.size()], "Enemy")
	if player_ref and player_ref.has_method("receive_damage"):
		player_ref.receive_damage(5.0)
	if components.is_empty():
		_become_empty_shell()

func _become_empty_shell() -> void:
	if player_ref and player_ref.has_method("receive_damage"):
		player_ref.receive_damage(attack_damage)
		Log.info("final attack (%.1f) before becoming shell" % attack_damage, "Enemy")
	is_empty_shell = true
	Log.info("became empty shell", "Enemy")

func receive_damage(amount: float) -> void:
	hp -= amount
	_fire_components("on_hit", {"amount": amount})
	if hp <= 0.0:
		Log.info("defeated (hp=%.1f)" % hp, "Enemy")
		enemy_defeated.emit()
		queue_free()

func _fire_components(event: String, context: Dictionary) -> void:
	var has_trigger := false
	for comp in components:
		if comp.slot_type == EntryComponent.SlotType.TRIGGER and comp.data.get("event") == event:
			has_trigger = true
			break
	if not has_trigger:
		return
	for comp in components:
		if comp.slot_type == EntryComponent.SlotType.EFFECT:
			_apply_effect(comp, context)

func _apply_effect(comp: EntryComponent, context: Dictionary) -> void:
	match comp.data.get("type", ""):
		"heal":
			hp = clampf(hp + 10.0, 0.0, max_hp)
			Log.info("heal → hp=%.1f" % hp, "Enemy")
		"reflect_damage":
			if player_ref and player_ref.has_method("receive_damage"):
				var dmg: float = context.get("amount", 0.0) * 0.5
				Log.info("reflect %.1f to player" % dmg, "Enemy")
				player_ref.receive_damage(dmg)
		"summon_clone":
			Log.info("summon_clone (not implemented)", "Enemy")
```

- [ ] **Step 2: Validate**

```bash
"S:/Godot_v4.6.2-stable_mono_win64/Godot_v4.6.2-stable_mono_win64.exe" --path "S:/attribute-loop" --headless --quit
```

- [ ] **Step 3: Commit**

```bash
git add scenes/enemy/Enemy.gd
git commit -m "feat: enemy strip retaliation (5 HP), final attack + empty shell on last strip, spawn_t field"
```

---

## Task 5: Player Heal + Speed Boost

**Files:**
- Modify: `scenes/player/Player.gd`

- [ ] **Step 1: Replace full content of `scenes/player/Player.gd`**

```gdscript
class_name Player
extends Node2D

const Rule = preload("res://scripts/core/Rule.gd")
const TrackScript = preload("res://scenes/track/Track.gd")
const Inventory = preload("res://scripts/systems/Inventory.gd")

signal rule_fired(rule: Rule, effect_type: String)
signal took_damage(amount: float)
signal healed(amount: float)
signal player_died

@export var speed: float = 80.0

var track: Node2D = null
var track_t: float = 0.0
var hp: float = 100.0
var max_hp: float = 100.0
var rules: Array[Rule] = []
var inventory: Inventory
var speed_multiplier: float = 1.0

var _speed_boost_timer: float = 0.0
const SPEED_BOOST_DURATION: float = 3.0

func _ready() -> void:
	inventory = Inventory.new()
	add_child(inventory)
	rule_fired.connect(_on_rule_fired)

func _process(delta: float) -> void:
	if track == null:
		return
	var length = track.get_total_length()
	track_t += (speed * speed_multiplier / length) * delta
	if track_t >= 1.0:
		track_t -= 1.0
	position = track.get_position_at(track_t)
	if _speed_boost_timer > 0.0:
		_speed_boost_timer -= delta
		if _speed_boost_timer <= 0.0:
			speed_multiplier = 1.0

func receive_damage(amount: float) -> void:
	hp = clampf(hp - amount, 0.0, max_hp)
	took_damage.emit(amount)
	if hp <= 0.0:
		Log.warn("player died", "Player")
		player_died.emit()
		return
	_fire_rules("on_hit", {"owner": self, "amount": amount})

func receive_heal(amount: float) -> void:
	hp = clampf(hp + amount, 0.0, max_hp)
	healed.emit(amount)

func apply_speed_boost(multiplier: float) -> void:
	speed_multiplier = multiplier
	_speed_boost_timer = SPEED_BOOST_DURATION

func _fire_rules(event: String, context: Dictionary) -> void:
	for rule in rules:
		rule.try_fire(event, context)

func add_rule(rule: Rule) -> void:
	rules.append(rule)

func _on_rule_fired(_rule: Rule, effect_type: String) -> void:
	match effect_type:
		"heal":
			receive_heal(15.0)
		"reflect_damage":
			pass
		"summon_clone":
			pass
```

- [ ] **Step 2: Validate**

```bash
"S:/Godot_v4.6.2-stable_mono_win64/Godot_v4.6.2-stable_mono_win64.exe" --path "S:/attribute-loop" --headless --quit
```

- [ ] **Step 3: Commit**

```bash
git add scenes/player/Player.gd
git commit -m "feat: Player.receive_heal, apply_speed_boost, speed_multiplier with timed reset"
```

---

## Task 6: Main — Tile Tracking, Trigger Dispatch, Death Transfer, Empty Shell Clear

**Files:**
- Modify: `scenes/main/Main.gd`

- [ ] **Step 1: Replace full content of `scenes/main/Main.gd`**

```gdscript
extends Node

const TrackScript = preload("res://scenes/track/Track.gd")
const PlayerScript = preload("res://scenes/player/Player.gd")
const HUDScript = preload("res://scenes/ui/HUD.gd")
const GameStateScript = preload("res://scripts/systems/GameState.gd")
const EntryComponent = preload("res://scripts/core/EntryComponent.gd")
const Rule = preload("res://scripts/core/Rule.gd")
const Tile = preload("res://scripts/core/Tile.gd")

@onready var track: Node2D = $World/Track
@onready var player: Node2D = $World/Player
@onready var enemies_node: Node2D = $World/Enemies
@onready var hud: CanvasLayer = $HUD

var game_state: Node
var enemy_a_scene: PackedScene = preload("res://scenes/enemy/Enemy.tscn")
var enemy_b_scene: PackedScene = preload("res://scenes/enemy/EnemyB.tscn")

var _spawn_timer: float = 0.0
var _spawn_interval: float = 5.0
var _player_attack_timer: float = 0.0
var _last_player_tile_index: int = -1

const PLAYER_ATTACK_INTERVAL: float = 1.0
const PLAYER_ATTACK_DAMAGE: float = 20.0
const PLAYER_ATTACK_RANGE: float = 50.0
const EMPTY_SHELL_CLEAR_RANGE: float = 30.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	$World.process_mode = Node.PROCESS_MODE_PAUSABLE
	game_state = GameStateScript.new()
	add_child(game_state)

	player.track = track
	player.took_damage.connect(_on_player_took_damage)
	player.healed.connect(_on_player_healed)
	player.player_died.connect(_on_player_died)
	game_state.state_changed.connect(_on_state_changed)

	hud.update_hp(player.hp, player.max_hp)
	hud.setup(player, player.inventory, enemies_node, track)

func _process(delta: float) -> void:
	if get_tree().paused:
		return
	_spawn_timer += delta
	if _spawn_timer >= _spawn_interval:
		_spawn_timer = 0.0
		_spawn_enemy()
	_player_attack_timer += delta
	if _player_attack_timer >= PLAYER_ATTACK_INTERVAL:
		_player_attack_timer = 0.0
		_attack_nearby_enemies()
	_check_player_tile()
	_clear_nearby_empty_shells()

func _check_player_tile() -> void:
	if track.tiles.is_empty():
		return
	var idx = track.get_tile_index_for_t(player.track_t)
	if idx == _last_player_tile_index:
		return
	_last_player_tile_index = idx
	_on_player_entered_tile(idx)

func _on_player_entered_tile(tile_index: int) -> void:
	var tile = track.tiles[tile_index] as Tile
	tile.pass_count += 1
	Log.info("entered tile %d, pass_count=%d" % [tile_index, tile.pass_count], "Main")
	var effect_type = tile.try_fire()
	if effect_type == "":
		return
	var mult = tile.effect_multiplier()
	match effect_type:
		"heal":
			player.receive_heal(15.0 * mult)
			Log.info("tile heal %.1f" % (15.0 * mult), "Main")
		"boost_speed":
			player.apply_speed_boost(1.5)
			Log.info("tile boost_speed x1.5", "Main")
		"deal_damage_nearby":
			var dmg = 10.0 * mult
			for enemy in enemies_node.get_children():
				if not is_instance_valid(enemy):
					continue
				if enemy.global_position.distance_to(player.global_position) <= 100.0:
					enemy.receive_damage(dmg)
			Log.info("tile deal_damage_nearby %.1f" % dmg, "Main")

func _clear_nearby_empty_shells() -> void:
	for enemy in enemies_node.get_children():
		if not is_instance_valid(enemy):
			continue
		if enemy.is_empty_shell and enemy.global_position.distance_to(player.global_position) <= EMPTY_SHELL_CLEAR_RANGE:
			enemy.queue_free()

func _attack_nearby_enemies() -> void:
	for enemy in enemies_node.get_children():
		if is_instance_valid(enemy) and not enemy.is_empty_shell:
			if enemy.global_position.distance_to(player.global_position) <= PLAYER_ATTACK_RANGE:
				enemy.receive_damage(PLAYER_ATTACK_DAMAGE)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		game_state.toggle()

func _spawn_enemy() -> void:
	var use_b := randf() > 0.5
	var scene := enemy_b_scene if use_b else enemy_a_scene
	var enemy := scene.instantiate()
	var components = _make_enemy_b_components() if use_b else _make_enemy_a_components()
	enemy.setup_components(components)
	enemies_node.add_child(enemy)
	var t = randf()
	enemy.position = track.get_position_at(t)
	enemy.spawn_t = t
	enemy.player_ref = player
	enemy.enemy_defeated.connect(_on_enemy_defeated.bind(enemy))

func _on_enemy_defeated(enemy: Node) -> void:
	if enemy.components.is_empty():
		return
	var nearest = _find_nearest_tile_to_t(enemy.spawn_t)
	if nearest == null:
		return
	for comp in enemy.components.duplicate():
		nearest.add_component(comp)
	Log.info("enemy death → %d components → tile (pass_count=%d)" % [enemy.components.size(), nearest.pass_count], "Main")

func _find_nearest_tile_to_t(t: float) -> Tile:
	if track.tiles.is_empty():
		return null
	var best_tile: Tile = null
	var best_dist := INF
	for tile in track.tiles:
		var d = absf(tile.track_t - t)
		d = minf(d, 1.0 - d)
		if d < best_dist:
			best_dist = d
			best_tile = tile
	return best_tile

func _make_enemy_a_components() -> Array[EntryComponent]:
	var trigger := EntryComponent.new()
	trigger.slot_type = EntryComponent.SlotType.TRIGGER
	trigger.label = "受到攻击时"
	trigger.data = {"event": "on_hit"}

	var effect := EntryComponent.new()
	effect.slot_type = EntryComponent.SlotType.EFFECT
	effect.label = "召唤分身"
	effect.data = {"type": "summon_clone"}

	return [trigger, effect]

func _make_enemy_b_components() -> Array[EntryComponent]:
	var trigger := EntryComponent.new()
	trigger.slot_type = EntryComponent.SlotType.TRIGGER
	trigger.label = "受到攻击时"
	trigger.data = {"event": "on_hit"}

	var effect1 := EntryComponent.new()
	effect1.slot_type = EntryComponent.SlotType.EFFECT
	effect1.label = "反弹伤害"
	effect1.data = {"type": "reflect_damage"}

	var effect2 := EntryComponent.new()
	effect2.slot_type = EntryComponent.SlotType.EFFECT
	effect2.label = "恢复生命"
	effect2.data = {"type": "heal"}

	return [trigger, effect1, effect2]

func _make_tile_components() -> Array[EntryComponent]:
	var trigger := EntryComponent.new()
	trigger.slot_type = EntryComponent.SlotType.TRIGGER
	trigger.label = "经过时"
	trigger.data = {"event": "on_pass"}

	var effect := EntryComponent.new()
	effect.slot_type = EntryComponent.SlotType.EFFECT
	effect.label = "治愈"
	effect.data = {"type": "heal"}

	return [trigger, effect]

func _seed_initial_tiles() -> void:
	if track.tiles.size() < 4:
		return
	var comps = _make_tile_components()
	var tile = track.tiles[0] as Tile
	for comp in comps:
		tile.add_component(comp)
	tile.pass_count = 3
	Log.info("seeded tile 0 with on_pass+heal (pass_count=3)", "Main")

func _on_player_took_damage(_amount: float) -> void:
	hud.update_hp(player.hp, player.max_hp)

func _on_player_healed(_amount: float) -> void:
	hud.update_hp(player.hp, player.max_hp)

func _on_player_died() -> void:
	get_tree().reload_current_scene()

func _on_state_changed(new_state: int) -> void:
	hud.set_paused(new_state == 1)
```

- [ ] **Step 2: Call `_seed_initial_tiles()` at end of `_ready`**

After `hud.setup(...)` in `_ready`, add:

```gdscript
	_seed_initial_tiles()
```

So the end of `_ready` looks like:
```gdscript
	hud.update_hp(player.hp, player.max_hp)
	hud.setup(player, player.inventory, enemies_node, track)
	_seed_initial_tiles()
```

- [ ] **Step 3: Validate**

```bash
"S:/Godot_v4.6.2-stable_mono_win64/Godot_v4.6.2-stable_mono_win64.exe" --path "S:/attribute-loop" --headless --quit
```

Expected: exit code 0. (HUD.setup signature mismatch will cause an error — that is expected and will be fixed in Task 11.)

- [ ] **Step 4: Commit**

```bash
git add scenes/main/Main.gd
git commit -m "feat: Main tile tracking, trigger dispatch, enemy death→tile transfer, empty shell clear"
```

---

## Task 7: ComponentCard — Tile in Drag Data

**Files:**
- Modify: `scenes/ui/ComponentCard.gd`

- [ ] **Step 1: Replace full content of `scenes/ui/ComponentCard.gd`**

```gdscript
class_name ComponentCard
extends Panel

const EntryComponent = preload("res://scripts/core/EntryComponent.gd")

var component: EntryComponent = null
var draggable: bool = true
var _enemy_ref = null
var _tile_ref = null

@onready var type_label: Label = $TypeLabel
@onready var name_label: Label = $NameLabel

func setup(comp: EntryComponent, enemy_ref = null, tile_ref = null, is_draggable: bool = true) -> void:
	component = comp
	_enemy_ref = enemy_ref
	_tile_ref = tile_ref
	draggable = is_draggable
	type_label.text = EntryComponent.SlotType.keys()[comp.slot_type]
	name_label.text = comp.label
	modulate.a = 1.0 if is_draggable else 0.4

func _get_drag_data(_at_position: Vector2) -> Variant:
	if not draggable:
		return null
	modulate.a = 0.3
	var preview := Panel.new()
	preview.size = Vector2(80, 50)
	var lbl := Label.new()
	lbl.text = component.label
	lbl.add_theme_font_size_override("font_size", 11)
	preview.add_child(lbl)
	set_drag_preview(preview)
	return {"component": component, "enemy": _enemy_ref, "tile": _tile_ref}

func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		modulate.a = 1.0 if draggable else 0.4
```

- [ ] **Step 2: Validate**

```bash
"S:/Godot_v4.6.2-stable_mono_win64/Godot_v4.6.2-stable_mono_win64.exe" --path "S:/attribute-loop" --headless --quit
```

- [ ] **Step 3: Commit**

```bash
git add scenes/ui/ComponentCard.gd
git commit -m "feat: ComponentCard drag data includes tile ref, setup accepts tile_ref + is_draggable"
```

---

## Task 8: InventoryPanel + RuleSlot Handle Tile Source

**Files:**
- Modify: `scenes/ui/InventoryPanel.gd`
- Modify: `scenes/ui/RuleSlot.gd`

- [ ] **Step 1: Replace full content of `scenes/ui/InventoryPanel.gd`**

```gdscript
class_name InventoryPanel
extends Panel

const EntryComponent = preload("res://scripts/core/EntryComponent.gd")
const ComponentCard = preload("res://scenes/ui/ComponentCard.tscn")
const ComponentCardScript = preload("res://scenes/ui/ComponentCard.gd")
const Inventory = preload("res://scripts/systems/Inventory.gd")

var inventory: Inventory = null
var player_ref = null

@onready var cards_container: HBoxContainer = $CardsContainer

func setup(player, inv: Inventory) -> void:
	player_ref = player
	if inventory != null:
		inventory.component_added.disconnect(_on_component_added)
		inventory.component_removed.disconnect(_on_component_removed)
	inventory = inv
	inventory.component_added.connect(_on_component_added)
	inventory.component_removed.connect(_on_component_removed)
	_refresh()

func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED and visible and inventory != null:
		_refresh()

func _refresh() -> void:
	for child in cards_container.get_children():
		cards_container.remove_child(child)
		child.queue_free()
	for comp in inventory.components:
		_add_card(comp)

func _add_card(comp: EntryComponent) -> void:
	var card = ComponentCard.instantiate()
	cards_container.add_child(card)
	card.setup(comp, null, null, true)

func _on_component_added(comp: EntryComponent) -> void:
	_add_card(comp)

func _on_component_removed(comp: EntryComponent) -> void:
	for card in cards_container.get_children():
		if card is ComponentCardScript and card.component == comp:
			cards_container.remove_child(card)
			card.queue_free()
			return

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if not (data is Dictionary and data.has("component")):
		return false
	var from_enemy = data.get("enemy") != null
	var from_tile = data.get("tile") != null
	return from_enemy or from_tile

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	var component := data["component"] as EntryComponent
	var enemy = data.get("enemy")
	var tile = data.get("tile")
	if enemy != null and is_instance_valid(enemy):
		enemy.strip_component(component)
	elif tile != null:
		tile.strip_component(component)
		if player_ref != null and player_ref.has_method("receive_damage"):
			player_ref.receive_damage(float(tile.pass_count * 2))
	if inventory != null and not inventory.components.has(component):
		inventory.add(component)
```

- [ ] **Step 2: Replace full content of `scenes/ui/RuleSlot.gd`**

```gdscript
class_name RuleSlot
extends Panel

const EntryComponent = preload("res://scripts/core/EntryComponent.gd")
const Inventory = preload("res://scripts/systems/Inventory.gd")
const ComponentCard = preload("res://scenes/ui/ComponentCard.tscn")

signal component_placed(component: EntryComponent)
signal component_cleared(component: EntryComponent)

@export var accepted_type: int = 0

var held_component: EntryComponent = null
var inventory: Inventory = null

@onready var type_label: Label = $TypeLabel
@onready var card_container: VBoxContainer = $CardContainer

func setup(p_accepted_type: int, p_inventory: Inventory) -> void:
	accepted_type = p_accepted_type
	inventory = p_inventory
	type_label.text = EntryComponent.SlotType.keys()[accepted_type]

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and held_component != null:
		var comp := held_component
		held_component = null
		for child in card_container.get_children():
			card_container.remove_child(child)
			child.queue_free()
		if inventory != null:
			inventory.add(comp)
		component_cleared.emit(comp)

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if not (data is Dictionary and data.has("component") and data.has("enemy")):
		return false
	if data.get("enemy") != null:
		return false
	var comp := data["component"] as EntryComponent
	if comp == null:
		return false
	return comp.slot_type == accepted_type and held_component == null

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if inventory == null:
		push_error("RuleSlot._drop_data called before setup()")
		return
	var component := data["component"] as EntryComponent
	if component == null:
		return
	var tile = data.get("tile")
	if tile != null:
		tile.strip_component(component)
	else:
		inventory.remove(component)
	held_component = component
	var card = ComponentCard.instantiate()
	card_container.add_child(card)
	card.setup(component, null, null, false)
	component_placed.emit(component)
```

- [ ] **Step 3: Validate**

```bash
"S:/Godot_v4.6.2-stable_mono_win64/Godot_v4.6.2-stable_mono_win64.exe" --path "S:/attribute-loop" --headless --quit
```

- [ ] **Step 4: Commit**

```bash
git add scenes/ui/InventoryPanel.gd scenes/ui/RuleSlot.gd
git commit -m "feat: InventoryPanel + RuleSlot accept tile-sourced drops, harvest cost in InventoryPanel"
```

---

## Task 9: TileSlot Scene (Player → Tile Drop Target)

**Files:**
- Create: `scenes/ui/TileSlot.gd`
- Create: `scenes/ui/TileSlot.tscn`

- [ ] **Step 1: Create `scenes/ui/TileSlot.gd`**

```gdscript
class_name TileSlot
extends Panel

const EntryComponent = preload("res://scripts/core/EntryComponent.gd")
const Inventory = preload("res://scripts/systems/Inventory.gd")

var tile = null
var inventory: Inventory = null

func setup(p_tile, p_inventory: Inventory) -> void:
	tile = p_tile
	inventory = p_inventory
	custom_minimum_size = Vector2(80, 30)

func _can_drop_data(_pos: Vector2, data: Variant) -> bool:
	if not (data is Dictionary and data.has("component")):
		return false
	if data.get("enemy") != null or data.get("tile") != null:
		return false
	if tile == null:
		return false
	return tile.components.size() < tile.MAX_COMPONENTS

func _drop_data(_pos: Vector2, data: Variant) -> void:
	var comp := data["component"] as EntryComponent
	if comp == null or tile == null:
		return
	if inventory != null:
		inventory.remove(comp)
	tile.add_component(comp)
	Log.info("invested '%s' into tile" % comp.label, "TileSlot")
```

- [ ] **Step 2: Create `scenes/ui/TileSlot.tscn` via MCP**

```
mcp__godot__create_scene:
  name: TileSlot
  path: res://scenes/ui/TileSlot.tscn
  root_node:
    type: Panel
    name: TileSlot
    script: res://scenes/ui/TileSlot.gd
```

Use the `mcp__godot__create_scene` tool with:
- path: `res://scenes/ui/TileSlot.tscn`
- root type: `Panel`, name: `TileSlot`, script attached: `res://scenes/ui/TileSlot.gd`

- [ ] **Step 3: Validate**

```bash
"S:/Godot_v4.6.2-stable_mono_win64/Godot_v4.6.2-stable_mono_win64.exe" --path "S:/attribute-loop" --headless --quit
```

- [ ] **Step 4: Commit**

```bash
git add scenes/ui/TileSlot.gd scenes/ui/TileSlot.tscn
git commit -m "feat: TileSlot drop target for Player→Tile component investment"
```

---

## Task 10: TileOverlay — Visual Layer + Pause Cards

**Files:**
- Create: `scenes/ui/TileOverlay.gd`
- Create: `scenes/ui/TileOverlay.tscn`

- [ ] **Step 1: Create `scenes/ui/TileOverlay.gd`**

```gdscript
class_name TileOverlay
extends Control

const ComponentCard = preload("res://scenes/ui/ComponentCard.tscn")
const TileSlot = preload("res://scenes/ui/TileSlot.tscn")
const Tile = preload("res://scripts/core/Tile.gd")
const Inventory = preload("res://scripts/systems/Inventory.gd")

var track = null
var player = null
var inventory: Inventory = null

var _is_paused: bool = false
var _tile_containers: Dictionary = {}

func setup(p_track, p_player, p_inventory: Inventory) -> void:
	track = p_track
	player = p_player
	inventory = p_inventory
	for tile in track.tiles:
		tile.component_stripped.connect(_on_tile_component_stripped.bind(tile))

func set_paused(paused: bool) -> void:
	_is_paused = paused
	if paused:
		_build_tile_cards()
	else:
		_clear_tile_cards()
	queue_redraw()

func _process(_delta: float) -> void:
	queue_redraw()
	if not _is_paused or track == null:
		return
	var canvas_tf = get_viewport().get_canvas_transform()
	for idx in _tile_containers:
		if not is_instance_valid(_tile_containers[idx]):
			continue
		var tile = track.tiles[idx] as Tile
		var world_pos = track.get_position_at(tile.track_t)
		var screen_pos = canvas_tf * world_pos
		_tile_containers[idx].position = screen_pos + Vector2(-40, -130)

func _draw() -> void:
	if track == null:
		return
	var canvas_tf = get_viewport().get_canvas_transform()
	for tile in track.tiles:
		var world_pos = track.get_position_at(tile.track_t)
		var screen_pos = canvas_tf * world_pos
		var color: Color
		if tile.components.is_empty():
			color = Color(0.35, 0.35, 0.35, 0.5)
		elif tile.pass_count >= tile.harvest_threshold:
			color = Color(1.0, 0.8, 0.1, 0.95)
		else:
			var t = clampf(float(tile.pass_count) / float(tile.harvest_threshold), 0.0, 1.0)
			color = Color(0.2 + t * 0.2, 0.5, 0.9, 0.7)
		draw_circle(screen_pos, 7.0, color)
		if tile.components.size() > 0:
			var font = get_theme_default_font()
			draw_string(font, screen_pos + Vector2(9, 4), str(tile.components.size()),
						HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color.WHITE)

func _build_tile_cards() -> void:
	_clear_tile_cards()
	if track == null or player == null:
		return
	var n = track.tiles.size()
	var player_idx = track.get_tile_index_for_t(player.track_t)
	for offset in [-1, 0, 1]:
		var idx = (player_idx + offset + n) % n
		var tile = track.tiles[idx] as Tile
		_create_tile_container(idx, tile)

func _create_tile_container(idx: int, tile: Tile) -> void:
	var container := VBoxContainer.new()
	add_child(container)
	_tile_containers[idx] = container

	var slot = TileSlot.instantiate()
	container.add_child(slot)
	slot.setup(tile, inventory)

	for comp in tile.components:
		var harvestable = tile.pass_count >= tile.harvest_threshold
		var card = ComponentCard.instantiate()
		container.add_child(card)
		card.setup(comp, null, tile, harvestable)

func _clear_tile_cards() -> void:
	for container in _tile_containers.values():
		if is_instance_valid(container):
			container.queue_free()
	_tile_containers.clear()

func _on_tile_component_stripped(component, tile: Tile) -> void:
	var idx = track.tiles.find(tile)
	if idx < 0 or idx not in _tile_containers:
		return
	var container = _tile_containers[idx]
	if not is_instance_valid(container):
		return
	for child in container.get_children():
		if child.has_method("setup") and child.get("component") == component:
			container.remove_child(child)
			child.queue_free()
			break
	if container.get_child_count() <= 1:
		container.queue_free()
		_tile_containers.erase(idx)
```

- [ ] **Step 2: Create `scenes/ui/TileOverlay.tscn` via MCP**

Use `mcp__godot__create_scene` with:
- path: `res://scenes/ui/TileOverlay.tscn`
- root type: `Control`, name: `TileOverlay`, script: `res://scenes/ui/TileOverlay.gd`
- Set `mouse_filter` to `MOUSE_FILTER_IGNORE` (value 2) so it doesn't block input to other controls.

- [ ] **Step 3: Validate**

```bash
"S:/Godot_v4.6.2-stable_mono_win64/Godot_v4.6.2-stable_mono_win64.exe" --path "S:/attribute-loop" --headless --quit
```

- [ ] **Step 4: Commit**

```bash
git add scenes/ui/TileOverlay.gd scenes/ui/TileOverlay.tscn
git commit -m "feat: TileOverlay draws tile dots, shows component cards + TileSlot in pause mode"
```

---

## Task 11: HUD + Main Final Wiring

**Files:**
- Modify: `scenes/ui/HUD.gd`
- Modify: `scenes/main/Main.gd` (one line — `_seed_initial_tiles` already added in Task 6)

- [ ] **Step 1: Add TileOverlay as a child of HUD scene**

Open `scenes/ui/HUD.tscn` in Godot editor via MCP and add `TileOverlay` as a child node. Then update `HUD.gd`:

- [ ] **Step 2: Replace full content of `scenes/ui/HUD.gd`**

```gdscript
class_name HUD
extends CanvasLayer

const Inventory = preload("res://scripts/systems/Inventory.gd")

@onready var hp_bar: ProgressBar = $HPBar
@onready var hp_label: Label = $HPLabel
@onready var pause_label: Label = $PauseLabel
@onready var enemy_card_overlay = $EnemyCardOverlay
@onready var inventory_panel = $InventoryPanel
@onready var rule_assembly_panel = $RuleAssemblyPanel
@onready var tile_overlay = $TileOverlay

func setup(player, inventory: Inventory, enemies_node: Node2D, track: Node2D) -> void:
	enemy_card_overlay.setup(enemies_node)
	inventory_panel.setup(player, inventory)
	rule_assembly_panel.setup(player, inventory)
	tile_overlay.setup(track, player, inventory)
	tile_overlay.strip_damage_handler = func(amount: float): player.receive_damage(amount)

func update_hp(current: float, maximum: float) -> void:
	hp_bar.max_value = maximum
	hp_bar.value = current
	hp_label.text = "HP: %d / %d" % [int(current), int(maximum)]

func set_paused(paused: bool) -> void:
	pause_label.visible = paused
	enemy_card_overlay.visible = paused
	inventory_panel.visible = paused
	rule_assembly_panel.visible = paused
	tile_overlay.set_paused(paused)
```

Wait — the strip damage for tile harvesting should be handled in InventoryPanel (which already receives `player_ref` after Task 8). The `strip_damage_handler` lambda above is not needed. Remove that line. The correct HUD.gd is:

```gdscript
class_name HUD
extends CanvasLayer

const Inventory = preload("res://scripts/systems/Inventory.gd")

@onready var hp_bar: ProgressBar = $HPBar
@onready var hp_label: Label = $HPLabel
@onready var pause_label: Label = $PauseLabel
@onready var enemy_card_overlay = $EnemyCardOverlay
@onready var inventory_panel = $InventoryPanel
@onready var rule_assembly_panel = $RuleAssemblyPanel
@onready var tile_overlay = $TileOverlay

func setup(player, inventory: Inventory, enemies_node: Node2D, track: Node2D) -> void:
	enemy_card_overlay.setup(enemies_node)
	inventory_panel.setup(player, inventory)
	rule_assembly_panel.setup(player, inventory)
	tile_overlay.setup(track, player, inventory)

func update_hp(current: float, maximum: float) -> void:
	hp_bar.max_value = maximum
	hp_bar.value = current
	hp_label.text = "HP: %d / %d" % [int(current), int(maximum)]

func set_paused(paused: bool) -> void:
	pause_label.visible = paused
	enemy_card_overlay.visible = paused
	inventory_panel.visible = paused
	rule_assembly_panel.visible = paused
	tile_overlay.set_paused(paused)
```

- [ ] **Step 3: Add TileOverlay node to HUD.tscn**

Use `mcp__godot__open_scene` to open `res://scenes/ui/HUD.tscn`, then `mcp__godot__create_node` to add a TileOverlay node as a child of the HUD root, with script `res://scenes/ui/TileOverlay.gd` or by instantiating `TileOverlay.tscn`. Then save with `mcp__godot__save_scene`.

- [ ] **Step 4: Validate**

```bash
"S:/Godot_v4.6.2-stable_mono_win64/Godot_v4.6.2-stable_mono_win64.exe" --path "S:/attribute-loop" --headless --quit
```

Expected: exit code 0, no ERROR lines.

- [ ] **Step 5: Commit**

```bash
git add scenes/ui/HUD.gd scenes/ui/HUD.tscn
git commit -m "feat: HUD wires TileOverlay, setup() passes track + player, set_paused drives overlay"
```

---

## Task 12: Seed on_pass + boost_speed Components for Testing

**Files:**
- Modify: `scenes/main/Main.gd`

- [ ] **Step 1: Add `_make_tile_boost_components()` to Main and seed a second tile**

Add this method to Main.gd:

```gdscript
func _make_tile_boost_components() -> Array[EntryComponent]:
	var trigger := EntryComponent.new()
	trigger.slot_type = EntryComponent.SlotType.TRIGGER
	trigger.label = "经过时"
	trigger.data = {"event": "on_pass"}

	var effect := EntryComponent.new()
	effect.slot_type = EntryComponent.SlotType.EFFECT
	effect.label = "加速"
	effect.data = {"type": "boost_speed"}

	return [trigger, effect]
```

Update `_seed_initial_tiles()` to also seed tile index 6 with boost_speed:

```gdscript
func _seed_initial_tiles() -> void:
	if track.tiles.size() < 7:
		return
	var heal_comps = _make_tile_components()
	var tile0 = track.tiles[0] as Tile
	for comp in heal_comps:
		tile0.add_component(comp)
	tile0.pass_count = 3

	var boost_comps = _make_tile_boost_components()
	var tile6 = track.tiles[6] as Tile
	for comp in boost_comps:
		tile6.add_component(comp)
	tile6.pass_count = 0

	Log.info("seeded tile 0 (heal, harvestable) + tile 6 (boost_speed, accumulating)", "Main")
```

- [ ] **Step 2: Validate**

```bash
"S:/Godot_v4.6.2-stable_mono_win64/Godot_v4.6.2-stable_mono_win64.exe" --path "S:/attribute-loop" --headless --quit
```

- [ ] **Step 3: Run the game and verify**

```bash
"S:/Godot_v4.6.2-stable_mono_win64/Godot_v4.6.2-stable_mono_win64.exe" --path "S:/attribute-loop"
```

Verify:
- Tile dots appear along the track (dim, lit, gold states visible)
- Press Space to pause — nearby tile shows cards
- Tile 0 (gold) shows harvestable cards — drag to inventory takes HP
- Player walks through tile 0, HP restores (after harvest_threshold=3)
- Enemy dies → components appear on nearest tile dot
- Stripping enemy component costs 5 HP

- [ ] **Step 4: Commit**

```bash
git add scenes/main/Main.gd
git commit -m "feat: seed two test tiles (heal+harvestable, boost_speed+accumulating) for verification"
```

---

## Self-Review Checklist

**Spec coverage:**
- [x] Tile Resource with track_t, components, pass_count, harvest_threshold — Task 1
- [x] Track generates tiles via tile_count export — Task 2
- [x] Inventory capacity limit — Task 3
- [x] Enemy strip retaliation 5 HP — Task 4
- [x] Last-component final attack + empty shell — Task 4
- [x] Enemy death → tile component transfer — Task 6
- [x] Player tile tracking (once per boundary crossing) — Task 6
- [x] pass_count increments on enter — Task 6
- [x] Tile trigger: on_pass + effect scales with multiplier — Task 6
- [x] heal, boost_speed, deal_damage_nearby effects — Task 6
- [x] Player → Tile investment via TileSlot drop target — Task 9
- [x] Tile → Player harvest (threshold required, harvest cost) — Task 8 + 10
- [x] TileOverlay dot indicators (4 states) — Task 10
- [x] Component cards in pause for ±1 tile — Task 10
- [x] HUD set_paused drives TileOverlay — Task 11
- [x] on_pass trigger component + new effect types — Task 12

**Type consistency:**
- `Tile.strip_component(comp)` used in InventoryPanel (Task 8), RuleSlot (Task 8), TileOverlay (Task 10) — all consistent.
- `tile.pass_count`, `tile.harvest_threshold`, `tile.components`, `tile.MAX_COMPONENTS` — all defined in Task 1.
- `track.tiles`, `track.get_tile_index_for_t(t)` — defined in Task 2, used in Task 6 and Task 10.
- `player.receive_heal(amount)`, `player.apply_speed_boost(mult)` — defined in Task 5, used in Task 6.
- `ComponentCard.setup(comp, enemy, tile, is_draggable)` — defined in Task 7, used in Tasks 8 and 10.
- `InventoryPanel.setup(player, inventory)` — defined in Task 8, called in HUD Task 11. ✓
- `HUD.setup(player, inventory, enemies_node, track)` — defined in Task 11, called in Main Task 6. ✓
