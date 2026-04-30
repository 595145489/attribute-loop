class_name Tile
extends Resource

const EntryComponent = preload("res://scripts/core/EntryComponent.gd")

signal component_stripped(component: EntryComponent)
signal strip_damage_requested(amount: float)

const MAX_COMPONENTS: int = 3

@export var track_t: float = 0.0
@export var pass_count: int = 0
@export var harvest_threshold: int = 3

var components: Array[EntryComponent] = []

func add_component(component: EntryComponent) -> bool:
	if components.size() >= MAX_COMPONENTS:
		return false
	components.append(component)
	return true

func strip_component(component: EntryComponent) -> void:
	if component in components:
		components.erase(component)
		component_stripped.emit(component)
		strip_damage_requested.emit(float(pass_count * 2))

func try_fire() -> String:
	var has_on_pass_trigger := false
	for comp in components:
		if comp.slot_type == EntryComponent.SlotType.TRIGGER and comp.data.get("event") == "on_pass":
			has_on_pass_trigger = true
			break
	if not has_on_pass_trigger:
		return ""
	for comp in components:
		if comp.slot_type == EntryComponent.SlotType.EFFECT:
			return comp.data.get("type", "")
	return ""

func effect_multiplier() -> float:
	return 1.0 + pass_count * 0.1
