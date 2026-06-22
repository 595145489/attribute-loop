class_name TileRuleSlotEntry
extends HBoxContainer

signal trigger_clicked(slot_idx: int)
signal effect_clicked(slot_idx: int)
signal remove_clicked(slot_idx: int)

@export var remove_btn_prefix: String = "移除 ¥"

var slot_idx: int = 0

@onready var _t_btn: Button = $TriggerBtn
@onready var _e_btn: Button = $EffectBtn
@onready var _remove_btn: Button = $RemoveBtn

func _ready() -> void:
	_t_btn.pressed.connect(func(): trigger_clicked.emit(slot_idx))
	_e_btn.pressed.connect(func(): effect_clicked.emit(slot_idx))
	_remove_btn.pressed.connect(func(): remove_clicked.emit(slot_idx))
	_t_btn.mouse_entered.connect(_on_t_hover)
	_t_btn.mouse_exited.connect(func(): Tooltip.hide_tip())

func _on_t_hover() -> void:
	var e: ComponentData = get_meta("effect_comp", null)
	var is_combat := e != null and e.id in RuleEngine.COMBAT_TILE_EFFECTS
	if is_combat:
		Tooltip.show_tip("触发槽 — 只能放「经过」\n当前效果为战斗类，改为每 N 场战斗触发一次")
	else:
		Tooltip.show_tip("触发槽 — 只能放「经过」\n每经过该地块 N 次触发一次")

func refresh(slot: Dictionary, tile: Tile) -> void:
	var t: ComponentData = slot.get("trigger")
	var e: ComponentData = slot.get("effect")
	set_meta("effect_comp", e)

	if t:
		var is_combat_effect := e != null and e.id in RuleEngine.COMBAT_TILE_EFFECTS
		if is_combat_effect:
			_t_btn.text = "%s %d/%d战" % [t.display_name, tile.combat_count % maxi(1, int(t.trigger_value)), int(t.trigger_value)]
		else:
			_t_btn.text = "%s %d/%d" % [t.display_name, tile.pass_count % maxi(1, int(t.trigger_value)), int(t.trigger_value)]
	else:
		pass  # keeps tscn value

	if e:
		var age := maxi(0, tile.pass_count - int(slot.get("placed_pass", 0)))
		var scale_factor := 1.0 + e.growth_rate * pow(float(age), e.scale_exponent)
		var val := e.effect_value * scale_factor
		_e_btn.text = "%s +%.1f" % [e.display_name, val]
	else:
		pass  # keeps tscn value

	var cost := GameState.get_deletion_cost()
	_remove_btn.text = "%s%d" % [remove_btn_prefix, cost]
	_remove_btn.disabled = (t == null and e == null) or not GameState.can_afford_deletion()
