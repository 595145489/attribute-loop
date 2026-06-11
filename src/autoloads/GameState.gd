extends Node

var hp: int
var hp_max: int = 500
var loops_completed: int = 0
var enemies_killed: int = 0
var current_phase: int = 1
var is_paused: bool = false

var speed_multiplier: float = 1.0:
	set(value):
		speed_multiplier = value
		_apply_time_scale()

var _panel_pause_count: int = 0

var pending_reflect_ratio: float = 0.0
var shield: int = 0
var slow_stacks: int = 0
var lifesteal_ratio: float = 0.0
var inventory: Array[ComponentData] = []
var rule_slots: Array = []
var gold: int = 0
var deletion_count: int = 0
var altar_bonuses: Dictionary = {}
var loops_in_phase: int = 0
var in_verdict_loop: bool = false
var pending_phase_advance: bool = false
var verdict_loops_survived: int = 0

# Auction / service bar
var service_bar: Array[int] = []
var deletion_free: bool = false
var enemy_pardon_type: String = ""
var enemy_pardon_remaining: int = 0

func _ready() -> void:
	reset()
	_setup_tooltip_style()

func _setup_tooltip_style() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.07, 0.12, 0.96)
	style.set_border_width_all(1)
	style.border_color = Color(0.5, 0.45, 0.65, 0.9)
	style.set_content_margin_all(8)
	style.set_corner_radius_all(4)
	ThemeDB.get_default_theme().set_stylebox("panel", "TooltipPanel", style)

func take_damage(amount: int) -> void:
	if shield > 0:
		var absorbed := mini(shield, amount)
		shield -= absorbed
		amount -= absorbed
	if amount > 0:
		hp = max(0, hp - amount)
		if hp == 0:
			EventBus.player_died.emit()

func reset() -> void:
	hp = hp_max
	loops_completed = 0
	enemies_killed = 0
	current_phase = 1
	is_paused = false
	_panel_pause_count = 0
	speed_multiplier = 1.0
	pending_reflect_ratio = 0.0
	shield = 0
	slow_stacks = 0
	lifesteal_ratio = 0.0
	inventory = []
	rule_slots = []
	gold = 0
	deletion_count = 0
	altar_bonuses = {}
	loops_in_phase = 0
	in_verdict_loop = false
	pending_phase_advance = false
	verdict_loops_survived = 0
	service_bar = []
	deletion_free = false
	enemy_pardon_type = ""
	enemy_pardon_remaining = 0
	for i in 2:
		rule_slots.append({"trigger": null, "effect": null})

func pause_for_panel() -> void:
	_panel_pause_count += 1
	_apply_time_scale()

func unpause_for_panel() -> void:
	_panel_pause_count = max(0, _panel_pause_count - 1)
	_apply_time_scale()

func _apply_time_scale() -> void:
	Engine.time_scale = 0.0 if _panel_pause_count > 0 else speed_multiplier

func inventory_has_space() -> bool:
	return inventory.size() < DataTables.config.inventory_cap

func add_to_inventory(c: ComponentData) -> void:
	inventory.append(c)

func remove_from_inventory(c: ComponentData) -> void:
	inventory.erase(c)

func delete_component(c: ComponentData) -> void:
	inventory.erase(c)

func equip(c: ComponentData, slot_idx: int, as_trigger: bool) -> void:
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

func get_deletion_cost() -> int:
	var seq: Array = DataTables.config.deletion_cost_sequence
	if deletion_count < seq.size():
		return seq[deletion_count]
	var cost: int = seq[-1]
	for i in deletion_count - (seq.size() - 1):
		cost = int(cost * DataTables.config.deletion_cost_multiplier)
	return cost

func can_afford_deletion() -> bool:
	return gold >= get_deletion_cost()

func pay_deletion_cost() -> void:
	if deletion_free:
		deletion_free = false
		EventBus.gold_changed.emit(gold)
		return
	gold -= get_deletion_cost()
	deletion_count += 1
	EventBus.gold_changed.emit(gold)

func force_phase_advance() -> void:
	current_phase += 1
	loops_in_phase = 0
	EventBus.phase_changed.emit(current_phase)
