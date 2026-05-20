extends GutTest

func test_roll_spawn_count_within_range() -> void:
	var phase: PhaseData = DataTables.get_phase(1)
	for i in 100:
		var count = GameLoop._roll_spawn_count(phase)
		assert_gte(count, phase.spawn_count_min)
		assert_lte(count, phase.spawn_count_max)

func test_pick_enemy_id_only_unlocked() -> void:
	var phase: PhaseData = DataTables.get_phase(1)
	for i in 50:
		var id = GameLoop._pick_enemy_id(phase, 1)
		var enemy_data: EnemyData = DataTables.get_enemy(id)
		assert_lte(enemy_data.unlock_phase, 1)

func test_pick_enemy_id_from_weights() -> void:
	var phase: PhaseData = DataTables.get_phase(1)
	var id = GameLoop._pick_enemy_id(phase, 1)
	assert_true(id == "汲取者" or id == "守卫者")

func test_pick_distinct_tile_indices_correct_count() -> void:
	var indices = GameLoop._pick_tile_indices(3, 12)
	assert_eq(indices.size(), 3)

func test_pick_distinct_tile_indices_no_duplicates() -> void:
	var indices = GameLoop._pick_tile_indices(5, 12)
	var unique = {}
	for i in indices:
		unique[i] = true
	assert_eq(unique.size(), 5)
