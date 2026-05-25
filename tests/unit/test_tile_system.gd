extends GutTest

func _make_tile(idx: int, altar: bool = false) -> Tile:
	var t := Tile.new()
	t.tile_index = idx
	t.is_altar = altar
	add_child_autofree(t)
	return t

func test_normal_tile_rule_slots_match_config() -> void:
	var t := _make_tile(1)
	assert_eq(t.rule_slots.size(), 1)

func test_normal_tile_index4_has_3_slots() -> void:
	var t := _make_tile(4)
	assert_eq(t.rule_slots.size(), 3)

func test_normal_tile_slots_start_empty() -> void:
	var t := _make_tile(1)
	assert_null(t.rule_slots[0]["trigger"])
	assert_null(t.rule_slots[0]["effect"])

func test_pass_count_starts_zero() -> void:
	var t := _make_tile(1)
	assert_eq(t.pass_count, 0)

func test_altar_tile_has_no_rule_slots() -> void:
	var t := _make_tile(0, true)
	assert_eq(t.rule_slots.size(), 0)

func test_altar_slots_size_matches_phase_requirement() -> void:
	GameState.reset()
	var t := _make_tile(0, true)
	var expected := DataTables.get_phase(1).altar_requirement
	assert_eq(t.altar_slots.size(), expected)

func test_altar_slots_start_null() -> void:
	GameState.reset()
	var t := _make_tile(0, true)
	for slot in t.altar_slots:
		assert_null(slot)