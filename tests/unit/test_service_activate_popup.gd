extends GutTest

const AuctionManager = preload("res://src/systems/AuctionManager.gd")

func test_all_service_types_have_subtitle() -> void:
	for svc_val in AuctionManager.ServiceType.values():
		assert_true(
			AuctionManager.SERVICE_SUBTITLES.has(svc_val),
			"Missing subtitle for ServiceType %d" % svc_val
		)

func test_all_service_types_have_flavour() -> void:
	for svc_val in AuctionManager.ServiceType.values():
		assert_true(
			AuctionManager.SERVICE_FLAVOUR.has(svc_val),
			"Missing flavour for ServiceType %d" % svc_val
		)

func test_subtitle_strings_are_nonempty() -> void:
	for svc_val in AuctionManager.ServiceType.values():
		var s: String = AuctionManager.SERVICE_SUBTITLES.get(svc_val, "")
		assert_true(s.length() > 0, "Empty subtitle for ServiceType %d" % svc_val)

func test_flavour_strings_are_nonempty() -> void:
	for svc_val in AuctionManager.ServiceType.values():
		var s: String = AuctionManager.SERVICE_FLAVOUR.get(svc_val, "")
		assert_true(s.length() > 0, "Empty flavour for ServiceType %d" % svc_val)

func test_make_row_returns_panel_container() -> void:
	var popup = load("res://scenes/ui/service_activate_popup.tscn").instantiate()
	add_child_autofree(popup)
	var grp := ButtonGroup.new()
	var row = popup._make_row("治愈", "12.5", "15.0", grp, null)
	assert_not_null(row)
	assert_true(row is PanelContainer, "Row should be a PanelContainer")

func test_make_row_button_in_group() -> void:
	var popup = load("res://scenes/ui/service_activate_popup.tscn").instantiate()
	add_child_autofree(popup)
	var grp := ButtonGroup.new()
	var row = popup._make_row("护盾", "8.0", "9.6", grp, null)
	var btn: Button = row.get_node("HBox/Btn")
	assert_eq(btn.button_group, grp)

func test_merge_row_value_label_updates_when_two_selected() -> void:
	var popup = load("res://scenes/ui/service_activate_popup.tscn").instantiate()
	add_child_autofree(popup)
	# Create two component data objects with known values
	var comp_a = load("res://src/resources/ComponentData.gd").new()
	comp_a.effect_value = 10.0
	var comp_b = load("res://src/resources/ComponentData.gd").new()
	comp_b.effect_value = 5.0
	# Create rows as merge rows (skip_value_toggle=true)
	var row_a = popup._make_row("治愈", "10.0", "10.0", null, comp_a, true)
	var row_b = popup._make_row("护盾", "5.0", "5.0", null, comp_b, true)
	add_child_autofree(row_a)
	add_child_autofree(row_b)
	var btn_a: Button = row_a.get_node("HBox/Btn")
	var btn_b: Button = row_b.get_node("HBox/Btn")
	btn_a.button_pressed = true
	btn_b.button_pressed = true
	# Manually call _update_merge_labels (signal not emitted by programmatic set)
	popup._update_merge_labels([row_a, row_b])
	# Both selected rows should show the merged result
	var val_a: Label = row_a.get_node("HBox/ValueLabel")
	var val_b: Label = row_b.get_node("HBox/ValueLabel")
	# merged = (10.0 + 5.0) * DataTables.config.auction_comp_merge_ratio = 15.0 * 0.8 = 12.0
	assert_true(val_a.text.begins_with("→"), "Selected merge row A should show → result, got: " + val_a.text)
	assert_true(val_b.text.begins_with("→"), "Selected merge row B should show → result, got: " + val_b.text)
