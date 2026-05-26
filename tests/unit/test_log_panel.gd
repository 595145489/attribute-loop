extends GutTest

func test_add_entry_trims_oldest_when_over_max() -> void:
	DataTables.config.combat_log_max_entries = 3
	var panel = preload("res://scenes/ui/log_panel.tscn").instantiate()
	add_child_autofree(panel)
	await get_tree().process_frame
	panel._add_entry("a", Color.WHITE)
	panel._add_entry("b", Color.WHITE)
	panel._add_entry("c", Color.WHITE)
	panel._add_entry("d", Color.WHITE)
	var entries = panel.get_node("VBox/Scroll/Entries")
	assert_eq(entries.get_child_count(), 3)
	assert_eq(entries.get_child(entries.get_child_count() - 1).text, "d")
	DataTables.config.combat_log_max_entries = 50

func test_gold_entry_only_added_on_increase() -> void:
	var panel = preload("res://scenes/ui/log_panel.tscn").instantiate()
	add_child_autofree(panel)
	await get_tree().process_frame
	panel._last_gold = 100
	panel._on_gold_changed(80)
	panel._on_gold_changed(120)
	var entries = panel.get_node("VBox/Scroll/Entries")
	assert_eq(entries.get_child_count(), 1)
	assert_eq(entries.get_child(0).text, "+40 金")
