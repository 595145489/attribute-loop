extends GutTest

func after_each() -> void:
	GameState.is_paused = false
	GameState.speed_multiplier = 1.0

func test_speed_multiplier_default_is_one() -> void:
	assert_eq(GameState.speed_multiplier, 1.0)

func test_set_speed_multiplier_updates_time_scale() -> void:
	GameState.is_paused = false
	GameState.speed_multiplier = 2.0
	assert_eq(Engine.time_scale, 2.0)

func test_set_speed_multiplier_zero_pauses_time() -> void:
	GameState.is_paused = false
	GameState.speed_multiplier = 0.0
	assert_eq(Engine.time_scale, 0.0)

func test_is_paused_true_overrides_speed_multiplier() -> void:
	GameState.speed_multiplier = 3.0
	GameState.is_paused = true
	assert_eq(Engine.time_scale, 0.0)

func test_unpause_restores_speed_multiplier() -> void:
	GameState.speed_multiplier = 2.0
	GameState.is_paused = true
	GameState.is_paused = false
	assert_eq(Engine.time_scale, 2.0)

func test_reset_restores_speed_to_one() -> void:
	GameState.speed_multiplier = 3.0
	GameState.reset()
	assert_eq(GameState.speed_multiplier, 1.0)

func test_reset_restores_time_scale_to_one() -> void:
	GameState.speed_multiplier = 3.0
	GameState.reset()
	assert_eq(Engine.time_scale, 1.0)
