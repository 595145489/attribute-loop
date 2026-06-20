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
