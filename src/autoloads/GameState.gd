extends Node

var hp: int
var hp_max: int = 100
var loops_completed: int = 0
var enemies_killed: int = 0
var current_phase: int = 1
var is_paused: bool = false
var pending_reflect_ratio: float = 0.0
var inventory: Array[ComponentData] = []
var rule_slots: Array = []  # Array of {"trigger": ComponentData|null, "effect": ComponentData|null}

func _ready() -> void:
	reset()

func take_damage(amount: int) -> void:
	hp = max(0, hp - amount)
	if hp == 0:
		EventBus.player_died.emit()

func reset() -> void:
	hp = hp_max
	loops_completed = 0
	enemies_killed = 0
	current_phase = 1
	is_paused = false
	pending_reflect_ratio = 0.0
	inventory = []
	rule_slots = []
	for i in 2:
		rule_slots.append({"trigger": null, "effect": null})

func inventory_has_space() -> bool:
	return inventory.size() < DataTables.config.inventory_cap

func add_to_inventory(c: ComponentData) -> void:
	inventory.append(c)

func remove_from_inventory(c: ComponentData) -> void:
	inventory.erase(c)

func delete_component(c: ComponentData) -> void:
	inventory.erase(c)

func equip(c: ComponentData, slot_idx: int, as_trigger: bool) -> void:
	# Remove c from any rule slot it already occupies (move, not copy)
	for s in rule_slots:
		if s["trigger"] == c:
			s["trigger"] = null
		if s["effect"] == c:
			s["effect"] = null
	var slot = rule_slots[slot_idx]
	var sub_key = "trigger" if as_trigger else "effect"
	var displaced = slot[sub_key]
	if displaced != null:
		inventory.append(displaced)
	slot[sub_key] = c
	inventory.erase(c)

func unequip(slot_idx: int, as_trigger: bool) -> void:
	var slot = rule_slots[slot_idx]
	var sub_key = "trigger" if as_trigger else "effect"
	var c = slot[sub_key]
	if c != null:
		slot[sub_key] = null
		inventory.append(c)
