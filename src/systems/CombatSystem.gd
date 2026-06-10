class_name CombatSystem
extends Node

var _player_timer: Timer
var _enemy_timer: Timer
var _active_enemy: Enemy = null

func _ready() -> void:
    _player_timer = Timer.new()
    _player_timer.one_shot = false
    _player_timer.timeout.connect(_on_player_attack)
    add_child(_player_timer)

    _enemy_timer = Timer.new()
    _enemy_timer.one_shot = false
    _enemy_timer.timeout.connect(_on_enemy_attack)
    add_child(_enemy_timer)

func start(enemy: Enemy) -> void:
    _active_enemy = enemy
    _player_timer.wait_time = DataTables.player.attack_interval
    _enemy_timer.wait_time = enemy.attack_interval
    _player_timer.start()
    _enemy_timer.start()

func stop() -> void:
    _player_timer.stop()
    _enemy_timer.stop()
    _active_enemy = null

func _on_player_attack() -> void:
    if _active_enemy == null:
        return
    _apply_player_attack(_active_enemy)

func _on_enemy_attack() -> void:
    if _active_enemy == null:
        return
    _apply_enemy_attack(_active_enemy)

func _apply_player_attack(enemy: Enemy) -> void:
    enemy.take_damage(DataTables.player.dmg_base)
    if GameState.lifesteal_ratio > 0.0:
        var heal := int(DataTables.player.dmg_base * GameState.lifesteal_ratio)
        GameState.hp = min(GameState.hp + heal, GameState.hp_max)
    if enemy.is_dead():
        _finish_combat(enemy)

func _apply_enemy_attack(enemy: Enemy) -> void:
    var dmg := enemy.dmg
    if GameState.slow_stacks > 0:
        var stack_cap := mini(GameState.current_phase + 1, 8)
        var capped := mini(GameState.slow_stacks, stack_cap)
        var reduction := capped * 0.1
        dmg = int(dmg * (1.0 - reduction))
    GameState.take_damage(dmg)
    EventBus.player_hit.emit(dmg)
    if GameState.pending_reflect_ratio > 0.0:
        enemy.take_damage(int(dmg * GameState.pending_reflect_ratio))
        GameState.pending_reflect_ratio = 0.0

func _finish_combat(enemy: Enemy = null) -> void:
    var resolved := enemy if enemy != null else _active_enemy
    if resolved == null:
        return
    stop()
    GameState.enemies_killed += 1
    EventBus.enemy_killed.emit(resolved)
    # combat_resolved is now emitted by StripManager after strip flow completes
