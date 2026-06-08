class_name AltarPanel
extends PanelContainer

const ALTAR_SLOT_BTN := preload("res://scenes/ui/components/altar_slot_button.tscn")
const INV_ITEM_BTN := preload("res://scenes/ui/components/inv_item_button.tscn")

var _tile: Tile = null
var _selecting_slot_idx: int = -1

@onready var _title: Label = $MarginContainer/VBox/Title
@onready var _progress: Label = $MarginContainer/VBox/Progress
@onready var _slots_container: VBoxContainer = $MarginContainer/VBox/AltarSlots
@onready var _bonuses_label: Label = $MarginContainer/VBox/BonusesLabel
@onready var _activate_btn: Button = $MarginContainer/VBox/ButtonRow/ActivateButton
@onready var _inv_picker: VBoxContainer = $MarginContainer/VBox/InvPicker
@onready var _inv_grid: GridContainer = $MarginContainer/VBox/InvPicker/InvScroll/InvGrid
@onready var _close_btn: Button = $MarginContainer/VBox/ButtonRow/CloseButton

func _ready() -> void:
	hide()
	_close_btn.pressed.connect(close)
	_activate_btn.pressed.connect(_on_activate)

func open(tile: Tile) -> void:
	_tile = tile
	_selecting_slot_idx = -1
	_inv_picker.hide()
	GameState.pause_for_panel()
	show()
	_refresh()

func close() -> void:
	hide()
	_tile = null
	GameState.unpause_for_panel()

func _refresh() -> void:
	var req := _tile.altar_slots.size()
	var filled := 0
	for slot in _tile.altar_slots:
		if slot != null:
			filled += 1
	_title.text = "绁潧 鈥?Phase %d 路 %s" % [GameState.current_phase, DataTables.get_phase(GameState.current_phase).phase_name]
	_progress.text = "杩涘害 %d / %d" % [filled, req]
	_activate_btn.disabled = filled < req
	_build_altar_slots()
	_build_bonuses_label()

func _build_altar_slots() -> void:
	for child in _slots_container.get_children():
		child.queue_free()
	for i in _tile.altar_slots.size():
		var comp := _tile.altar_slots[i] as ComponentData
		var btn: Button = ALTAR_SLOT_BTN.instantiate()
		if comp != null:
			var preview_bonus: float = comp.effect_value * comp.altar_ratio
			btn.text = "%s 鈫?+%.2f %s" % [comp.display_name, preview_bonus, comp.id]
			btn.icon = ComponentIcons.get_icon(comp.id)
		else:
			btn.text = "[绌?鈥?鏀惧叆E缁勪欢]"
		var idx := i
		btn.pressed.connect(func(): _on_altar_slot_clicked(idx))
		_slots_container.add_child(btn)

func _build_bonuses_label() -> void:
	if GameState.altar_bonuses.is_empty():
		_bonuses_label.text = "褰撳墠绁潧鍔犳垚锛氭棤"
		return
	var parts: Array[String] = []
	for k in GameState.altar_bonuses:
		parts.append("%s +%.2f" % [k, GameState.altar_bonuses[k]])
	_bonuses_label.text = "褰撳墠绁潧鍔犳垚锛? + " / ".join(parts)

func _on_altar_slot_clicked(slot_idx: int) -> void:
	if _tile.altar_slots[slot_idx] != null:
		return
	_selecting_slot_idx = slot_idx
	_show_inv_picker()

func _show_inv_picker() -> void:
	for child in _inv_grid.get_children():
		child.queue_free()
	for comp in GameState.inventory:
		var ok := comp.slot_type in [ComponentData.SlotType.EFFECT_ONLY, ComponentData.SlotType.BOTH]
		if not ok:
			continue
		var btn: Button = INV_ITEM_BTN.instantiate()
		btn.text = "%s (%.1f)" % [comp.display_name, comp.effect_value]
		btn.icon = ComponentIcons.get_icon(comp.id)
		var c := comp
		btn.pressed.connect(func(): _on_inv_pick(c))
		_inv_grid.add_child(btn)
	_inv_picker.show()

func _on_inv_pick(comp: ComponentData) -> void:
	if _selecting_slot_idx < 0:
		return
	_tile.altar_slots[_selecting_slot_idx] = comp
	GameState.remove_from_inventory(comp)
	_selecting_slot_idx = -1
	_inv_picker.hide()
	_refresh()

func _on_activate() -> void:
	for raw in _tile.altar_slots:
		var comp := raw as ComponentData
		if comp == null:
			continue
		var bonus: float = comp.effect_value * comp.altar_ratio
		GameState.altar_bonuses[comp.id] = GameState.altar_bonuses.get(comp.id, 0.0) as float + bonus
	_tile.altar_slots.fill(null)
	GameState.pending_phase_advance = true
	close()

