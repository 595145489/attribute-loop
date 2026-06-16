class_name RuleSlotsPanel
extends PanelContainer

const ENTRY = preload("res://scenes/ui/rule_slot_entry.tscn")

@onready var _container: VBoxContainer = $VBox/SlotsContainer

func _ready() -> void:
	EventBus.rule_slots_changed.connect(_rebuild)
	EventBus.rule_equipped.connect(_rebuild)
	_rebuild()

func _rebuild(_ignored = null) -> void:
	for child in _container.get_children():
		child.free()
	for slot in GameState.rule_slots:
		var entry: RuleSlotEntry = ENTRY.instantiate()
		_container.add_child(entry)
		entry.refresh(slot)

func _refresh_all() -> void:
	var children := _container.get_children()
	for i in children.size():
		if i < GameState.rule_slots.size():
			children[i].refresh(GameState.rule_slots[i])

# Poll every frame: amplify_stacks/charge_stacks/dmg_boost_stacks have no dedicated change signals
func _process(_delta: float) -> void:
	_refresh_all()
