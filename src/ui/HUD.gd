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
@onready var char_btn: Button = $BottomBar/HContent/CharButton
@onready var _char_panel: CharacterPanel = $CharacterPanel
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


func _ready() -> void:
	bag_btn.pressed.connect(_on_bag_pressed)
	char_btn.pressed.connect(_on_char_pressed)
	log_btn.pressed.connect(log_panel.toggle)
	altar_btn.pressed.connect(_on_altar_pressed)
	float_label.hide()
	EventBus.rule_fired.connect(_on_rule_fired)
	EventBus.combat_enrage.connect(_on_combat_enrage)
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
	if GameState.shield > 0:
		hp_label.text = " %d / %d  (+%d)" % [GameState.hp, GameState.hp_max, GameState.shield]
	else:
		hp_label.text = " %d / %d" % [GameState.hp, GameState.hp_max]
	hp_bar.max_value = GameState.hp_max
	hp_bar.value = GameState.hp
	loop_label.text = "圈 × %d" % GameState.loops_completed
	bag_btn.text = "背包 [B] %d/%d" % [GameState.inventory.size(), DataTables.config.inventory_cap]
	gold_label.text = "%d" % GameState.gold
	if GameState.in_verdict_loop:
		var cfg: GameConfig = DataTables.config
		phase_label.text = "裁决圈"
		pressure_label.text = "进度: %d/%d圈" % [GameState.verdict_loops_survived, cfg.verdict_survive_loops]
	elif GameState.in_boss_circle:
		var phase_data: PhaseData = DataTables.get_phase(GameState.current_phase)
		phase_label.text = "阶段%d · %s  ⚠ Boss圈" % [GameState.current_phase, phase_data.phase_name]
		pressure_label.text = "压力: %d/%d圈" % [GameState.loops_in_phase, phase_data.world_pressure_window]
	else:
		var phase_data: PhaseData = DataTables.get_phase(GameState.current_phase)
		phase_label.text = "阶段%d · %s" % [GameState.current_phase, phase_data.phase_name]
		pressure_label.text = "压力: %d/%d圈" % [GameState.loops_in_phase, phase_data.world_pressure_window]

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_C:
			_on_char_pressed()
			get_viewport().set_input_as_handled()

func _on_char_pressed() -> void:
	if _char_panel == null:
		return
	if _inventory_panel != null and _inventory_panel.visible:
		_inventory_panel.toggle()
	_char_panel.toggle()

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
	EventBus.speed_changed.emit()

func _on_rule_fired(_slot_idx: int, effect_id: String, value: float) -> void:
	match effect_id:
		"治愈":
			float_label.text = "+%.0f 治愈" % value
		"反射":
			float_label.text = "反射 %.0f%%" % (value * 100)
		"护盾":
			float_label.text = "+%.0f 护盾" % value
		"减伤":
			float_label.text = "减伤 ×%.0f层" % value
		"吸血":
			float_label.text = "吸血 %.0f%%" % (value * 100)
		"强化":
			float_label.text = "强化 ×%d层" % GameState.amplify_stacks
		"增伤":
			float_label.text = "增伤 ×%d层" % GameState.dmg_boost_stacks
		"蓄能":
			float_label.text = "蓄能 %d层" % GameState.charge_stacks
		"蓄能释放":
			float_label.text = "蓄能释放 +%.0f" % value
		"灼烧":
			float_label.text = "灼烧 ×%.0f层" % value
		"侵蚀":
			float_label.text = "侵蚀 -%.0f" % value
		_:
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

func _on_combat_enrage(stacks: int) -> void:
	float_label.text = "激怒 ×%d" % stacks
	float_label.show()
	float_label.modulate = Color(1.0, 0.3, 0.1)
	if _float_tween:
		_float_tween.kill()
	_float_tween = create_tween()
	_float_tween.tween_property(float_label, "modulate:a", 0.0, 1.2)
	_float_tween.tween_callback(float_label.hide)

func setup_auction(ap, sb) -> void:
	_auction_panel = ap
	_service_bar = sb
	if _auction_panel:
		auction_btn.pressed.connect(_auction_panel.toggle)
