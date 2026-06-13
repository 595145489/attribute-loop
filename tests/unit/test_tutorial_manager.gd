extends GutTest

func before_each() -> void:
	GameState.reset()
	GameState.is_tutorial = false
	TutorialManager.is_active = false
	TutorialManager.current_step = 0

func test_not_active_by_default():
	assert_false(TutorialManager.is_active)

func test_step_count_matches_tutorial_steps():
	assert_eq(TutorialManager.get_step_count(), TutorialSteps.get_steps().size())

func test_current_step_zero_initially():
	assert_eq(TutorialManager.current_step, 0)
