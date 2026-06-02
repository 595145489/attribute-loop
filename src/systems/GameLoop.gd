class_name GameLoop
extends Node

enum State { WALKING, COMBAT, GAME_OVER }

var state: State = State.WALKING
var _tiles: Array = []
var _enemies_container: Node
var _player: Player
var _combat_system: CombatSystem
var _enemy_scene: PackedScene = preload("res://scenes/entities/enemy.tscn")
var _combat_tile: Tile = null

func setup(tiles: Array, enemies_container: Node, player: Player, combat: CombatSystem) -> void:
	_tiles = tiles
	_enemies_container = enemies_container
	_player = player
	_combat_system = combat
	EventBus.loop_completed.connect(_on_loop_completed)
	EventBus.combat_resolved.connect(_on_combat_resolved)
	EventBus.player_died.connect(_on_player_died)
	EventBus.verdict_loop_entered.connect(spawn_enemies)
	spawn_enemies()

func spawn_enemies() -> void:
	for child in _enemies_container.get_children():
		child.queue_free()
	for tile in _tiles:
		tile.clear_enemy()

	var config: GameConfig = DataTables.config
	var spawn_phase := config.verdict_spawn_phase if GameState.in_verdict_loop else GameState.current_phase
	var stat_phase := config.verdict_enemy_phase if GameState.in_verdict_loop else GameState.current_phase

	var phase_data: PhaseData = DataTables.get_phase(spawn_phase)
	var count = _roll_spawn_count(phase_data)
	var indices = _pick_tile_indices(count, _tiles.size())

	for idx in indices:
		var enemy_id = "急袭者"  # DEBUG: force rusher for testing
		var enemy: Enemy = _enemy_scene.instantiate()
		_enemies_container.add_child(enemy)
		enemy.init(enemy_id, stat_phase)
		enemy.position = _tiles[idx].guard_position
		_tiles[idx].place_enemy(enemy)
		_assign_components(enemy, stat_phase)

func check_tile_for_enemy(tile: Tile) -> void:
	if state != State.WALKING:
		return
	if not tile.has_enemy():
		return
	state = State.COMBAT
	GameState.is_paused = true
	_player.enter_combat()
	_combat_tile = tile
	_combat_system.start(tile.enemy)

func _on_loop_completed() -> void:
	if state == State.WALKING:
		if GameState.in_verdict_loop:
			GameState.verdict_loops_survived += 1
			var config: GameConfig = DataTables.config
			if GameState.verdict_loops_survived >= config.verdict_survive_loops:
				state = State.GAME_OVER
				GameState.is_paused = true
				EventBus.game_won.emit()
				return
		else:
			GameState.loops_in_phase += 1
			var phase_data: PhaseData = DataTables.get_phase(GameState.current_phase)
			if GameState.loops_in_phase >= phase_data.world_pressure_window:
				if not _altar_is_full(_tiles[0]):
					GameState.force_phase_advance()
		for tile in _tiles:
			tile.visited_this_loop = false
		spawn_enemies()

func _on_combat_resolved() -> void:
	if state == State.GAME_OVER:
		return
	if _combat_tile != null:
		if _combat_tile.enemy != null:
			_combat_tile.enemy.queue_free()
		_combat_tile.clear_enemy()
		_combat_tile = null
	state = State.WALKING
	_player.exit_combat()
	GameState.is_paused = false

func _on_player_died() -> void:
	state = State.GAME_OVER
	_combat_system.stop()
	GameState.is_paused = true

func _assign_components(enemy: Enemy, stat_phase: int = -1) -> void:
	var enemy_data: EnemyData = DataTables.get_enemy(enemy.enemy_id)
	var effective_phase := stat_phase if stat_phase > 0 else GameState.current_phase
	var phase_data: PhaseData = DataTables.get_phase(effective_phase)
	var preset: DropPreset = _resolve_drop_preset(enemy_data, effective_phase)
	if preset == null:
		return
	var pairs = randi_range(
		enemy_data.component_pair_min + phase_data.component_count_bonus,
		enemy_data.component_pair_max + phase_data.component_count_bonus
	)
	for i in pairs:
		var t_id = _weighted_pick_with_modifiers(enemy_data.trigger_weights, phase_data)
		var e_id = _weighted_pick_with_modifiers(enemy_data.effect_weights, phase_data)
		enemy.components.append(_create_component(t_id, preset))
		enemy.components.append(_create_component(e_id, preset))

static func _resolve_drop_preset(enemy_data: EnemyData, current_phase: int) -> DropPreset:
	if enemy_data.phase_drop_presets.is_empty():
		return null
	var best_key = -1
	for key in enemy_data.phase_drop_presets:
		if key <= current_phase and key > best_key:
			best_key = key
	if best_key == -1:
		return null
	return enemy_data.phase_drop_presets[best_key]

static func _weighted_pick_with_modifiers(weights: Dictionary, phase_data: PhaseData) -> String:
	var final_weights: Dictionary = {}
	var total: float = 0.0
	for id in weights:
		var w = weights[id] * phase_data.component_weight_modifiers.get(id, 1.0)
		final_weights[id] = w
		total += w
	var roll = randf() * total
	var acc: float = 0.0
	for id in final_weights:
		acc += final_weights[id]
		if roll <= acc:
			return id
	return final_weights.keys()[0]

static func _create_component(id: String, preset: DropPreset) -> ComponentData:
	var base: ComponentData = DataTables.get_component(id)
	var comp: ComponentData = base.duplicate()
	comp.trigger_count = 0
	var ranges = preset.component_ranges.get(id, {})
	if comp.slot_type in [ComponentData.SlotType.TRIGGER_ONLY, ComponentData.SlotType.BOTH]:
		var t_range = ranges.get("trigger", null)
		if t_range != null:
			comp.trigger_value = float(randi_range(int(t_range.x), int(t_range.y)))
	if comp.slot_type in [ComponentData.SlotType.EFFECT_ONLY, ComponentData.SlotType.BOTH]:
		var e_range = ranges.get("effect", null)
		if e_range != null:
			comp.effect_value = randf_range(e_range.x, e_range.y)
	return comp

## Pure functions used by tests

static func _roll_spawn_count(phase: PhaseData) -> int:
	return randi_range(phase.spawn_count_min, phase.spawn_count_max)

static func _pick_enemy_id(phase: PhaseData, current_phase: int) -> String:
	var eligible: Dictionary = {}
	for id in phase.spawn_weights:
		var data: EnemyData = DataTables.get_enemy(id)
		if data.unlock_phase <= current_phase:
			eligible[id] = phase.spawn_weights[id]
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
	var pool = range(1, total)
	pool.shuffle()
	return pool.slice(0, count)

static func _altar_is_full(altar: Tile) -> bool:
	if altar.altar_slots.is_empty():
		return false
	for slot in altar.altar_slots:
		if slot == null:
			return false
	return true
