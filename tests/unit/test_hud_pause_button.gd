extends GutTest

var hud: HUD

func before_each() -> void:
	GameState.reset()
	while GameState._panel_pause_count > 0:
		GameState.unpause_for_panel()
	hud = preload("res://scenes/ui/HUD.tscn").instantiate()
	add_child_autofree(hud)
	await get_tree().process_frame

func after_each() -> void:
	GameState.speed_multiplier = 1.0

func test_pause_button_pauses_when_running() -> void:
	# Game running at default X1.
	assert_eq(Engine.time_scale, 1.0)
	hud._on_pause_pressed()
	assert_eq(GameState.speed_multiplier, 0.0)
	assert_true(hud._speed_btns[0].button_pressed)

func test_pause_button_resumes_to_last_speed() -> void:
	hud._on_speed_pressed(2)  # 2x
	hud._on_pause_pressed()   # pause
	assert_eq(GameState.speed_multiplier, 0.0)
	hud._on_pause_pressed()   # resume
	assert_eq(GameState.speed_multiplier, 2.0)
	assert_true(hud._speed_btns[2].button_pressed)

func test_pause_button_resumes_default_x1_when_no_speed_selected() -> void:
	# Fresh HUD: _last_speed defaults to 1.0 (X1), no explicit speed chosen.
	hud._on_pause_pressed()  # pause from X1
	assert_eq(GameState.speed_multiplier, 0.0)
	hud._on_pause_pressed()  # resume — should default to X1
	assert_eq(GameState.speed_multiplier, 1.0)
	assert_true(hud._speed_btns[1].button_pressed)

func test_pause_button_starts_game_from_tutorial_panel_pause() -> void:
	# Reproduces the reported bug: at tutorial entry the game is panel-paused
	# (time_scale == 0) while speed_multiplier is still the default 1.0.
	# Clicking pause must START the game at X1, not freeze it.
	GameState.pause_for_panel()
	assert_eq(Engine.time_scale, 0.0)
	assert_eq(GameState.speed_multiplier, 1.0)
	hud._on_pause_pressed()
	# speed_changed emitted -> tutorial would advance and unpause the panel:
	GameState.unpause_for_panel()
	assert_eq(GameState.speed_multiplier, 1.0)
	assert_eq(Engine.time_scale, 1.0)
