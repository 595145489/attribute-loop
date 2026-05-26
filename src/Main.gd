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

func _build_tiles() -> Array:
	var tiles: Array = []
	var curve = track.curve
	var length = curve.get_baked_length()
	for i in 13:
		var t = float(i) / 13.0
		var pos = curve.sample_baked(t * length)
		var tile: Tile = TILE_SCENE.instantiate()
		tile.tile_index = i
		tile.is_altar = (i == 0)
		tile.position = pos
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
		if player_pos.distance_to(tile.global_position) < 30.0:
			if tile.has_enemy():
				game_loop.check_tile_for_enemy(tile)
				return
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
