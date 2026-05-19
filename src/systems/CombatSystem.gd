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
    if enemy.is_dead():
        _finish_combat(enemy)

func _apply_enemy_attack(enemy: Enemy) -> void:
    GameState.take_damage(enemy.dmg)

func _finish_combat(enemy: Enemy = null) -> void:
    var resolved := enemy if enemy != null else _active_enemy
    if resolved == null:
        return
    var killed_id := resolved.enemy_id
    stop()
    GameState.enemies_killed += 1
    EventBus.enemy_killed.emit(killed_id)
    EventBus.combat_resolved.emit()
