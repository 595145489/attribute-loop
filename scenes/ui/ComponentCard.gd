class_name ComponentCard
extends Panel

const EntryComponent = preload("res://scripts/core/EntryComponent.gd")

var component: EntryComponent = null
var draggable: bool = true
var _enemy_ref = null

@onready var type_label: Label = $TypeLabel
@onready var name_label: Label = $NameLabel

func setup(comp: EntryComponent, enemy_ref = null) -> void:
	component = comp
	_enemy_ref = enemy_ref
	type_label.text = EntryComponent.SlotType.keys()[comp.slot_type]
	name_label.text = comp.label

func _get_drag_data(_at_position: Vector2) -> Variant:
	if not draggable:
		return null
	var preview := Panel.new()
	preview.size = Vector2(80, 50)
	var lbl := Label.new()
	lbl.text = component.label
	lbl.add_theme_font_size_override("font_size", 11)
	preview.add_child(lbl)
	set_drag_preview(preview)
	return {"component": component, "enemy": _enemy_ref}

func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		if get_viewport().gui_is_drag_successful():
			queue_free()
