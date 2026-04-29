class_name InventoryPanel
extends Panel

const EntryComponent = preload("res://scripts/core/EntryComponent.gd")
const ComponentCard = preload("res://scenes/ui/ComponentCard.tscn")
const ComponentCardScript = preload("res://scenes/ui/ComponentCard.gd")
const Inventory = preload("res://scripts/systems/Inventory.gd")

var inventory: Inventory = null

@onready var cards_container: HBoxContainer = $CardsContainer

func setup(inv: Inventory) -> void:
	if inventory != null:
		inventory.component_added.disconnect(_on_component_added)
		inventory.component_removed.disconnect(_on_component_removed)
	inventory = inv
	inventory.component_added.connect(_on_component_added)
	inventory.component_removed.connect(_on_component_removed)
	_refresh()

func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED and visible and inventory != null:
		_refresh()

func _refresh() -> void:
	for child in cards_container.get_children():
		cards_container.remove_child(child)
		child.queue_free()
	for comp in inventory.components:
		_add_card(comp)

func _add_card(comp: EntryComponent) -> void:
	var card = ComponentCard.instantiate()
	cards_container.add_child(card)
	card.setup(comp, null)

func _on_component_added(comp: EntryComponent) -> void:
	_add_card(comp)

func _on_component_removed(comp: EntryComponent) -> void:
	for card in cards_container.get_children():
		if card is ComponentCardScript and card.component == comp:
			card.queue_free()
			return

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if not (data is Dictionary and data.has("component") and data.has("enemy")):
		return false
	return data["enemy"] != null

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	var component := data["component"] as EntryComponent
	var enemy = data["enemy"]
	if is_instance_valid(enemy):
		enemy.strip_component(component)
	if not inventory.components.has(component):
		inventory.add(component)
