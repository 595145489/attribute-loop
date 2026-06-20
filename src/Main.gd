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
	if GameState.difficulty == "easy":
		GameState.apply_easy_player_slots()
		DataTables.apply_easy_tile_rules(_tiles)
	player.setup(player_follow, track)
	game_loop.setup(_tiles, enemies_container, player, combat_system)
	strip_manager.setup(_strip_panel)
	_strip_panel.setup(_inventory_panel)
	_hud.setup(_inventory_panel)
	_hud.setup_altar(_altar_panel, _tiles[0])
	rule_engine.set_tiles(_tiles)
	combat_system.rule_engine = rule_engine
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
	var player_local = to_local(player.global_position)
	for tile in tiles_container.get_children():
		if tile.has_enemy() and player_local.distance_to(tile.guard_position) < 70.0:
			game_loop.check_tile_for_enemy(tile)
			return
		if not tile.has_enemy() and player_local.distance_to(tile.position) < 55.0:
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
		tile.combat_count = 0
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
