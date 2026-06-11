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
	_label.custom_minimum_size.x = 160
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
