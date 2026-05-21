class_name HUD
extends CanvasLayer

var _inventory_panel = null  # InventoryPanel
var _float_tween: Tween = null

@onready var hp_label: Label = $VBox/HPLabel
@onready var loops_label: Label = $VBox/LoopsLabel
@onready var phase_label: Label = $VBox/PhaseLabel
@onready var rules_label: Label = $VBox/RulesLabel
@onready var bag_btn: Button = $VBox/BagButton
@onready var float_label: Label = $FloatLabel

func _ready() -> void:
    bag_btn.pressed.connect(_on_bag_pressed)
    float_label.hide()
    EventBus.rule_fired.connect(_on_rule_fired)

func setup(inv_panel) -> void:
    _inventory_panel = inv_panel

func _process(_delta: float) -> void:
    hp_label.text = "HP: %d / %d" % [GameState.hp, GameState.hp_max]
    loops_label.text = "圈数: %d" % GameState.loops_completed
    var phase_data: PhaseData = DataTables.get_phase(GameState.current_phase)
    phase_label.text = "阶段 %d — %s" % [GameState.current_phase, phase_data.phase_name]
    rules_label.text = _build_rules_summary()
    bag_btn.text = "背包 [B] %d/%d" % [GameState.inventory.size(), DataTables.config.inventory_cap]

func _build_rules_summary() -> String:
    var parts: Array = []
    for slot in GameState.rule_slots:
        var t: ComponentData = slot["trigger"]
        var e: ComponentData = slot["effect"]
        if t != null and e != null:
            parts.append("%s→%s" % [t.display_name, e.display_name])
        else:
            parts.append("空")
    return " / ".join(parts)

func _on_bag_pressed() -> void:
    if _inventory_panel != null:
        _inventory_panel.toggle()

func _on_rule_fired(_slot_idx: int, effect_id: String, value: float) -> void:
    if effect_id == "治愈":
        float_label.text = "+%.0f 治愈" % value
    elif effect_id == "反射":
        float_label.text = "反射 %.0f%%" % (value * 100)
    else:
        float_label.text = effect_id
    float_label.show()
    float_label.modulate = Color.WHITE
    if _float_tween:
        _float_tween.kill()
    _float_tween = create_tween()
    _float_tween.tween_property(float_label, "modulate:a", 0.0, 1.0)
    _float_tween.tween_callback(float_label.hide)
