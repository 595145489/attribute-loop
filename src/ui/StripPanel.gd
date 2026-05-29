class_name StripPanel
extends PanelContainer

var _on_complete: Callable
var _inventory_panel = null  # InventoryPanel 闁?set via setup()

@onready var _grid: GridContainer = $VBox/ComponentScroll/ComponentGrid
@onready var _continue_btn: Button = $VBox/HBox/ContinueButton
@onready var _bag_btn: Button = $VBox/HBox/BagButton

func _ready() -> void:
    _continue_btn.pressed.connect(_on_continue)
    _bag_btn.pressed.connect(_on_open_bag)

func setup(inv_panel) -> void:
    _inventory_panel = inv_panel

func show_for_enemy(enemy: Enemy, on_complete: Callable) -> void:
    _on_complete = on_complete
    _build_grid(enemy.components)
    show()
    GameState.pause_for_panel()

func _build_grid(components: Array[ComponentData]) -> void:
    for child in _grid.get_children():
        child.queue_free()
    for comp in components:
        _grid.add_child(_make_card(comp))

func _make_card(comp: ComponentData) -> PanelContainer:
    var card := PanelContainer.new()
    card.custom_minimum_size = Vector2(200, 110)
    card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    var vbox := VBoxContainer.new()
    card.add_child(vbox)
    var hbox := HBoxContainer.new()
    hbox.add_theme_constant_override("separation", 8)
    vbox.add_child(hbox)
    var icon_container := Control.new()
    icon_container.custom_minimum_size = Vector2(32, 32)
    icon_container.size_flags_vertical = Control.SIZE_SHRINK_CENTER
    hbox.add_child(icon_container)
    var icon_tex := ComponentIcons.get_icon(comp.id)
    if icon_tex != null:
        var icon_rect := TextureRect.new()
        icon_rect.texture = icon_tex
        icon_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
        icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        icon_container.add_child(icon_rect)
    var info_lbl := Label.new()
    var val_str: String
    if comp.slot_type == ComponentData.SlotType.TRIGGER_ONLY:
        val_str = " (T:%.0f)" % comp.trigger_value
    elif comp.slot_type == ComponentData.SlotType.EFFECT_ONLY:
        val_str = " (E:%.1f)" % comp.effect_value
    else:
        val_str = " (T:%.0f/E:%.1f)" % [comp.trigger_value, comp.effect_value]
    info_lbl.text = comp.display_name + val_str
    hbox.add_child(info_lbl)
    var take_btn := Button.new()
    take_btn.text = "取走"
    take_btn.custom_minimum_size = Vector2(120, 40)
    take_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
    take_btn.disabled = not GameState.inventory_has_space()
    take_btn.pressed.connect(func():
        GameState.add_to_inventory(comp)
        take_btn.disabled = true
        take_btn.text = "已取"
        _refresh_take_buttons()
    )
    vbox.add_child(take_btn)
    return card

func _refresh_take_buttons() -> void:
    var has_space = GameState.inventory_has_space()
    for card in _grid.get_children():
        for child in card.get_children():
            if child is VBoxContainer:
                for btn_node in child.get_children():
                    if btn_node is Button and btn_node.text == "取走":
                        btn_node.disabled = not has_space

func _on_continue() -> void:
    hide()
    GameState.unpause_for_panel()
    if _on_complete.is_valid():
        _on_complete.call()

func _on_open_bag() -> void:
    if _inventory_panel != null:
        _inventory_panel.toggle()
