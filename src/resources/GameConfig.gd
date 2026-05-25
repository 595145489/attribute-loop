class_name GameConfig
extends Resource

# stat = base × (1 + (phase - 1) × stat_scale_factor)
@export var stat_scale_factor: float = 0.3
@export var inventory_cap: int = 12
@export var rule_slot_count_base: int = 2
@export var rule_slot_count_max: int = 5
@export var low_hp_threshold: float = 0.3
@export var deletion_cost_sequence: Array[int] = [20, 50, 100]
@export var deletion_cost_multiplier: float = 2.0
@export var verdict_trigger_phase: int = 10
@export var verdict_survive_loops: int = 5
@export var verdict_enemy_phase: int = 10
@export var verdict_spawn_phase: int = 11
