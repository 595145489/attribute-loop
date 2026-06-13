class_name TutorialOverlay
extends CanvasLayer

const DARK_COLOR := Color(0.0, 0.0, 0.0, 0.72)

@onready var _top: ColorRect = $TopDark
@onready var _bottom: ColorRect = $BottomDark
@onready var _left: ColorRect = $LeftDark
@onready var _right: ColorRect = $RightDark
@onready var _border: Panel = $HighlightBorder
@onready var _text_box: PanelContainer = $TextBox
@onready var _instruction: Label = $TextBox/VBox/InstructionLabel
@onready var _step_label: Label = $TextBox/VBox/StepLabel
@onready var _confirm_btn: Button = $ConfirmButton

var _highlight_rect: Rect2 = Rect2()
var _block_input: bool = false
var _highlight_node_path: String = ""

signal confirm_pressed

func _ready() -> void:
	for panel in [_top, _bottom, _left, _right]:
		panel.color = DARK_COLOR
	_confirm_btn.pressed.connect(func(): confirm_pressed.emit())
	_confirm_btn.hide()
	var style := StyleBoxFlat.new()
	style.border_color = Color(0.94, 0.75, 0.25, 1.0)
	style.set_border_width_all(2)
	style.shadow_color = Color(0.94, 0.75, 0.25, 0.35)
	style.shadow_size = 6
	style.bg_color = Color(0, 0, 0, 0)
	_border.add_theme_stylebox_override("panel", style)

func show_step(step: Dictionary, step_index: int, total: int) -> void:
	_instruction.text = step["text"]
	_step_label.text = "步骤 %d / %d" % [step_index + 1, total]
	_block_input = step.get("block_outside_input", false)
	_highlight_node_path = step.get("highlight_node", "")
	_confirm_btn.hide()
	if _highlight_node_path == "":
		_hide_dark_panels()
		_center_text_box()
		visible = true
		return
	_highlight_rect = Rect2()
	set_process(true)
	visible = true

func show_complete() -> void:
	_hide_dark_panels()
	_block_input = false
	_highlight_rect = Rect2()
	_center_text_box()
	_confirm_btn.show()
	_confirm_btn.position = Vector2(
		get_viewport().get_visible_rect().size.x / 2.0 - 80.0,
		get_viewport().get_visible_rect().size.y / 2.0 + 20.0
	)
	visible = true

func hide_overlay() -> void:
	visible = false
	set_process(false)
	_highlight_rect = Rect2()
	_block_input = false

func _process(_delta: float) -> void:
	if _highlight_node_path == "":
		set_process(false)
		return
	var node = get_tree().current_scene.find_child(
		_highlight_node_path.trim_prefix("%"), true, false)
	if node == null or not (node is Control):
		return
	var ctrl := node as Control
	if not ctrl.visible:
		return
	var rect: Rect2 = ctrl.get_global_rect().grow(6.0)
	if rect == _highlight_rect:
		return
	_highlight_rect = rect
	_update_dark_panels(rect)
	_position_text_box(rect)
	set_process(false)

func _update_dark_panels(hl: Rect2) -> void:
	var vp := get_viewport().get_visible_rect().size
	_top.visible = true
	_top.position = Vector2.ZERO
	_top.size = Vector2(vp.x, hl.position.y)
	_bottom.visible = true
	_bottom.position = Vector2(0.0, hl.end.y)
	_bottom.size = Vector2(vp.x, vp.y - hl.end.y)
	_left.visible = true
	_left.position = Vector2(0.0, hl.position.y)
	_left.size = Vector2(hl.position.x, hl.size.y)
	_right.visible = true
	_right.position = Vector2(hl.end.x, hl.position.y)
	_right.size = Vector2(vp.x - hl.end.x, hl.size.y)
	_border.visible = true
	_border.position = hl.position
	_border.size = hl.size

func _hide_dark_panels() -> void:
	for node in [_top, _bottom, _left, _right, _border]:
		node.visible = false

func _center_text_box() -> void:
	var vp := get_viewport().get_visible_rect().size
	_text_box.reset_size()
	_text_box.position = Vector2(vp.x / 2.0 - _text_box.size.x / 2.0, vp.y / 2.0 - 40.0)

func _position_text_box(hl: Rect2) -> void:
	var vp := get_viewport().get_visible_rect().size
	var box_h := 80.0
	var y_below := hl.end.y + 12.0
	var y_above := hl.position.y - box_h - 12.0
	var y := y_below if y_below + box_h < vp.y else y_above
	_text_box.reset_size()
	var x := clampf(hl.position.x, 8.0, vp.x - _text_box.size.x - 8.0)
	_text_box.position = Vector2(x, y)

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		GameState.is_tutorial = false
		get_tree().change_scene_to_file("res://scenes/ui/loading_screen.tscn")
		get_viewport().set_input_as_handled()
		return
	if not _block_input:
		return
	if _highlight_rect == Rect2():
		return
	if event is InputEventMouseButton or event is InputEventMouseMotion:
		if not _highlight_rect.has_point(event.position):
			get_viewport().set_input_as_handled()
