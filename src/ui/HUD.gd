class_name HUD
extends CanvasLayer

var _inventory_panel = null
var _altar_panel = null
var _altar_tile = null
var _float_tween: Tween = null

@onready var altar_btn: Button = $BottomBar/HContent/AltarButton
@onready var hp_label: Label = $BottomBar/HContent/HPPill/HPLabel
@onready var loop_label: Label = $BottomBar/HContent/LoopPill/LoopLabel
@onready var phase_label: Label = $BottomBar/HContent/PhasePill/PhaseLabel
@onready var bag_btn: Button = $BottomBar/HContent/BagButton
@onready var gold_label: Label = $BottomBar/HContent/GoldPill/GoldLabel
@onready var float_label: Label = $FloatLabel

@onready var _t_name: Array[Label] = [
	$BottomBar/HContent/RulePanel0/RuleVBox0/TRow0/TName0,
	$BottomBar/HContent/RulePanel1/RuleVBox1/TRow1/TName1,
]
@onready var _t_bar: Array[ProgressBar] = [
	$BottomBar/HContent/RulePanel0/RuleVBox0/TRow0/TBar0,
	$BottomBar/HContent/RulePanel1/RuleVBox1/TRow1/TBar1,
]
@onready var _t_count: Array[Label] = [
	$BottomBar/HContent/RulePanel0/RuleVBox0/TRow0/TCount0,
	$BottomBar/HContent/RulePanel1/RuleVBox1/TRow1/TCount1,
]
@onready var _e_name: Array[Label] = [
	$BottomBar/HContent/RulePanel0/RuleVBox0/ERow0/EName0,
	$BottomBar/HContent/RulePanel1/RuleVBox1/ERow1/EName1,
]
@onready var _e_value: Array[Label] = [
	$BottomBar/HContent/RulePanel0/RuleVBox0/ERow0/EValue0,
	$BottomBar/HContent/RulePanel1/RuleVBox1/ERow1/EValue1,
]

func _ready() -> void:
	bag_btn.pressed.connect(_on_bag_pressed)
	altar_btn.pressed.connect(_on_altar_pressed)
	float_label.hide()
	EventBus.rule_fired.connect(_on_rule_fired)

func setup(inv_panel) -> void:
	_inventory_panel = inv_panel

func setup_altar(panel, tile) -> void:
	_altar_panel = panel
	_altar_tile = tile

func _process(_delta: float) -> void:
	hp_label.text = "❤ %d / %d" % [GameState.hp, GameState.hp_max]
	loop_label.text = "圈 × %d" % GameState.loops_completed
	var phase_data: PhaseData = DataTables.get_phase(GameState.current_phase)
	phase_label.text = "阶段%d · %s" % [GameState.current_phase, phase_data.phase_name]
	bag_btn.text = "背包 [B] %d/%d" % [GameState.inventory.size(), DataTables.config.inventory_cap]
	gold_label.text = "金: %d" % GameState.gold
	for i in GameState.rule_slots.size():
		_update_rule_panel(i)

func _update_rule_panel(i: int) -> void:
	var slot = GameState.rule_slots[i]
	var t: ComponentData = slot.get("trigger")
	var e: ComponentData = slot.get("effect")
	if t == null or e == null:
		_t_name[i].text = "— 空槽 —"
		_t_bar[i].max_value = 1
		_t_bar[i].value = 0
		_t_count[i].text = ""
		_e_name[i].text = ""
		_e_value[i].text = ""
		return
	_t_name[i].text = t.display_name
	_t_bar[i].max_value = t.trigger_value
	_t_bar[i].value = t.trigger_count
	_t_count[i].text = "%d/%d" % [t.trigger_count, int(t.trigger_value)]
	_e_name[i].text = e.display_name
	match e.id:
		"治愈":
			_e_value[i].text = "+%d" % int(e.effect_value)
		"反射":
			_e_value[i].text = "%d%%" % int(e.effect_value * 100)
		_:
			_e_value[i].text = ""

func _on_bag_pressed() -> void:
	if _inventory_panel != null:
		_inventory_panel.toggle()

func _on_altar_pressed() -> void:
	if _altar_panel == null or _altar_tile == null:
		return
	if _altar_panel.visible:
		_altar_panel.close()
	else:
		_altar_panel.open(_altar_tile)

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
