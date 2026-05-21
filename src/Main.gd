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
@onready var strip_panel: StripPanel = $UI/StripPanel
@onready var inventory_panel: InventoryPanel = $UI/InventoryPanel
@onready var hud: HUD = $UI/HUD

func _ready() -> void:
    var tiles = _build_tiles()
    player.setup(player_follow, track)
    game_loop.setup(tiles, enemies_container, player, combat_system)
    strip_manager.setup(strip_panel)
    strip_panel.setup(inventory_panel)
    hud.setup(inventory_panel)
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
        if player_pos.distance_to(tile.global_position) < 30.0:
            if tile.has_enemy():
                game_loop.check_tile_for_enemy(tile)
                return
            if not tile.visited_this_loop:
                tile.visited_this_loop = true
                EventBus.tile_passed.emit(tile.tile_index)
            return

func _on_player_died() -> void:
    var go = GAME_OVER_SCENE.instantiate()
    add_child(go)
