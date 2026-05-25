extends GutTest

func before_each() -> void:
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
    assert_eq(GameState.get_deletion_cost(), 20)

func test_get_deletion_cost_second_deletion() -> void:
    GameState.deletion_count = 1
    assert_eq(GameState.get_deletion_cost(), 50)

func test_get_deletion_cost_third_deletion() -> void:
    GameState.deletion_count = 2
    assert_eq(GameState.get_deletion_cost(), 100)

func test_get_deletion_cost_fourth_uses_multiplier() -> void:
    GameState.deletion_count = 3
    assert_eq(GameState.get_deletion_cost(), 200)

func test_get_deletion_cost_fifth_doubles_again() -> void:
    GameState.deletion_count = 4
    assert_eq(GameState.get_deletion_cost(), 400)

func test_can_afford_deletion_true_when_enough_gold() -> void:
    GameState.gold = 20
    GameState.deletion_count = 0
    assert_true(GameState.can_afford_deletion())

func test_can_afford_deletion_false_when_insufficient() -> void:
    GameState.gold = 19
    GameState.deletion_count = 0
    assert_false(GameState.can_afford_deletion())

func test_pay_deletion_cost_deducts_gold() -> void:
    GameState.gold = 100
    GameState.deletion_count = 0
    GameState.pay_deletion_cost()
    assert_eq(GameState.gold, 80)

func test_pay_deletion_cost_increments_deletion_count() -> void:
    GameState.gold = 100
    GameState.deletion_count = 0
    GameState.pay_deletion_cost()
    assert_eq(GameState.deletion_count, 1)
