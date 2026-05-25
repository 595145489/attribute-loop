class_name EconomyManager
extends Node

func _ready() -> void:
	EventBus.enemy_killed.connect(_on_enemy_killed)

func _on_enemy_killed(enemy: Enemy) -> void:
	var ed: EnemyData = DataTables.get_enemy(enemy.enemy_id)
	var amount := calc_gold_drop(ed, GameState.current_phase)
	GameState.gold += amount
	EventBus.gold_changed.emit(GameState.gold)

static func calc_gold_drop(ed: EnemyData, phase: int) -> int:
	var mult := 1.0 + (phase - 1) * ed.gold_scale
	return int(randi_range(ed.gold_min, ed.gold_max) * mult)
