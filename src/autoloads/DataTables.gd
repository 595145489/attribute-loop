extends Node

# Index 0 = altar (capacity managed by AltarPanel). Indices 1-12 = normal tiles.
const TILE_MAX_RULES: Array[int] = [0, 1, 2, 1, 3, 2, 1, 2, 3, 1, 2, 3, 2]

var config: GameConfig
var player: PlayerData
var enemies: Dictionary = {}   # String -> EnemyData
var phases: Dictionary = {}    # int -> PhaseData
var components: Dictionary = {}  # String -> ComponentData
var drop_presets: Dictionary = {}  # int -> DropPreset (tier number)

func _ready() -> void:
	config = load("res://data/game_config.tres")
	player = load("res://data/player_data.tres")
	_load_enemies()
	_load_phases()
	_load_components()
	_load_drop_presets()

func _load_enemies() -> void:
	var ids = ["汲取者", "守卫者", "急袭者", "复制者", "先驱者"]
	for id in ids:
		enemies[id] = load("res://data/enemies/enemy_%s.tres" % id)

func _load_phases() -> void:
	for i in range(1, 12):
		phases[i] = load("res://data/phases/phase_%d.tres" % i)

func _load_components() -> void:
	var paths = [
		"res://data/components/trigger_受击.tres",
		"res://data/components/trigger_击杀.tres",
		"res://data/components/trigger_完成圈数.tres",
		"res://data/components/trigger_经过.tres",
		"res://data/components/both_治愈.tres",
		"res://data/components/both_反射.tres",
	]
	for path in paths:
		var c: ComponentData = load(path)
		components[c.id] = c

func _load_drop_presets() -> void:
	for tier in [1, 2, 3]:
		drop_presets[tier] = load("res://data/drop_presets/drop_tier_%02d.tres" % tier)

func get_enemy(id: String) -> EnemyData:
	return enemies[id]

func get_phase(phase_id: int) -> PhaseData:
	return phases[phase_id]

func get_component(id: String) -> ComponentData:
	return components[id]

func get_drop_preset(tier: int) -> DropPreset:
	return drop_presets[tier]

func calc_stat(base: int, phase: int) -> int:
	return int(base * (1.0 + (phase - 1) * config.stat_scale_factor))
