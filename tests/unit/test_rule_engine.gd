extends GutTest

var engine: RuleEngine

func before_each() -> void:
    GameState.reset()
    engine = RuleEngine.new()
    add_child_autofree(engine)

func _make_rule(trigger_id: String, trigger_value: float, effect_id: String, effect_value: float) -> void:
    var t = ComponentData.new()
    t.id = trigger_id
    t.slot_type = ComponentData.SlotType.TRIGGER_ONLY
    t.trigger_value = trigger_value
    t.trigger_count = 0
    var e = ComponentData.new()
    e.id = effect_id
    e.slot_type = ComponentData.SlotType.EFFECT_ONLY
    e.effect_value = effect_value
    GameState.rule_slots[0]["trigger"] = t
    GameState.rule_slots[0]["effect"] = e

func test_trigger_count_increments_on_player_hit() -> void:
    _make_rule("受击", 3.0, "治愈", 10.0)
    var t = GameState.rule_slots[0]["trigger"]
    EventBus.player_hit.emit(5)
    assert_eq(t.trigger_count, 1)

func test_trigger_count_increments_on_enemy_killed() -> void:
    _make_rule("击杀", 2.0, "治愈", 10.0)
    var t = GameState.rule_slots[0]["trigger"]
    var dummy = Enemy.new()
    dummy.init("汲取者")
    EventBus.enemy_killed.emit(dummy)
    assert_eq(t.trigger_count, 1)

func test_trigger_count_increments_on_loop_completed() -> void:
    _make_rule("完成圈数", 2.0, "治愈", 10.0)
    var t = GameState.rule_slots[0]["trigger"]
    EventBus.loop_completed.emit()
    assert_eq(t.trigger_count, 1)

func test_trigger_count_increments_on_tile_passed() -> void:
    _make_rule("经过", 3.0, "治愈", 10.0)
    var t = GameState.rule_slots[0]["trigger"]
    EventBus.tile_passed.emit(0)
    assert_eq(t.trigger_count, 1)

func test_heal_fires_when_threshold_reached() -> void:
    _make_rule("受击", 1.0, "治愈", 15.0)
    GameState.hp = 50
    EventBus.player_hit.emit(5)
    assert_eq(GameState.hp, 65)

func test_heal_resets_trigger_count() -> void:
    _make_rule("受击", 1.0, "治愈", 10.0)
    var t = GameState.rule_slots[0]["trigger"]
    EventBus.player_hit.emit(5)
    assert_eq(t.trigger_count, 0)

func test_heal_capped_at_hp_max() -> void:
    _make_rule("受击", 1.0, "治愈", 999.0)
    GameState.hp = 90
    EventBus.player_hit.emit(5)
    assert_eq(GameState.hp, GameState.hp_max)

func test_reflect_sets_pending_ratio() -> void:
    _make_rule("受击", 1.0, "反射", 0.5)
    EventBus.player_hit.emit(5)
    assert_eq(GameState.pending_reflect_ratio, 0.5)

func test_rule_fired_signal_emitted_on_effect() -> void:
    watch_signals(EventBus)
    _make_rule("受击", 1.0, "治愈", 10.0)
    GameState.hp = 50
    EventBus.player_hit.emit(5)
    assert_signal_emitted(EventBus, "rule_fired")

func test_no_fire_when_trigger_slot_empty() -> void:
    var e = ComponentData.new()
    e.id = "治愈"
    e.effect_value = 10.0
    GameState.rule_slots[0]["effect"] = e
    GameState.rule_slots[0]["trigger"] = null
    GameState.hp = 50
    EventBus.player_hit.emit(5)
    assert_eq(GameState.hp, 50)

func test_no_fire_when_effect_slot_empty() -> void:
    var t = ComponentData.new()
    t.id = "受击"
    t.trigger_value = 1.0
    GameState.rule_slots[0]["trigger"] = t
    GameState.rule_slots[0]["effect"] = null
    GameState.hp = 50
    EventBus.player_hit.emit(5)
    assert_eq(GameState.hp, 50)
