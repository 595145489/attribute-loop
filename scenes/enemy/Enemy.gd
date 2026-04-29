class_name Enemy
extends Node2D

const EntryComponent = preload("res://scripts/core/EntryComponent.gd")

signal component_stripped(component: EntryComponent)
signal enemy_defeated

@export var hp: float = 40.0
@export var attack_damage: float = 8.0
@export var attack_interval: float = 2.0

var components: Array[EntryComponent] = []
var _attack_timer: float = 0.0
var player_ref: Node2D = null

func _process(delta: float) -> void:
	if player_ref == null:
		return
	_attack_timer += delta
	if _attack_timer >= attack_interval:
		_attack_timer = 0.0
		_attack_player()

func setup_components(comp_list: Array[EntryComponent]) -> void:
	components = comp_list

func _attack_player() -> void:
	if player_ref and player_ref.has_method("receive_damage"):
		player_ref.receive_damage(attack_damage)

func strip_component(component: EntryComponent) -> void:
	if component in components:
		components.erase(component)
		component_stripped.emit(component)

func receive_damage(amount: float) -> void:
	hp -= amount
	if hp <= 0.0:
		enemy_defeated.emit()
		queue_free()
