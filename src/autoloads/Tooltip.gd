extends CanvasLayer

var _panel: PanelContainer
var _label: Label

func _ready() -> void:
	layer = 128

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.07, 0.13, 0.95)
	style.set_border_width_all(1)
	style.border_color = Color(0.55, 0.48, 0.68, 0.9)
	style.set_content_margin_all(8)
	style.set_corner_radius_all(4)

	_panel = PanelContainer.new()
	_panel.add_theme_stylebox_override("panel", style)
	add_child(_panel)

	_label = Label.new()
	_label.add_theme_color_override("font_color", Color(0.93, 0.91, 0.96, 1.0))
	_label.add_theme_font_size_override("font_size", 13)
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.custom_minimum_size.x = 180
	_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_panel.add_child(_label)

	_panel.hide()

func show_tip(text: String) -> void:
	if text.is_empty():
		return
	_label.text = text
	_panel.show()

func hide_tip() -> void:
	_panel.hide()

func _process(_delta: float) -> void:
	if not _panel.visible:
		return
	var mouse := _panel.get_viewport().get_mouse_position()
	var vp := _panel.get_viewport().get_visible_rect().size
	var size := _panel.size
	var pos := mouse + Vector2(14, 14)
	if pos.x + size.x > vp.x:
		pos.x = mouse.x - size.x - 4
	if pos.y + size.y > vp.y:
		pos.y = mouse.y - size.y - 4
	_panel.global_position = pos

# Build a dynamic tooltip string for a ComponentData instance.
# For BOTH-type components, shows trigger and effect lines.
# For equipped slots, call build_trigger_tip / build_effect_tip directly.
static func build_tip(comp: ComponentData) -> String:
	match comp.slot_type:
		ComponentData.SlotType.TRIGGER_ONLY:
			return _trigger_line(comp)
		ComponentData.SlotType.EFFECT_ONLY:
			return _effect_line(comp)
		ComponentData.SlotType.BOTH:
			return "[T] " + _trigger_line(comp) + "\n[E] " + _effect_line(comp)
	return comp.description

static func build_trigger_tip(comp: ComponentData) -> String:
	return _trigger_line(comp)

static func build_effect_tip(comp: ComponentData) -> String:
	return _effect_line(comp)

static func _trigger_line(comp: ComponentData) -> String:
	var n := int(comp.trigger_value)
	match comp.id:
		"受击":      return "受击 %d 次后触发" % n
		"击杀":      return "击杀 %d 个敌人后触发" % n
		"完成圈数":  return "完成 %d 圈后触发" % n
		"经过":      return "经过 %d 格后触发" % n
		"低血":      return "生命 <30%%，每持续 %d 秒触发" % n
		"满血":      return "生命值满，每持续 %d 秒触发" % n
		"规则触发":  return "其他规则触发 %d 次后触发" % n
		"治愈":      return "触发 %d 次治愈后激活" % n
		"反射":      return "触发 %d 次反射后激活" % n
	return "每 %d 次触发" % n

static func _effect_line(comp: ComponentData) -> String:
	var e := comp.effect_value
	match comp.id:
		"治愈":    return "恢复 %.0f 点生命值" % e
		"反射":    return "反弹 %.0f%% 伤害给攻击者" % (e * 100.0)
		"护盾":    return "获得 %.0f 点护盾" % e
		"减伤":    return "叠加 %.0f 层减伤，敌方伤害 -%d%%" % [e, int(e) * 10]
		"吸血":    return "获得 %.0f%% 吸血率" % (e * 100.0)
	return "效果值 %.1f" % e
