class_name CombatFeed
extends Control

# Real-time scrolling combat stream shown in the center of the map.
# Complements LogPanel (retained history) by surfacing the live damage flow
# as short-lived, fading entries.

const MAX_VISIBLE := 6
const LIFETIME := 3.5  # seconds before an entry finishes fading out

const COL_PLAYER_HIT := Color(0.85, 0.18, 0.18)
const COL_PLAYER_ATK := Color(0.30, 0.55, 0.95)
const COL_ENEMY_DMG  := Color(0.90, 0.45, 0.16)
const COL_KILL       := Color(0.90, 0.55, 0.18)
const COL_ENRAGE     := Color(0.95, 0.35, 0.12)
const COL_SELF_DMG   := Color(0.85, 0.25, 0.30)

@onready var _entries: VBoxContainer = $Entries

# Tracks live fade tweens so the cap-enforcer can cancel a tween before
# freeing the label it animates (avoids orphaned-tween warnings).
var _tweens: Dictionary = {}


func _ready() -> void:
	EventBus.player_hit.connect(_on_player_hit)
	EventBus.player_attacked.connect(_on_player_attacked)
	EventBus.rule_fired.connect(_on_rule_fired)
	EventBus.enemy_killed.connect(_on_enemy_killed)
	EventBus.combat_enrage.connect(_on_combat_enrage)


func _add_entry(text: String, color: Color) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", 14)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_entries.add_child(label)
	_trim_to_cap()
	_start_fade(label)


func _trim_to_cap() -> void:
	while _entries.get_child_count() > MAX_VISIBLE:
		var oldest: Label = _entries.get_child(0)
		_free_entry(oldest)


func _start_fade(label: Label) -> void:
	var tw := create_tween()
	tw.tween_interval(LIFETIME * 0.55)
	tw.tween_property(label, "modulate:a", 0.0, LIFETIME * 0.45)
	tw.tween_callback(_free_entry.bind(label))
	_tweens[label.get_instance_id()] = tw


func _free_entry(label: Label) -> void:
	if not is_instance_valid(label):
		return
	var id := label.get_instance_id()
	if _tweens.has(id):
		var tw: Tween = _tweens[id]
		_tweens.erase(id)
		if tw.is_valid():
			tw.kill()
	# queue_free() is deferred — remove from the parent first so the entry
	# count drops immediately (otherwise the cap-trim loop never terminates).
	if label.get_parent() != null:
		label.get_parent().remove_child(label)
	label.queue_free()


func _on_player_hit(damage: int) -> void:
	_add_entry(CombatText.player_hit(damage), COL_PLAYER_HIT)


func _on_player_attacked(damage: int) -> void:
	_add_entry(CombatText.player_attacked(damage), COL_PLAYER_ATK)


func _on_rule_fired(_slot_idx: int, effect_id: String, value: float) -> void:
	# Only damage-bearing effects; buff stacks stay in LogPanel only.
	match effect_id:
		"灼烧伤害", "侵蚀伤害", "蓄能释放", "受击", "低血", "击杀":
			_add_entry(CombatText.rule_effect(effect_id, value), _color_for_effect(effect_id))


func _on_enemy_killed(enemy: Enemy) -> void:
	_add_entry(CombatText.enemy_killed(enemy), COL_KILL)


func _on_combat_enrage(stacks: int) -> void:
	_add_entry(CombatText.combat_enrage(stacks), COL_ENRAGE)


func _color_for_effect(effect_id: String) -> Color:
	match effect_id:
		"灼烧伤害", "侵蚀伤害": return COL_ENEMY_DMG
		"蓄能释放", "击杀":    return COL_PLAYER_ATK
		"受击", "低血":        return COL_SELF_DMG
		_:                     return COL_ENEMY_DMG
