class_name LogPanel
extends PanelContainer

var _is_open: bool = false
var _last_gold: int = 0
var _open_offset: float = -280.0

@onready var _entries: VBoxContainer = $VBox/Scroll/Entries
@onready var _scroll: ScrollContainer = $VBox/Scroll
@onready var _close_btn: Button = $VBox/Header/CloseBtn

func _ready() -> void:
	_open_offset = offset_left
	offset_left = 0.0
	_close_btn.pressed.connect(toggle)
	EventBus.player_hit.connect(_on_player_hit)
	EventBus.player_attacked.connect(_on_player_attacked)
	EventBus.rule_fired.connect(_on_rule_fired)
	EventBus.enemy_killed.connect(_on_enemy_killed)
	EventBus.gold_changed.connect(_on_gold_changed)
	EventBus.phase_changed.connect(_on_phase_changed)
	EventBus.verdict_loop_entered.connect(_on_verdict_loop_entered)
	EventBus.combat_enrage.connect(_on_combat_enrage)

func toggle() -> void:
	if _is_open:
		_close()
	else:
		_open()

func _open() -> void:
	_is_open = true
	show()
	if Engine.time_scale == 0.0:
		offset_left = _open_offset
		return
	var tw = create_tween()
	tw.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(self, "offset_left", _open_offset, 0.25)

func _close() -> void:
	_is_open = false
	if Engine.time_scale == 0.0:
		offset_left = 0.0
		hide()
		return
	var tw = create_tween()
	tw.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(self, "offset_left", 0.0, 0.2)
	tw.tween_callback(hide)
func _add_entry(text: String, color: Color) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_color_override("font_color", color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_entries.add_child(label)
	var max_entries: int = DataTables.config.combat_log_max_entries
	while _entries.get_child_count() > max_entries:
		var oldest = _entries.get_child(0)
		_entries.remove_child(oldest)
		oldest.queue_free()
	call_deferred("_scroll_to_bottom")

func _scroll_to_bottom() -> void:
	_scroll.scroll_vertical = 99999

func _on_player_hit(damage: int) -> void:
	_add_entry(CombatText.player_hit(damage), Color(0.65, 0.08, 0.08))

func _on_player_attacked(damage: int) -> void:
	_add_entry(CombatText.player_attacked(damage), Color(0.12, 0.28, 0.55))

func _on_rule_fired(_slot_idx: int, effect_id: String, value: float) -> void:
	_add_entry(CombatText.rule_effect(effect_id, value), _color_for_effect(effect_id))

func _color_for_effect(effect_id: String) -> Color:
	var col_rule := Color(0.10, 0.40, 0.18)
	var col_dmg  := Color(0.50, 0.22, 0.04)
	var col_self := Color(0.65, 0.08, 0.08)
	var col_blue := Color(0.12, 0.28, 0.55)
	match effect_id:
		"灼烧", "灼烧伤害", "侵蚀", "侵蚀伤害": return col_dmg
		"受击", "低血":                       return col_self
		"蓄能释放", "击杀":                    return col_blue
		_:                                    return col_rule

func _on_enemy_killed(enemy: Enemy) -> void:
	_add_entry(CombatText.enemy_killed(enemy), Color(0.50, 0.22, 0.04))

func _on_gold_changed(new_amount: int) -> void:
	if new_amount > _last_gold:
		_add_entry("+%d 金" % (new_amount - _last_gold), Color(0.48, 0.36, 0.02))
	_last_gold = new_amount

func _on_phase_changed(n: int) -> void:
	_add_entry("→ 阶段 %d" % n, Color(0.15, 0.15, 0.55))

func _on_verdict_loop_entered() -> void:
	_add_entry("进入裁决圈", Color(0.35, 0.08, 0.48))

func _on_combat_enrage(stacks: int) -> void:
	_add_entry(CombatText.combat_enrage(stacks), Color(0.55, 0.12, 0.04))
