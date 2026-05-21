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
