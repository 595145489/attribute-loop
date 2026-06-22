class_name RuleEngine
extends Node

const COMBAT_TILE_EFFECTS: Array[String] = ["吸血", "反射", "灼烧", "侵蚀"]

var _tiles: Array = []
var _state_timer: float = 0.0
var _firing_rule_trigger: bool = false
const _STATE_INTERVAL: float = 1.0
var _active_enemy: Enemy = null
var _executing_self_hit: bool = false

func set_active_enemy(e: Enemy) -> void:
	_active_enemy = e

func _ready() -> void:
	EventBus.player_hit.connect(_on_player_hit)
	EventBus.enemy_killed.connect(_on_enemy_killed)
	EventBus.loop_completed.connect(_on_loop_completed)
	EventBus.tile_passed.connect(_on_tile_passed)
	EventBus.rule_fired.connect(_on_rule_fired)
	EventBus.shield_absorbed.connect(func(_a): _evaluate_player_triggers(["护盾"]))
	EventBus.slow_applied.connect(func(_s): _evaluate_player_triggers(["减伤"]))
	EventBus.lifesteal_healed.connect(func(_a): _evaluate_player_triggers(["吸血"]))
	EventBus.amplify_consumed.connect(func(): _evaluate_player_triggers(["强化"]))
	EventBus.dmg_boost_consumed.connect(func(_s): _evaluate_player_triggers(["增伤"]))

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
	if _executing_self_hit:
		return
	_evaluate_player_triggers(["受击"])

func _on_rule_fired(_slot_idx: int, effect_id: String, _value: float) -> void:
	if effect_id == "治愈":
		_evaluate_player_triggers(["治愈"])
	if effect_id == "反射":
		_evaluate_player_triggers(["反射"])
	if effect_id == "蓄能释放":
		_evaluate_player_triggers(["蓄能"])
	if effect_id == "灼烧":
		_evaluate_player_triggers(["灼烧"])
	if effect_id == "侵蚀":
		_evaluate_player_triggers(["侵蚀"])
	if effect_id in ["强化", "增伤", "蓄能", "蓄能释放", "灼烧", "侵蚀"]:
		return
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
	GameState.shield = int(GameState.shield * 0.65)
	# 增伤 decays with the same phase-scaled rate as 减伤 so neither buff nor
	# debuff snowballs indefinitely across loops.
	GameState.dmg_boost_stacks = max(0, GameState.dmg_boost_stacks - decay)

func _on_tile_passed(tile_idx: int) -> void:
	GameState.current_tile_index = tile_idx
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
		if e.id in COMBAT_TILE_EFFECTS:
			continue
		var n := int(t.trigger_value)
		if n > 0 and tile.pass_count % n == 0:
			_execute_effect(-1, e, tile.pass_count)

func evaluate_tile_combat_effects(tile: Tile) -> void:
	tile.combat_count += 1
	for slot in tile.rule_slots:
		var t: ComponentData = slot.get("trigger")
		var e: ComponentData = slot.get("effect")
		if t == null or e == null:
			continue
		if e.id not in COMBAT_TILE_EFFECTS:
			continue
		var n := int(t.trigger_value)
		if n > 0 and tile.combat_count % n == 0:
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

	if effect.id != "强化" and GameState.amplify_stacks > 0:
		final_value *= 1.0 + GameState.amplify_stacks * 0.5
		GameState.amplify_stacks = 0
		EventBus.amplify_consumed.emit()

	match effect.id:
		"治愈":
			GameState.hp = min(GameState.hp + int(final_value), GameState.hp_max)
			EventBus.rule_fired.emit(slot_idx, "治愈", final_value)
		"反射":
			GameState.pending_reflect_ratio = final_value
			EventBus.rule_fired.emit(slot_idx, "反射", final_value)
		"护盾":
			GameState.shield = mini(GameState.shield + int(final_value), GameState.hp_max)
			EventBus.rule_fired.emit(slot_idx, "护盾", final_value)
		"减伤":
			GameState.slow_stacks += int(final_value)
			EventBus.rule_fired.emit(slot_idx, "减伤", final_value)
		"吸血":
			GameState.lifesteal_ratio += final_value
			EventBus.rule_fired.emit(slot_idx, "吸血", final_value)
		"强化":
			GameState.amplify_stacks = min(GameState.amplify_stacks + 1, GameState.amplify_max_stacks)
			EventBus.rule_fired.emit(slot_idx, "强化", float(GameState.amplify_stacks))
		"增伤":
			GameState.dmg_boost_stacks += int(final_value)
			EventBus.rule_fired.emit(slot_idx, "增伤", final_value)
		"蓄能":
			GameState.charge_stacks += int(final_value)
			EventBus.rule_fired.emit(slot_idx, "蓄能", final_value)
		"灼烧":
			EventBus.rule_fired.emit(slot_idx, "灼烧", final_value)
		"侵蚀":
			EventBus.rule_fired.emit(slot_idx, "侵蚀", final_value)
		"受击":
			var dmg := maxi(1, int(final_value))
			GameState.hp = maxi(1, GameState.hp - dmg)
			EventBus.rule_fired.emit(slot_idx, "受击", float(dmg))
			_executing_self_hit = true
			EventBus.player_hit.emit(dmg)
			_executing_self_hit = false
		"低血":
			var dmg := maxi(1, int(final_value))
			GameState.hp = maxi(1, GameState.hp - dmg)
			EventBus.rule_fired.emit(slot_idx, "低血", float(dmg))
		"满血":
			if GameState.charge_stacks > 0:
				GameState.charge_stacks = mini(GameState.charge_stacks + 1, 20)
			if GameState.dmg_boost_stacks > 0:
				GameState.dmg_boost_stacks = mini(GameState.dmg_boost_stacks + 1, 8)
			if GameState.amplify_stacks > 0:
				GameState.amplify_stacks = mini(GameState.amplify_stacks + 1, GameState.amplify_max_stacks)
			EventBus.rule_fired.emit(slot_idx, "满血", 1.0)
		"规则触发":
			for s in GameState.rule_slots:
				var t: ComponentData = s.get("trigger")
				if t != null:
					t.trigger_count += 1
			EventBus.rule_fired.emit(slot_idx, "规则触发", 1.0)
		"击杀":
			if _active_enemy != null and not _active_enemy.is_dead():
				var kill_bonus := int(_active_enemy.hp * final_value / 100.0)
				if kill_bonus > 0:
					_active_enemy.take_damage(kill_bonus)
			EventBus.rule_fired.emit(slot_idx, "击杀", final_value)
		"经过":
			var idx := GameState.current_tile_index
			if idx >= 0 and idx < _tiles.size() and _tiles[idx] != null:
				_evaluate_tile_rules(_tiles[idx])
			EventBus.rule_fired.emit(slot_idx, "经过", 1.0)
