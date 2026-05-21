extends GutTest

func before_each() -> void:
    GameState.reset()

func test_combat_resolved_emitted_immediately_when_no_components() -> void:
    watch_signals(EventBus)
    var manager = StripManager.new()
    add_child_autofree(manager)
    var enemy = Enemy.new()
    enemy.init("汲取者")
    enemy.components.clear()
    manager._on_enemy_killed(enemy)
    assert_signal_emitted(EventBus, "combat_resolved")

func test_combat_resolved_not_emitted_when_components_present() -> void:
    watch_signals(EventBus)
    var manager = StripManager.new()
    add_child_autofree(manager)
    var enemy = Enemy.new()
    enemy.init("汲取者")
    var c = ComponentData.new()
    c.id = "受击"
    enemy.components.append(c)
    manager._on_enemy_killed(enemy)
    assert_signal_not_emitted(EventBus, "combat_resolved")

func test_on_strip_completed_emits_combat_resolved() -> void:
    watch_signals(EventBus)
    var manager = StripManager.new()
    add_child_autofree(manager)
    manager._on_strip_completed()
    assert_signal_emitted(EventBus, "combat_resolved")
