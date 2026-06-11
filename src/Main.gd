extends Node2D

const TILE_SCENE = preload("res://scenes/entities/tile.tscn")
const GAME_OVER_SCENE = preload("res://scenes/ui/game_over.tscn")
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
@onready var strip_panel: StripPanel = $UI/StripPanel
@onready var inventory_panel: InventoryPanel = $UI/InventoryPanel
@onready var tile_rule_panel = $UI/TileRulePanel
@onready var altar_panel = $UI/AltarPanel
@onready var hud: HUD = $UI/HUD
@onready var auction_manager = $Systems/AuctionManager
@onready var auction_panel = $UI/AuctionPanel
@onready var service_bar = $UI/ServiceBar
@onready var service_activate_popup = $UI/ServiceActivatePopup

var _initialized: bool = false
var _phase_transition: PhaseTransition
var _enemy_inspect: EnemyInspectPanel

func _ready() -> void:
	get_viewport().physics_object_picking = true
	await Enemy.preload_all_async(get_tree())
	var tiles = _build_tiles()
	player.setup(player_follow, track)
	game_loop.setup(tiles, enemies_container, player, combat_system)
	strip_manager.setup(strip_panel)
	strip_panel.setup(inventory_panel)
	hud.setup(inventory_panel)
	hud.setup_altar(altar_panel, tiles[0])
	rule_engine.set_tiles(tiles)
	game_loop.setup_auction(auction_manager)
	auction_panel.setup(auction_manager)
	service_activate_popup.setup(auction_manager, tiles)
	service_bar.setup(auction_manager, service_activate_popup)
	hud.setup_auction(auction_panel, service_bar)
	EventBus.player_died.connect(_on_player_died)
	EventBus.phase_changed.connect(_on_phase_changed)
	EventBus.game_won.connect(_on_game_won)
	_initialized = true
	_phase_transition = PHASE_TRANSITION_SCENE.instantiate()
	add_child(_phase_transition)
	_phase_transition.show_for_phase(1)
	_enemy_inspect = ENEMY_INSPECT_SCENE.instantiate()
	add_child(_enemy_inspect)

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
		tile.is_altar = (i == 0)
		tile.position = TILE_POSITIONS[i]
		tile.guard_position = GUARD_POSITIONS[i]
		tile.clicked.connect(_on_tile_clicked)
		tiles_container.add_child(tile)
		tiles.append(tile)
	return tiles

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
		altar_panel.open(tile)
	elif tile.has_enemy():
		_enemy_inspect.open(tile.enemy)
	else:
		tile_rule_panel.open(tile)

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
	var go = GAME_OVER_SCENE.instantiate()
	go.outcome = "lose"
	add_child(go)

func _on_game_won() -> void:
	var go = GAME_OVER_SCENE.instantiate()
	go.outcome = "win"
	add_child(go)

func _on_phase_changed(new_phase: int) -> void:
	_phase_transition.show_for_phase(new_phase)
	for tile in tiles_container.get_children():
		if tile.is_altar:
			tile.resize_altar_for_phase(new_phase)
