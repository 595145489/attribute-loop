class_name EnemyData
extends Resource

@export var id: String = ""
@export var hp_base: int = 0
@export var dmg_base: int = 0
@export var gold_min: int = 0
@export var gold_max: int = 0
@export var gold_scale: float = 0.3
@export var unlock_phase: int = 1
@export var attack_interval: float = 1.0
@export var component_pair_min: int = 1
@export var component_pair_max: int = 2
## Keys: component id (String), Values: weight (int)
@export var trigger_weights: Dictionary = {}
## Keys: component id (String), Values: weight (int)
@export var effect_weights: Dictionary = {}
## Keys: phase number (int), Values: DropPreset resource
@export var phase_drop_presets: Dictionary = {}
