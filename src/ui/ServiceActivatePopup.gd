extends Control

const AuctionManager = preload("res://src/systems/AuctionManager.gd")

var _auction_manager = null
var _tiles: Array = []
var _current_service: int = -1
var _current_bar_idx: int = -1
var _discard_mode: bool = false
var _discard_options: Array[int] = []
var _discard_new_svc: int = -1

@onready var title_label: Label = $Panel/VBox/Title
@onready var content_container: VBoxContainer = $Panel/VBox/Content
@onready var confirm_btn: Button = $Panel/VBox/Buttons/Confirm
@onready var cancel_btn: Button = $Panel/VBox/Buttons/Cancel

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
	_build_content(svc)
	GameState.pause_for_panel()
	show()

func open_discard(options: Array[int], new_svc: int, am) -> void:
	_discard_mode = true
	_discard_options = options
	_discard_new_svc = new_svc
	_auction_manager = am
	title_label.text = "服务栏已满，选择一个放弃"
	_build_discard_content(options, new_svc)
	GameState.pause_for_panel()
	show()

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
	for i in content_container.get_children().size():
		var c := content_container.get_children()[i]
		if c is Button and c.button_pressed:
			discard_idx = i
			break
	if discard_idx < 0:
		return
	var discarded_svc: int = _discard_options[discard_idx]
	if discarded_svc != _discard_new_svc:
		# discarded an existing one; add the new service
		if discard_idx < GameState.service_bar.size():
			GameState.service_bar.remove_at(discard_idx)
		GameState.service_bar.append(_discard_new_svc)
	# else: discarded the new one, keep existing bar unchanged
	if _auction_manager != null:
		_auction_manager._pending_overflow_service = -1
	EventBus.service_bar_changed.emit()
	GameState.unpause_for_panel()
	hide()

func _build_content(svc: int) -> void:
	for c in content_container.get_children():
		c.queue_free()
	match svc:
		AuctionManager.ServiceType.PRESSURE_DELAY, AuctionManager.ServiceType.DELETE_PARDON:
			var lbl := Label.new()
			lbl.text = AuctionManager.SERVICE_DESCRIPTIONS.get(svc, "")
			lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
			content_container.add_child(lbl)

		AuctionManager.ServiceType.ENEMY_PARDON:
			var lbl := Label.new()
			lbl.text = "选择赦免的敌人类型："
			content_container.add_child(lbl)
			var grp := ButtonGroup.new()
			for enemy_id in ["汲取者", "守卫者", "急袭者", "复制者", "先驱者"]:
				var btn := Button.new()
				btn.text = enemy_id
				btn.toggle_mode = true
				btn.button_group = grp
				content_container.add_child(btn)

		AuctionManager.ServiceType.COMP_REWRITE:
			var lbl := Label.new()
			lbl.text = "选择要改写的词条（效果值 +20%）："
			content_container.add_child(lbl)
			var grp := ButtonGroup.new()
			for comp in GameState.inventory:
				var btn := Button.new()
				btn.text = "%s (%.1f)" % [comp.display_name, comp.effect_value]
				btn.toggle_mode = true
				btn.button_group = grp
				btn.set_meta("comp_ref", comp)
				content_container.add_child(btn)

		AuctionManager.ServiceType.COMP_MERGE:
			var lbl := Label.new()
			lbl.text = "选择两个同类词条合并（总和×0.8）："
			content_container.add_child(lbl)
			for comp in GameState.inventory:
				var btn := Button.new()
				btn.text = "%s (%.1f)" % [comp.display_name, comp.effect_value]
				btn.toggle_mode = true
				btn.set_meta("comp_ref", comp)
				content_container.add_child(btn)

func _build_discard_content(options: Array[int], new_svc: int) -> void:
	for c in content_container.get_children():
		c.queue_free()
	var grp := ButtonGroup.new()
	for i in options.size():
		var svc := options[i]
		var btn := Button.new()
		var label: String = AuctionManager.SERVICE_NAMES.get(svc, "?")
		if svc == new_svc:
			label += " (新赢得)"
		btn.text = label
		btn.toggle_mode = true
		btn.button_group = grp
		content_container.add_child(btn)

func _collect_params(svc: int):
	match svc:
		AuctionManager.ServiceType.PRESSURE_DELAY, AuctionManager.ServiceType.DELETE_PARDON:
			return {}

		AuctionManager.ServiceType.ENEMY_PARDON:
			for c in content_container.get_children():
				if c is Button and c.button_pressed:
					return {"enemy_id": c.text}
			return null

		AuctionManager.ServiceType.COMP_REWRITE:
			for c in content_container.get_children():
				if c is Button and c.button_pressed and c.has_meta("comp_ref"):
					return {"component": c.get_meta("comp_ref"), "new_effect_delta": DataTables.config.auction_comp_rewrite_delta}
			return null

		AuctionManager.ServiceType.COMP_MERGE:
			var selected: Array = []
			for c in content_container.get_children():
				if c is Button and c.button_pressed and c.has_meta("comp_ref"):
					selected.append(c.get_meta("comp_ref"))
			if selected.size() < 2:
				return null
			if selected[0].slot_type != selected[1].slot_type:
				return null
			return {"comp_a": selected[0], "comp_b": selected[1]}

	return {}
