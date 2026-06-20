extends GutTest

func before_each() -> void:
    GameState.difficulty = "hard"
    GameState.reset()

func test_initial_hp_equals_hp_max() -> void:
    assert_eq(GameState.hp, GameState.hp_max)

func test_hp_max_is_positive() -> void:
    assert_gt(GameState.hp_max, 0)

func test_take_damage_reduces_hp() -> void:
    var before = GameState.hp
    GameState.take_damage(10)
    assert_eq(GameState.hp, before - 10)

func test_take_damage_clamps_to_zero() -> void:
    GameState.take_damage(GameState.hp_max + 999)
    assert_eq(GameState.hp, 0)

func test_take_damage_emits_player_died_when_hp_zero() -> void:
    watch_signals(EventBus)
    GameState.take_damage(GameState.hp_max + 999)
    assert_signal_emitted(EventBus, "player_died")

func test_reset_restores_hp() -> void:
    GameState.take_damage(50)
    GameState.reset()
    assert_eq(GameState.hp, GameState.hp_max)

func test_reset_clears_loops_and_kills() -> void:
    GameState.loops_completed = 5
    GameState.enemies_killed = 10
    GameState.reset()
    assert_eq(GameState.loops_completed, 0)
    assert_eq(GameState.enemies_killed, 0)

func test_is_paused_defaults_false() -> void:
    assert_false(GameState.is_paused)

func test_inventory_empty_after_reset() -> void:
    var c = ComponentData.new()
    GameState.add_to_inventory(c)
    GameState.reset()
    assert_eq(GameState.inventory.size(), 0)

func test_inventory_has_space_when_empty() -> void:
    assert_true(GameState.inventory_has_space())

func test_inventory_full_at_cap() -> void:
    for i in DataTables.config.inventory_cap:
        GameState.add_to_inventory(ComponentData.new())
    assert_false(GameState.inventory_has_space())

func test_add_to_inventory_appends() -> void:
    var c = ComponentData.new()
    c.id = "受击"
    GameState.add_to_inventory(c)
    assert_true(GameState.inventory.has(c))

func test_remove_from_inventory() -> void:
    var c = ComponentData.new()
    GameState.add_to_inventory(c)
    GameState.remove_from_inventory(c)
    assert_false(GameState.inventory.has(c))

func test_delete_component_removes_from_inventory() -> void:
    var c = ComponentData.new()
    GameState.add_to_inventory(c)
    GameState.delete_component(c)
    assert_false(GameState.inventory.has(c))

func test_rule_slots_initialized_after_reset() -> void:
    GameState.reset()
    assert_eq(GameState.rule_slots.size(), 2)

func test_equip_trigger_only_into_trigger_sub_slot() -> void:
    var c = ComponentData.new()
    c.id = "受击"
    c.slot_type = ComponentData.SlotType.TRIGGER_ONLY
    GameState.add_to_inventory(c)
    GameState.equip(c, 0, true)
    assert_eq(GameState.rule_slots[0]["trigger"], c)
    assert_false(GameState.inventory.has(c))

func test_equip_effect_only_into_effect_sub_slot() -> void:
    var c = ComponentData.new()
    c.slot_type = ComponentData.SlotType.EFFECT_ONLY
    GameState.add_to_inventory(c)
    GameState.equip(c, 0, false)
    assert_eq(GameState.rule_slots[0]["effect"], c)

func test_equip_swaps_when_slot_occupied() -> void:
    var old_c = ComponentData.new()
    old_c.slot_type = ComponentData.SlotType.TRIGGER_ONLY
    GameState.add_to_inventory(old_c)
    GameState.equip(old_c, 0, true)
    var new_c = ComponentData.new()
    new_c.slot_type = ComponentData.SlotType.TRIGGER_ONLY
    GameState.add_to_inventory(new_c)
    GameState.equip(new_c, 0, true)
    assert_eq(GameState.rule_slots[0]["trigger"], new_c)
    assert_true(GameState.inventory.has(old_c))

func test_unequip_moves_to_inventory() -> void:
    var c = ComponentData.new()
    c.slot_type = ComponentData.SlotType.TRIGGER_ONLY
    GameState.add_to_inventory(c)
    GameState.equip(c, 0, true)
    GameState.unequip(0, true)
    assert_eq(GameState.rule_slots[0]["trigger"], null)
    assert_true(GameState.inventory.has(c))

func test_pending_reflect_ratio_zero_after_reset() -> void:
    GameState.pending_reflect_ratio = 0.5
    GameState.reset()
    assert_eq(GameState.pending_reflect_ratio, 0.0)

func test_gold_zero_after_reset() -> void:
    GameState.gold = 50
    GameState.reset()
    assert_eq(GameState.gold, 0)

func test_deletion_count_zero_after_reset() -> void:
    GameState.deletion_count = 3
    GameState.reset()
    assert_eq(GameState.deletion_count, 0)

func test_altar_bonuses_empty_after_reset() -> void:
    GameState.altar_bonuses["治愈"] = 5.0
    GameState.reset()
    assert_eq(GameState.altar_bonuses.size(), 0)

func test_get_deletion_cost_first_deletion() -> void:
    GameState.reset()
    assert_eq(GameState.get_deletion_cost(), 15)

func test_get_deletion_cost_second_deletion() -> void:
    GameState.deletion_count = 1
    assert_eq(GameState.get_deletion_cost(), 35)

func test_get_deletion_cost_third_deletion() -> void:
    GameState.deletion_count = 2
    assert_eq(GameState.get_deletion_cost(), 70)

func test_get_deletion_cost_fourth_uses_multiplier() -> void:
    GameState.deletion_count = 3
    assert_eq(GameState.get_deletion_cost(), 140)

func test_get_deletion_cost_fifth_doubles_again() -> void:
    GameState.deletion_count = 4
    assert_eq(GameState.get_deletion_cost(), 280)

func test_can_afford_deletion_true_when_enough_gold() -> void:
    GameState.gold = 15
    GameState.deletion_count = 0
    assert_true(GameState.can_afford_deletion())

func test_can_afford_deletion_false_when_insufficient() -> void:
    GameState.gold = 14
    GameState.deletion_count = 0
    assert_false(GameState.can_afford_deletion())

func test_pay_deletion_cost_deducts_gold() -> void:
    GameState.gold = 100
    GameState.deletion_count = 0
    GameState.pay_deletion_cost()
    assert_eq(GameState.gold, 85)

func test_pay_deletion_cost_increments_deletion_count() -> void:
    GameState.gold = 100
    GameState.deletion_count = 0
    GameState.pay_deletion_cost()
    assert_eq(GameState.deletion_count, 1)

func test_loops_in_phase_zero_after_reset() -> void:
    GameState.loops_in_phase = 5
    GameState.reset()
    assert_eq(GameState.loops_in_phase, 0)

func test_force_phase_advance_increments_phase() -> void:
    GameState.current_phase = 1
    GameState.force_phase_advance()
    assert_eq(GameState.current_phase, 2)

func test_force_phase_advance_resets_loops_in_phase() -> void:
    GameState.loops_in_phase = 7
    GameState.force_phase_advance()
    assert_eq(GameState.loops_in_phase, 0)

func test_force_phase_advance_emits_phase_changed() -> void:
    watch_signals(EventBus)
    GameState.force_phase_advance()
    assert_signal_emitted(EventBus, "phase_changed")

func test_in_verdict_loop_false_after_reset() -> void:
    GameState.in_verdict_loop = true
    GameState.reset()
    assert_false(GameState.in_verdict_loop)

func test_verdict_loops_survived_zero_after_reset() -> void:
    GameState.verdict_loops_survived = 3
    GameState.reset()
    assert_eq(GameState.verdict_loops_survived, 0)

func test_reset_clears_service_bar() -> void:
    GameState.service_bar = [0, 1, 2]
    GameState.deletion_free = true
    GameState.enemy_pardon_type = "汲取者"
    GameState.enemy_pardon_remaining = 3
    GameState.reset()
    assert_eq(GameState.service_bar.size(), 0)
    assert_false(GameState.deletion_free)
    assert_eq(GameState.enemy_pardon_type, "")
    assert_eq(GameState.enemy_pardon_remaining, 0)

func test_deletion_free_skips_cost_and_count() -> void:
    GameState.gold = 100
    GameState.deletion_free = true
    GameState.pay_deletion_cost()
    assert_eq(GameState.gold, 100)
    assert_eq(GameState.deletion_count, 0)
    assert_false(GameState.deletion_free)

func test_shield_absorbs_damage_before_hp() -> void:
    GameState.shield = 30
    var hp_before = GameState.hp
    GameState.take_damage(20)
    assert_eq(GameState.shield, 10)
    assert_eq(GameState.hp, hp_before)

func test_shield_depletes_then_overflow_hits_hp() -> void:
    GameState.shield = 10
    var hp_before = GameState.hp
    GameState.take_damage(20)
    assert_eq(GameState.shield, 0)
    assert_eq(GameState.hp, hp_before - 10)

func test_shield_resets_to_zero_on_reset() -> void:
    GameState.shield = 50
    GameState.reset()
    assert_eq(GameState.shield, 0)

func test_slow_stacks_resets_to_zero_on_reset() -> void:
    GameState.slow_stacks = 5
    GameState.reset()
    assert_eq(GameState.slow_stacks, 0)

func test_lifesteal_ratio_resets_to_zero_on_reset() -> void:
    GameState.lifesteal_ratio = 0.5
    GameState.reset()
    assert_almost_eq(GameState.lifesteal_ratio, 0.0, 0.001)

func test_hp_max_matches_player_data() -> void:
    assert_eq(GameState.hp_max, DataTables.player.hp_base)

func test_hp_starts_at_hp_max_after_reset() -> void:
    GameState.hp = 1
    GameState.reset()
    assert_eq(GameState.hp, DataTables.player.hp_base)

func test_boss_circle_pending_false_after_reset() -> void:
    GameState.boss_circle_pending = true
    GameState.reset()
    assert_false(GameState.boss_circle_pending)

func test_dmg_bonus_zero_after_reset() -> void:
    GameState.dmg_bonus = 5
    GameState.reset()
    assert_eq(GameState.dmg_bonus, 0)

func test_attack_interval_bonus_zero_after_reset() -> void:
    GameState.attack_interval_bonus = 0.3
    GameState.reset()
    assert_almost_eq(GameState.attack_interval_bonus, 0.0, 0.001)

func test_service_bar_max_restored_after_reset() -> void:
    GameState.service_bar_max = 99
    GameState.reset()
    assert_eq(GameState.service_bar_max, DataTables.config.auction_service_bar_cap)

func test_dmg_boost_stacks_starts_zero() -> void:
    assert_eq(GameState.dmg_boost_stacks, 0)

func test_charge_stacks_starts_zero() -> void:
    assert_eq(GameState.charge_stacks, 0)

func test_dmg_boost_resets_on_reset() -> void:
    GameState.dmg_boost_stacks = 5
    GameState.reset()
    assert_eq(GameState.dmg_boost_stacks, 0)

func test_charge_resets_on_reset() -> void:
    GameState.charge_stacks = 3
    GameState.reset()
    assert_eq(GameState.charge_stacks, 0)

func test_shield_absorbed_signal_emitted_when_shield_absorbs() -> void:
    watch_signals(EventBus)
    GameState.shield = 50
    GameState.take_damage(20)
    assert_signal_emitted(EventBus, "shield_absorbed")

func test_shield_absorbed_signal_not_emitted_without_shield() -> void:
    watch_signals(EventBus)
    GameState.shield = 0
    GameState.take_damage(20)
    assert_signal_not_emitted(EventBus, "shield_absorbed")

func test_difficulty_defaults_hard() -> void:
    GameState.difficulty = "hard"
    GameState.reset()
    assert_eq(GameState.difficulty, "hard")

func test_reset_creates_2_slots_for_hard() -> void:
    GameState.difficulty = "hard"
    GameState.reset()
    assert_eq(GameState.rule_slots.size(), 2)

func test_reset_creates_3_slots_for_easy() -> void:
    GameState.difficulty = "easy"
    GameState.reset()
    assert_eq(GameState.rule_slots.size(), 3)

func test_reset_does_not_clear_difficulty() -> void:
    GameState.difficulty = "easy"
    GameState.reset()
    assert_eq(GameState.difficulty, "easy")
