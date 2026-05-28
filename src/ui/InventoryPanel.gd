class_name InventoryPanel
extends PanelContainer

var _selected: ComponentData = null

@onready var _rule_slot_container: VBoxContainer = $VBox/RuleSlots
@onready var _inv_grid: GridContainer = $VBox/InventoryGrid
@onready var _delete_btn: Button = $VBox/DeleteButton
@onready var _close_btn: Button = $VBox/CloseButton
@onready var _inv_label: Label = $VBox/InvLabel

func _ready() -> void:
    hide()
    _delete_btn.hide()
    _delete_btn.pressed.connect(_on_delete)
    _close_btn.pressed.connect(toggle)

func _input(event: InputEvent) -> void:
    if not visible:
        return
    if event is InputEventKey and event.pressed and event.keycode == KEY_TAB:
        toggle()
        get_viewport().set_input_as_handled()

func toggle() -> void:
    if visible:
        hide()
        GameState.unpause_for_panel()
    else:
        show()
        GameState.pause_for_panel()
        _refresh()

func _refresh() -> void:
    _build_rule_slots()
    _build_inventory_grid()
    _inv_label.text = "背包 %d/%d" % [GameState.inventory.size(), DataTables.config.inventory_cap]

func _build_rule_slots() -> void:
    for child in _rule_slot_container.get_children():
        child.queue_free()
    for i in GameState.rule_slots.size():
        var slot = GameState.rule_slots[i]
        var hbox := HBoxContainer.new()
        _rule_slot_container.add_child(hbox)
        var t_comp: ComponentData = slot["trigger"]
        var t_btn := Button.new()
        t_btn.text = (t_comp.display_name + " [%d/%.0f]" % [t_comp.trigger_count, t_comp.trigger_value]) if t_comp else "[T 空]"
        if t_comp != null:
            var t_tex := ComponentIcons.get_icon(t_comp.id)
            if t_tex != null:
                t_btn.icon = t_tex
        t_btn.pressed.connect(_make_slot_handler(i, true, t_comp))
        hbox.add_child(t_btn)
        var e_comp: ComponentData = slot["effect"]
        var e_btn := Button.new()
        e_btn.text = (e_comp.display_name + " [%.1f]" % e_comp.effect_value) if e_comp else "[E 空]"
        if e_comp != null:
            var e_tex := ComponentIcons.get_icon(e_comp.id)
            if e_tex != null:
                e_btn.icon = e_tex
        e_btn.pressed.connect(_make_slot_handler(i, false, e_comp))
        hbox.add_child(e_btn)

func _make_slot_handler(slot_idx: int, is_trigger: bool, existing: ComponentData) -> Callable:
    return func():
        if _selected != null:
            var wrong_type = (is_trigger and _selected.slot_type == ComponentData.SlotType.EFFECT_ONLY) or \
                             (not is_trigger and _selected.slot_type == ComponentData.SlotType.TRIGGER_ONLY)
            if not wrong_type:
                GameState.equip(_selected, slot_idx, is_trigger)
                _selected = null
                _delete_btn.hide()
                _refresh()
        elif existing != null:
            _select(existing)

func _build_inventory_grid() -> void:
    for child in _inv_grid.get_children():
        child.queue_free()
    for comp in GameState.inventory:
        var btn := Button.new()
        var label = comp.display_name
        if comp.slot_type == ComponentData.SlotType.TRIGGER_ONLY:
            label += " (T:%.0f)" % comp.trigger_value
        elif comp.slot_type == ComponentData.SlotType.EFFECT_ONLY:
            label += " (E:%.1f)" % comp.effect_value
        else:
            label += " (T:%.0f/E:%.1f)" % [comp.trigger_value, comp.effect_value]
        btn.text = label
        btn.custom_minimum_size = Vector2i(120, 40)
        var icon_tex := ComponentIcons.get_icon(comp.id)
        if icon_tex != null:
            btn.icon = icon_tex
        var c = comp
        btn.pressed.connect(func(): _select(c))
        _inv_grid.add_child(btn)

func _select(comp: ComponentData) -> void:
    _selected = comp
    var cost = GameState.get_deletion_cost()
    _delete_btn.text = "删除 ¥%d" % cost
    _delete_btn.disabled = not GameState.can_afford_deletion()
    _delete_btn.show()
    _refresh()

func _on_delete() -> void:
    if _selected == null:
        return
    if not GameState.can_afford_deletion():
        return
    for i in GameState.rule_slots.size():
        var slot = GameState.rule_slots[i]
        if slot["trigger"] == _selected:
            slot["trigger"] = null
        if slot["effect"] == _selected:
            slot["effect"] = null
    GameState.pay_deletion_cost()
    GameState.delete_component(_selected)
    _selected = null
    _delete_btn.hide()
    _refresh()
