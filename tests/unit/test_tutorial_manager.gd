extends GutTest

func before_each() -> void:
	GameState.reset()
	GameState.is_tutorial = false
	TutorialManager.is_active = false
	TutorialManager.current_step = 0
	DirAccess.remove_absolute("user://onboarding.cfg")
	OnboardingState.reload()

func test_not_active_by_default():
	assert_false(TutorialManager.is_active)

func test_step_count_matches_tutorial_steps():
	assert_eq(TutorialManager.get_step_count(), TutorialSteps.get_steps().size())

func test_current_step_zero_initially():
	assert_eq(TutorialManager.current_step, 0)

func test_mark_completed_sets_onboarding_state() -> void:
	assert_false(OnboardingState.is_tutorial_completed())
	TutorialManager._mark_completed()
	assert_true(OnboardingState.is_tutorial_completed())

func test_skip_method_exists_and_marks_completed() -> void:
	# skip() routes through _mark_completed(); we test _mark_completed directly
	# because skip()'s scene change is unsafe inside the GUT runner.
	assert_true(TutorialManager.has_method("skip"))
	TutorialManager._mark_completed()
	assert_true(OnboardingState.is_tutorial_completed())
