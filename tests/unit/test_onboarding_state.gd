extends GutTest

const CONFIG_PATH := "user://onboarding.cfg"

func before_each() -> void:
	# Ensure a clean slate on disk and in memory before every test.
	DirAccess.remove_absolute(CONFIG_PATH)
	OnboardingState.reload()

func after_all() -> void:
	# Do not pollute the dev machine between runs.
	DirAccess.remove_absolute(CONFIG_PATH)

func test_not_completed_when_no_config_file() -> void:
	assert_false(OnboardingState.is_tutorial_completed())

func test_mark_completed_flips_flag_in_memory() -> void:
	OnboardingState.mark_tutorial_completed()
	assert_true(OnboardingState.is_tutorial_completed())

func test_completion_persists_across_reload() -> void:
	OnboardingState.mark_tutorial_completed()
	OnboardingState.reload()
	assert_true(OnboardingState.is_tutorial_completed())

func test_reload_false_after_file_deleted() -> void:
	OnboardingState.mark_tutorial_completed()
	DirAccess.remove_absolute(CONFIG_PATH)
	OnboardingState.reload()
	assert_false(OnboardingState.is_tutorial_completed())
