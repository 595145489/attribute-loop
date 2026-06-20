extends GutTest

const CombatFeed = preload("res://src/ui/CombatFeed.gd")

func test_player_hit_adds_red_entry() -> void:
	var feed = preload("res://scenes/ui/combat_feed.tscn").instantiate()
	add_child_autofree(feed)
	await get_tree().process_frame
	feed._on_player_hit(42)
	var entries = feed.get_node("Entries")
	assert_eq(entries.get_child_count(), 1)
	assert_eq(entries.get_child(0).text, "你 −42")

func test_player_attacked_adds_blue_entry() -> void:
	var feed = preload("res://scenes/ui/combat_feed.tscn").instantiate()
	add_child_autofree(feed)
	await get_tree().process_frame
	feed._on_player_attacked(17)
	var entries = feed.get_node("Entries")
	assert_eq(entries.get_child_count(), 1)
	assert_eq(entries.get_child(0).text, "敌 −17")

func test_cap_trims_oldest() -> void:
	var feed = preload("res://scenes/ui/combat_feed.tscn").instantiate()
	add_child_autofree(feed)
	await get_tree().process_frame
	# Emit more than MAX_VISIBLE; oldest must be freed to hold the cap.
	for i in CombatFeed.MAX_VISIBLE + 3:
		feed._on_player_hit(i)
	var entries = feed.get_node("Entries")
	assert_eq(entries.get_child_count(), CombatFeed.MAX_VISIBLE)
	# Newest surviving entry is the last emitted value.
	assert_eq(entries.get_child(entries.get_child_count() - 1).text,
		"你 −%d" % (CombatFeed.MAX_VISIBLE + 2))

func test_rule_fired_damage_effects_surface() -> void:
	var feed = preload("res://scenes/ui/combat_feed.tscn").instantiate()
	add_child_autofree(feed)
	await get_tree().process_frame
	feed._on_rule_fired(0, "灼烧伤害", 5.0)
	feed._on_rule_fired(0, "蓄能释放", 30.0)
	# Buff-only effects must NOT appear in the feed.
	feed._on_rule_fired(0, "治愈", 10.0)
	feed._on_rule_fired(0, "护盾", 8.0)
	var entries = feed.get_node("Entries")
	assert_eq(entries.get_child_count(), 2)
	assert_eq(entries.get_child(0).text, "灼烧 −5")
	assert_eq(entries.get_child(1).text, "蓄能释放 −30")
