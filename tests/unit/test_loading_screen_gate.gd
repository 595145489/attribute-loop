extends GutTest

const CONFIG_PATH := "user://onboarding.cfg"
const SENTINEL := "res://tests/.test_mode"
const SCREEN_SCRIPT := preload("res://src/ui/LoadingScreen.gd")

func before_each() -> void:
	DirAccess.remove_absolute(CONFIG_PATH)
	OnboardingState.reload()
	DirAccess.remove_absolute(SENTINEL)

func after_all() -> void:
	DirAccess.remove_absolute(CONFIG_PATH)
	DirAccess.remove_absolute(SENTINEL)

# LoadingScreen.new() does NOT run _ready (node never enters tree), so the
# @onready children stay null and preload never fires. _should_block_start()
# only touches OnboardingState + the sentinel file, so this is safe.
func _make_screen() -> Control:
	var screen := SCREEN_SCRIPT.new()
	autofree(screen)
	return screen

func test_blocks_when_not_completed_and_not_test_mode() -> void:
	var screen := _make_screen()
	assert_true(screen._should_block_start())

func test_does_not_block_when_completed() -> void:
	OnboardingState.mark_tutorial_completed()
	var screen := _make_screen()
	assert_false(screen._should_block_start())

func test_does_not_block_in_test_mode_even_if_not_completed() -> void:
	var f := FileAccess.open(SENTINEL, FileAccess.WRITE)
	f.close()
	var screen := _make_screen()
	assert_false(screen._should_block_start())
