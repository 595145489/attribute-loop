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
