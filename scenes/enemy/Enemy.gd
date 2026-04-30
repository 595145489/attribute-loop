class_name Enemy
extends Node2D

const EntryComponent = preload("res://scripts/core/EntryComponent.gd")

signal component_stripped(component: EntryComponent)
signal enemy_defeated

@export var hp: float = 40.0
@export var attack_damage: float = 8.0
@export var attack_interval: float = 2.0

var max_hp: float = 40.0
var components: Array[EntryComponent] = []
var _attack_timer: float = 0.0
var player_ref: Node2D = null

func _ready() -> void:
	max_hp = hp

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
		Log.info("stripped '%s', remaining=%d" % [component.label, components.size()], "Enemy")

func receive_damage(amount: float) -> void:
	hp -= amount
	_fire_components("on_hit", {"amount": amount})
	if hp <= 0.0:
		Log.info("defeated (hp=%.1f)" % hp, "Enemy")
		enemy_defeated.emit()
		queue_free()

func _fire_components(event: String, context: Dictionary) -> void:
	var has_trigger := false
	for comp in components:
		if comp.slot_type == EntryComponent.SlotType.TRIGGER and comp.data.get("event") == event:
			has_trigger = true
			break
	if not has_trigger:
		return
	for comp in components:
		if comp.slot_type == EntryComponent.SlotType.EFFECT:
			_apply_effect(comp, context)

func _apply_effect(comp: EntryComponent, context: Dictionary) -> void:
	match comp.data.get("type", ""):
		"heal":
			hp = clampf(hp + 10.0, 0.0, max_hp)
			Log.info("heal → hp=%.1f" % hp, "Enemy")
		"reflect_damage":
			if player_ref and player_ref.has_method("receive_damage"):
				var dmg: float = context.get("amount", 0.0) * 0.5
				Log.info("reflect %.1f to player" % dmg, "Enemy")
				player_ref.receive_damage(dmg)
		"summon_clone":
			Log.info("summon_clone (not implemented)", "Enemy")
