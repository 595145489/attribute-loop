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
	position.x = -_open_offset
	hide()
	_close_btn.pressed.connect(toggle)
	EventBus.player_hit.connect(_on_player_hit)
	EventBus.rule_fired.connect(_on_rule_fired)
	EventBus.enemy_killed.connect(_on_enemy_killed)
	EventBus.gold_changed.connect(_on_gold_changed)
	EventBus.phase_changed.connect(_on_phase_changed)
	EventBus.verdict_loop_entered.connect(_on_verdict_loop_entered)

func toggle() -> void:
	if _is_open:
		_close()
	else:
		_open()

func _open() -> void:
	_is_open = true
	show()
	var tw = create_tween()
	tw.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(self, "position:x", 0.0, 0.2)

func _close() -> void:
	_is_open = false
	var tw = create_tween()
	tw.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(self, "position:x", -_open_offset, 0.2)
	await tw.finished
	hide()

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
	_add_entry("受击 −%d HP" % damage, Color.RED)

func _on_rule_fired(_slot_idx: int, effect_id: String, value: float) -> void:
	_add_entry("规则: %s +%.1f" % [effect_id, value], Color.GREEN)

func _on_enemy_killed(enemy: Enemy) -> void:
	_add_entry("击杀 %s" % enemy.enemy_id, Color.YELLOW)

func _on_gold_changed(new_amount: int) -> void:
	if new_amount > _last_gold:
		_add_entry("+%d 金" % (new_amount - _last_gold), Color(1.0, 0.8, 0.0))
	_last_gold = new_amount

func _on_phase_changed(n: int) -> void:
	_add_entry("→ Phase %d" % n, Color.CYAN)

func _on_verdict_loop_entered() -> void:
	_add_entry("进入裁决圈", Color(0.7, 0.4, 1.0))
