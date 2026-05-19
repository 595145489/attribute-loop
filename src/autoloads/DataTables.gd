extends Node

var config: GameConfig
var player: PlayerData
var enemies: Dictionary = {}   # String → EnemyData
var phases: Dictionary = {}    # int → PhaseData

func _ready() -> void:
	config = load("res://data/game_config.tres")
	player = load("res://data/player_data.tres")
	_load_enemies()
	_load_phases()

func _load_enemies() -> void:
	var ids = ["汲取者", "守卫者", "急袭者", "复制者", "先驱者"]
	for id in ids:
		enemies[id] = load("res://data/enemies/enemy_%s.tres" % id)

func _load_phases() -> void:
	for i in range(1, 11):
		phases[i] = load("res://data/phases/phase_%d.tres" % i)

func get_enemy(id: String) -> EnemyData:
	return enemies[id]

func get_phase(phase_id: int) -> PhaseData:
	return phases[phase_id]

func calc_stat(base: int, phase: int) -> int:
	return int(base * (1.0 + (phase - 1) * config.stat_scale_factor))
