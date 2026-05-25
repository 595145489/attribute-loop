class_name TileRulePanel
extends PanelContainer

var _tile: Tile = null
var _selecting_slot_idx: int = -1
var _selecting_trigger: bool = false

@onready var _title: Label = $VBox/Title
@onready var _slots_container: VBoxContainer = $VBox/Slots
@onready var _inv_picker: VBoxContainer = $VBox/InvPicker
@onready var _inv_label: Label = $VBox/InvPicker/InvLabel
@onready var _inv_grid: GridContainer = $VBox/InvPicker/InvGrid
@onready var _close_btn: Button = $VBox/CloseButton

func _ready() -> void:
	hide()
	_close_btn.pressed.connect(close)

func open(tile: Tile) -> void:
	_tile = tile
	_selecting_slot_idx = -1
	_inv_picker.hide()
	GameState.is_paused = true
	show()
	_refresh()

func close() -> void:
	hide()
	_tile = null
	GameState.is_paused = false

func _refresh() -> void:
	_title.text = "地块 #%d — 经过 %d 次" % [_tile.tile_index, _tile.pass_count]
	_build_slots()

func _build_slots() -> void:
	for child in _slots_container.get_children():
		child.queue_free()

	for i in _tile.rule_slots.size():
		var slot = _tile.rule_slots[i]
		var t: ComponentData = slot["trigger"]
		var e: ComponentData = slot["effect"]

		var hbox := HBoxContainer.new()
		_slots_container.add_child(hbox)

		var t_btn := Button.new()
		t_btn.text = ("%s (%d)" % [t.display_name, int(t.trigger_value)]) if t else "[T 经过]"
		var idx = i
		t_btn.pressed.connect(func(): _on_sub_slot_clicked(idx, true))
		hbox.add_child(t_btn)

		var e_btn := Button.new()
		if e:
			var scale_factor = 1.0 + e.growth_rate * pow(float(_tile.pass_count), e.scale_exponent)
			var val = e.effect_value * scale_factor
			e_btn.text = "%s (%.1f)" % [e.display_name, val]
		else:
			e_btn.text = "[E 空]"
		e_btn.pressed.connect(func(): _on_sub_slot_clicked(idx, false))
		hbox.add_child(e_btn)

		var remove_btn := Button.new()
		var cost = GameState.get_deletion_cost()
		remove_btn.text = "移除 ¥%d" % cost
		remove_btn.disabled = (t == null and e == null) or not GameState.can_afford_deletion()
		remove_btn.pressed.connect(func(): _on_remove_slot(idx))
		hbox.add_child(remove_btn)

func _on_sub_slot_clicked(slot_idx: int, is_trigger: bool) -> void:
	_selecting_slot_idx = slot_idx
	_selecting_trigger = is_trigger
	_show_inv_picker(is_trigger)

func _show_inv_picker(trigger_only: bool) -> void:
	for child in _inv_grid.get_children():
		child.queue_free()
	_inv_label.text = "选择%s组件" % ("经过触发" if trigger_only else "效果")
	for comp in GameState.inventory:
		var ok: bool
		if trigger_only:
			ok = comp.id == "经过"
		else:
			ok = comp.slot_type in [ComponentData.SlotType.EFFECT_ONLY, ComponentData.SlotType.BOTH]
		if not ok:
			continue
		var btn := Button.new()
		btn.text = comp.display_name
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
