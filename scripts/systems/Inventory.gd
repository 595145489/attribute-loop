class_name Inventory
extends Node

const EntryComponent = preload("res://scripts/core/EntryComponent.gd")

signal component_added(component: EntryComponent)
signal component_removed(component: EntryComponent)

var components: Array[EntryComponent] = []
const MAX_SIZE = 12

func add(component: EntryComponent) -> bool:
	if components.size() >= MAX_SIZE:
		return false
	components.append(component)
	component_added.emit(component)
	return true

func remove(component: EntryComponent) -> void:
	components.erase(component)
	component_removed.emit(component)
