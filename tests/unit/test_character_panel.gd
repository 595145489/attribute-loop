extends GutTest

var panel: CharacterPanel

func before_each() -> void:
	GameState.reset()
	panel = preload("res://scenes/ui/character_panel.tscn").instantiate()
	add_child_autofree(panel)
	await get_tree().process_frame

func test_panel_hidden_by_default() -> void:
	assert_false(panel.visible)

func test_toggle_shows_panel() -> void:
	panel.toggle()
	assert_true(panel.visible)

func test_toggle_twice_hides_panel() -> void:
	panel.toggle()
	panel.toggle()
	assert_false(panel.visible)

func test_toggle_open_pauses_game() -> void:
	var before = GameState._panel_pause_count
	panel.toggle()
	assert_eq(GameState._panel_pause_count, before + 1)

func test_toggle_close_unpauses_game() -> void:
	panel.toggle()
	var mid = GameState._panel_pause_count
	panel.toggle()
	assert_eq(GameState._panel_pause_count, mid - 1)

func test_refresh_shows_correct_hp() -> void:
	GameState.hp = 42
	GameState.hp_max = 200
	panel.toggle()
	var hp_val: Label = panel.get_node("Margin/VBox/SurvivalGroup/HP/Value")
	assert_eq(hp_val.text, "42 / 200")

func test_refresh_shows_dash_when_shield_zero() -> void:
	GameState.shield = 0
	panel.toggle()
	var val: Label = panel.get_node("Margin/VBox/SurvivalGroup/Shield/Value")
	assert_eq(val.text, "—")

func test_refresh_shows_shield_value_when_nonzero() -> void:
	GameState.shield = 150
	panel.toggle()
	var val: Label = panel.get_node("Margin/VBox/SurvivalGroup/Shield/Value")
	assert_eq(val.text, "150")

func test_refresh_shows_dash_when_lifesteal_zero() -> void:
	GameState.lifesteal_ratio = 0.0
	panel.toggle()
	var val: Label = panel.get_node("Margin/VBox/OffenseGroup/Lifesteal/Value")
	assert_eq(val.text, "—")

func test_refresh_shows_lifesteal_percent_when_nonzero() -> void:
	GameState.lifesteal_ratio = 0.15
	panel.toggle()
	var val: Label = panel.get_node("Margin/VBox/OffenseGroup/Lifesteal/Value")
	assert_eq(val.text, "15%")
