extends GutTest

func test_init_stat_phase_override_increases_hp_at_higher_phase() -> void:
	var e1 := Enemy.new()
	e1.init("汲取者", 1)
	var hp_phase1 := e1.hp_max

	var e2 := Enemy.new()
	e2.init("汲取者", 5)
	var hp_phase5 := e2.hp_max

	assert_gt(hp_phase5, hp_phase1)

func test_init_default_uses_current_phase() -> void:
	GameState.current_phase = 2
	var e := Enemy.new()
	e.init("守卫者")
	var expected_hp := DataTables.calc_stat(DataTables.get_enemy("守卫者").hp_base, 2)
	assert_eq(e.hp_max, expected_hp)
	GameState.reset()
