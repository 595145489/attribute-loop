class_name ComponentData
extends Resource

enum SlotType { TRIGGER_ONLY, EFFECT_ONLY, BOTH }

@export var id: String = ""
@export var display_name: String = ""
@export var description: String = ""
@export var slot_type: SlotType = SlotType.TRIGGER_ONLY
@export var trigger_formula: String = ""
@export var effect_formula: String = ""
@export var trigger_value: float = 0.0
@export var effect_value: float = 0.0
@export var growth_rate: float = 0.0
@export var scale_exponent: float = 1.0
@export var max_scale: float = 0.0
@export var altar_ratio: float = 0.0
var trigger_count: int = 0
