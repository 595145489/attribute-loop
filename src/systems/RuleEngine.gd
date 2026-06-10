class_name RuleEngine
extends Node

var _tiles: Array = []
var _state_timer: float = 0.0
var _firing_rule_trigger: bool = false
const _STATE_INTERVAL: float = 1.0

func _ready() -> void:
	EventBus.player_hit.connect(_on_player_hit)
	EventBus.enemy_killed.connect(_on_enemy_killed)
	EventBus.loop_completed.connect(_on_loop_completed)
	EventBus.tile_passed.connect(_on_tile_passed)
	EventBus.rule_fired.connect(_on_rule_fired)

func set_tiles(tiles: Array) -> void:
	_tiles = tiles

func _process(delta: float) -> void:
	_state_timer += delta
	if _state_timer >= _STATE_INTERVAL:
		_state_timer = 0.0
		_check_state_triggers()

func _check_state_triggers() -> void:
	if float(GameState.hp) / float(GameState.hp_max) < 0.3:
		_evaluate_player_triggers(["低血"])
	if GameState.hp >= GameState.hp_max:
		_evaluate_player_triggers(["满血"])

func _on_player_hit(_damage: int) -> void:
	_evaluate_player_triggers(["受击"])

func _on_rule_fired(_slot_idx: int, effect_id: String, _value: float) -> void:
	if effect_id == "治愈":
		_evaluate_player_triggers(["治愈"])
	if not _firing_rule_trigger:
		_firing_rule_trigger = true
		_evaluate_player_triggers(["规则触发"])
		_firing_rule_trigger = false

func _on_enemy_killed(_enemy: Enemy) -> void:
	_evaluate_player_triggers(["击杀"])

func _on_loop_completed() -> void:
	_evaluate_player_triggers(["完成圈数"])
	var decay := ceili(float(GameState.current_phase) / 2.0)
	GameState.slow_stacks = max(0, GameState.slow_stacks - decay)

func _on_tile_passed(tile_idx: int) -> void:
	_evaluate_player_triggers(["经过"])
	if tile_idx < _tiles.size() and _tiles[tile_idx] != null:
		_evaluate_tile_rules(_tiles[tile_idx])

func _evaluate_player_triggers(trigger_ids: Array) -> void:
	for i in GameState.rule_slots.size():
		var slot = GameState.rule_slots[i]
		var trigger: ComponentData = slot.get("trigger")
		var effect: ComponentData = slot.get("effect")
		if trigger == null or effect == null:
			continue
		if trigger.id not in trigger_ids:
			continue
		trigger.trigger_count += 1
		if trigger.trigger_count >= trigger.trigger_value:
			trigger.trigger_count = 0
			_execute_effect(i, effect, 0)

func _evaluate_tile_rules(tile: Tile) -> void:
	for slot in tile.rule_slots:
		var t: ComponentData = slot.get("trigger")
		var e: ComponentData = slot.get("effect")
		if t == null or e == null:
			continue
		var n := int(t.trigger_value)
		if n > 0 and tile.pass_count % n == 0:
			_execute_effect(-1, e, tile.pass_count)

func _execute_effect(slot_idx: int, effect: ComponentData, pass_count: int) -> void:
	var exponent := effect.scale_exponent if effect.scale_exponent > 0.0 else 1.0
	var scale_factor := 1.0 + effect.growth_rate * pow(float(pass_count), exponent)
	var scaled := effect.effect_value * scale_factor
	var actual: float
	if effect.max_scale > 0.0:
		actual = min(scaled, effect.effect_value * effect.max_scale)
	else:
		actual = scaled
	var bonus: float = GameState.altar_bonuses.get(effect.id, 0.0)
	var final_value: float = actual + bonus

	match effect.id:
		"治愈":
			GameState.hp = min(GameState.hp + int(final_value), GameState.hp_max)
			EventBus.rule_fired.emit(slot_idx, "治愈", final_value)
		"反射":
			GameState.pending_reflect_ratio = final_value
			EventBus.rule_fired.emit(slot_idx, "反射", final_value)
		"护盾":
			GameState.shield += int(final_value)
			EventBus.rule_fired.emit(slot_idx, "护盾", final_value)
		"减伤":
			GameState.slow_stacks += int(final_value)
			EventBus.rule_fired.emit(slot_idx, "减伤", final_value)
		"吸血":
			GameState.lifesteal_ratio += final_value
			EventBus.rule_fired.emit(slot_idx, "吸血", final_value)
