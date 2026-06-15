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

func test_step_count_is_fourteen():
	var steps = TutorialSteps.get_steps()
	assert_eq(steps.size(), 31)

func test_each_step_has_required_keys():
	var required = ["id", "text", "highlight_node", "complete_signal", "block_outside_input"]
	for step in TutorialSteps.get_steps():
		for key in required:
			assert_true(step.has(key), "Step '%s' missing key '%s'" % [step.get("id", "?"), key])

func test_step_ids_are_unique():
	var ids := {}
	for step in TutorialSteps.get_steps():
		var id: String = step["id"]
		assert_false(ids.has(id), "Duplicate step id: %s" % id)
		ids[id] = true

func test_observe_steps_have_no_input_block():
	for step in TutorialSteps.get_steps():
		var has_highlight = step["highlight_node"] != "" or step.get("highlight_contains", "") != ""
		if not has_highlight:
			assert_false(step["block_outside_input"],
				"Step '%s' has no highlight but block_outside_input=true" % step["id"])

func test_rule_equipped_signal_exists():
	assert_true(EventBus.has_signal("rule_equipped"))
