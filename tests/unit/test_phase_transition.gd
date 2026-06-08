extends GutTest

const PhaseTransition = preload("res://src/ui/PhaseTransition.gd")

var pt: PhaseTransition

func before_each() -> void:
	pt = PhaseTransition.new()

func after_each() -> void:
	pt.free()

func test_get_copy_phase_1_label() -> void:
	var copy = pt.get_copy(1)
	assert_eq(copy["label"], "Phase 1 · 觉醒")

func test_get_copy_phase_10_label() -> void:
	var copy = pt.get_copy(10)
	assert_eq(copy["label"], "Phase 10 · 裁决前夜")

func test_get_copy_phase_1_text_not_empty() -> void:
	var copy = pt.get_copy(1)
	assert_true(copy["text"].length() > 0)

func test_get_copy_all_phases_have_entries() -> void:
	for i in range(1, 11):
		var copy = pt.get_copy(i)
		assert_false(copy.is_empty(), "Phase %d missing copy" % i)

func test_get_background_phase_1_returns_1_2() -> void:
	assert_eq(pt.get_background_path(1), "res://resources/backgrounds/bg_phase_1_2.png")

func test_get_background_phase_2_returns_1_2() -> void:
	assert_eq(pt.get_background_path(2), "res://resources/backgrounds/bg_phase_1_2.png")

func test_get_background_phase_3_returns_3_4() -> void:
	assert_eq(pt.get_background_path(3), "res://resources/backgrounds/bg_phase_3_4.png")

func test_get_background_phase_4_returns_3_4() -> void:
	assert_eq(pt.get_background_path(4), "res://resources/backgrounds/bg_phase_3_4.png")

func test_get_background_phase_5_returns_5_6() -> void:
	assert_eq(pt.get_background_path(5), "res://resources/backgrounds/bg_phase_5_6.png")

func test_get_background_phase_9_returns_9_10() -> void:
	assert_eq(pt.get_background_path(9), "res://resources/backgrounds/bg_phase_9_10.png")

func test_get_background_phase_10_returns_9_10() -> void:
	assert_eq(pt.get_background_path(10), "res://resources/backgrounds/bg_phase_9_10.png")
