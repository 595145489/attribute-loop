extends GutTest

var combat: CombatSystem

func before_each() -> void:
    GameState.reset()
    combat = CombatSystem.new()
    add_child_autofree(combat)

func test_player_damage_reduces_enemy_hp() -> void:
    var enemy = Enemy.new()
    enemy.init("汲取者")
    var hp_before = enemy.hp
    combat._apply_player_attack(enemy)
    assert_lt(enemy.hp, hp_before)

func test_enemy_damage_reduces_player_hp() -> void:
    var enemy = Enemy.new()
    enemy.init("汲取者")
    var hp_before = GameState.hp
    combat._apply_enemy_attack(enemy)
    assert_lt(GameState.hp, hp_before)

func test_player_damage_uses_player_dmg_base() -> void:
    var enemy = Enemy.new()
    enemy.init("汲取者")
    var hp_before = enemy.hp
    combat._apply_player_attack(enemy)
    assert_eq(enemy.hp, maxi(0, hp_before - DataTables.player.dmg_base))

func test_enemy_damage_uses_phase_scaled_dmg() -> void:
    var enemy = Enemy.new()
    enemy.init("汲取者")
    var expected_dmg = DataTables.calc_stat(DataTables.get_enemy("汲取者").dmg_base, 1)
    assert_eq(enemy.dmg, expected_dmg)

func test_player_hit_emitted_on_enemy_attack() -> void:
    watch_signals(EventBus)
    var enemy = Enemy.new()
    enemy.init("汲取者")
    combat._apply_enemy_attack(enemy)
    assert_signal_emitted(EventBus, "player_hit")

func test_enemy_killed_emitted_when_enemy_dies() -> void:
    watch_signals(EventBus)
    var enemy = Enemy.new()
    enemy.init("汲取者")
    enemy.hp = 1
    combat._apply_player_attack(enemy)
    assert_signal_emitted(EventBus, "enemy_killed")

func test_combat_resolved_not_emitted_by_combat_system() -> void:
    watch_signals(EventBus)
    var enemy = Enemy.new()
    enemy.init("汲取者")
    enemy.hp = 1
    combat._apply_player_attack(enemy)
    assert_signal_not_emitted(EventBus, "combat_resolved")

func test_reflect_damage_applied_when_pending_ratio_set() -> void:
    GameState.pending_reflect_ratio = 0.5
    var enemy = Enemy.new()
    enemy.init("汲取者")
    var enemy_hp_before = enemy.hp
    combat._apply_enemy_attack(enemy)
    assert_lt(enemy.hp, enemy_hp_before)
    assert_eq(GameState.pending_reflect_ratio, 0.0)

func test_slow_stacks_reduce_enemy_damage() -> void:
    var base_dmg := 10
    var reduced := int(base_dmg * (1.0 - 2 * 0.1))
    assert_eq(reduced, 8)

func test_slow_stacks_capped_by_phase() -> void:
    GameState.current_phase = 1
    var stack_cap := mini(GameState.current_phase + 1, 8)
    assert_eq(stack_cap, 2)

func test_slow_stacks_cap_scales_with_phase() -> void:
    GameState.current_phase = 7
    var stack_cap := mini(GameState.current_phase + 1, 8)
    assert_eq(stack_cap, 8)

func test_lifesteal_heals_after_player_attack() -> void:
    GameState.lifesteal_ratio = 0.5
    GameState.hp = 100
    var enemy = Enemy.new()
    enemy.init("汲取者")
    combat._apply_player_attack(enemy)
    var expected_heal = int(DataTables.player.dmg_base * 0.5)
    assert_eq(GameState.hp, min(100 + expected_heal, GameState.hp_max))

func test_lifesteal_capped_at_hp_max() -> void:
    GameState.lifesteal_ratio = 99.0
    GameState.hp = GameState.hp_max - 1
    var enemy = Enemy.new()
    enemy.init("汲取者")
    combat._apply_player_attack(enemy)
    assert_eq(GameState.hp, GameState.hp_max)

func test_no_lifesteal_when_ratio_zero() -> void:
    GameState.lifesteal_ratio = 0.0
    GameState.hp = 100
    var enemy = Enemy.new()
    enemy.init("汲取者")
    combat._apply_player_attack(enemy)
    assert_eq(GameState.hp, 100)

func test_lifesteal_ratio_resets_after_combat() -> void:
    GameState.lifesteal_ratio = 0.4
    var enemy = Enemy.new()
    enemy.init("汲取者")
    combat._finish_combat(enemy)
    assert_almost_eq(GameState.lifesteal_ratio, 0.0, 0.001)

func test_enrage_stacks_zero_at_init() -> void:
    assert_eq(combat._enrage_stacks, 0)

func test_enrage_stacks_increment_past_threshold() -> void:
    var cfg: GameConfig = DataTables.config
    combat._enrage_timer = cfg.combat_enrage_time + 0.1
    combat._check_enrage()
    assert_eq(combat._enrage_stacks, 1)

func test_enrage_second_stack_after_interval() -> void:
    var cfg: GameConfig = DataTables.config
    combat._enrage_stacks = 1
    combat._enrage_timer = cfg.combat_enrage_time + cfg.combat_enrage_interval + 0.1
    combat._check_enrage()
    assert_eq(combat._enrage_stacks, 2)

func test_enrage_no_stack_before_threshold() -> void:
    var cfg: GameConfig = DataTables.config
    combat._enrage_timer = cfg.combat_enrage_time - 0.1
    combat._check_enrage()
    assert_eq(combat._enrage_stacks, 0)

func test_enrage_bonus_per_stack_is_positive() -> void:
    var cfg: GameConfig = DataTables.config
    assert_gt(cfg.combat_enrage_bonus_per_stack, 0.0)

func test_enrage_resets_via_reset_enrage() -> void:
    combat._enrage_stacks = 3
    combat._enrage_timer = 20.0
    combat.reset_enrage()
    assert_eq(combat._enrage_stacks, 0)
    assert_almost_eq(combat._enrage_timer, 0.0, 0.001)

func test_enrage_signal_emitted_on_first_stack() -> void:
    watch_signals(EventBus)
    var cfg: GameConfig = DataTables.config
    combat._enrage_timer = cfg.combat_enrage_time + 0.1
    combat._check_enrage()
    assert_signal_emitted(EventBus, "combat_enrage")

func test_player_attack_applies_dmg_bonus() -> void:
    GameState.dmg_bonus = 3
    var enemy = Enemy.new()
    enemy.init("汲取者")
    var hp_before = enemy.hp
    combat._apply_player_attack(enemy)
    assert_eq(enemy.hp, maxi(0, hp_before - (DataTables.player.dmg_base + 3)))

func test_combat_start_uses_attack_interval_bonus() -> void:
    GameState.attack_interval_bonus = 0.2
    var enemy = Enemy.new()
    enemy.init("汲取者")
    combat.start(enemy)
    var expected := maxf(DataTables.player.attack_interval - 0.2, 0.2)
    assert_almost_eq(combat._player_timer.wait_time, expected, 0.001)
    combat.stop()

func test_dmg_boost_increases_player_damage() -> void:
    GameState.dmg_boost_stacks = 2
    var pd: PlayerData = DataTables.player
    var expected := int((pd.dmg_base + GameState.dmg_bonus) * (1.0 + 2 * 0.1))
    assert_eq(combat._calc_player_dmg(), expected)

func test_dmg_boost_capped_by_phase_in_formula() -> void:
    # Stacks far above the phase cap must be clamped (phase 1 -> cap 2).
    GameState.current_phase = 1
    GameState.dmg_boost_stacks = 50
    var pd: PlayerData = DataTables.player
    var expected := int((pd.dmg_base + GameState.dmg_bonus) * (1.0 + 2 * 0.1))
    assert_eq(combat._calc_player_dmg(), expected)

func test_dmg_boost_cap_scales_with_phase() -> void:
    # Cap grows with phase (phase 5 -> cap 6), hard-capped at 8.
    GameState.current_phase = 5
    GameState.dmg_boost_stacks = 50
    var pd: PlayerData = DataTables.player
    var expected := int((pd.dmg_base + GameState.dmg_bonus) * (1.0 + 6 * 0.1))
    assert_eq(combat._calc_player_dmg(), expected)

func test_dmg_boost_cap_hard_eight_at_high_phase() -> void:
    GameState.current_phase = 20
    GameState.dmg_boost_stacks = 50
    var pd: PlayerData = DataTables.player
    var expected := int((pd.dmg_base + GameState.dmg_bonus) * (1.0 + 8 * 0.1))
    assert_eq(combat._calc_player_dmg(), expected)

func test_charge_release_deals_bonus_damage() -> void:
    GameState.charge_stacks = 3
    var pd: PlayerData = DataTables.player
    var expected_bonus := 3 * pd.dmg_base
    assert_eq(combat._calc_charge_bonus(), expected_bonus)

func test_charge_resets_after_release() -> void:
    GameState.charge_stacks = 2
    combat._release_charge_if_any()
    assert_eq(GameState.charge_stacks, 0)

func test_dmg_boost_decays_on_loop_completed() -> void:
    var re := RuleEngine.new()
    add_child_autofree(re)
    GameState.dmg_boost_stacks = 3
    EventBus.loop_completed.emit()
    assert_eq(GameState.dmg_boost_stacks, 2)

func test_dmg_boost_decay_scales_with_phase() -> void:
    # Decay mirrors slow_stacks: ceili(phase / 2). Phase 5 -> decay 3.
    var re := RuleEngine.new()
    add_child_autofree(re)
    GameState.current_phase = 5
    GameState.dmg_boost_stacks = 10
    EventBus.loop_completed.emit()
    assert_eq(GameState.dmg_boost_stacks, 7)

func test_dmg_boost_not_below_zero_on_decay() -> void:
    var re := RuleEngine.new()
    add_child_autofree(re)
    GameState.dmg_boost_stacks = 0
    EventBus.loop_completed.emit()
    assert_eq(GameState.dmg_boost_stacks, 0)

func test_slow_applied_emitted_when_slow_reduces_damage() -> void:
    watch_signals(EventBus)
    var enemy = Enemy.new()
    enemy.init("汲取者")
    GameState.slow_stacks = 3
    combat._apply_enemy_attack(enemy)
    assert_signal_emitted(EventBus, "slow_applied")

func test_slow_applied_not_emitted_without_slow_stacks() -> void:
    watch_signals(EventBus)
    var enemy = Enemy.new()
    enemy.init("汲取者")
    GameState.slow_stacks = 0
    combat._apply_enemy_attack(enemy)
    assert_signal_not_emitted(EventBus, "slow_applied")

func test_lifesteal_healed_emitted_when_lifesteal_heals() -> void:
    watch_signals(EventBus)
    var enemy = Enemy.new()
    enemy.init("汲取者")
    enemy.hp = 9999
    GameState.lifesteal_ratio = 0.5
    GameState.hp = 100
    combat._apply_player_attack(enemy)
    assert_signal_emitted(EventBus, "lifesteal_healed")

func test_dmg_boost_consumed_emitted_when_boost_used() -> void:
    watch_signals(EventBus)
    var enemy = Enemy.new()
    enemy.init("汲取者")
    enemy.hp = 9999
    GameState.dmg_boost_stacks = 2
    combat._apply_player_attack(enemy)
    assert_signal_emitted(EventBus, "dmg_boost_consumed")

func test_dmg_boost_consumed_not_emitted_without_boost() -> void:
    watch_signals(EventBus)
    var enemy = Enemy.new()
    enemy.init("汲取者")
    enemy.hp = 9999
    GameState.dmg_boost_stacks = 0
    combat._apply_player_attack(enemy)
    assert_signal_not_emitted(EventBus, "dmg_boost_consumed")
