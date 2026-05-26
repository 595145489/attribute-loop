extends GutTest

func after_each() -> void:
	GameState.is_paused = false
	GameState.speed_multiplier = 1.0
	while GameState._panel_pause_count > 0:
		GameState.unpause_for_panel()

func test_speed_multiplier_default_is_one() -> void:
	assert_eq(GameState.speed_multiplier, 1.0)

func test_set_speed_multiplier_updates_time_scale() -> void:
	GameState.speed_multiplier = 2.0
	assert_eq(Engine.time_scale, 2.0)

func test_set_speed_multiplier_zero_pauses_time() -> void:
	GameState.speed_multiplier = 0.0
	assert_eq(Engine.time_scale, 0.0)

func test_set_speed_multiplier_three() -> void:
	GameState.speed_multiplier = 3.0
	assert_eq(Engine.time_scale, 3.0)

func test_is_paused_does_not_affect_time_scale() -> void:
	GameState.speed_multiplier = 2.0
	GameState.is_paused = true
	assert_eq(Engine.time_scale, 2.0)

func test_pause_for_panel_freezes_time() -> void:
	GameState.speed_multiplier = 2.0
	GameState.pause_for_panel()
	assert_eq(Engine.time_scale, 0.0)

func test_unpause_for_panel_restores_speed() -> void:
	GameState.speed_multiplier = 2.0
	GameState.pause_for_panel()
	GameState.unpause_for_panel()
	assert_eq(Engine.time_scale, 2.0)

func test_panel_pause_is_ref_counted() -> void:
	GameState.pause_for_panel()
	GameState.pause_for_panel()
	GameState.unpause_for_panel()
	assert_eq(Engine.time_scale, 0.0)
	GameState.unpause_for_panel()
	assert_eq(Engine.time_scale, 1.0)

func test_reset_restores_speed_to_one() -> void:
	GameState.speed_multiplier = 3.0
	GameState.reset()
	assert_eq(GameState.speed_multiplier, 1.0)

func test_reset_restores_time_scale_to_one() -> void:
	GameState.speed_multiplier = 3.0
	GameState.reset()
	assert_eq(Engine.time_scale, 1.0)

func test_reset_clears_panel_pause() -> void:
	GameState.pause_for_panel()
	GameState.reset()
	assert_eq(Engine.time_scale, 1.0)