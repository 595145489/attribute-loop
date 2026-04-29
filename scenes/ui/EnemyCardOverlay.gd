class_name EnemyCardOverlay
extends Control

const ComponentCard = preload("res://scenes/ui/ComponentCard.tscn")

var enemies_node: Node2D = null
var _enemy_containers: Dictionary = {}
var _strip_connections: Dictionary = {}

func setup(p_enemies_node: Node2D) -> void:
	enemies_node = p_enemies_node

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
	for enemy in _strip_connections:
		if is_instance_valid(enemy):
			var callable = _strip_connections[enemy]
			if enemy.component_stripped.is_connected(callable):
				enemy.component_stripped.disconnect(callable)
	_strip_connections.clear()
	for container in _enemy_containers.values():
		if is_instance_valid(container):
			container.queue_free()
	_enemy_containers.clear()

func _create_enemy_container(enemy: Node) -> void:
	var container := VBoxContainer.new()
	add_child(container)
	_enemy_containers[enemy] = container
	var callable := _remove_card_for_component.bind(enemy)
	_strip_connections[enemy] = callable
	enemy.component_stripped.connect(callable)
	for comp in enemy.components:
		var card = ComponentCard.instantiate()
		container.add_child(card)
		card.setup(comp, enemy)

func _remove_card_for_component(component, enemy: Node) -> void:
	var container = _enemy_containers.get(enemy)
	if container == null or not is_instance_valid(container):
		return
	for child in container.get_children():
		if is_instance_valid(child) and child.component == component:
			container.remove_child(child)
			child.queue_free()
			return
