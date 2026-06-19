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

func test_get_copy_phase_6_label() -> void:
	var copy = pt.get_copy(6)
	assert_eq(copy["label"], "Phase 6 · 裁决前夜Boss")

func test_get_copy_phase_1_text_not_empty() -> void:
	var copy = pt.get_copy(1)
	assert_true(copy["text"].length() > 0)

func test_get_copy_all_six_phases_have_entries() -> void:
	for i in range(1, 7):
		var copy = pt.get_copy(i)
		assert_false(copy.is_empty(), "Phase %d missing copy" % i)

func test_get_copy_phase_7_is_empty() -> void:
	assert_eq(pt.get_copy(7), {})

func test_phase2_stone_thread_present() -> void:
	# 承上启下 connecting line — must not be deleted at polish time.
	var copy = pt.get_copy(2)
	assert_true(copy["text"].find("也许这里不只有你") != -1, "Phase 2 must keep the stone connecting line")

func test_phase5_stone_bookend_present() -> void:
	# Stone (石子) bookend echo of phase 2's 问号 — must not be deleted at polish time.
	var copy = pt.get_copy(5)
	assert_true(copy["text"].find("石子摆成的问号") != -1, "Phase 5 must keep the stone bookend echo")

func test_get_background_phase_1() -> void:
	assert_eq(pt.get_background_path(1), "res://resources/backgrounds/bg_phase_1.png")

func test_get_background_phase_2() -> void:
	assert_eq(pt.get_background_path(2), "res://resources/backgrounds/bg_phase_2.png")

func test_get_background_phase_3() -> void:
	assert_eq(pt.get_background_path(3), "res://resources/backgrounds/bg_phase_3.png")

func test_get_background_phase_4() -> void:
	assert_eq(pt.get_background_path(4), "res://resources/backgrounds/bg_phase_4.png")

func test_get_background_phase_5() -> void:
	assert_eq(pt.get_background_path(5), "res://resources/backgrounds/bg_phase_5.png")

func test_get_background_phase_6_shares_phase_5() -> void:
	assert_eq(pt.get_background_path(6), "res://resources/backgrounds/bg_phase_5.png")

func test_get_background_phase_7_is_empty() -> void:
	assert_eq(pt.get_background_path(7), "")
