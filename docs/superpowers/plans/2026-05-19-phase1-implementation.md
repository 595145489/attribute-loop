# Phase 1 — 可行走的世界 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a playable loop where the player auto-walks a rectangular track, encounters enemies, fights automatically, and can die — with all balance values driven by data files.

**Architecture:** Three autoloads (EventBus, GameState, DataTables) provide global state and signals. Game logic lives in scene-node systems (GameLoop, CombatSystem) under main.tscn. All balance numbers are in .tres Resource files under data/; no magic numbers in scripts.

**Tech Stack:** Godot 4.6 GDScript, GUT v9.6.0 for unit tests, Godot MCP for scene/editor operations.

---

## File Map

**New — src/autoloads/**
- `EventBus.gd` — global signal hub
- `GameState.gd` — runtime state (hp, loops, phase, is_paused)
- `DataTables.gd` — loads and caches all .tres files

**New — src/resources/**
- `GameConfig.gd` — Resource class: formula coefficients
- `PlayerData.gd` — Resource class: player base stats
- `EnemyData.gd` — Resource class: enemy definition
- `PhaseData.gd` — Resource class: phase config and spawn table

**New — src/entities/**
- `Player.gd` — PathFollow2D movement, loop detection
- `Enemy.gd` — data-driven init, hp tracking
- `Tile.gd` — tile position holder, enemy slot

**New — src/systems/**
- `GameLoop.gd` — walking/combat/gameover state machine + spawn logic
- `CombatSystem.gd` — auto-attack rounds, damage application

**New — src/ui/**
- `HUD.gd` — updates HP / loops / phase labels
- `GameOver.gd` — displays stats, handles restart

**New — scenes/**
- `main.tscn` — root scene
- `entities/player.tscn`, `entities/enemy.tscn`, `entities/tile.tscn`
- `ui/hud.tscn`, `ui/game_over.tscn`

**New — data/**
- `game_config.tres`, `player_data.tres`
- `enemies/enemy_汲取者.tres`, `enemy_守卫者.tres`, `enemy_急袭者.tres`, `enemy_复制者.tres`, `enemy_先驱者.tres`
- `phases/phase_1.tres` … `phase_10.tres`

**New — tests/unit/**
- `test_event_bus.gd`, `test_game_state.gd`, `test_data_tables.gd`
- `test_combat_system.gd`, `test_game_loop.gd`

**Modified:**
- `project.godot` — add GameState, EventBus, DataTables autoload entries

---

## Task 1: Project Scaffolding

**Files:**
- Modify: `project.godot`

- [ ] **Step 1: Create source directories**

```powershell
New-Item -ItemType Directory -Force "S:/attribute-loop/src/resources"
New-Item -ItemType Directory -Force "S:/attribute-loop/src/systems"
New-Item -ItemType Directory -Force "S:/attribute-loop/scenes/entities"
New-Item -ItemType Directory -Force "S:/attribute-loop/scenes/ui"
New-Item -ItemType Directory -Force "S:/attribute-loop/data/enemies"
New-Item -ItemType Directory -Force "S:/attribute-loop/data/phases"
New-Item -ItemType Directory -Force "S:/attribute-loop/tests/unit"
```

- [ ] **Step 2: Register autoloads in project.godot**

Find the `[autoload]` section and add three lines after the existing `TestHelper` entry:

```ini
[autoload]

TestHelper="*res://src/autoloads/TestHelper.gd"
EventBus="*res://src/autoloads/EventBus.gd"
GameState="*res://src/autoloads/GameState.gd"
DataTables="*res://src/autoloads/DataTables.gd"
```

- [ ] **Step 3: Commit**

```bash
git add project.godot
git commit -m "chore: register EventBus, GameState, DataTables autoloads"
```

---

## Task 2: EventBus

**Files:**
- Create: `src/autoloads/EventBus.gd`
- Create: `tests/unit/test_event_bus.gd`

- [ ] **Step 1: Write the failing test**

`tests/unit/test_event_bus.gd`:
```gdscript
extends GutTest

func test_has_enemy_killed_signal() -> void:
    assert_true(EventBus.has_signal("enemy_killed"))

func test_has_combat_resolved_signal() -> void:
    assert_true(EventBus.has_signal("combat_resolved"))

func test_has_loop_completed_signal() -> void:
    assert_true(EventBus.has_signal("loop_completed"))

func test_has_player_died_signal() -> void:
    assert_true(EventBus.has_signal("player_died"))

func test_enemy_killed_emits_with_id() -> void:
    watch_signals(EventBus)
    EventBus.enemy_killed.emit("汲取者")
    assert_signal_emitted_with_parameters(EventBus, "enemy_killed", ["汲取者"])
```

- [ ] **Step 2: Run test — expect failure**

```powershell
cd "S:/attribute-loop"; powershell -NoProfile -File scripts/self-test.ps1
```

Expected: errors about EventBus not existing.

- [ ] **Step 3: Implement EventBus**

`src/autoloads/EventBus.gd`:
```gdscript
extends Node

signal enemy_killed(enemy_id: String)
signal combat_resolved
signal loop_completed
signal player_died
```

- [ ] **Step 4: Run test — expect pass**

```powershell
cd "S:/attribute-loop"; powershell -NoProfile -File scripts/self-test.ps1
```

Expected: all 5 tests pass.

- [ ] **Step 5: Commit**

```bash
git add src/autoloads/EventBus.gd tests/unit/test_event_bus.gd
git commit -m "feat: add EventBus autoload with Phase 1 signals"
```

---

## Task 3: GameState

**Files:**
- Create: `src/autoloads/GameState.gd`
- Create: `tests/unit/test_game_state.gd`

- [ ] **Step 1: Write the failing test**

`tests/unit/test_game_state.gd`:
```gdscript
extends GutTest

func before_each() -> void:
    GameState.reset()

func test_initial_hp_equals_hp_max() -> void:
    assert_eq(GameState.hp, GameState.hp_max)

func test_hp_max_is_positive() -> void:
    assert_gt(GameState.hp_max, 0)

func test_take_damage_reduces_hp() -> void:
    var before = GameState.hp
    GameState.take_damage(10)
    assert_eq(GameState.hp, before - 10)

func test_take_damage_clamps_to_zero() -> void:
    GameState.take_damage(GameState.hp_max + 999)
    assert_eq(GameState.hp, 0)

func test_take_damage_emits_player_died_when_hp_zero() -> void:
    watch_signals(EventBus)
    GameState.take_damage(GameState.hp_max + 999)
    assert_signal_emitted(EventBus, "player_died")

func test_reset_restores_hp() -> void:
    GameState.take_damage(50)
    GameState.reset()
    assert_eq(GameState.hp, GameState.hp_max)

func test_reset_clears_loops_and_kills() -> void:
    GameState.loops_completed = 5
    GameState.enemies_killed = 10
    GameState.reset()
    assert_eq(GameState.loops_completed, 0)
    assert_eq(GameState.enemies_killed, 0)

func test_is_paused_defaults_false() -> void:
    assert_false(GameState.is_paused)
```

- [ ] **Step 2: Run test — expect failure**

```powershell
cd "S:/attribute-loop"; powershell -NoProfile -File scripts/self-test.ps1
```

- [ ] **Step 3: Implement GameState**

`src/autoloads/GameState.gd`:
```gdscript
extends Node

var hp: int
var hp_max: int = 100
var loops_completed: int = 0
var enemies_killed: int = 0
var current_phase: int = 1
var is_paused: bool = false

func _ready() -> void:
    reset()

func take_damage(amount: int) -> void:
    hp = max(0, hp - amount)
    if hp == 0:
        EventBus.player_died.emit()

func reset() -> void:
    hp = hp_max
    loops_completed = 0
    enemies_killed = 0
    current_phase = 1
    is_paused = false
```

- [ ] **Step 4: Run test — expect pass**

```powershell
cd "S:/attribute-loop"; powershell -NoProfile -File scripts/self-test.ps1
```

- [ ] **Step 5: Commit**

```bash
git add src/autoloads/GameState.gd tests/unit/test_game_state.gd
git commit -m "feat: add GameState autoload with HP, loops, phase fields"
```

---

## Task 4: Resource Class Definitions

**Files:**
- Create: `src/resources/GameConfig.gd`
- Create: `src/resources/PlayerData.gd`
- Create: `src/resources/EnemyData.gd`
- Create: `src/resources/PhaseData.gd`

No tests needed — these are pure data class declarations.

- [ ] **Step 1: Write GameConfig**

`src/resources/GameConfig.gd`:
```gdscript
class_name GameConfig
extends Resource

# stat = base × (1 + (phase - 1) × stat_scale_factor)
@export var stat_scale_factor: float = 0.3
```

- [ ] **Step 2: Write PlayerData**

`src/resources/PlayerData.gd`:
```gdscript
class_name PlayerData
extends Resource

@export var hp_base: int = 100
@export var dmg_base: int = 15
@export var attack_interval: float = 0.8   # seconds between player attacks
@export var walk_speed: float = 120.0      # pixels per second along path
```

- [ ] **Step 3: Write EnemyData**

`src/resources/EnemyData.gd`:
```gdscript
class_name EnemyData
extends Resource

@export var id: String = ""
@export var hp_base: int = 0
@export var dmg_base: int = 0
@export var gold_min: int = 0
@export var gold_max: int = 0
@export var unlock_phase: int = 1
@export var attack_interval: float = 1.0   # seconds between this enemy's attacks
```

- [ ] **Step 4: Write PhaseData**

`src/resources/PhaseData.gd`:
```gdscript
class_name PhaseData
extends Resource

@export var phase_id: int = 1
@export var phase_name: String = ""
@export var altar_requirement: int = 0
@export var world_pressure_window: int = 10     # loops before forced advance
@export var spawn_count_min: int = 1
@export var spawn_count_max: int = 3
## Keys: enemy id (String), Values: weight (int). Normalised at runtime.
@export var spawn_weights: Dictionary = {}
@export var enemy_component_count_min: int = 1
@export var enemy_component_count_max: int = 2
```

- [ ] **Step 5: Commit**

```bash
git add src/resources/
git commit -m "feat: add Resource class definitions (GameConfig, PlayerData, EnemyData, PhaseData)"
```

---

## Task 5: Data Files

**Files:**
- Create: `data/game_config.tres`, `data/player_data.tres`
- Create: `data/enemies/enemy_*.tres` (5 files)
- Create: `data/phases/phase_*.tres` (10 files)

All files are created via `mcp__godot__execute_editor_script` so Godot handles serialisation correctly. The editor must be open for these steps.

- [ ] **Step 1: Create game_config.tres and player_data.tres**

Execute in editor:
```gdscript
var cfg = GameConfig.new()
cfg.stat_scale_factor = 0.3
ResourceSaver.save(cfg, "res://data/game_config.tres")

var pd = PlayerData.new()
pd.hp_base = 100
pd.dmg_base = 15
pd.attack_interval = 0.8
pd.walk_speed = 120.0
ResourceSaver.save(pd, "res://data/player_data.tres")
print("OK: game_config + player_data saved")
```

- [ ] **Step 2: Create enemy data files**

Execute in editor:
```gdscript
var enemies = [
    {id="汲取者", hp=40,  dmg=8,  g_min=5,  g_max=15, phase=1, interval=0.8},
    {id="守卫者", hp=80,  dmg=16, g_min=5,  g_max=15, phase=1, interval=1.2},
    {id="急袭者", hp=25,  dmg=10, g_min=20, g_max=50, phase=4, interval=0.4},
    {id="复制者", hp=50,  dmg=12, g_min=20, g_max=50, phase=7, interval=0.6},
    {id="先驱者", hp=100, dmg=20, g_min=20, g_max=50, phase=10, interval=0.8},
]
for e in enemies:
    var ed = EnemyData.new()
    ed.id = e.id
    ed.hp_base = e.hp
    ed.dmg_base = e.dmg
    ed.gold_min = e.g_min
    ed.gold_max = e.g_max
    ed.unlock_phase = e.phase
    ed.attack_interval = e.interval
    ResourceSaver.save(ed, "res://data/enemies/enemy_%s.tres" % e.id)
print("OK: 5 enemy files saved")
```

- [ ] **Step 3: Create phase data files**

Execute in editor:
```gdscript
var phases = [
    {id=1,  name="觉醒",    altar=2,  pressure=10, s_min=1, s_max=3, weights={"汲取者":50,"守卫者":50},              comp_min=1, comp_max=2},
    {id=2,  name="萌动",    altar=3,  pressure=9,  s_min=1, s_max=3, weights={"汲取者":45,"守卫者":45},              comp_min=1, comp_max=2},
    {id=3,  name="涌动",    altar=4,  pressure=8,  s_min=2, s_max=4, weights={"汲取者":45,"守卫者":45},              comp_min=2, comp_max=3},
    {id=4,  name="侵蚀",    altar=5,  pressure=7,  s_min=2, s_max=4, weights={"汲取者":40,"守卫者":40,"急袭者":20},  comp_min=2, comp_max=3},
    {id=5,  name="失衡",    altar=6,  pressure=6,  s_min=2, s_max=4, weights={"汲取者":35,"守卫者":35,"急袭者":30},  comp_min=3, comp_max=4},
    {id=6,  name="碰撞",    altar=7,  pressure=5,  s_min=2, s_max=4, weights={"汲取者":30,"守卫者":30,"急袭者":40},  comp_min=3, comp_max=4},
    {id=7,  name="觉醒II",  altar=8,  pressure=4,  s_min=2, s_max=5, weights={"汲取者":25,"守卫者":25,"急袭者":30,"复制者":20}, comp_min=4, comp_max=5},
    {id=8,  name="压制",    altar=9,  pressure=3,  s_min=2, s_max=5, weights={"汲取者":20,"守卫者":20,"急袭者":30,"复制者":30}, comp_min=4, comp_max=5},
    {id=9,  name="律法",    altar=10, pressure=2,  s_min=3, s_max=5, weights={"汲取者":15,"守卫者":15,"急袭者":30,"复制者":40}, comp_min=5, comp_max=6},
    {id=10, name="裁决前夜", altar=12, pressure=1,  s_min=3, s_max=5, weights={"汲取者":10,"守卫者":10,"急袭者":20,"复制者":30,"先驱者":30}, comp_min=5, comp_max=6},
]
for p in phases:
    var pd = PhaseData.new()
    pd.phase_id = p.id
    pd.phase_name = p.name
    pd.altar_requirement = p.altar
    pd.world_pressure_window = p.pressure
    pd.spawn_count_min = p.s_min
    pd.spawn_count_max = p.s_max
    pd.spawn_weights = p.weights
    pd.enemy_component_count_min = p.comp_min
    pd.enemy_component_count_max = p.comp_max
    ResourceSaver.save(pd, "res://data/phases/phase_%d.tres" % p.id)
print("OK: 10 phase files saved")
```

- [ ] **Step 4: Commit**

```bash
git add data/
git commit -m "feat: add all data .tres files (game_config, player, 5 enemies, 10 phases)"
```

---

## Task 6: DataTables

**Files:**
- Create: `src/autoloads/DataTables.gd`
- Create: `tests/unit/test_data_tables.gd`

- [ ] **Step 1: Write the failing test**

`tests/unit/test_data_tables.gd`:
```gdscript
extends GutTest

func test_game_config_loaded() -> void:
    assert_not_null(DataTables.config)
    assert_gt(DataTables.config.stat_scale_factor, 0.0)

func test_player_data_loaded() -> void:
    assert_not_null(DataTables.player)
    assert_gt(DataTables.player.hp_base, 0)
    assert_gt(DataTables.player.walk_speed, 0.0)

func test_enemy_data_has_all_five_types() -> void:
    assert_true(DataTables.enemies.has("汲取者"))
    assert_true(DataTables.enemies.has("守卫者"))
    assert_true(DataTables.enemies.has("急袭者"))
    assert_true(DataTables.enemies.has("复制者"))
    assert_true(DataTables.enemies.has("先驱者"))

func test_enemy_data_values_valid() -> void:
    var e: EnemyData = DataTables.enemies["汲取者"]
    assert_gt(e.hp_base, 0)
    assert_gt(e.dmg_base, 0)
    assert_gt(e.attack_interval, 0.0)

func test_all_ten_phases_loaded() -> void:
    for i in range(1, 11):
        assert_true(DataTables.phases.has(i), "Missing phase %d" % i)

func test_phase_data_values_valid() -> void:
    var p: PhaseData = DataTables.phases[1]
    assert_eq(p.phase_id, 1)
    assert_gt(p.spawn_count_max, 0)
    assert_false(p.spawn_weights.is_empty())

func test_get_phase_returns_correct_data() -> void:
    var p = DataTables.get_phase(3)
    assert_eq(p.phase_id, 3)

func test_get_enemy_returns_correct_data() -> void:
    var e = DataTables.get_enemy("守卫者")
    assert_eq(e.id, "守卫者")
```

- [ ] **Step 2: Run test — expect failure**

```powershell
cd "S:/attribute-loop"; powershell -NoProfile -File scripts/self-test.ps1
```

- [ ] **Step 3: Implement DataTables**

`src/autoloads/DataTables.gd`:
```gdscript
extends Node

var config: GameConfig
var player: PlayerData
var enemies: Dictionary = {}   # String → EnemyData
var phases: Dictionary = {}    # int → PhaseData

func _ready() -> void:
    config = load("res://data/game_config.tres")
    player = load("res://data/player_data.tres")
    _load_enemies()
    _load_phases()

func _load_enemies() -> void:
    var ids = ["汲取者", "守卫者", "急袭者", "复制者", "先驱者"]
    for id in ids:
        enemies[id] = load("res://data/enemies/enemy_%s.tres" % id)

func _load_phases() -> void:
    for i in range(1, 11):
        phases[i] = load("res://data/phases/phase_%d.tres" % i)

func get_enemy(id: String) -> EnemyData:
    return enemies[id]

func get_phase(phase_id: int) -> PhaseData:
    return phases[phase_id]

func calc_stat(base: int, phase: int) -> int:
    return int(base * (1.0 + (phase - 1) * config.stat_scale_factor))
```

- [ ] **Step 4: Run test — expect pass**

```powershell
cd "S:/attribute-loop"; powershell -NoProfile -File scripts/self-test.ps1
```

- [ ] **Step 5: Commit**

```bash
git add src/autoloads/DataTables.gd tests/unit/test_data_tables.gd
git commit -m "feat: add DataTables autoload — loads and caches all .tres data"
```

---

## Task 7: Tile Scene

**Files:**
- Create: `src/entities/Tile.gd`
- Create: `scenes/entities/tile.tscn`

- [ ] **Step 1: Write Tile script**

`src/entities/Tile.gd`:
```gdscript
class_name Tile
extends Node2D

var tile_index: int = 0
var enemy: Enemy = null   # null when tile is unoccupied

func has_enemy() -> bool:
    return enemy != null

func place_enemy(e: Enemy) -> void:
    enemy = e

func clear_enemy() -> void:
    enemy = null
```

- [ ] **Step 2: Create tile.tscn via MCP**

Use `mcp__godot__create_scene` to create `scenes/entities/tile.tscn` with:
- Root node: `Node2D` named `Tile`, script = `res://src/entities/Tile.gd`
- Child: `ColorRect` named `Visual`, size = `Vector2(24, 24)`, offset = `Vector2(-12, -12)`, color = `Color(0.3, 0.5, 0.8)`

- [ ] **Step 3: Commit**

```bash
git add src/entities/Tile.gd scenes/entities/tile.tscn
git commit -m "feat: add Tile scene — track position holder with enemy slot"
```

---

## Task 8: Player Scene & Auto-Walk

**Files:**
- Create: `src/entities/Player.gd`
- Create: `scenes/entities/player.tscn`

- [ ] **Step 1: Write Player script**

`src/entities/Player.gd`:
```gdscript
class_name Player
extends Node2D

var _path_follow: PathFollow2D
var _walk_speed: float = 0.0
var _path_length: float = 0.0
var _loop_count: int = 0

func setup(path_follow: PathFollow2D, path: Path2D) -> void:
    _path_follow = path_follow
    _walk_speed = DataTables.player.walk_speed
    _path_length = path.curve.get_baked_length()

func _process(delta: float) -> void:
    if GameState.is_paused:
        return
    _path_follow.progress += _walk_speed * delta
    var new_loop = int(_path_follow.progress / _path_length)
    if new_loop > _loop_count:
        _loop_count = new_loop
        GameState.loops_completed += 1
        EventBus.loop_completed.emit()
```

- [ ] **Step 2: Create player.tscn via MCP**

Use `mcp__godot__create_scene` to create `scenes/entities/player.tscn` with:
- Root node: `Node2D` named `Player`, script = `res://src/entities/Player.gd`
- Child: `ColorRect` named `Visual`, size = `Vector2(20, 20)`, offset = `Vector2(-10, -10)`, color = `Color(0.95, 0.53, 0.24)` (orange)

- [ ] **Step 3: Commit**

```bash
git add src/entities/Player.gd scenes/entities/player.tscn
git commit -m "feat: add Player scene — PathFollow2D auto-walk with loop detection"
```

---

## Task 9: Enemy Scene

**Files:**
- Create: `src/entities/Enemy.gd`
- Create: `scenes/entities/enemy.tscn`

- [ ] **Step 1: Write Enemy script**

`src/entities/Enemy.gd`:
```gdscript
class_name Enemy
extends Node2D

var enemy_id: String = ""
var hp: int = 0
var hp_max: int = 0
var dmg: int = 0
var attack_interval: float = 1.0

func init(id: String) -> void:
    enemy_id = id
    var data: EnemyData = DataTables.get_enemy(id)
    var phase = GameState.current_phase
    hp_max = DataTables.calc_stat(data.hp_base, phase)
    hp = hp_max
    dmg = DataTables.calc_stat(data.dmg_base, phase)
    attack_interval = data.attack_interval

func take_damage(amount: int) -> void:
    hp = max(0, hp - amount)

func is_dead() -> bool:
    return hp <= 0
```

- [ ] **Step 2: Create enemy.tscn via MCP**

Use `mcp__godot__create_scene` to create `scenes/entities/enemy.tscn` with:
- Root node: `Node2D` named `Enemy`, script = `res://src/entities/Enemy.gd`
- Child: `ColorRect` named `Visual`, size = `Vector2(24, 24)`, offset = `Vector2(-12, -12)`, color = `Color(0.8, 0.2, 0.2)` (red)

- [ ] **Step 3: Commit**

```bash
git add src/entities/Enemy.gd scenes/entities/enemy.tscn
git commit -m "feat: add Enemy scene — data-driven init with phase-scaled stats"
```

---

## Task 10: CombatSystem

**Files:**
- Create: `src/systems/CombatSystem.gd`
- Create: `tests/unit/test_combat_system.gd`

- [ ] **Step 1: Write the failing test**

`tests/unit/test_combat_system.gd`:
```gdscript
extends GutTest

var combat: CombatSystem

func before_each() -> void:
    GameState.reset()
    combat = CombatSystem.new()
    add_child_autofree(combat)

func test_player_damage_reduces_enemy_hp() -> void:
    var enemy = Enemy.new()
    enemy.init("汲取者")
    var hp_before = enemy.hp
    combat._apply_player_attack(enemy)
    assert_lt(enemy.hp, hp_before)

func test_enemy_damage_reduces_player_hp() -> void:
    var enemy = Enemy.new()
    enemy.init("汲取者")
    var hp_before = GameState.hp
    combat._apply_enemy_attack(enemy)
    assert_lt(GameState.hp, hp_before)

func test_player_damage_uses_player_dmg_base() -> void:
    var enemy = Enemy.new()
    enemy.init("汲取者")
    var hp_before = enemy.hp
    combat._apply_player_attack(enemy)
    assert_eq(enemy.hp, hp_before - DataTables.player.dmg_base)

func test_enemy_damage_uses_phase_scaled_dmg() -> void:
    var enemy = Enemy.new()
    enemy.init("汲取者")
    var expected_dmg = DataTables.calc_stat(DataTables.get_enemy("汲取者").dmg_base, 1)
    assert_eq(enemy.dmg, expected_dmg)

func test_combat_resolved_emitted_when_enemy_dies() -> void:
    watch_signals(EventBus)
    var enemy = Enemy.new()
    enemy.init("汲取者")
    enemy.hp = 1
    combat._apply_player_attack(enemy)
    assert_signal_emitted(EventBus, "combat_resolved")
```

- [ ] **Step 2: Run test — expect failure**

```powershell
cd "S:/attribute-loop"; powershell -NoProfile -File scripts/self-test.ps1
```

- [ ] **Step 3: Implement CombatSystem**

`src/systems/CombatSystem.gd`:
```gdscript
class_name CombatSystem
extends Node

var _player_timer: Timer
var _enemy_timer: Timer
var _active_enemy: Enemy = null
var _enemies_container: Node

func _ready() -> void:
    _player_timer = Timer.new()
    _player_timer.one_shot = false
    _player_timer.timeout.connect(_on_player_attack)
    add_child(_player_timer)

    _enemy_timer = Timer.new()
    _enemy_timer.one_shot = false
    _enemy_timer.timeout.connect(_on_enemy_attack)
    add_child(_enemy_timer)

func start(enemy: Enemy) -> void:
    _active_enemy = enemy
    _player_timer.wait_time = DataTables.player.attack_interval
    _enemy_timer.wait_time = enemy.attack_interval
    _player_timer.start()
    _enemy_timer.start()

func stop() -> void:
    _player_timer.stop()
    _enemy_timer.stop()
    _active_enemy = null

func _on_player_attack() -> void:
    if _active_enemy == null:
        return
    _apply_player_attack(_active_enemy)
    if _active_enemy.is_dead():
        _finish_combat()

func _on_enemy_attack() -> void:
    if _active_enemy == null:
        return
    _apply_enemy_attack(_active_enemy)

func _apply_player_attack(enemy: Enemy) -> void:
    enemy.take_damage(DataTables.player.dmg_base)

func _apply_enemy_attack(enemy: Enemy) -> void:
    GameState.take_damage(enemy.dmg)

func _finish_combat() -> void:
    stop()
    GameState.enemies_killed += 1
    EventBus.enemy_killed.emit(_active_enemy.enemy_id)
    EventBus.combat_resolved.emit()
```

- [ ] **Step 4: Run test — expect pass**

```powershell
cd "S:/attribute-loop"; powershell -NoProfile -File scripts/self-test.ps1
```

- [ ] **Step 5: Commit**

```bash
git add src/systems/CombatSystem.gd tests/unit/test_combat_system.gd
git commit -m "feat: add CombatSystem — auto-attack rounds with timer-driven damage"
```

---

## Task 11: GameLoop — Spawner & State Machine

**Files:**
- Create: `src/systems/GameLoop.gd`
- Create: `tests/unit/test_game_loop.gd`

- [ ] **Step 1: Write the failing test**

`tests/unit/test_game_loop.gd`:
```gdscript
extends GutTest

func test_roll_spawn_count_within_range() -> void:
    var phase: PhaseData = DataTables.get_phase(1)
    for i in 100:
        var count = GameLoop._roll_spawn_count(phase)
        assert_gte(count, phase.spawn_count_min)
        assert_lte(count, phase.spawn_count_max)

func test_pick_enemy_id_only_unlocked() -> void:
    var phase: PhaseData = DataTables.get_phase(1)
    for i in 50:
        var id = GameLoop._pick_enemy_id(phase, 1)
        var enemy_data: EnemyData = DataTables.get_enemy(id)
        assert_lte(enemy_data.unlock_phase, 1)

func test_pick_enemy_id_from_weights() -> void:
    var phase: PhaseData = DataTables.get_phase(1)
    var id = GameLoop._pick_enemy_id(phase, 1)
    assert_true(id == "汲取者" or id == "守卫者")

func test_pick_distinct_tile_indices_correct_count() -> void:
    var indices = GameLoop._pick_tile_indices(3, 12)
    assert_eq(indices.size(), 3)

func test_pick_distinct_tile_indices_no_duplicates() -> void:
    var indices = GameLoop._pick_tile_indices(5, 12)
    var unique = {}
    for i in indices:
        unique[i] = true
    assert_eq(unique.size(), 5)
```

- [ ] **Step 2: Run test — expect failure**

```powershell
cd "S:/attribute-loop"; powershell -NoProfile -File scripts/self-test.ps1
```

- [ ] **Step 3: Implement GameLoop**

`src/systems/GameLoop.gd`:
```gdscript
class_name GameLoop
extends Node

enum State { WALKING, COMBAT, GAME_OVER }

var state: State = State.WALKING
var _tiles: Array = []          # Array[Tile]
var _enemies_container: Node
var _player: Player
var _combat_system: CombatSystem
var _enemy_scene: PackedScene = preload("res://scenes/entities/enemy.tscn")

func setup(tiles: Array, enemies_container: Node, player: Player, combat: CombatSystem) -> void:
    _tiles = tiles
    _enemies_container = enemies_container
    _player = player
    _combat_system = combat
    EventBus.loop_completed.connect(_on_loop_completed)
    EventBus.combat_resolved.connect(_on_combat_resolved)
    EventBus.player_died.connect(_on_player_died)
    spawn_enemies()

func spawn_enemies() -> void:
    # Clear existing enemies
    for child in _enemies_container.get_children():
        child.queue_free()
    for tile in _tiles:
        tile.clear_enemy()

    var phase_data: PhaseData = DataTables.get_phase(GameState.current_phase)
    var count = _roll_spawn_count(phase_data)
    var indices = _pick_tile_indices(count, _tiles.size())

    for idx in indices:
        var enemy_id = _pick_enemy_id(phase_data, GameState.current_phase)
        var enemy: Enemy = _enemy_scene.instantiate()
        _enemies_container.add_child(enemy)
        enemy.init(enemy_id)
        enemy.position = _tiles[idx].position
        _tiles[idx].place_enemy(enemy)

var _combat_tile: Tile = null

func check_tile_for_enemy(tile: Tile) -> void:
    if state != State.WALKING:
        return
    if not tile.has_enemy():
        return
    state = State.COMBAT
    GameState.is_paused = true
    _combat_tile = tile
    _combat_system.start(tile.enemy)

func _on_loop_completed() -> void:
    if state == State.WALKING:
        spawn_enemies()

func _on_combat_resolved() -> void:
    if _combat_tile != null:
        if _combat_tile.enemy != null:
            _combat_tile.enemy.queue_free()
        _combat_tile.clear_enemy()
        _combat_tile = null
    state = State.WALKING
    GameState.is_paused = false

func _on_player_died() -> void:
    state = State.GAME_OVER
    GameState.is_paused = true

## Pure functions used by tests

static func _roll_spawn_count(phase: PhaseData) -> int:
    return randi_range(phase.spawn_count_min, phase.spawn_count_max)

static func _pick_enemy_id(phase: PhaseData, current_phase: int) -> String:
    # Filter to unlocked enemies only
    var eligible: Dictionary = {}
    for id in phase.spawn_weights:
        var data: EnemyData = DataTables.get_enemy(id)
        if data.unlock_phase <= current_phase:
            eligible[id] = phase.spawn_weights[id]

    # Weighted random pick
    var total = 0
    for w in eligible.values():
        total += w
    var roll = randi_range(1, total)
    var acc = 0
    for id in eligible:
        acc += eligible[id]
        if roll <= acc:
            return id
    return eligible.keys()[0]

static func _pick_tile_indices(count: int, total: int) -> Array:
    var pool = range(total)
    pool.shuffle()
    return pool.slice(0, count)
```

- [ ] **Step 4: Run test — expect pass**

```powershell
cd "S:/attribute-loop"; powershell -NoProfile -File scripts/self-test.ps1
```

- [ ] **Step 5: Commit**

```bash
git add src/systems/GameLoop.gd tests/unit/test_game_loop.gd
git commit -m "feat: add GameLoop — state machine + data-driven enemy spawning"
```

---

## Task 12: HUD Scene

**Files:**
- Create: `src/ui/HUD.gd`
- Create: `scenes/ui/hud.tscn`

- [ ] **Step 1: Write HUD script**

`src/ui/HUD.gd`:
```gdscript
class_name HUD
extends CanvasLayer

@onready var hp_label: Label = $HPLabel
@onready var loops_label: Label = $LoopsLabel
@onready var phase_label: Label = $PhaseLabel

func _process(_delta: float) -> void:
    hp_label.text = "HP: %d / %d" % [GameState.hp, GameState.hp_max]
    loops_label.text = "Loops: %d" % GameState.loops_completed
    var phase_data: PhaseData = DataTables.get_phase(GameState.current_phase)
    phase_label.text = "Phase %d — %s" % [GameState.current_phase, phase_data.phase_name]
```

- [ ] **Step 2: Create hud.tscn via MCP**

Use `mcp__godot__create_scene` to create `scenes/ui/hud.tscn`:
- Root: `CanvasLayer` named `HUD`, script = `res://src/ui/HUD.gd`
- Child `VBoxContainer` (anchored top-left, position `Vector2(16, 16)`)
  - Child `Label` named `HPLabel`, text = `"HP: 100 / 100"`
  - Child `Label` named `LoopsLabel`, text = `"Loops: 0"`
  - Child `Label` named `PhaseLabel`, text = `"Phase 1 — 觉醒"`

- [ ] **Step 3: Commit**

```bash
git add src/ui/HUD.gd scenes/ui/hud.tscn
git commit -m "feat: add HUD scene — HP, loops, phase display"
```

---

## Task 13: GameOver Scene

**Files:**
- Create: `src/ui/GameOver.gd`
- Create: `scenes/ui/game_over.tscn`

- [ ] **Step 1: Write GameOver script**

`src/ui/GameOver.gd`:
```gdscript
class_name GameOver
extends CanvasLayer

@onready var loops_label: Label = $Panel/VBox/LoopsLabel
@onready var kills_label: Label = $Panel/VBox/KillsLabel
@onready var restart_button: Button = $Panel/VBox/RestartButton

func _ready() -> void:
    loops_label.text = "Loops survived: %d" % GameState.loops_completed
    kills_label.text = "Enemies killed: %d" % GameState.enemies_killed
    restart_button.pressed.connect(_on_restart)

func _on_restart() -> void:
    GameState.reset()
    get_tree().reload_current_scene()
```

- [ ] **Step 2: Create game_over.tscn via MCP**

Use `mcp__godot__create_scene` to create `scenes/ui/game_over.tscn`:
- Root: `CanvasLayer` named `GameOver`, script = `res://src/ui/GameOver.gd`
- Child `Panel` named `Panel` (anchored center, size `Vector2(320, 220)`, offset to center)
  - Child `VBoxContainer` named `VBox` (fill parent, separation=16, margin=24)
    - Child `Label` named `Title`, text = `"GAME OVER"`, horizontal_alignment = CENTER
    - Child `HSeparator`
    - Child `Label` named `LoopsLabel`, text = `"Loops survived: 0"`
    - Child `Label` named `KillsLabel`, text = `"Enemies killed: 0"`
    - Child `Button` named `RestartButton`, text = `"Restart"`

- [ ] **Step 3: Commit**

```bash
git add src/ui/GameOver.gd scenes/ui/game_over.tscn
git commit -m "feat: add GameOver scene — stats display + restart button"
```

---

## Task 14: Wire main.tscn

**Files:**
- Create: `scenes/main.tscn`

This task assembles all scenes into the playable game.

- [ ] **Step 1: Create main.tscn via MCP**

Use `mcp__godot__create_scene` to create `scenes/main.tscn`:

```
Node2D "Main"
├── Path2D "Track"
│   └── PathFollow2D "PlayerFollow"
│       └── [instance: scenes/entities/player.tscn] "Player"
├── Node2D "TilesContainer"
├── Node2D "EnemiesContainer"
├── CombatSystem "CombatSystem"  (script: res://src/systems/CombatSystem.gd)
├── GameLoop "GameLoop"           (script: res://src/systems/GameLoop.gd)
└── [instance: scenes/ui/hud.tscn] "HUD"
```

- [ ] **Step 2: Set up the rectangular Path2D curve via editor script**

Execute in editor (with main.tscn open):
```gdscript
var scene = get_tree().get_edited_scene_root()
var track = scene.get_node("Track")
var curve = Curve2D.new()
curve.add_point(Vector2(150, 120), Vector2.ZERO, Vector2.ZERO)
curve.add_point(Vector2(1130, 120), Vector2.ZERO, Vector2.ZERO)
curve.add_point(Vector2(1130, 580), Vector2.ZERO, Vector2.ZERO)
curve.add_point(Vector2(150, 580), Vector2.ZERO, Vector2.ZERO)
curve.closed = true
track.curve = curve
print("Track curve set")
```

- [ ] **Step 3: Create a Main script that wires everything at runtime**

`src/Main.gd`:
```gdscript
extends Node2D

const TILE_SCENE = preload("res://scenes/entities/tile.tscn")
const GAME_OVER_SCENE = preload("res://scenes/ui/game_over.tscn")

@onready var track: Path2D = $Track
@onready var player_follow: PathFollow2D = $Track/PlayerFollow
@onready var player: Player = $Track/PlayerFollow/Player
@onready var tiles_container: Node2D = $TilesContainer
@onready var enemies_container: Node2D = $EnemiesContainer
@onready var combat_system: CombatSystem = $CombatSystem
@onready var game_loop: GameLoop = $GameLoop

func _ready() -> void:
    var tiles = _build_tiles()
    player.setup(player_follow, track)
    game_loop.setup(tiles, enemies_container, player, combat_system)
    EventBus.player_died.connect(_on_player_died)

func _build_tiles() -> Array:
    var tiles: Array = []
    var curve = track.curve
    var length = curve.get_baked_length()
    for i in 12:
        var t = float(i) / 12.0
        var pos = curve.sample_baked(t * length)
        var tile: Tile = TILE_SCENE.instantiate()
        tile.position = pos
        tile.tile_index = i
        tiles_container.add_child(tile)
        tiles.append(tile)
    return tiles

func _process(_delta: float) -> void:
    if GameState.is_paused:
        return
    _check_player_tile()

func _check_player_tile() -> void:
    var player_pos = player.global_position
    for tile in tiles_container.get_children():
        if tile.has_enemy() and player_pos.distance_to(tile.global_position) < 30.0:
            game_loop.check_tile_for_enemy(tile)
            return

func _on_player_died() -> void:
    var go = GAME_OVER_SCENE.instantiate()
    add_child(go)
```

Attach `src/Main.gd` as the script on the root `Main` node of `main.tscn`.

- [ ] **Step 4: Set main scene in project settings**

Execute in editor:
```gdscript
ProjectSettings.set_setting("application/run/main_scene", "res://scenes/main.tscn")
ProjectSettings.save()
print("Main scene set")
```

- [ ] **Step 5: Run all unit tests**

```powershell
cd "S:/attribute-loop"; powershell -NoProfile -File scripts/self-test.ps1
```

Expected: all tests pass.

- [ ] **Step 6: Visual integration test (requires Godot editor open)**

Follow CLAUDE.md Step 3: create `tests/.test_mode`, run main scene via MCP, poll for screenshot, verify game window renders with orange player dot moving around a rectangular track with red enemy dots, HUD visible.

- [ ] **Step 7: Commit**

```bash
git add scenes/main.tscn src/Main.gd
git commit -m "feat: wire main.tscn — playable Phase 1 loop with track, player, enemies, combat"
```

---

## Task 15: Documentation

Per CLAUDE.md Step 4, after all tests pass write module docs.

- [ ] **Step 1: Write docs/modules/phase1-systems.md**

Cover: GameLoop, CombatSystem, Player movement, DataTables data flow, EventBus signal chain.

- [ ] **Step 2: Commit**

```bash
git add docs/modules/phase1-systems.md
git commit -m "docs: add Phase 1 systems module documentation"
```
