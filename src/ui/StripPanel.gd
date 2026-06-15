class_name StripPanel
extends PanelContainer

const STRIP_CARD = preload("res://scenes/ui/components/strip_card.tscn")

var _on_complete: Callable
var _inventory_panel = null

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
    var card: PanelContainer = STRIP_CARD.instantiate()
    var val_str: String
    if comp.slot_type == ComponentData.SlotType.TRIGGER_ONLY:
        val_str = " (T:%.0f)" % comp.trigger_value
    elif comp.slot_type == ComponentData.SlotType.EFFECT_ONLY:
        val_str = " (E:%.1f)" % comp.effect_value
    else:
        val_str = " (T:%.0f/E:%.1f)" % [comp.trigger_value, comp.effect_value]
    card.get_node("VBox/InfoRow/Label").text = comp.display_name + val_str
    card.mouse_entered.connect(func(): Tooltip.show_tip(Tooltip.build_tip(comp)))
    card.mouse_exited.connect(Tooltip.hide_tip)
    var icon_tex := ComponentIcons.get_icon(comp.id)
    if icon_tex != null:
        card.get_node("VBox/InfoRow/Icon").texture = icon_tex
    var take_btn: Button = card.get_node("VBox/TakeButton")
    take_btn.disabled = not GameState.inventory_has_space()
    take_btn.pressed.connect(func():
        GameState.add_to_inventory(comp)
        EventBus.component_stripped.emit(comp)
        take_btn.disabled = true
        take_btn.text = "已取"
        _refresh_take_buttons()
    )
    return card

func _refresh_take_buttons() -> void:
    var has_space = GameState.inventory_has_space()
    for card in _grid.get_children():
        var take_btn = card.get_node_or_null("VBox/TakeButton")
        if take_btn and take_btn.text == "取走":
            take_btn.disabled = not has_space

func _on_continue() -> void:
    hide()
    GameState.unpause_for_panel()
    EventBus.strip_panel_closed.emit()
    if _on_complete.is_valid():
        _on_complete.call()

func _on_open_bag() -> void:
    if _inventory_panel != null:
        _inventory_panel.toggle()
