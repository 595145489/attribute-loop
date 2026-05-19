class_name Enemy
extends Node2D

var enemy_id: String = ""
var hp: int = 0
var hp_max: int = 0
var dmg: int = 0
var attack_interval: float = 1.0

func init(id: String) -> void:
	enemy_id = id
	var data: EnemyData = DataTables.get_enemy(id)
	var phase = GameState.current_phase
	hp_max = DataTables.calc_stat(data.hp_base, phase)
	hp = hp_max
	dmg = DataTables.calc_stat(data.dmg_base, phase)
	attack_interval = data.attack_interval

func take_damage(amount: int) -> void:
	hp = max(0, hp - amount)

func is_dead() -> bool:
	return hp <= 0
