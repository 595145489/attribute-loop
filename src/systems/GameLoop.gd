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
var _auction_manager = null

func setup_auction(am) -> void:
	_auction_manager = am

func setup(tiles: Array, enemies_container: Node, player: Player, combat: CombatSystem) -> void:
	_tiles = tiles
	_enemies_container = enemies_container
	_player = player
	_combat_system = combat
	EventBus.loop_completed.connect(_on_loop_completed)
	EventBus.combat_resolved.connect(_on_combat_resolved)
	EventBus.player_died.connect(_on_player_died)
	EventBus.altar_activated.connect(_on_altar_activated)
	spawn_enemies()

func spawn_enemies() -> void:
	if GameState.is_tutorial:
		return
	for child in _enemies_container.get_children():
		child.queue_free()
	for tile in _tiles:
		tile.clear_enemy()

	if GameState.boss_circle_pending:
		GameState.boss_circle_pending = false
		GameState.in_boss_circle = true
		var b_phase := DataTables.config.verdict_spawn_phase if GameState.in_verdict_loop else GameState.current_phase
		var b_phase_data: PhaseData = DataTables.get_phase(b_phase)
		var last_idx := _tiles.size() - 1
		var b_enemy_id := _pick_enemy_id(b_phase_data, b_phase)
		var b_enemy: Enemy = _enemy_scene.instantiate()
		_enemies_container.add_child(b_enemy)
		b_enemy.init(b_enemy_id, b_phase)
		b_enemy.position = _tiles[last_idx].guard_position
		_tiles[last_idx].place_enemy(b_enemy)
		_assign_components(b_enemy, b_phase, _BOSS_RULE_PAIR_BONUS)
		_apply_boss_modifiers(b_enemy, b_phase_data)
		return

	GameState.in_boss_circle = false
	var config: GameConfig = DataTables.config
	var spawn_phase := config.verdict_spawn_phase if GameState.in_verdict_loop else GameState.current_phase
	var stat_phase := config.verdict_enemy_phase if GameState.in_verdict_loop else GameState.current_phase

	var phase_data: PhaseData = DataTables.get_phase(spawn_phase)
	var count = _roll_spawn_count(phase_data)
	var indices = _pick_tile_indices(count, _tiles.size())

	for idx in indices:
		var enemy_id = _pick_enemy_id(phase_data, spawn_phase)
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
	if GameState.enemy_pardon_remaining > 0 and GameState.enemy_pardon_type == tile.enemy.enemy_id:
		GameState.enemy_pardon_remaining -= 1
		if GameState.enemy_pardon_remaining == 0:
			GameState.enemy_pardon_type = ""
		EventBus.enemy_pardoned.emit(tile.enemy.enemy_id)
		if _auction_manager != null:
			_auction_manager.register_kill(tile.enemy.enemy_id)
		tile.enemy.queue_free()
		tile.clear_enemy()
		return
	state = State.COMBAT
	GameState.is_paused = true
	tile.enemy.play_activate()
	_player.enter_combat()
	_combat_tile = tile
	if _combat_system.rule_engine != null:
		_combat_system.rule_engine.evaluate_tile_combat_effects(tile)
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
			if GameState.pending_phase_advance and not GameState.boss_circle_pending:
				# Boss circle already ran — now advance phase
				GameState.pending_phase_advance = false
				var config_ref: GameConfig = DataTables.config
				if GameState.current_phase == config_ref.verdict_trigger_phase:
					GameState.in_verdict_loop = true
					GameState.verdict_loops_survived = 0
					GameState.loops_in_phase = 0
					EventBus.verdict_loop_entered.emit()
				else:
					GameState.current_phase += 1
					GameState.loops_in_phase = 0
					EventBus.phase_changed.emit(GameState.current_phase)
			elif not GameState.pending_phase_advance:
				GameState.loops_in_phase += 1
				var phase_data: PhaseData = DataTables.get_phase(GameState.current_phase)
				if GameState.loops_in_phase >= phase_data.world_pressure_window:
					if not _altar_is_full(_tiles[0]):
						# Every phase ends its pressure window with a boss circle;
						# the next loop_completed then advances the phase (or, at the
						# verdict threshold, enters the verdict loop after the boss).
						GameState.boss_circle_pending = true
						GameState.pending_phase_advance = true
		for tile in _tiles:
			tile.visited_this_loop = false
		spawn_enemies()

func _on_combat_resolved() -> void:
	if state == State.GAME_OVER:
		return
	if _combat_tile != null:
		if _combat_tile.enemy != null:
			if _auction_manager != null:
				_auction_manager.register_kill(_combat_tile.enemy.enemy_id)
			_combat_tile.enemy.queue_free()
		_combat_tile.clear_enemy()
		_combat_tile = null
	state = State.WALKING
	_player.exit_combat()
	GameState.is_paused = false

func _on_player_died() -> void:
	if GameState.is_tutorial:
		GameState.hp = GameState.hp_max
		return
	state = State.GAME_OVER
	_combat_system.stop()
	GameState.is_paused = true

func _on_altar_activated() -> void:
	GameState.boss_circle_pending = true

# Boss enemies get this many extra rule pairs on top of the phase's normal range.
# Spec 7.4: "Boss multipliers: HP x2.0, Attack x2.0, Rule pairs +2".
const _BOSS_RULE_PAIR_BONUS: int = 2

static func _assign_components(enemy: Enemy, stat_phase: int = -1, extra_pairs: int = 0) -> void:
	var enemy_data: EnemyData = DataTables.get_enemy(enemy.enemy_id)
	var effective_phase := stat_phase if stat_phase > 0 else GameState.current_phase
	var phase_data: PhaseData = DataTables.get_phase(effective_phase)
	# Pair count is driven by the phase's enemy_component_count_min/max (spec 5.1),
	# not by per-enemy fields — this is what makes enemies gain rule pairs as phases
	# advance. `extra_pairs` adds the boss bonus (spec 7.4).
	var pairs = randi_range(
		phase_data.enemy_component_count_min + extra_pairs,
		phase_data.enemy_component_count_max + extra_pairs
	)
	for i in pairs:
		var preset: DropPreset = _roll_tier_preset(phase_data)
		if preset == null:
			continue
		var t_id = _weighted_pick_with_modifiers(enemy_data.trigger_weights, phase_data)
		var e_id = _weighted_pick_with_modifiers(enemy_data.effect_weights, phase_data)
		enemy.components.append(_create_component(t_id, preset))
		enemy.components.append(_create_component(e_id, preset))

static func _roll_tier_preset(phase_data: PhaseData) -> DropPreset:
	var weights: Array[int] = phase_data.tier_drop_weights
	var total := 0
	for w in weights:
		total += w
	var roll := randi_range(1, total)
	var acc := 0
	for idx in weights.size():
		acc += weights[idx]
		if roll <= acc:
			return DataTables.get_drop_preset(idx + 1)
	return DataTables.get_drop_preset(1)

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

static func _apply_boss_modifiers(enemy: Enemy, phase_data: PhaseData) -> void:
	enemy.hp_max = int(enemy.hp_max * phase_data.boss_hp_multiplier)
	enemy.hp = enemy.hp_max
	enemy.dmg = int(enemy.dmg * phase_data.boss_damage_multiplier)
	enemy.scale = Vector2.ONE * phase_data.boss_scale

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
