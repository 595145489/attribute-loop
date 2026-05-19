extends GutTest

func test_has_enemy_killed_signal() -> void:
	assert_true(EventBus.has_signal("enemy_killed"))

func test_has_combat_resolved_signal() -> void:
	assert_true(EventBus.has_signal("combat_resolved"))

func test_has_loop_completed_signal() -> void:
	assert_true(EventBus.has_signal("loop_completed"))

func test_has_player_died_signal() -> void:
	assert_true(EventBus.has_signal("player_died"))

func test_enemy_killed_emits_with_id() -> void:
	watch_signals(EventBus)
	EventBus.enemy_killed.emit("汲取者")
	assert_signal_emitted_with_parameters(EventBus, "enemy_killed", ["汲取者"])
