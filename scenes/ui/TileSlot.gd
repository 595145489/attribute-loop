class_name TileSlot
extends Panel

const EntryComponent = preload("res://scripts/core/EntryComponent.gd")
const Inventory = preload("res://scripts/systems/Inventory.gd")

var tile = null
var inventory: Inventory = null

func setup(p_tile, p_inventory: Inventory) -> void:
	tile = p_tile
	inventory = p_inventory
	custom_minimum_size = Vector2(80, 30)

func _can_drop_data(_pos: Vector2, data: Variant) -> bool:
	if not (data is Dictionary and data.has("component")):
		return false
	if data.get("enemy") != null or data.get("tile") != null:
		return false
	if tile == null:
		return false
	return tile.components.size() < tile.MAX_COMPONENTS

func _drop_data(_pos: Vector2, data: Variant) -> void:
	var comp := data["component"] as EntryComponent
	if comp == null or tile == null:
		return
	if inventory != null:
		inventory.remove(comp)
	tile.add_component(comp)
	Log.info("invested '%s' into tile" % comp.label, "TileSlot")
