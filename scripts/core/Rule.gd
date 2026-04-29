class_name Rule
extends Resource

const EntryComponent = preload("res://scripts/core/EntryComponent.gd")

var trigger: EntryComponent = null
var effect: EntryComponent = null

func is_active() -> bool:
	return trigger != null and effect != null

func try_fire(event: String, context: Dictionary) -> void:
	if not is_active():
		return
	if trigger.data.get("event") == event:
		_apply_effect(context)

func _apply_effect(context: Dictionary) -> void:
	var type = effect.data.get("type", "")
	var owner_node = context.get("owner")
	if owner_node:
		owner_node.emit_signal("rule_fired", self, type)
