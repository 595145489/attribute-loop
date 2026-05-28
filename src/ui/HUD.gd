class_name HUD
extends CanvasLayer

var _inventory_panel = null
var _altar_panel = null
var _altar_tile = null
var _float_tween: Tween = null

@onready var altar_btn: Button = $BottomBar/HContent/AltarButton
@onready var log_btn: Button = $BottomBar/HContent/LogButton
@onready var log_panel: LogPanel = $LogPanel
@onready var hp_label: Label = $BottomBar/HContent/HPPill/HPLabel
@onready var loop_label: Label = $BottomBar/HContent/LoopPill/LoopLabel
@onready var phase_label: Label = $BottomBar/HContent/PhasePill/PhaseLabel
@onready var bag_btn: Button = $BottomBar/HContent/BagButton
@onready var gold_label: Label = $BottomBar/HContent/GoldPill/GoldLabel
@onready var pressure_label: Label = $BottomBar/HContent/PressurePill/PressureLabel
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
	log_btn.pressed.connect(log_panel.toggle)
	altar_btn.pressed.connect(_on_altar_pressed)
	float_label.hide()
	EventBus.rule_fired.connect(_on_rule_fired)
	_apply_ui_skin()

func _apply_ui_skin() -> void:
	var ui_theme = load("res://resources/ui_theme.tres")
	var panel_tex = load("res://resources/ui/panel_bg.png")
	var badge_tex = load("res://resources/ui/phase_badge_bg.png")
	var gold_icon_tex = load("res://resources/ui/gold_icon.png")

	if panel_tex:
		var s := StyleBoxTexture.new()
		s.texture = panel_tex
		s.content_margin_left = 8.0
		s.content_margin_top = 4.0
		s.content_margin_right = 8.0
		s.content_margin_bottom = 4.0
		for node in [
			$BottomBar,
			$BottomBar/HContent/HPPill,
			$BottomBar/HContent/LoopPill,
			$BottomBar/HContent/GoldPill,
			$BottomBar/HContent/PressurePill,
			$BottomBar/HContent/RulePanel0,
			$BottomBar/HContent/RulePanel1,
		]:
			node.add_theme_stylebox_override("panel", s)

	if badge_tex:
		var bs := StyleBoxTexture.new()
		bs.texture = badge_tex
		bs.content_margin_left = 8.0
		bs.content_margin_top = 2.0
		bs.content_margin_right = 8.0
		bs.content_margin_bottom = 2.0
		$BottomBar/HContent/PhasePill.add_theme_stylebox_override("panel", bs)

	if ui_theme:
		$BottomBar.theme = ui_theme
		bag_btn.remove_theme_stylebox_override("normal")

	if gold_icon_tex:
		var gold_pill := $BottomBar/HContent/GoldPill
		var gold_lbl := gold_label
		gold_pill.remove_child(gold_lbl)
		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 3)
		var icon_rect := TextureRect.new()
		icon_rect.texture = gold_icon_tex
		icon_rect.custom_minimum_size = Vector2(16, 16)
		icon_rect.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		hbox.add_child(icon_rect)
		hbox.add_child(gold_lbl)
		gold_pill.add_child(hbox)

func setup(inv_panel) -> void:
	_inventory_panel = inv_panel

func setup_altar(panel, tile) -> void:
	_altar_panel = panel
	_altar_tile = tile

func _process(_delta: float) -> void:
	hp_label.text = "❤ %d / %d" % [GameState.hp, GameState.hp_max]
	loop_label.text = "圈 × %d" % GameState.loops_completed
	bag_btn.text = "背包 [B] %d/%d" % [GameState.inventory.size(), DataTables.config.inventory_cap]
	gold_label.text = "金: %d" % GameState.gold
	if GameState.in_verdict_loop:
		var cfg: GameConfig = DataTables.config
		phase_label.text = "裁决圈"
		pressure_label.text = "进度: %d/%d圈" % [GameState.verdict_loops_survived, cfg.verdict_survive_loops]
	else:
		var phase_data: PhaseData = DataTables.get_phase(GameState.current_phase)
		phase_label.text = "阶段%d · %s" % [GameState.current_phase, phase_data.phase_name]
		pressure_label.text = "压力: %d/%d圈" % [GameState.loops_in_phase, phase_data.world_pressure_window]
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
