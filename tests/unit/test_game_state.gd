extends GutTest

func before_each() -> void:
    GameState.reset()

func test_initial_hp_equals_hp_max() -> void:
    assert_eq(GameState.hp, GameState.hp_max)

func test_hp_max_is_positive() -> void:
    assert_gt(GameState.hp_max, 0)

func test_take_damage_reduces_hp() -> void:
    var before = GameState.hp
    GameState.take_damage(10)
    assert_eq(GameState.hp, before - 10)

func test_take_damage_clamps_to_zero() -> void:
    GameState.take_damage(GameState.hp_max + 999)
    assert_eq(GameState.hp, 0)

func test_take_damage_emits_player_died_when_hp_zero() -> void:
    watch_signals(EventBus)
    GameState.take_damage(GameState.hp_max + 999)
    assert_signal_emitted(EventBus, "player_died")

func test_reset_restores_hp() -> void:
    GameState.take_damage(50)
    GameState.reset()
    assert_eq(GameState.hp, GameState.hp_max)

func test_reset_clears_loops_and_kills() -> void:
    GameState.loops_completed = 5
    GameState.enemies_killed = 10
    GameState.reset()
    assert_eq(GameState.loops_completed, 0)
    assert_eq(GameState.enemies_killed, 0)

func test_is_paused_defaults_false() -> void:
    assert_false(GameState.is_paused)
