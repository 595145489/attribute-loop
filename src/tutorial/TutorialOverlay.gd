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
@onready var _skip_btn: Button = $SkipButton

var _highlight_rect: Rect2 = Rect2()
var _pending_skip_dialog: ConfirmationDialog = null
var _block_input: bool = false
var _highlight_node_path: String = ""
var _highlight_contains: String = ""
var _highlight_initial: String = ""
var _switch_on_select: String = ""
var _highlight_next: String = ""
var _confirm_click: bool = false
var _paused_for_complete: bool = false
var _highlight_contains_2: String = ""

signal confirm_pressed

func _ready() -> void:
	for panel in [_top, _bottom, _left, _right]:
		panel.color = DARK_COLOR
	_confirm_btn.pressed.connect(func(): confirm_pressed.emit())
	_confirm_btn.hide()
	_skip_btn.pressed.connect(_on_skip_pressed)
	_skip_btn.hide()
	var style := StyleBoxFlat.new()
	style.border_color = Color(0.94, 0.75, 0.25, 1.0)
	style.set_border_width_all(2)
	style.shadow_color = Color(0.94, 0.75, 0.25, 0.35)
	style.shadow_size = 6
	style.bg_color = Color(0, 0, 0, 0)
	_border.add_theme_stylebox_override("panel", style)
	EventBus.tutorial_component_selected.connect(_on_component_selected)
	EventBus.tile_slot_selected.connect(_on_tile_slot_selected)
	EventBus.altar_slot_selected.connect(func(): _on_tile_slot_selected(false))

func _on_component_selected(comp: ComponentData) -> void:
	if _switch_on_select == "" or _highlight_initial == "":
		return
	if comp.display_name not in _highlight_initial:
		return
	_highlight_contains = _switch_on_select
	_highlight_initial = ""
	_highlight_rect = Rect2()
	set_process(true)

func _on_tile_slot_selected(_is_trigger: bool) -> void:
	if _highlight_next == "":
		return
	_highlight_contains = _highlight_next
	_highlight_next = ""
	_highlight_rect = Rect2()
	set_process(true)

func show_step(step: Dictionary, step_index: int, total: int) -> void:
	_instruction.text = step["text"]
	_step_label.text = "步骤 %d / %d" % [step_index + 1, total]
	_block_input = step.get("block_outside_input", false)
	_confirm_click = step.get("confirm_to_advance", false)
	_highlight_node_path = step.get("highlight_node", "")
	_highlight_contains = step.get("highlight_contains", "")
	_highlight_contains_2 = step.get("highlight_contains_2", "")
	_highlight_initial = _highlight_contains
	_switch_on_select = step.get("switch_highlight_on_select", "")
	_highlight_next = step.get("highlight_next", "")
	_confirm_btn.hide()
	_hide_dark_panels()
	_center_text_box()
	visible = true
	_skip_btn.show()
	if _highlight_node_path == "" and _highlight_contains == "":
		return
	_highlight_rect = Rect2()
	set_process(true)

func show_complete() -> void:
	GameState.pause_for_panel()
	_paused_for_complete = true
	_block_input = false
	_confirm_click = false
	_highlight_rect = Rect2()
	_highlight_contains = ""
	_highlight_initial = ""
	_switch_on_select = ""
	_highlight_next = ""
	_highlight_node_path = ""
	set_process(false)
	var vp := get_viewport().get_visible_rect().size
	_top.visible = true
	_top.position = Vector2.ZERO
	_top.size = vp
	_bottom.visible = false
	_left.visible = false
	_right.visible = false
	_border.visible = false
	_skip_btn.hide()
	_instruction.text = "教程结束！\n返回主界面开始冒险吧"
	_step_label.hide()
	_text_box.reset_size()
	_text_box.position = Vector2(
		vp.x / 2.0 - _text_box.size.x / 2.0,
		vp.y / 2.0 - _text_box.size.y / 2.0 - 30.0
	)
	_confirm_btn.text = "开始冒险 →"
	_confirm_btn.show()
	_confirm_btn.position = Vector2(
		vp.x / 2.0 - 80.0,
		vp.y / 2.0 + _text_box.size.y / 2.0 - 10.0
	)
	visible = true

func hide_overlay() -> void:
	if _paused_for_complete:
		GameState.unpause_for_panel()
		_paused_for_complete = false
	visible = false
	set_process(false)
	_skip_btn.hide()
	_highlight_rect = Rect2()
	_highlight_contains = ""
	_highlight_contains_2 = ""
	_highlight_initial = ""
	_switch_on_select = ""
	_highlight_next = ""
	_confirm_click = false
	_block_input = false
	_step_label.show()

func _process(_delta: float) -> void:
	if _highlight_node_path == "" and _highlight_contains == "":
		set_process(false)
		return

	var target_rect := Rect2()
	var found := false

	if _highlight_contains != "":
		var ctrl := _find_by_text(_highlight_contains)
		if ctrl != null and ctrl.is_visible_in_tree():
			target_rect = ctrl.get_global_rect()
			found = true
	elif _highlight_node_path != "":
		var node = get_tree().current_scene.find_child(
			_highlight_node_path.trim_prefix("%"), true, false)
		if node != null:
			if node is Control:
				var c := node as Control
				if c.is_visible_in_tree():
					target_rect = c.get_global_rect()
					found = true
			elif node is Node2D:
				var n2d := node as Node2D
				var sp := get_viewport().get_canvas_transform() * n2d.global_position
				target_rect = Rect2(sp - Vector2(50, 50), Vector2(100, 100))
				found = true

	if not found:
		return

	if _highlight_contains_2 != "":
		var ctrl2 := _find_by_text(_highlight_contains_2)
		if ctrl2 != null and ctrl2.is_visible_in_tree():
			target_rect = target_rect.merge(ctrl2.get_global_rect())

	var rect := target_rect.grow(6.0)
	if rect == _highlight_rect:
		return
	_highlight_rect = rect
	_update_dark_panels(rect)
	_position_text_box(rect)
	if _highlight_contains == "":
		set_process(false)

func _find_by_text(search: String) -> Control:
	var nodes = get_tree().current_scene.find_children("*", "Control", true, false)
	var label_fallback: Control = null
	for n in nodes:
		var c := n as Control
		if not c.is_visible_in_tree():
			continue
		if not (c is Button or c is Label):
			continue
		var t = c.get("text")
		if not (t is String) or search not in (t as String):
			continue
		if c is Button:
			return c
		if label_fallback == null:
			label_fallback = c
	return label_fallback

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
	_text_box.reset_size()
	var bw := _text_box.size.x
	var bh := _text_box.size.y
	var y_below := hl.end.y + 12.0
	var y_above := hl.position.y - bh - 12.0
	var y: float
	if y_below + bh < vp.y:
		y = y_below
	elif y_above >= 4.0:
		y = y_above
	else:
		y = hl.position.y + 8.0
	var x := clampf(hl.position.x, 8.0, vp.x - bw - 8.0)
	_text_box.position = Vector2(x, y)

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if _paused_for_complete:
			GameState.unpause_for_panel()
			_paused_for_complete = false
		GameState.is_tutorial = false
		get_tree().change_scene_to_file("res://scenes/ui/loading_screen.tscn")
		get_viewport().set_input_as_handled()
		return
	# confirm-click: clicking inside the highlight advances an informational step
	if _confirm_click and _highlight_rect != Rect2():
		if event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
			if (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
				if _highlight_rect.has_point(event.position):
					EventBus.tutorial_info_confirmed.emit()
					get_viewport().set_input_as_handled()
					return
	if not _block_input:
		return
	if _highlight_rect == Rect2():
		return
	if event is InputEventMouseButton or event is InputEventMouseMotion:
		if not _highlight_rect.has_point(event.position):
			get_viewport().set_input_as_handled()

func _on_skip_pressed() -> void:
	if _pending_skip_dialog != null:
		return
	_pending_skip_dialog = ConfirmationDialog.new()
	_pending_skip_dialog.title = "跳过教程"
	_pending_skip_dialog.dialog_text = "确定跳过教程？\n跳过后将返回主菜单。"
	_pending_skip_dialog.ok_button_text = "跳过"
	_pending_skip_dialog.cancel_button_text = "继续教程"
	_pending_skip_dialog.confirmed.connect(_on_skip_confirmed)
	_pending_skip_dialog.canceled.connect(_on_skip_canceled)
	add_child(_pending_skip_dialog)
	_pending_skip_dialog.popup_centered()

func _on_skip_confirmed() -> void:
	_clear_skip_dialog()
	TutorialManager.skip()

func _on_skip_canceled() -> void:
	_clear_skip_dialog()

func _clear_skip_dialog() -> void:
	if _pending_skip_dialog != null:
		_pending_skip_dialog.queue_free()
		_pending_skip_dialog = null
