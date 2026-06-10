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
    assert_eq(enemy.hp, hp_before - DataTables.player.dmg_base)

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
    GameState.slow_stacks = 3
    var enemy = Enemy.new()
    enemy.init("汲取者")
    var hp_before = GameState.hp
    combat._apply_enemy_attack(enemy)
    var expected_dmg = int(enemy.dmg * (1.0 - 0.3))
    assert_eq(GameState.hp, hp_before - expected_dmg)

func test_slow_stacks_capped_at_80_percent_reduction() -> void:
    GameState.slow_stacks = 10
    var enemy = Enemy.new()
    enemy.init("汲取者")
    var hp_before = GameState.hp
    combat._apply_enemy_attack(enemy)
    var expected_dmg = int(enemy.dmg * 0.2)
    assert_eq(GameState.hp, hp_before - expected_dmg)

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
