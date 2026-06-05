class_name HUD
extends CanvasLayer

const SPEEDS: Array[float] = [0.0, 1.0, 2.0, 3.0]

var _inventory_panel = null
var _altar_panel = null
var _altar_tile = null
var _float_tween: Tween = null

@onready var altar_btn: Button = $BottomBar/HContent/AltarButton
@onready var log_btn: Button = $BottomBar/HContent/LogButton
@onready var log_panel: LogPanel = $LogPanel
@onready var hp_label: Label = $BottomBar/HContent/HPPill/HPVBox/HPLabel
@onready var hp_bar: ProgressBar = $BottomBar/HContent/HPPill/HPVBox/HPBarContainer/HPBar
@onready var loop_label: Label = $BottomBar/HContent/LoopPill/LoopLabel
@onready var phase_label: Label = $BottomBar/HContent/PhasePill/PhaseLabel
@onready var bag_btn: Button = $BottomBar/HContent/BagButton
@onready var gold_label: Label = $BottomBar/HContent/GoldPill/GoldHBox/GoldLabel
@onready var pressure_label: Label = $BottomBar/HContent/PressurePill/PressureLabel
@onready var float_label: Label = $FloatLabel
@onready var auction_btn: Button = $BottomBar/HContent/AuctionBtn
@onready var _speed_btns: Array[Button] = [
	$SpeedControl/Pause,
	$SpeedControl/Speed1x,
	$SpeedControl/Speed2x,
	$SpeedControl/Speed3x,
]

@onready var _t_name: Array[Label] = [
	$BottomBar/HContent/RulePanel0/RuleVBox0/TGroup0/TName0,
	$BottomBar/HContent/RulePanel1/RuleVBox1/TGroup1/TName1,
]
@onready var _t_count: Array[Label] = [
	$BottomBar/HContent/RulePanel0/RuleVBox0/TGroup0/TCount0,
	$BottomBar/HContent/RulePanel1/RuleVBox1/TGroup1/TCount1,
]
@onready var _e_name: Array[Label] = [
	$BottomBar/HContent/RulePanel0/RuleVBox0/EGroup0/EName0,
	$BottomBar/HContent/RulePanel1/RuleVBox1/EGroup1/EName1,
]
@onready var _e_value: Array[Label] = [
	$BottomBar/HContent/RulePanel0/RuleVBox0/EGroup0/EValue0,
	$BottomBar/HContent/RulePanel1/RuleVBox1/EGroup1/EValue1,
]

func _ready() -> void:
	bag_btn.pressed.connect(_on_bag_pressed)
	log_btn.pressed.connect(log_panel.toggle)
	altar_btn.pressed.connect(_on_altar_pressed)
	float_label.hide()
	EventBus.rule_fired.connect(_on_rule_fired)
	for i in _speed_btns.size():
		_speed_btns[i].pressed.connect(_on_speed_pressed.bind(i))

func setup(inv_panel) -> void:
	_inventory_panel = inv_panel

func setup_altar(panel, tile) -> void:
	_altar_panel = panel
	_altar_tile = tile

func _process(_delta: float) -> void:
	if hp_label == null:
		return
	hp_label.text = "❤ %d / %d" % [GameState.hp, GameState.hp_max]
	hp_bar.max_value = GameState.hp_max
	hp_bar.value = GameState.hp
	loop_label.text = "圈 × %d" % GameState.loops_completed
	bag_btn.text = "背包 [B] %d/%d" % [GameState.inventory.size(), DataTables.config.inventory_cap]
	gold_label.text = "%d" % GameState.gold
	if GameState.in_verdict_loop:
		var cfg: GameConfig = DataTables.config
		phase_label.text = "裁决圈"
		pressure_label.text = "进度: %d/%d圈" % [GameState.verdict_loops_survived, cfg.verdict_survive_loops]
	else:
		var phase_data: PhaseData = DataTables.get_phase(GameState.current_phase)
		phase_label.text = "阶段%d · %s" % [GameState.current_phase, phase_data.phase_name]
		pressure_label.text = "压力: %d/%d圈" % [GameState.loops_in_phase, phase_data.world_pressure_window]
		_update_rule_panel(i)

func _update_rule_panel(i: int) -> void:
	var slot = GameState.rule_slots[i]
	var t: ComponentData = slot.get("trigger")
	var e: ComponentData = slot.get("effect")
	if t == null or e == null:
		_t_name[i].text = "— 空槽 —"
		_t_count[i].text = ""
		_e_name[i].text = ""
		_e_value[i].text = ""
		return
	_t_name[i].text = t.display_name
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

func _on_speed_pressed(index: int) -> void:
	GameState.speed_multiplier = SPEEDS[index]

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

var _auction_panel = null
var _service_bar = null

func setup_auction(ap, sb) -> void:
	_auction_panel = ap
	_service_bar = sb
	if _auction_panel:
		auction_btn.pressed.connect(_auction_panel.toggle)

