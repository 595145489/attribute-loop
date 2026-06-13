extends GutTest

func test_gamestate_has_is_tutorial_flag():
	assert_false(GameState.is_tutorial)

func test_is_tutorial_not_reset_by_reset():
	GameState.is_tutorial = true
	GameState.reset()
	assert_true(GameState.is_tutorial, "is_tutorial must survive reset()")
	GameState.is_tutorial = false

func test_component_deleted_signal_emitted():
	watch_signals(EventBus)
	var comp := ComponentData.new()
	GameState.inventory.append(comp)
	GameState.delete_component(comp)
	assert_signal_emitted(EventBus, "component_deleted")

func test_eventbus_has_new_signals():
	assert_true(EventBus.has_signal("component_stripped"))
	assert_true(EventBus.has_signal("rule_equipped"))
	assert_true(EventBus.has_signal("component_deleted"))
	assert_true(EventBus.has_signal("tile_rule_set"))
	assert_true(EventBus.has_signal("altar_component_added"))
