class_name RuleSlotsPanel
extends PanelContainer

const ENTRY = preload("res://scenes/ui/rule_slot_entry.tscn")

@onready var _container: VBoxContainer = $VBox/SlotsContainer

func _ready() -> void:
	EventBus.rule_slots_changed.connect(_rebuild)
	EventBus.rule_fired.connect(_on_rule_fired)
	EventBus.rule_equipped.connect(_rebuild)
	_rebuild()

func _rebuild(_ignored = null) -> void:
	for child in _container.get_children():
		child.queue_free()
	for slot in GameState.rule_slots:
		var entry: RuleSlotEntry = ENTRY.instantiate()
		_container.add_child(entry)
		entry.refresh(slot)

func _on_rule_fired(_slot_idx: int, _effect_id: String, _value: float) -> void:
	_refresh_all()

func _refresh_all() -> void:
	var children := _container.get_children()
	for i in children.size():
		if i < GameState.rule_slots.size():
			children[i].refresh(GameState.rule_slots[i])

func _process(_delta: float) -> void:
	_refresh_all()
