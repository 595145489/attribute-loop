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

func _press(keycode: int) -> void:
	var ev := InputEventKey.new()
	ev.keycode = keycode
	ev.pressed = true
	hud._input(ev)

func test_key_2_sets_speed_to_2x() -> void:
	_press(KEY_2)
	assert_eq(GameState.speed_multiplier, 2.0)
	assert_true(hud._speed_btns[2].button_pressed)

func test_key_1_and_3_set_speed() -> void:
	_press(KEY_3)
	assert_eq(GameState.speed_multiplier, 3.0)
	_press(KEY_1)
	assert_eq(GameState.speed_multiplier, 1.0)

func test_space_toggles_pause_and_resumes_last_speed() -> void:
	_press(KEY_2)
	assert_eq(GameState.speed_multiplier, 2.0)
	_press(KEY_SPACE)
	assert_eq(GameState.speed_multiplier, 0.0)
	assert_true(hud._speed_btns[0].button_pressed)
	_press(KEY_SPACE)
	assert_eq(GameState.speed_multiplier, 2.0)
	assert_true(hud._speed_btns[2].button_pressed)

func test_space_pauses_from_default_speed() -> void:
	_press(KEY_SPACE)
	assert_eq(GameState.speed_multiplier, 0.0)
	_press(KEY_SPACE)
	assert_eq(GameState.speed_multiplier, 1.0)

func test_speed_keys_ignored_while_panel_paused() -> void:
	GameState.pause_for_panel()
	_press(KEY_2)
	assert_eq(GameState.speed_multiplier, 1.0)
	_press(KEY_SPACE)
	assert_eq(GameState.speed_multiplier, 1.0)

func test_key_b_toggles_inventory() -> void:
	var panel := _MockPanel.new()
	add_child_autofree(panel)
	hud.setup(panel)
	assert_false(panel.toggled)
	_press(KEY_B)
	assert_true(panel.toggled)
	_press(KEY_B)
	assert_false(panel.toggled)

class _MockPanel extends PanelContainer:
	var toggled: bool = false
	func toggle() -> void:
		toggled = not toggled
