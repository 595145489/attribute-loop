class_name RuleAssemblyPanel
extends Panel

const Rule = preload("res://scripts/core/Rule.gd")
const EntryComponent = preload("res://scripts/core/EntryComponent.gd")
const Inventory = preload("res://scripts/systems/Inventory.gd")

var _player = null
var _current_rule: Rule = null
var _flashing: bool = false

@onready var trigger_slot = $SlotsContainer/TriggerSlot
@onready var effect_slot = $SlotsContainer/EffectSlot

var _is_setup: bool = false

func setup(p_player, p_inventory: Inventory) -> void:
	if _is_setup:
		return
	_is_setup = true
	_player = p_player
	trigger_slot.setup(EntryComponent.SlotType.TRIGGER, p_inventory)
	effect_slot.setup(EntryComponent.SlotType.EFFECT, p_inventory)
	trigger_slot.component_placed.connect(_on_slot_filled)
	trigger_slot.component_cleared.connect(_on_slot_cleared)
	effect_slot.component_placed.connect(_on_slot_filled)
	effect_slot.component_cleared.connect(_on_slot_cleared)
	_player.rule_fired.connect(_on_rule_fired)

func _on_slot_filled(_component: EntryComponent) -> void:
	_try_build_rule()

func _on_slot_cleared(_component: EntryComponent) -> void:
	if _current_rule != null:
		_player.rules.erase(_current_rule)
		_current_rule = null

func _try_build_rule() -> void:
	if trigger_slot.held_component == null or effect_slot.held_component == null:
		return
	if _current_rule != null:
		_player.rules.erase(_current_rule)
	_current_rule = Rule.new()
	_current_rule.trigger = trigger_slot.held_component
	_current_rule.effect = effect_slot.held_component
	_player.add_rule(_current_rule)

func _on_rule_fired(rule: Rule, _effect_type: String) -> void:
	if rule == _current_rule:
		_flash_slots()

func _flash_slots() -> void:
	if _flashing:
		return
	_flashing = true
	trigger_slot.modulate = Color(1.5, 1.5, 0.3)
	effect_slot.modulate = Color(1.5, 1.5, 0.3)
	await get_tree().create_timer(0.5).timeout
	if not is_instance_valid(self):
		return
	trigger_slot.modulate = Color(1, 1, 1)
	effect_slot.modulate = Color(1, 1, 1)
	_flashing = false
