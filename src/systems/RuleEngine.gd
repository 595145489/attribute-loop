class_name RuleEngine
extends Node

var _tiles: Array = []
var _log_file: FileAccess = null

func _ready() -> void:
	_log_file = FileAccess.open("res://tests/rule_debug.log", FileAccess.WRITE)
	EventBus.player_hit.connect(_on_player_hit)
	EventBus.enemy_killed.connect(_on_enemy_killed)
	EventBus.loop_completed.connect(_on_loop_completed)
	EventBus.tile_passed.connect(_on_tile_passed)
	EventBus.rule_fired.connect(_on_rule_fired)

func set_tiles(tiles: Array) -> void:
	_tiles = tiles

func _log(msg: String) -> void:
	if _log_file:
		_log_file.store_line(msg)
		_log_file.flush()
	print(msg)

func _on_player_hit(_damage: int) -> void:
	_evaluate_player_triggers(["受击"])

func _on_rule_fired(_slot_idx: int, effect_id: String, _value: float) -> void:
	if effect_id == "治愈":
		_evaluate_player_triggers(["治愈"])

func _on_enemy_killed(_enemy: Enemy) -> void:
	_evaluate_player_triggers(["击杀"])

func _on_loop_completed() -> void:
	_evaluate_player_triggers(["完成圈数"])

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
		_log("[slot%d] T=%s count=%d/%.0f E=%s eff_val=%.2f" % [
			i, trigger.id, trigger.trigger_count, trigger.trigger_value,
			effect.id, effect.effect_value])
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
			_log("[tile%d] 经过(%d) pass=%d FIRE E=%s" % [tile.tile_index, n, tile.pass_count, e.id])
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

	_log("[FIRE] E=%s pass=%d scale=%.2f actual=%.2f bonus=%.2f final=%.2f hp_before=%d" % [
		effect.id, pass_count, scale_factor, actual, bonus, final_value, GameState.hp])

	match effect.id:
		"治愈":
			GameState.hp = min(GameState.hp + int(final_value), GameState.hp_max)
			EventBus.rule_fired.emit(slot_idx, "治愈", final_value)
		"反射":
			GameState.pending_reflect_ratio = final_value
			EventBus.rule_fired.emit(slot_idx, "反射", final_value)
		_:
			_log("[FIRE] unknown effect id: '" + effect.id + "'")

	_log("[FIRE] hp_after=%d" % GameState.hp)
