extends Node

# Index 0 = altar (capacity managed by AltarPanel). Indices 1-12 = normal tiles.
const TILE_MAX_RULES: Array[int] = [0, 1, 2, 1, 3, 2, 1, 2, 3, 1, 2, 3, 2]

# Easy difficulty starter build. trigger_value = N for fires_every triggers;
# effect_value = magnitude for the paired effect. Components are duplicated at
# apply time so each slot owns its own instance.
const EASY_PLAYER_SLOTS := [
	{"trigger": "受击", "trigger_value": 5, "effect": "治愈", "effect_value": 12},
	{"trigger": "治愈", "trigger_value": 3, "effect": "灼烧", "effect_value": 2},
	{"trigger": "治愈", "trigger_value": 3, "effect": "护盾", "effect_value": 15},
]

const EASY_TILE_RULES := {
	1: {"trigger": "经过", "trigger_value": 6, "effect": "增伤", "effect_value": 1},
	5: {"trigger": "经过", "trigger_value": 6, "effect": "减伤", "effect_value": 1},
	8: {"trigger": "经过", "trigger_value": 6, "effect": "治愈", "effect_value": 12},
	9: {"trigger": "经过", "trigger_value": 6, "effect": "护盾", "effect_value": 15},
	12: {"trigger": "经过", "trigger_value": 6, "effect": "护盾", "effect_value": 15},
}

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
	for i in range(1, 8):
		phases[i] = load("res://data/phases/phase_%d.tres" % i)

func _load_components() -> void:
	var paths = [
		"res://data/components/trigger_受击.tres",
		"res://data/components/trigger_击杀.tres",
		"res://data/components/trigger_完成圈数.tres",
		"res://data/components/trigger_经过.tres",
		"res://data/components/both_治愈.tres",
		"res://data/components/both_反射.tres",
		"res://data/components/trigger_低血.tres",
		"res://data/components/trigger_满血.tres",
		"res://data/components/trigger_规则触发.tres",
		"res://data/components/effect_护盾.tres",
		"res://data/components/effect_减伤.tres",
		"res://data/components/effect_吸血.tres",
		"res://data/components/effect_强化.tres",
		"res://data/components/effect_增伤.tres",
		"res://data/components/effect_蓄能.tres",
		"res://data/components/effect_灼烧.tres",
		"res://data/components/effect_侵蚀.tres",
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

func make_easy_slot(spec: Dictionary) -> Dictionary:
	var t: ComponentData = get_component(spec["trigger"]).duplicate()
	t.trigger_value = float(spec["trigger_value"])
	t.trigger_count = 0
	var e: ComponentData = get_component(spec["effect"]).duplicate()
	e.effect_value = float(spec["effect_value"])
	e.trigger_count = 0
	return {"trigger": t, "effect": e}

func apply_easy_tile_rules(tiles: Array) -> void:
	for tile in tiles:
		if not (tile is Tile):
			continue
		if not EASY_TILE_RULES.has(tile.tile_index):
			continue
		if tile.rule_slots.is_empty():
			continue
		tile.rule_slots[0] = make_easy_slot(EASY_TILE_RULES[tile.tile_index])

func get_drop_preset(tier: int) -> DropPreset:
	return drop_presets[tier]

func calc_stat(base: int, phase: int) -> int:
	return int(base * (1.0 + (phase - 1) * config.stat_scale_factor))
