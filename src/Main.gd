extends Node2D

const TILE_SCENE = preload("res://scenes/entities/tile.tscn")
const GAME_OVER_SCENE = preload("res://scenes/ui/game_over.tscn")

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

func _ready() -> void:
	get_viewport().physics_object_picking = true
	var tiles = _build_tiles()
	player.setup(player_follow, track)
	game_loop.setup(tiles, enemies_container, player, combat_system)
	strip_manager.setup(strip_panel)
	strip_panel.setup(inventory_panel)
	hud.setup(inventory_panel)
	hud.setup_altar(altar_panel, tiles[0])
	rule_engine.set_tiles(tiles)
	EventBus.player_died.connect(_on_player_died)
	EventBus.phase_changed.connect(_on_phase_changed)
	EventBus.game_won.connect(_on_game_won)

const TILE_POSITIONS: Array[Vector2] = [
	Vector2(576, 115),  # 0  altar        top center
	Vector2(739, 115),  # 1               top right
	Vector2(903, 115),  # 2               top far right
	Vector2(1021, 223), # 3               right upper
	Vector2(1021, 377), # 4               right lower
	Vector2(870, 485),  # 5               bottom far right
	Vector2(674, 485),  # 6               bottom right
	Vector2(478, 485),  # 7               bottom left
	Vector2(282, 485),  # 8               bottom far left
	Vector2(131, 377),  # 9               left lower
	Vector2(131, 223),  # 10              left upper
	Vector2(249, 115),  # 11              top far left
	Vector2(413, 115),  # 12              top left
]

const GUARD_POSITIONS: Array[Vector2] = [
	Vector2(576,  70),   # 0  altar        top center (no enemy)
	Vector2(704,  70),   # 1               top right
	Vector2(868,  70),   # 2               top far right
	Vector2(1066, 188),  # 3               right upper
	Vector2(1066, 342),  # 4               right lower
	Vector2(905,  530),  # 5               bottom far right
	Vector2(709,  530),  # 6               bottom right
	Vector2(513,  530),  # 7               bottom left
	Vector2(317,  530),  # 8               bottom far left
	Vector2(86,   412),  # 9               left lower
	Vector2(86,   258),  # 10              left upper
	Vector2(214,  70),   # 11              top far left
	Vector2(378,  70),   # 12              top left
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
	if GameState.is_paused:
		return
	_check_player_tile()

func _check_player_tile() -> void:
	var player_pos = player.global_position
	for tile in tiles_container.get_children():
		if tile.has_enemy() and player_pos.distance_to(tile.guard_position) < 40.0:
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
	for tile in tiles_container.get_children():
		if tile.is_altar:
			tile.resize_altar_for_phase(new_phase)
