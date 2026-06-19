class_name TileRulePanel
extends PanelContainer

const SLOT_ENTRY_SCENE = preload("res://scenes/ui/tile_rule_slot_entry.tscn")

var _tile: Tile = null
var _selecting_slot_idx: int = -1
var _selecting_trigger: bool = false

@onready var _title: Label = $MarginContainer/VBox/Title
@onready var _slots_container: VBoxContainer = $MarginContainer/VBox/Slots
@onready var _inv_picker: VBoxContainer = $MarginContainer/VBox/InvPicker
@onready var _inv_label: Label = $MarginContainer/VBox/InvPicker/InvLabel
@onready var _inv_grid: GridContainer = $MarginContainer/VBox/InvPicker/InvGrid
@onready var _close_btn: Button = $MarginContainer/VBox/CloseButton

func _ready() -> void:
	hide()
	_close_btn.pressed.connect(close)

func open(tile: Tile) -> void:
	# Idempotent: only pause on the hidden→visible transition so repeated
	# open() calls can't drift the panel-pause refcount.
	var was_visible := visible
	_tile = tile
	_selecting_slot_idx = -1
	_inv_picker.hide()
	if not was_visible:
		GameState.pause_for_panel()
		show()
	_refresh()
	EventBus.tile_rule_panel_opened.emit()

func close() -> void:
	hide()
	_tile = null
	GameState.unpause_for_panel()
	if GameState.is_tutorial:
		EventBus.tile_rule_panel_closed.emit()

func _refresh() -> void:
	_title.text = "%s — 经过 %d 次" % [_tile.get_tile_name(), _tile.pass_count]
	_build_slots()

func _build_slots() -> void:
	for child in _slots_container.get_children():
		child.queue_free()

	for i in _tile.rule_slots.size():
		var entry: TileRuleSlotEntry = SLOT_ENTRY_SCENE.instantiate()
		entry.slot_idx = i
		_slots_container.add_child(entry)
		entry.refresh(_tile.rule_slots[i], _tile)
		entry.trigger_clicked.connect(_on_sub_slot_clicked.bind(true))
		entry.effect_clicked.connect(_on_sub_slot_clicked.bind(false))
		entry.remove_clicked.connect(_on_remove_slot)

func _on_sub_slot_clicked(slot_idx: int, is_trigger: bool) -> void:
	_selecting_slot_idx = slot_idx
	_selecting_trigger = is_trigger
	if GameState.is_tutorial:
		EventBus.tile_slot_selected.emit(is_trigger)
	_show_inv_picker(is_trigger)

func _show_inv_picker(trigger_only: bool) -> void:
	for child in _inv_grid.get_children():
		child.queue_free()
	_inv_label.text = "选择%s词条" % ("经过触发" if trigger_only else "效果")
	for comp in GameState.inventory:
		var ok: bool
		if trigger_only:
			ok = comp.id == "经过"
		else:
			ok = comp.slot_type in [ComponentData.SlotType.EFFECT_ONLY, ComponentData.SlotType.BOTH]
		if not ok:
			continue
		var btn := Button.new()
		if trigger_only:
			btn.text = "%s  每%.0f次" % [comp.display_name, comp.trigger_value]
		else:
			btn.text = "%s  +%.1f" % [comp.display_name, comp.effect_value]
		var c = comp
		btn.pressed.connect(func(): _on_inv_pick(c))
		_inv_grid.add_child(btn)
	_inv_picker.show()

func _on_inv_pick(comp: ComponentData) -> void:
	if _selecting_slot_idx < 0:
		return
	var slot = _tile.rule_slots[_selecting_slot_idx]
	var key = "trigger" if _selecting_trigger else "effect"
	var displaced: ComponentData = slot[key]
	if displaced != null:
		GameState.add_to_inventory(displaced)
	slot[key] = comp
	GameState.remove_from_inventory(comp)
	EventBus.tile_rule_set.emit()
	_selecting_slot_idx = -1
	_inv_picker.hide()
	_refresh()

func _on_remove_slot(slot_idx: int) -> void:
	if not GameState.can_afford_deletion():
		return
	GameState.pay_deletion_cost()
	var slot = _tile.rule_slots[slot_idx]
	slot["trigger"] = null
	slot["effect"] = null
	_refresh()
