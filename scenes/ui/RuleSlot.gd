class_name RuleSlot
extends Panel

const EntryComponent = preload("res://scripts/core/EntryComponent.gd")
const Inventory = preload("res://scripts/systems/Inventory.gd")
const ComponentCard = preload("res://scenes/ui/ComponentCard.tscn")

signal component_placed(component: EntryComponent)
signal component_cleared(component: EntryComponent)

@export var accepted_type: int = 0

var held_component: EntryComponent = null
var inventory: Inventory = null

@onready var type_label: Label = $TypeLabel
@onready var card_container: VBoxContainer = $CardContainer

func setup(p_accepted_type: int, p_inventory: Inventory) -> void:
	accepted_type = p_accepted_type
	inventory = p_inventory
	type_label.text = EntryComponent.SlotType.keys()[accepted_type]

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and held_component != null:
		var comp := held_component
		held_component = null
		for child in card_container.get_children():
			card_container.remove_child(child)
			child.queue_free()
		if inventory != null:
			inventory.add(comp)
		component_cleared.emit(comp)

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if not (data is Dictionary and data.has("component") and data.has("enemy")):
		return false
	if data["enemy"] != null:
		return false
	var comp := data["component"] as EntryComponent
	if comp == null:
		return false
	return comp.slot_type == accepted_type and held_component == null

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if inventory == null:
		push_error("RuleSlot._drop_data called before setup()")
		return
	var component := data["component"] as EntryComponent
	if component == null:
		return
	inventory.remove(component)
	held_component = component
	var card = ComponentCard.instantiate()
	card_container.add_child(card)
	card.setup(component, null)
	card.draggable = false
	component_placed.emit(component)
