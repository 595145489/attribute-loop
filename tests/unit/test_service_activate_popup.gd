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
