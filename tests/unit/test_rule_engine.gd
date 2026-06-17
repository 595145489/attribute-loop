extends GutTest

var engine: RuleEngine

func before_each() -> void:
	GameState.reset()
	engine = RuleEngine.new()
	add_child_autofree(engine)

func _make_rule(trigger_id: String, trigger_value: float, effect_id: String, effect_value: float) -> void:
	var t = ComponentData.new()
	t.id = trigger_id
	t.slot_type = ComponentData.SlotType.TRIGGER_ONLY
	t.trigger_value = trigger_value
	t.trigger_count = 0
	var e = ComponentData.new()
	e.id = effect_id
	e.slot_type = ComponentData.SlotType.EFFECT_ONLY
	e.effect_value = effect_value
	GameState.rule_slots[0]["trigger"] = t
	GameState.rule_slots[0]["effect"] = e

func test_trigger_count_increments_on_player_hit() -> void:
	_make_rule("受击", 3.0, "治愈", 10.0)
	var t = GameState.rule_slots[0]["trigger"]
	EventBus.player_hit.emit(5)
	assert_eq(t.trigger_count, 1)

func test_trigger_count_increments_on_enemy_killed() -> void:
	_make_rule("击杀", 2.0, "治愈", 10.0)
	var t = GameState.rule_slots[0]["trigger"]
	var dummy = Enemy.new()
	dummy.init("汲取者")
	EventBus.enemy_killed.emit(dummy)
	assert_eq(t.trigger_count, 1)

func test_trigger_count_increments_on_loop_completed() -> void:
	_make_rule("完成圈数", 2.0, "治愈", 10.0)
	var t = GameState.rule_slots[0]["trigger"]
	EventBus.loop_completed.emit()
	assert_eq(t.trigger_count, 1)

func test_trigger_count_increments_on_tile_passed() -> void:
	_make_rule("经过", 3.0, "治愈", 10.0)
	var t = GameState.rule_slots[0]["trigger"]
	EventBus.tile_passed.emit(0)
	assert_eq(t.trigger_count, 1)

func test_heal_fires_when_threshold_reached() -> void:
	_make_rule("受击", 1.0, "治愈", 15.0)
	GameState.hp = 50
	EventBus.player_hit.emit(5)
	assert_eq(GameState.hp, 65)

func test_heal_resets_trigger_count() -> void:
	_make_rule("受击", 1.0, "治愈", 10.0)
	var t = GameState.rule_slots[0]["trigger"]
	EventBus.player_hit.emit(5)
	assert_eq(t.trigger_count, 0)

func test_heal_capped_at_hp_max() -> void:
	_make_rule("受击", 1.0, "治愈", 999.0)
	GameState.hp = GameState.hp_max - 50
	EventBus.player_hit.emit(5)
	assert_eq(GameState.hp, GameState.hp_max)

func test_reflect_sets_pending_ratio() -> void:
	_make_rule("受击", 1.0, "反射", 0.5)
	EventBus.player_hit.emit(5)
	assert_eq(GameState.pending_reflect_ratio, 0.5)

func test_rule_fired_signal_emitted_on_effect() -> void:
	watch_signals(EventBus)
	_make_rule("受击", 1.0, "治愈", 10.0)
	GameState.hp = 50
	EventBus.player_hit.emit(5)
	assert_signal_emitted(EventBus, "rule_fired")

func test_no_fire_when_trigger_slot_empty() -> void:
	var e = ComponentData.new()
	e.id = "治愈"
	e.effect_value = 10.0
	GameState.rule_slots[0]["effect"] = e
	GameState.rule_slots[0]["trigger"] = null
	GameState.hp = 50
	EventBus.player_hit.emit(5)
	assert_eq(GameState.hp, 50)

func test_no_fire_when_effect_slot_empty() -> void:
	var t = ComponentData.new()
	t.id = "受击"
	t.trigger_value = 1.0
	GameState.rule_slots[0]["trigger"] = t
	GameState.rule_slots[0]["effect"] = null
	GameState.hp = 50
	EventBus.player_hit.emit(5)
	assert_eq(GameState.hp, 50)

func _make_rule_slot1(trigger_id: String, trigger_value: float, effect_id: String, effect_value: float) -> void:
	var t = ComponentData.new()
	t.id = trigger_id
	t.slot_type = ComponentData.SlotType.TRIGGER_ONLY
	t.trigger_value = trigger_value
	t.trigger_count = 0
	var e = ComponentData.new()
	e.id = effect_id
	e.slot_type = ComponentData.SlotType.EFFECT_ONLY
	e.effect_value = effect_value
	GameState.rule_slots[1]["trigger"] = t
	GameState.rule_slots[1]["effect"] = e

func test_heal_trigger_increments_when_heal_fires() -> void:
	_make_rule("受击", 1.0, "治愈", 10.0)
	_make_rule_slot1("治愈", 2.0, "反射", 0.3)
	GameState.hp = 50
	EventBus.player_hit.emit(5)
	assert_eq(GameState.rule_slots[1]["trigger"].trigger_count, 1)

func test_heal_trigger_does_not_increment_without_heal() -> void:
	_make_rule("受击", 5.0, "治愈", 10.0)
	_make_rule_slot1("治愈", 1.0, "反射", 0.3)
	EventBus.player_hit.emit(5)
	assert_eq(GameState.rule_slots[1]["trigger"].trigger_count, 0)

func test_heal_trigger_fires_even_at_full_hp() -> void:
	_make_rule("受击", 1.0, "治愈", 10.0)
	_make_rule_slot1("治愈", 1.0, "反射", 0.3)
	GameState.hp = GameState.hp_max
	EventBus.player_hit.emit(5)
	assert_eq(GameState.hp, GameState.hp_max)
	assert_eq(GameState.pending_reflect_ratio, 0.3, "heal trigger should still fire even at full HP")

func _make_tile_with_rule(tile_idx: int, n: int, effect_id: String, effect_value: float, growth_rate: float = 0.0) -> Tile:
	var tile := Tile.new()
	tile.tile_index = tile_idx
	tile.is_altar = false
	add_child_autofree(tile)
	tile.rule_slots.clear()
	var t := ComponentData.new()
	t.id = "经过"
	t.slot_type = ComponentData.SlotType.TRIGGER_ONLY
	t.trigger_value = float(n)
	var e := ComponentData.new()
	e.id = effect_id
	e.slot_type = ComponentData.SlotType.EFFECT_ONLY
	e.effect_value = effect_value
	e.growth_rate = growth_rate
	e.scale_exponent = 1.0
	e.max_scale = 0.0
	e.altar_ratio = 0.0
	tile.rule_slots.append({"trigger": t, "effect": e})
	return tile

func test_tile_rule_fires_on_nth_pass() -> void:
	var tile := _make_tile_with_rule(1, 2, "治愈", 10.0)
	engine.set_tiles([null, tile])
	GameState.hp = 50
	tile.pass_count = 1
	EventBus.tile_passed.emit(1)
	assert_eq(GameState.hp, 50, "should not fire on pass 1 (need 2)")
	tile.pass_count = 2
	EventBus.tile_passed.emit(1)
	assert_eq(GameState.hp, 60, "should fire on pass 2")

func test_tile_rule_does_not_fire_with_incomplete_slot() -> void:
	var tile := Tile.new()
	tile.tile_index = 1
	tile.is_altar = false
	add_child_autofree(tile)
	tile.rule_slots.append({"trigger": null, "effect": null})
	engine.set_tiles([null, tile])
	GameState.hp = 50
	tile.pass_count = 1
	EventBus.tile_passed.emit(1)
	assert_eq(GameState.hp, 50)

func test_tile_rule_scales_with_pass_count() -> void:
	var tile := _make_tile_with_rule(1, 1, "治愈", 10.0, 0.1)
	engine.set_tiles([null, tile])
	GameState.hp = 0
	GameState.hp_max = 9999
	tile.pass_count = 10
	EventBus.tile_passed.emit(1)
	assert_eq(GameState.hp, 20)

func test_altar_bonus_applied_to_player_rule() -> void:
	_make_rule("受击", 1.0, "治愈", 10.0)
	GameState.altar_bonuses["治愈"] = 5.0
	GameState.hp = 50
	EventBus.player_hit.emit(5)
	assert_eq(GameState.hp, 65, "heal should be 10 base + 5 altar bonus = 15")

func test_altar_bonus_applied_to_tile_rule() -> void:
	var tile := _make_tile_with_rule(1, 1, "治愈", 10.0)
	engine.set_tiles([null, tile])
	GameState.altar_bonuses["治愈"] = 5.0
	GameState.hp = 0
	GameState.hp_max = 9999
	tile.pass_count = 1
	EventBus.tile_passed.emit(1)
	assert_eq(GameState.hp, 15, "heal should be 10 + 5 altar bonus = 15")

func test_max_scale_caps_tile_effect() -> void:
	var tile := _make_tile_with_rule(1, 1, "治愈", 10.0, 1.0)
	tile.rule_slots[0]["effect"].max_scale = 2.0
	engine.set_tiles([null, tile])
	GameState.hp = 0
	GameState.hp_max = 9999
	tile.pass_count = 100
	EventBus.tile_passed.emit(1)
	assert_eq(GameState.hp, 20, "should be capped at base * max_scale = 10 * 2 = 20")

func test_low_hp_trigger_counts_when_hp_below_threshold() -> void:
	_make_rule("低血", 3.0, "治愈", 10.0)
	GameState.hp = int(GameState.hp_max * 0.29)
	var t = GameState.rule_slots[0]["trigger"]
	engine._check_state_triggers()
	assert_eq(t.trigger_count, 1)

func test_low_hp_trigger_does_not_count_at_normal_hp() -> void:
	_make_rule("低血", 3.0, "治愈", 10.0)
	GameState.hp = int(GameState.hp_max * 0.5)
	var t = GameState.rule_slots[0]["trigger"]
	engine._check_state_triggers()
	assert_eq(t.trigger_count, 0)

func test_low_hp_trigger_fires_after_n_checks() -> void:
	_make_rule("低血", 2.0, "治愈", 20.0)
	GameState.hp_max = 9999
	GameState.hp = 50
	engine._check_state_triggers()
	engine._check_state_triggers()
	assert_eq(GameState.hp, 70)

func test_full_hp_trigger_counts_when_at_max() -> void:
	_make_rule("满血", 2.0, "治愈", 10.0)
	GameState.hp = GameState.hp_max
	var t = GameState.rule_slots[0]["trigger"]
	engine._check_state_triggers()
	assert_eq(t.trigger_count, 1)

func test_full_hp_trigger_does_not_count_below_max() -> void:
	_make_rule("满血", 2.0, "治愈", 10.0)
	GameState.hp = GameState.hp_max - 1
	var t = GameState.rule_slots[0]["trigger"]
	engine._check_state_triggers()
	assert_eq(t.trigger_count, 0)

func test_rule_fire_trigger_counts_on_rule_fire() -> void:
	_make_rule("受击", 1.0, "治愈", 10.0)
	_make_rule_slot1("规则触发", 2.0, "反射", 0.3)
	var t = GameState.rule_slots[1]["trigger"]
	GameState.hp = 50
	EventBus.player_hit.emit(5)
	assert_eq(t.trigger_count, 1, "should count 1 after one rule fire")
	assert_almost_eq(GameState.pending_reflect_ratio, 0.0, 0.001, "should not fire yet")

func test_rule_fire_trigger_fires_at_threshold() -> void:
	_make_rule("受击", 1.0, "治愈", 10.0)
	_make_rule_slot1("规则触发", 2.0, "反射", 0.3)
	GameState.hp = 50
	EventBus.player_hit.emit(5)
	EventBus.player_hit.emit(5)
	assert_almost_eq(GameState.pending_reflect_ratio, 0.3, 0.001, "should fire after 2 rule fires")

func test_rule_fire_trigger_no_infinite_loop() -> void:
	_make_rule("规则触发", 1.0, "治愈", 10.0)
	_make_rule_slot1("受击", 1.0, "反射", 0.1)
	GameState.hp = 50
	EventBus.player_hit.emit(5)
	assert_eq(GameState.hp, 60, "heal fired once, no infinite loop")

func test_shield_effect_adds_to_gamestate_shield() -> void:
	_make_rule("受击", 1.0, "护盾", 50.0)
	EventBus.player_hit.emit(5)
	assert_eq(GameState.shield, 50)

func test_shield_effect_accumulates() -> void:
	_make_rule("受击", 1.0, "护盾", 30.0)
	EventBus.player_hit.emit(5)
	EventBus.player_hit.emit(5)
	assert_eq(GameState.shield, 60)

func test_slow_effect_adds_slow_stacks() -> void:
	_make_rule("受击", 1.0, "减伤", 2.0)
	EventBus.player_hit.emit(5)
	assert_eq(GameState.slow_stacks, 2)

func test_slow_effect_accumulates() -> void:
	_make_rule("受击", 1.0, "减伤", 1.0)
	EventBus.player_hit.emit(5)
	EventBus.player_hit.emit(5)
	assert_eq(GameState.slow_stacks, 2)

func test_lifesteal_effect_adds_to_lifesteal_ratio() -> void:
	_make_rule("受击", 1.0, "吸血", 0.1)
	EventBus.player_hit.emit(5)
	assert_almost_eq(GameState.lifesteal_ratio, 0.1, 0.001)

func test_rule_fired_signal_emitted_for_shield() -> void:
	watch_signals(EventBus)
	_make_rule("受击", 1.0, "护盾", 30.0)
	EventBus.player_hit.emit(5)
	assert_signal_emitted(EventBus, "rule_fired")

func test_slow_stacks_decay_on_loop_completed() -> void:
	GameState.slow_stacks = 5
	GameState.current_phase = 2
	EventBus.loop_completed.emit()
	assert_eq(GameState.slow_stacks, 4)

func test_slow_stacks_decay_does_not_go_below_zero() -> void:
	GameState.slow_stacks = 1
	GameState.current_phase = 4
	EventBus.loop_completed.emit()
	assert_eq(GameState.slow_stacks, 0)

func test_shield_capped_at_hp_max() -> void:
	GameState.shield = GameState.hp_max - 10
	_make_rule("受击", 1.0, "护盾", 100.0)
	EventBus.player_hit.emit(5)
	assert_eq(GameState.shield, GameState.hp_max)

func test_shield_decays_65_percent_on_loop_completed() -> void:
	GameState.shield = 200
	EventBus.loop_completed.emit()
	assert_eq(GameState.shield, int(200 * 0.65))

func test_amplify_adds_one_stack() -> void:
	_make_rule("受击", 1.0, "强化", 1.0)
	EventBus.player_hit.emit(5)
	assert_eq(GameState.amplify_stacks, 1)

func test_amplify_capped_at_max_stacks() -> void:
	_make_rule("受击", 1.0, "强化", 1.0)
	for i in 5:
		EventBus.player_hit.emit(5)
	assert_eq(GameState.amplify_stacks, GameState.amplify_max_stacks,
		"should not exceed amplify_max_stacks")

func test_amplify_stacks_accumulate_when_max_raised() -> void:
	GameState.amplify_max_stacks = 5
	_make_rule("受击", 1.0, "强化", 1.0)
	for i in 3:
		EventBus.player_hit.emit(5)
	assert_eq(GameState.amplify_stacks, 3)

func test_amplify_multiplies_next_effect() -> void:
	_make_rule("受击", 1.0, "强化", 1.0)
	_make_rule_slot1("完成圈数", 1.0, "治愈", 10.0)
	GameState.hp = 50
	EventBus.player_hit.emit(5)
	assert_eq(GameState.amplify_stacks, 1)
	EventBus.loop_completed.emit()
	assert_eq(GameState.hp, 65, "heal 10 * 1.5x (1 stack) = 15")

func test_amplify_resets_stacks_after_use() -> void:
	GameState.amplify_stacks = 1
	_make_rule("完成圈数", 1.0, "治愈", 10.0)
	EventBus.loop_completed.emit()
	assert_eq(GameState.amplify_stacks, 0)

func test_amplify_three_stacks_triples_bonus() -> void:
	GameState.amplify_max_stacks = 5
	_make_rule("受击", 1.0, "强化", 1.0)
	_make_rule_slot1("完成圈数", 1.0, "治愈", 10.0)
	GameState.hp = 0
	GameState.hp_max = 9999
	for i in 3:
		EventBus.player_hit.emit(5)
	EventBus.loop_completed.emit()
	assert_eq(GameState.hp, 25, "heal 10 * (1 + 3*0.5) = 10 * 2.5 = 25")

func test_amplify_not_amplified_by_existing_stacks() -> void:
	GameState.amplify_max_stacks = 5
	GameState.amplify_stacks = 3
	_make_rule("受击", 1.0, "强化", 1.0)
	EventBus.player_hit.emit(5)
	assert_eq(GameState.amplify_stacks, 4, "stacks should add 1, not be multiplied")

func test_dmg_boost_adds_stacks() -> void:
	_make_rule("受击", 1.0, "增伤", 2.0)
	EventBus.player_hit.emit(5)
	assert_eq(GameState.dmg_boost_stacks, 2)

func test_dmg_boost_accumulates() -> void:
	_make_rule("受击", 1.0, "增伤", 2.0)
	EventBus.player_hit.emit(5)
	EventBus.player_hit.emit(5)
	assert_eq(GameState.dmg_boost_stacks, 4)

func test_charge_adds_stacks() -> void:
	_make_rule("受击", 1.0, "蓄能", 1.0)
	EventBus.player_hit.emit(5)
	assert_eq(GameState.charge_stacks, 1)

func test_charge_accumulates_from_two_rules() -> void:
	_make_rule("受击", 1.0, "蓄能", 1.0)
	_make_rule_slot1("完成圈数", 1.0, "蓄能", 1.0)
	EventBus.player_hit.emit(5)
	EventBus.loop_completed.emit()
	assert_eq(GameState.charge_stacks, 2)

func test_scorch_emits_rule_fired() -> void:
	watch_signals(EventBus)
	_make_rule("受击", 1.0, "灼烧", 3.0)
	EventBus.player_hit.emit(5)
	assert_signal_emitted(EventBus, "rule_fired")

func test_erode_emits_rule_fired() -> void:
	watch_signals(EventBus)
	_make_rule("受击", 1.0, "侵蚀", 20.0)
	EventBus.player_hit.emit(5)
	assert_signal_emitted(EventBus, "rule_fired")

func test_amplify_consumed_emitted_when_amplify_used() -> void:
	watch_signals(EventBus)
	GameState.amplify_stacks = 1
	_make_rule("完成圈数", 1.0, "治愈", 10.0)
	GameState.hp = 50
	EventBus.loop_completed.emit()
	assert_signal_emitted(EventBus, "amplify_consumed")

func test_amplify_consumed_not_emitted_without_amplify() -> void:
	watch_signals(EventBus)
	GameState.amplify_stacks = 0
	_make_rule("完成圈数", 1.0, "治愈", 10.0)
	GameState.hp = 50
	EventBus.loop_completed.emit()
	assert_signal_not_emitted(EventBus, "amplify_consumed")

func test_shield_trigger_counts_on_shield_absorbed() -> void:
	_make_rule("护盾", 2.0, "治愈", 10.0)
	var t = GameState.rule_slots[0]["trigger"]
	EventBus.shield_absorbed.emit(20)
	assert_eq(t.trigger_count, 1)

func test_slow_trigger_counts_on_slow_applied() -> void:
	_make_rule("减伤", 2.0, "治愈", 10.0)
	var t = GameState.rule_slots[0]["trigger"]
	EventBus.slow_applied.emit(2)
	assert_eq(t.trigger_count, 1)

func test_lifesteal_trigger_counts_on_lifesteal_healed() -> void:
	_make_rule("吸血", 2.0, "治愈", 10.0)
	var t = GameState.rule_slots[0]["trigger"]
	EventBus.lifesteal_healed.emit(5)
	assert_eq(t.trigger_count, 1)

func test_amplify_trigger_counts_on_amplify_consumed() -> void:
	_make_rule("强化", 2.0, "治愈", 10.0)
	var t = GameState.rule_slots[0]["trigger"]
	EventBus.amplify_consumed.emit()
	assert_eq(t.trigger_count, 1)

func test_dmg_boost_trigger_counts_on_dmg_boost_consumed() -> void:
	_make_rule("增伤", 2.0, "治愈", 10.0)
	var t = GameState.rule_slots[0]["trigger"]
	EventBus.dmg_boost_consumed.emit(2)
	assert_eq(t.trigger_count, 1)

func test_charge_trigger_counts_on_charge_release() -> void:
	_make_rule("蓄能", 2.0, "治愈", 10.0)
	var t = GameState.rule_slots[0]["trigger"]
	EventBus.rule_fired.emit(-1, "蓄能释放", 10.0)
	assert_eq(t.trigger_count, 1)

func test_burn_trigger_counts_on_burn_rule_fired() -> void:
	_make_rule("灼烧", 2.0, "治愈", 10.0)
	var t = GameState.rule_slots[0]["trigger"]
	EventBus.rule_fired.emit(-1, "灼烧", 3.0)
	assert_eq(t.trigger_count, 1)

func test_erode_trigger_counts_on_erode_rule_fired() -> void:
	_make_rule("侵蚀", 2.0, "治愈", 10.0)
	var t = GameState.rule_slots[0]["trigger"]
	EventBus.rule_fired.emit(-1, "侵蚀", 10.0)
	assert_eq(t.trigger_count, 1)

func test_effect_受击_deals_self_damage() -> void:
	_make_rule("完成圈数", 1.0, "受击", 20.0)
	GameState.hp = 100
	EventBus.loop_completed.emit()
	assert_eq(GameState.hp, 80)

func test_effect_受击_does_not_kill() -> void:
	_make_rule("完成圈数", 1.0, "受击", 9999.0)
	GameState.hp = 50
	EventBus.loop_completed.emit()
	assert_eq(GameState.hp, 1)

func test_effect_受击_emits_player_hit() -> void:
	watch_signals(EventBus)
	_make_rule("完成圈数", 1.0, "受击", 10.0)
	GameState.hp = 100
	EventBus.loop_completed.emit()
	assert_signal_emitted(EventBus, "player_hit")

func test_effect_低血_deals_self_damage() -> void:
	_make_rule("完成圈数", 1.0, "低血", 20.0)
	GameState.hp = 100
	EventBus.loop_completed.emit()
	assert_eq(GameState.hp, 80)

func test_effect_低血_does_not_kill() -> void:
	_make_rule("完成圈数", 1.0, "低血", 9999.0)
	GameState.hp = 50
	EventBus.loop_completed.emit()
	assert_eq(GameState.hp, 1)

func test_effect_低血_does_not_emit_player_hit() -> void:
	watch_signals(EventBus)
	_make_rule("完成圈数", 1.0, "低血", 10.0)
	GameState.hp = 100
	EventBus.loop_completed.emit()
	assert_signal_not_emitted(EventBus, "player_hit")

func test_effect_满血_adds_one_to_each_nonzero_stack() -> void:
	_make_rule("受击", 1.0, "满血", 1.0)
	GameState.charge_stacks = 2
	GameState.dmg_boost_stacks = 1
	GameState.amplify_stacks = 0
	EventBus.player_hit.emit(5)
	assert_eq(GameState.charge_stacks, 3)
	assert_eq(GameState.dmg_boost_stacks, 2)
	assert_eq(GameState.amplify_stacks, 0)

func test_effect_规则触发_increments_all_trigger_counts() -> void:
	_make_rule("受击", 5.0, "治愈", 10.0)
	_make_rule_slot1("完成圈数", 1.0, "规则触发", 1.0)
	var t0 = GameState.rule_slots[0]["trigger"]
	EventBus.loop_completed.emit()
	assert_eq(t0.trigger_count, 1, "slot 0 trigger count should be incremented")

func test_effect_规则触发_does_not_fire_rules() -> void:
	_make_rule("受击", 2.0, "治愈", 10.0)
	_make_rule_slot1("完成圈数", 1.0, "规则触发", 1.0)
	GameState.hp = 50
	EventBus.loop_completed.emit()
	assert_eq(GameState.hp, 50, "heal should not fire — count only reached 1 of 2")
