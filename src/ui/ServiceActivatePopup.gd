extends Control

const AuctionManager = preload("res://src/systems/AuctionManager.gd")

var _auction_manager = null
var _tiles: Array = []  # reserved — passed by caller for future enemy-pardon tile filtering
var _current_service: int = -1
var _current_bar_idx: int = -1
var _discard_mode: bool = false
var _discard_options: Array[int] = []
var _discard_new_svc: int = -1

# Colours
const COL_GOLD        := Color(0.941, 0.816, 0.502, 1.0)   # #f0d080
const COL_GOLD_MUTED  := Color(0.627, 0.471, 0.251, 1.0)   # #a07840
const COL_GOLD_DIM    := Color(0.784, 0.573, 0.227, 0.133) # #c8923a22
const COL_GOLD_BORDER := Color(0.784, 0.573, 0.227, 1.0)   # #c8923a
const COL_DARK        := Color(0.102, 0.063, 0.031, 1.0)   # #1a1008
const COL_DARK_ROW    := Color(0.051, 0.039, 0.016, 1.0)   # #0d0a04
const COL_WARN        := Color(0.784, 0.471, 0.220, 1.0)   # #c87838
const COL_GREEN       := Color(0.761, 0.851, 0.565, 1.0)   # #c2d990

@onready var title_label: Label      = $VBox/Header/Title
@onready var subtitle_label: Label   = $VBox/Header/Subtitle
@onready var content_container: VBoxContainer = $VBox/Scroll/Content
@onready var confirm_btn: Button     = $VBox/Buttons/Confirm
@onready var cancel_btn: Button      = $VBox/Buttons/Cancel

func setup(am, tiles: Array) -> void:
	_auction_manager = am
	_tiles = tiles
	confirm_btn.pressed.connect(_on_confirm)
	cancel_btn.pressed.connect(_on_cancel)
	hide()

func open(svc: int, bar_idx: int) -> void:
	_discard_mode = false
	_current_service = svc
	_current_bar_idx = bar_idx
	title_label.text = AuctionManager.SERVICE_NAMES.get(svc, "?")
	subtitle_label.text = AuctionManager.SERVICE_SUBTITLES.get(svc, "")
	cancel_btn.text = "取消"
	_set_warning_mode(false)
	_build_content(svc)
	GameState.pause_for_panel()
	show()

func open_discard(options: Array[int], new_svc: int, am) -> void:
	_discard_mode = true
	_discard_options = options
	_discard_new_svc = new_svc
	_auction_manager = am
	title_label.text = "服务栏已满"
	subtitle_label.text = "新赢得：%s · 选择一个放弃" % AuctionManager.SERVICE_NAMES.get(new_svc, "?")
	cancel_btn.text = "取消（放弃新的）"
	_set_warning_mode(true)
	_build_discard_content(options, new_svc)
	GameState.pause_for_panel()
	show()

func _set_warning_mode(warning: bool) -> void:
	var col := COL_WARN if warning else COL_GOLD
	confirm_btn.add_theme_color_override("font_color", col)

func _on_cancel() -> void:
	if _discard_mode and _auction_manager != null:
		_auction_manager._pending_overflow_service = -1
	GameState.unpause_for_panel()
	hide()

func _on_confirm() -> void:
	if _discard_mode:
		_apply_discard()
		return
	if _current_service < 0:
		return
	var params = _collect_params(_current_service)
	if params == null:
		return
	if _current_bar_idx >= 0 and _current_bar_idx < GameState.service_bar.size():
		GameState.service_bar.remove_at(_current_bar_idx)
	_auction_manager.execute_service(_current_service, params)
	GameState.unpause_for_panel()
	hide()

func _apply_discard() -> void:
	var discard_idx := -1
	var row_idx := 0
	for c in content_container.get_children():
		if c is PanelContainer:
			var btn: Button = c.get_node("HBox/Btn")
			if btn.button_pressed:
				discard_idx = row_idx
				break
			row_idx += 1
	if discard_idx < 0:
		return
	var discarded_svc: int = _discard_options[discard_idx]
	if discarded_svc != _discard_new_svc:
		if discard_idx < GameState.service_bar.size():
			GameState.service_bar.remove_at(discard_idx)
		GameState.service_bar.append(_discard_new_svc)
	if _auction_manager != null:
		_auction_manager._pending_overflow_service = -1
	EventBus.service_bar_changed.emit()
	GameState.unpause_for_panel()
	hide()

# ---------------------------------------------------------------------------
# Row builder
# Returns a PanelContainer with internal path HBox/Btn (toggle Button) and
# HBox/ValueLabel (right-aligned Label).
# comp_ref: optional metadata stored on the button (pass null if not needed).
# ---------------------------------------------------------------------------
func _make_row(left_text: String, value_text: String, value_after: String,
		grp, comp_ref, skip_value_toggle: bool = false) -> PanelContainer:
	var panel := PanelContainer.new()
	var style_normal := StyleBoxFlat.new()
	style_normal.bg_color = COL_DARK_ROW
	style_normal.border_color = Color(COL_GOLD_BORDER.r, COL_GOLD_BORDER.g,
			COL_GOLD_BORDER.b, 0.27)
	style_normal.set_border_width_all(1)
	style_normal.set_corner_radius_all(3)
	panel.add_theme_stylebox_override("panel", style_normal)
	panel.set_meta("style_normal", style_normal)

	var style_selected := StyleBoxFlat.new()
	style_selected.bg_color = COL_GOLD_DIM
	style_selected.border_color = COL_GOLD_BORDER
	style_selected.set_border_width_all(1)
	style_selected.set_corner_radius_all(3)
	panel.set_meta("style_selected", style_selected)

	var hbox := HBoxContainer.new()
	hbox.name = "HBox"
	hbox.add_theme_constant_override("separation", 6)
	panel.add_child(hbox)

	var btn := Button.new()
	btn.name = "Btn"
	btn.text = left_text
	btn.toggle_mode = true
	btn.flat = true
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.add_theme_color_override("font_color", COL_GOLD_MUTED)
	btn.add_theme_color_override("font_pressed_color", COL_GOLD)
	btn.add_theme_color_override("font_hover_color", COL_GOLD)
	if grp != null:
		btn.button_group = grp
	if comp_ref != null:
		btn.set_meta("comp_ref", comp_ref)
	hbox.add_child(btn)

	var val_lbl := Label.new()
	val_lbl.name = "ValueLabel"
	val_lbl.text = value_text
	val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	val_lbl.add_theme_color_override("font_color", COL_GOLD_MUTED)
	val_lbl.add_theme_font_size_override("font_size", 11)
	val_lbl.set_meta("value_text", value_text)
	val_lbl.set_meta("value_after", value_after)
	hbox.add_child(val_lbl)

	btn.toggled.connect(func(pressed: bool) -> void:
		if pressed:
			panel.add_theme_stylebox_override("panel", style_selected)
			if not skip_value_toggle:
				val_lbl.text = value_after if value_after != "" else value_text
				val_lbl.add_theme_color_override("font_color", COL_GREEN)
		else:
			panel.add_theme_stylebox_override("panel", style_normal)
			if not skip_value_toggle:
				val_lbl.text = value_text
				val_lbl.add_theme_color_override("font_color", COL_GOLD_MUTED)
		_refresh_confirm()
	)
	return panel

func _refresh_confirm() -> void:
	var valid := _collect_params(_current_service) != null if not _discard_mode else _has_discard_selection()
	confirm_btn.disabled = not valid

func _has_discard_selection() -> bool:
	for c in content_container.get_children():
		if c is PanelContainer:
			var btn: Button = c.get_node("HBox/Btn")
			if btn.button_pressed:
				return true
	return false

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
func _instant_types() -> Array:
	return [
		AuctionManager.ServiceType.PRESSURE_DELAY,
		AuctionManager.ServiceType.DELETE_PARDON,
		AuctionManager.ServiceType.STAT_DMG,
		AuctionManager.ServiceType.STAT_HP,
		AuctionManager.ServiceType.STAT_SPEED,
		AuctionManager.ServiceType.STAT_AMPLIFY,
		AuctionManager.ServiceType.SLOT_RULE,
		AuctionManager.ServiceType.SLOT_SERVICE,
	]

# ---------------------------------------------------------------------------
# Content builders
# ---------------------------------------------------------------------------
func _build_content(svc: int) -> void:
	for c in content_container.get_children():
		c.queue_free()

	if svc in _instant_types():
		_build_instant(svc)
		confirm_btn.text = "立即使用"
		confirm_btn.disabled = false
		return

	match svc:
		AuctionManager.ServiceType.COMP_REWRITE:
			_build_comp_list(false)
			confirm_btn.text = "改写"
			confirm_btn.disabled = true

		AuctionManager.ServiceType.COMP_MERGE:
			_build_comp_list(true)
			confirm_btn.text = "融合"
			confirm_btn.disabled = true

		AuctionManager.ServiceType.ENEMY_PARDON:
			_build_enemy_list()
			confirm_btn.text = "赦免"
			confirm_btn.disabled = true

func _build_instant(svc: int) -> void:
	var desc_lbl := Label.new()
	desc_lbl.text = AuctionManager.SERVICE_DESCRIPTIONS.get(svc, "")
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc_lbl.add_theme_color_override("font_color", COL_GOLD_MUTED)
	desc_lbl.add_theme_font_size_override("font_size", 12)
	content_container.add_child(desc_lbl)

	var flavour_lbl := Label.new()
	flavour_lbl.text = AuctionManager.SERVICE_FLAVOUR.get(svc, "")
	flavour_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	flavour_lbl.add_theme_color_override("font_color", Color(COL_GOLD_MUTED.r,
			COL_GOLD_MUTED.g, COL_GOLD_MUTED.b, 0.6))
	flavour_lbl.add_theme_font_size_override("font_size", 10)
	content_container.add_child(flavour_lbl)

func _build_comp_list(multi: bool) -> void:
	var desc_lbl := Label.new()
	desc_lbl.text = AuctionManager.SERVICE_DESCRIPTIONS.get(_current_service, "")
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc_lbl.add_theme_color_override("font_color", COL_GOLD_MUTED)
	desc_lbl.add_theme_font_size_override("font_size", 11)
	content_container.add_child(desc_lbl)

	var header_row := HBoxContainer.new()
	var left_h := Label.new()
	left_h.text = "词条名称"
	left_h.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_h.add_theme_color_override("font_color", Color(COL_GOLD_MUTED.r, COL_GOLD_MUTED.g, COL_GOLD_MUTED.b, 0.6))
	left_h.add_theme_font_size_override("font_size", 9)
	var right_h := Label.new()
	right_h.text = "当前 → 改写后" if not multi else "当前值"
	right_h.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	right_h.add_theme_color_override("font_color", Color(COL_GOLD_MUTED.r, COL_GOLD_MUTED.g, COL_GOLD_MUTED.b, 0.6))
	right_h.add_theme_font_size_override("font_size", 9)
	header_row.add_child(left_h)
	header_row.add_child(right_h)
	content_container.add_child(header_row)

	var grp := null if multi else ButtonGroup.new()
	var delta: float = DataTables.config.auction_comp_rewrite_delta

	var rows: Array = []
	for comp in GameState.inventory:
		var cur_val := "%.1f" % comp.effect_value
		var after_val: String
		if multi:
			after_val = ""
		else:
			after_val = "→ %.1f" % (comp.effect_value * (1.0 + delta))
		var row := _make_row(comp.display_name, cur_val, after_val, grp, comp, multi)
		content_container.add_child(row)
		rows.append(row)

	if multi:
		for row in rows:
			var btn: Button = row.get_node("HBox/Btn")
			btn.toggled.connect(func(_p: bool) -> void:
				_update_merge_labels(rows)
			)

func _update_merge_labels(rows: Array) -> void:
	var selected: Array = []
	for row in rows:
		var btn: Button = row.get_node("HBox/Btn")
		if btn.button_pressed and btn.has_meta("comp_ref"):
			selected.append({"row": row, "comp": btn.get_meta("comp_ref")})
	for row in rows:
		var val_lbl: Label = row.get_node("HBox/ValueLabel")
		var btn: Button = row.get_node("HBox/Btn")
		if selected.size() == 2:
			var a_val: float = selected[0]["comp"].effect_value
			var b_val: float = selected[1]["comp"].effect_value
			var merged: float = (a_val + b_val) * DataTables.config.auction_comp_merge_ratio
			if btn.button_pressed:
				val_lbl.text = "→ %.1f" % merged
			else:
				val_lbl.text = "%.1f" % btn.get_meta("comp_ref").effect_value if btn.has_meta("comp_ref") else ""
		else:
			if btn.has_meta("comp_ref"):
				val_lbl.text = "%.1f" % btn.get_meta("comp_ref").effect_value
	_refresh_confirm()

func _build_enemy_list() -> void:
	var desc_lbl := Label.new()
	desc_lbl.text = "下 3 次遭遇自动掉落，无需战斗"
	desc_lbl.add_theme_color_override("font_color", COL_GOLD_MUTED)
	desc_lbl.add_theme_font_size_override("font_size", 11)
	content_container.add_child(desc_lbl)

	var grp := ButtonGroup.new()
	for enemy_id in ["汲取者", "守卫者", "急袭者", "复制者", "先驱者"]:
		var row := _make_row(enemy_id, "", "", grp, null)
		content_container.add_child(row)

func _build_discard_content(options: Array[int], new_svc: int) -> void:
	for c in content_container.get_children():
		c.queue_free()

	var warn_lbl := Label.new()
	warn_lbl.text = "选择放弃哪一个服务（放弃后无法找回）"
	warn_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	warn_lbl.add_theme_color_override("font_color", COL_WARN)
	warn_lbl.add_theme_font_size_override("font_size", 11)
	content_container.add_child(warn_lbl)

	var grp := ButtonGroup.new()
	for i in options.size():
		var svc := options[i]
		var svc_name: String = AuctionManager.SERVICE_NAMES.get(svc, "?")
		var badge := " ★新" if svc == new_svc else ""
		var row := _make_row(svc_name + badge, "", "", grp, null)
		content_container.add_child(row)

	confirm_btn.text = "放弃选中"
	confirm_btn.disabled = true

# ---------------------------------------------------------------------------
# Param collection (unchanged logic, updated to read PanelContainer rows)
# ---------------------------------------------------------------------------
func _collect_params(svc: int):
	if svc in _instant_types():
		return {}

	match svc:
		AuctionManager.ServiceType.ENEMY_PARDON:
			for c in content_container.get_children():
				if c is PanelContainer:
					var btn: Button = c.get_node("HBox/Btn")
					if btn.button_pressed:
						return {"enemy_id": btn.text}
			return null

		AuctionManager.ServiceType.COMP_REWRITE:
			for c in content_container.get_children():
				if c is PanelContainer:
					var btn: Button = c.get_node("HBox/Btn")
					if btn.button_pressed and btn.has_meta("comp_ref"):
						return {"component": btn.get_meta("comp_ref"),
								"new_effect_delta": DataTables.config.auction_comp_rewrite_delta}
			return null

		AuctionManager.ServiceType.COMP_MERGE:
			var selected: Array = []
			for c in content_container.get_children():
				if c is PanelContainer:
					var btn: Button = c.get_node("HBox/Btn")
					if btn.button_pressed and btn.has_meta("comp_ref"):
						selected.append(btn.get_meta("comp_ref"))
			if selected.size() < 2:
				return null
			if selected[0].slot_type != selected[1].slot_type:
				return null
			return {"comp_a": selected[0], "comp_b": selected[1]}

	return {}
