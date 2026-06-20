extends GutTest

func test_easy_player_slots_has_three_entries() -> void:
	assert_eq(DataTables.EASY_PLAYER_SLOTS.size(), 3)

func test_easy_tile_rules_has_five_entries() -> void:
	assert_eq(DataTables.EASY_TILE_RULES.size(), 5)

func test_easy_tile_rules_targets_expected_tiles() -> void:
	assert_true(DataTables.EASY_TILE_RULES.has(1))
	assert_true(DataTables.EASY_TILE_RULES.has(5))
	assert_true(DataTables.EASY_TILE_RULES.has(8))
	assert_true(DataTables.EASY_TILE_RULES.has(9))
	assert_true(DataTables.EASY_TILE_RULES.has(12))

func test_make_easy_slot_sets_ids_and_values() -> void:
	var spec := {"trigger": "受击", "trigger_value": 5, "effect": "治愈", "effect_value": 12}
	var slot: Dictionary = DataTables.make_easy_slot(spec)
	assert_eq(slot["trigger"].id, "受击")
	assert_eq(slot["effect"].id, "治愈")
	assert_eq(slot["trigger"].trigger_value, 5.0)
	assert_eq(slot["effect"].effect_value, 12.0)
	assert_eq(slot["trigger"].trigger_count, 0)
	assert_eq(slot["effect"].trigger_count, 0)

func test_make_easy_slot_duplicates_instances() -> void:
	var spec := {"trigger": "经过", "trigger_value": 6, "effect": "护盾", "effect_value": 15}
	var slot: Dictionary = DataTables.make_easy_slot(spec)
	assert_false(slot["trigger"] == DataTables.get_component("经过"))
	assert_false(slot["effect"] == DataTables.get_component("护盾"))

func test_apply_easy_player_slots_fills_three_slots() -> void:
	GameState.difficulty = "easy"
	GameState.reset()
	GameState.apply_easy_player_slots()
	assert_eq(GameState.rule_slots.size(), 3)
	assert_eq(GameState.rule_slots[0]["trigger"].id, "受击")
	assert_eq(GameState.rule_slots[0]["effect"].id, "治愈")
	assert_eq(GameState.rule_slots[1]["trigger"].id, "治愈")
	assert_eq(GameState.rule_slots[1]["effect"].id, "灼烧")
	assert_eq(GameState.rule_slots[2]["trigger"].id, "治愈")
	assert_eq(GameState.rule_slots[2]["effect"].id, "护盾")

func test_apply_easy_player_slots_owns_distinct_instances() -> void:
	GameState.difficulty = "easy"
	GameState.reset()
	GameState.apply_easy_player_slots()
	assert_false(GameState.rule_slots[1]["trigger"] == GameState.rule_slots[2]["trigger"])

func _make_tile(idx: int, altar: bool = false) -> Tile:
	var t := Tile.new()
	t.tile_index = idx
	t.is_altar = altar
	add_child_autofree(t)
	return t

func _make_all_tiles() -> Array:
	var tiles: Array = []
	for i in range(13):
		tiles.append(_make_tile(i, i == 0))
	return tiles

func test_apply_easy_tile_rules_fills_five_tiles() -> void:
	var tiles := _make_all_tiles()
	DataTables.apply_easy_tile_rules(tiles)
	var filled: Array = []
	for t in tiles:
		if t.tile_index > 0 and not t.rule_slots.is_empty() and t.rule_slots[0]["trigger"] != null:
			filled.append(t.tile_index)
	assert_eq(filled.size(), 5)
	for idx in [1, 5, 8, 9, 12]:
		assert_true(filled.has(idx), "expected tile %d filled" % idx)

func test_apply_easy_tile_rules_skips_altar() -> void:
	var tiles := _make_all_tiles()
	DataTables.apply_easy_tile_rules(tiles)
	assert_eq(tiles[0].rule_slots.size(), 0)

func test_apply_easy_tile_rules_tile9_is_护盾() -> void:
	var tiles := _make_all_tiles()
	DataTables.apply_easy_tile_rules(tiles)
	var t9: Tile = tiles[9]
	assert_eq(t9.rule_slots[0]["trigger"].id, "经过")
	assert_eq(t9.rule_slots[0]["effect"].id, "护盾")

func test_apply_easy_tile_rules_leaves_other_tiles_empty() -> void:
	var tiles := _make_all_tiles()
	DataTables.apply_easy_tile_rules(tiles)
	var t2: Tile = tiles[2]
	assert_null(t2.rule_slots[0]["trigger"])
