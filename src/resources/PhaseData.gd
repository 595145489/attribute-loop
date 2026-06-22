class_name PhaseData
extends Resource

@export var phase_id: int = 1
@export var phase_name: String = ""
@export var altar_requirement: int = 0
@export var world_pressure_window: int = 10     # loops before forced advance
@export var spawn_count_min: int = 1
@export var spawn_count_max: int = 3
## Keys: enemy id (String), Values: weight (int). Normalised at runtime.
@export var spawn_weights: Dictionary = {}
@export var enemy_component_count_min: int = 1
@export var enemy_component_count_max: int = 2
## Keys: component id (String), Values: weight multiplier (float)
@export var component_weight_modifiers: Dictionary = {}
@export var boss_hp_multiplier: float = 2.0
@export var boss_damage_multiplier: float = 2.0
@export var boss_scale: float = 1.6
## Tier drop probabilities: [tier_01_weight, tier_02_weight, tier_03_weight]
@export var tier_drop_weights: Array[int] = [85, 12, 3]
