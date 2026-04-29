class_name EnemyCardOverlay
extends Control

const ComponentCard = preload("res://scenes/ui/ComponentCard.tscn")
const Inventory = preload("res://scripts/systems/Inventory.gd")

var enemies_node: Node2D = null
var inventory: Inventory = null
var _enemy_containers: Dictionary = {}

func setup(p_enemies_node: Node2D, p_inventory: Inventory) -> void:
	enemies_node = p_enemies_node
	inventory = p_inventory

func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED:
		if visible:
			_build_all_cards()
		else:
			_clear_all_cards()

func _process(_delta: float) -> void:
	if not visible or enemies_node == null:
		return
	var canvas_tf := get_viewport().get_canvas_transform()
	for enemy in _enemy_containers:
		if is_instance_valid(enemy) and is_instance_valid(_enemy_containers[enemy]):
			_enemy_containers[enemy].position = canvas_tf * enemy.global_position + Vector2(-40, -90)

func _build_all_cards() -> void:
	_clear_all_cards()
	if enemies_node == null:
		return
	for enemy in enemies_node.get_children():
		if enemy.has_method("strip_component") and enemy.components.size() > 0:
			_create_enemy_container(enemy)

func _clear_all_cards() -> void:
	for container in _enemy_containers.values():
		if is_instance_valid(container):
			container.queue_free()
	_enemy_containers.clear()

func _create_enemy_container(enemy: Node) -> void:
	var container := VBoxContainer.new()
	add_child(container)
	_enemy_containers[enemy] = container
	for comp in enemy.components:
		var card = ComponentCard.instantiate()
		container.add_child(card)
		card.setup(comp, enemy)
