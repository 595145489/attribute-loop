class_name CharacterPanel
extends PanelContainer

const _TOOLTIPS: Dictionary = {
	"SurvivalGroup/HP":         "当前生命 / 上限，归零即游戏结束",
	"SurvivalGroup/Shield":     "先于生命值承受伤害，耗尽后不再生效",
	"SurvivalGroup/SlowStacks": "每层降低你对敌人造成的伤害",
	"SurvivalGroup/Reflect":    "将受到伤害的一定比例反弹给攻击者",
	"OffenseGroup/Dmg":         "每次攻击造成的基础伤害",
	"OffenseGroup/Interval":    "两次攻击之间的间隔（秒），越低越快",
	"OffenseGroup/Amplify":     "每层提升你对敌人造成的伤害",
	"OffenseGroup/Lifesteal":   "每次造成伤害时按比例回复生命",
	"OffenseGroup/DmgBoost": "每层提升攻击伤害 10%，每圈结束衰减 1 层",
	"OffenseGroup/Charge":   "蓄积层数，下次攻击时全部释放为额外伤害（括号内为预期伤害）",
}

const _VALUE_COLORS: Dictionary = {
	"SurvivalGroup/HP":         Color(0.6, 0.18, 0.12, 1),
	"SurvivalGroup/Shield":     Color(0.2, 0.38, 0.6, 1),
	"SurvivalGroup/SlowStacks": Color(0.45, 0.2, 0.55, 1),
	"SurvivalGroup/Reflect":    Color(0.1, 0.45, 0.42, 1),
	"OffenseGroup/Dmg":         Color(0.65, 0.38, 0.08, 1),
	"OffenseGroup/Interval":    Color(0.45, 0.45, 0.45, 1),
	"OffenseGroup/Amplify":     Color(0.6, 0.5, 0.05, 1),
	"OffenseGroup/Lifesteal":   Color(0.65, 0.1, 0.22, 1),
	"OffenseGroup/DmgBoost": Color(0.72, 0.25, 0.08, 1),
	"OffenseGroup/Charge":   Color(0.55, 0.45, 0.05, 1),
}

func _ready() -> void:
	hide()
	$Margin/VBox/CloseButton.pressed.connect(toggle)
	for path in _TOOLTIPS:
		var row: HBoxContainer = $Margin/VBox.get_node(path)
		var tip: String = _TOOLTIPS[path]
		row.mouse_entered.connect(func(): Tooltip.show_tip(tip))
		row.mouse_exited.connect(Tooltip.hide_tip)

func toggle() -> void:
	if visible:
		hide()
		GameState.unpause_for_panel()
	else:
		_refresh()
		show()
		GameState.pause_for_panel()

func _refresh() -> void:
	var pd: PlayerData = DataTables.player

	_set_row("SurvivalGroup/HP",         "%d / %d" % [GameState.hp, GameState.hp_max])
	_set_row("SurvivalGroup/Shield",     _int_or_dash(GameState.shield))
	_set_row("SurvivalGroup/SlowStacks", _stacks_or_dash(GameState.slow_stacks))
	_set_row("SurvivalGroup/Reflect",    _pct_or_dash(GameState.pending_reflect_ratio))
	_set_row("OffenseGroup/Dmg",         "%d" % (pd.dmg_base + GameState.dmg_bonus))
	_set_row("OffenseGroup/Interval",    "%.1f 秒" % maxf(0.1, pd.attack_interval - GameState.attack_interval_bonus))
	_set_row("OffenseGroup/Amplify",     _stacks_or_dash(GameState.amplify_stacks))
	_set_row("OffenseGroup/Lifesteal",   _pct_or_dash(GameState.lifesteal_ratio))
	_set_row("OffenseGroup/DmgBoost", _stacks_or_dash(GameState.dmg_boost_stacks))
	var charge_potential := GameState.charge_stacks * DataTables.player.dmg_base
	_set_row("OffenseGroup/Charge",
		"—" if GameState.charge_stacks == 0 else "%d层 (%d)" % [GameState.charge_stacks, charge_potential])

func _set_row(path: String, value: String) -> void:
	var val_label: Label = $Margin/VBox.get_node(path + "/Value")
	val_label.text = value
	if value == "—":
		val_label.add_theme_color_override("font_color", Color(0.55, 0.45, 0.32, 0.45))
	else:
		val_label.add_theme_color_override("font_color", _VALUE_COLORS[path])

static func _int_or_dash(v: int) -> String:
	return "—" if v == 0 else "%d" % v

static func _stacks_or_dash(v: int) -> String:
	return "—" if v == 0 else "×%d 层" % v

static func _pct_or_dash(v: float) -> String:
	return "—" if v == 0.0 else "%d%%" % int(v * 100.0)
