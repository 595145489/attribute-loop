class_name RuleSlotEntry
extends PanelContainer

@onready var _t_name: Label = $VBox/TRow/TName
@onready var _t_count: Label = $VBox/TRow/TCount
@onready var _e_name: Label = $VBox/ERow/EName
@onready var _e_value: Label = $VBox/ERow/EValue

func refresh(slot: Dictionary) -> void:
	var t: ComponentData = slot.get("trigger")
	var e: ComponentData = slot.get("effect")
	if t == null or e == null:
		_t_name.text = "— 空槽 —"
		_t_count.text = ""
		_e_name.text = ""
		_e_value.text = ""
		modulate = Color(1, 1, 1, 0.4)
		return
	modulate = Color(1, 1, 1, 1)
	_t_name.text = t.display_name
	_t_count.text = "%d/%d" % [t.trigger_count, int(t.trigger_value)]
	_e_name.text = e.display_name
	match e.id:
		"治愈":
			_e_value.text = "+%d" % int(e.effect_value)
		"反射":
			_e_value.text = "%d%%" % int(e.effect_value * 100)
		"护盾":
			_e_value.text = "+%d" % int(e.effect_value)
		"减伤":
			_e_value.text = "×%d层" % int(e.effect_value)
		"吸血":
			_e_value.text = "%d%%" % int(e.effect_value * 100)
		"强化":
			_e_value.text = "×%d/%d" % [GameState.amplify_stacks, GameState.amplify_max_stacks]
		"增伤":
			_e_value.text = "×%d层" % int(e.effect_value)
		"蓄能":
			var potential := GameState.charge_stacks * DataTables.player.dmg_base
			_e_value.text = "%d层 (%d)" % [GameState.charge_stacks, potential]
		"灼烧":
			_e_value.text = "×%d层" % int(e.effect_value)
		"侵蚀":
			_e_value.text = "-%d" % int(e.effect_value)
		_:
			_e_value.text = ""
