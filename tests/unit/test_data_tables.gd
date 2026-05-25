extends GutTest

func test_game_config_loaded() -> void:
	assert_not_null(DataTables.config)
	assert_gt(DataTables.config.stat_scale_factor, 0.0)

func test_player_data_loaded() -> void:
	assert_not_null(DataTables.player)
	assert_gt(DataTables.player.hp_base, 0)
	assert_gt(DataTables.player.walk_speed, 0.0)

func test_enemy_data_has_all_five_types() -> void:
	assert_true(DataTables.enemies.has("汲取者"))
	assert_true(DataTables.enemies.has("守卫者"))
	assert_true(DataTables.enemies.has("急袭者"))
	assert_true(DataTables.enemies.has("复制者"))
	assert_true(DataTables.enemies.has("先驱者"))

func test_enemy_data_values_valid() -> void:
	var e: EnemyData = DataTables.enemies["汲取者"]
	assert_gt(e.hp_base, 0)
	assert_gt(e.dmg_base, 0)
	assert_gt(e.attack_interval, 0.0)

func test_all_ten_phases_loaded() -> void:
	for i in range(1, 11):
		assert_true(DataTables.phases.has(i), "Missing phase %d" % i)

func test_phase_data_values_valid() -> void:
	var p: PhaseData = DataTables.phases[1]
	assert_eq(p.phase_id, 1)
	assert_gt(p.spawn_count_max, 0)
	assert_false(p.spawn_weights.is_empty())

func test_get_phase_returns_correct_data() -> void:
	var p = DataTables.get_phase(3)
	assert_eq(p.phase_id, 3)

func test_get_enemy_returns_correct_data() -> void:
	var e = DataTables.get_enemy("守卫者")
	assert_eq(e.id, "守卫者")

func test_get_component_受击_is_trigger_only() -> void:
	var c: ComponentData = DataTables.get_component("受击")
	assert_eq(c.slot_type, ComponentData.SlotType.TRIGGER_ONLY)

func test_get_component_治愈_is_both() -> void:
	var c: ComponentData = DataTables.get_component("治愈")
	assert_eq(c.slot_type, ComponentData.SlotType.BOTH)

func test_get_component_反射_is_both() -> void:
	var c: ComponentData = DataTables.get_component("反射")
	assert_eq(c.slot_type, ComponentData.SlotType.BOTH)

func test_get_drop_preset_tier1_has_受击_range() -> void:
	var dp: DropPreset = DataTables.get_drop_preset(1)
	assert_true(dp.component_ranges.has("受击"))
	var r = dp.component_ranges["受击"]
	assert_true(r.has("trigger"))

func test_enemy_汲取者_has_component_pair_range() -> void:
	var e: EnemyData = DataTables.get_enemy("汲取者")
	assert_gte(e.component_pair_max, e.component_pair_min)
	assert_gte(e.component_pair_min, 1)

func test_enemy_汲取者_has_trigger_weights() -> void:
	var e: EnemyData = DataTables.get_enemy("汲取者")
	assert_false(e.trigger_weights.is_empty())

func test_enemy_汲取者_has_phase_drop_preset() -> void:
	var e: EnemyData = DataTables.get_enemy("汲取者")
	assert_true(e.phase_drop_presets.has(1))

func test_phase1_has_component_count_bonus() -> void:
	var p: PhaseData = DataTables.get_phase(1)
	assert_eq(p.component_count_bonus, 0)

func test_config_has_inventory_cap() -> void:
	assert_eq(DataTables.config.inventory_cap, 12)

func test_config_has_rule_slot_count() -> void:
	assert_eq(DataTables.config.rule_slot_count_base, 2)

func test_enemy_has_gold_scale() -> void:
	var ed: EnemyData = DataTables.get_enemy("汲取者")
	assert_eq(ed.gold_scale, 0.3)

func test_config_has_deletion_cost_sequence() -> void:
	assert_eq(DataTables.config.deletion_cost_sequence.size(), 3)
	assert_eq(DataTables.config.deletion_cost_sequence[0], 20)
	assert_eq(DataTables.config.deletion_cost_sequence[1], 50)
	assert_eq(DataTables.config.deletion_cost_sequence[2], 100)

func test_config_has_deletion_cost_multiplier() -> void:
	assert_eq(DataTables.config.deletion_cost_multiplier, 2.0)

func test_tile_max_rules_has_13_entries() -> void:
	assert_eq(DataTables.TILE_MAX_RULES.size(), 13)

func test_tile_max_rules_altar_at_index_0() -> void:
	assert_eq(DataTables.TILE_MAX_RULES[0], 0)

func test_tile_max_rules_values_in_range() -> void:
	for i in range(1, DataTables.TILE_MAX_RULES.size()):
		var v = DataTables.TILE_MAX_RULES[i]
		assert_true(v >= 1 and v <= 3, "tile %d has invalid max_rules %d" % [i, v])
