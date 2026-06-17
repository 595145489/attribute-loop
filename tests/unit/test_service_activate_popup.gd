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
