class_name GameLoop
extends Node

enum State { WALKING, COMBAT, GAME_OVER }

var state: State = State.WALKING
var _tiles: Array = []          # Array[Tile]
var _enemies_container: Node
var _player: Player
var _combat_system: CombatSystem
var _enemy_scene: PackedScene = null
var _combat_tile: Tile = null

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
