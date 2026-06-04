extends Control

const AuctionManager = preload("res://src/systems/AuctionManager.gd")

var _auction_manager = null

@onready var last_results_container: HBoxContainer = $VBox/LastSection/HBox
@onready var current_container: HBoxContainer = $VBox/CurrentSection/HBox
@onready var gold_label: Label = $VBox/Footer/GoldLabel
@onready var allocated_label: Label = $VBox/Footer/AllocatedLabel
@onready var lock_btn: Button = $VBox/Footer/LockBtn
@onready var title_label: Label = $VBox/TitleBar/TitleLabel

var _bid_inputs: Dictionary = {}

func setup(am) -> void:
	_auction_manager = am
	EventBus.auction_settled.connect(_on_settled)
	EventBus.gold_changed.connect(_refresh_footer)
	lock_btn.pressed.connect(_on_lock_pressed)
	hide()

func toggle() -> void:
	if visible:
		close()
	else:
		open()

func open() -> void:
	_refresh_last_results()
	_refresh_current()
	_refresh_footer(GameState.gold)
	GameState.pause_for_panel()
	show()

func close() -> void:
	GameState.unpause_for_panel()
	hide()

func _on_settled(_results: Array) -> void:
	if visible:
		_refresh_last_results()
		_refresh_current()

func _refresh_footer(_gold: int = -1) -> void:
	gold_label.text = "金币: %d" % GameState.gold
	var alloc := 0
	for svc in _bid_inputs:
		alloc += int(_bid_inputs[svc].value)
	allocated_label.text = "已分配: %dg" % alloc

func _on_lock_pressed() -> void:
	if _auction_manager == null:
		return
	for svc in _bid_inputs:
		_auction_manager.set_player_bid(svc, int(_bid_inputs[svc].value))
	close()

func _refresh_last_results() -> void:
	for c in last_results_container.get_children():
		c.queue_free()
	if _auction_manager == null or _auction_manager.last_results.is_empty():
		var lbl := Label.new()
		lbl.text = "（本局首圈，暂无记录）"
		last_results_container.add_child(lbl)
		return
	for r in _auction_manager.last_results:
		last_results_container.add_child(_make_result_card(r))

func _refresh_current() -> void:
	for c in current_container.get_children():
		c.queue_free()
	_bid_inputs = {}
	if _auction_manager == null or _auction_manager.current_services.is_empty():
		var lbl := Label.new()
		lbl.text = "（等待圈末刷新）"
		current_container.add_child(lbl)
		return
	for svc in _auction_manager.current_services:
		current_container.add_child(_make_bid_card(svc))

func _make_result_card(r: Dictionary) -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(120, 0)
	var vbox := VBoxContainer.new()
	panel.add_child(vbox)

	var name_lbl := Label.new()
	name_lbl.text = AuctionManager.SERVICE_NAMES.get(r["service_type"], "?")
	name_lbl.add_theme_font_size_override("font_size", 12)
	vbox.add_child(name_lbl)

	var winner_lbl := Label.new()
	winner_lbl.add_theme_font_size_override("font_size", 11)
	match r["winner"]:
		"player":
			winner_lbl.text = "✓ 你赢  %dg" % r["bids"]["player"]
		"phantom_a":
			winner_lbl.text = "✗ 影子甲赢\n你:%dg↩" % r["bids"]["player"]
		"phantom_b":
			winner_lbl.text = "✗ 影子乙赢\n你:%dg↩" % r["bids"]["player"]
		"none":
			winner_lbl.text = "— 无人竞价"
	vbox.add_child(winner_lbl)

	var bids_lbl := Label.new()
	bids_lbl.add_theme_font_size_override("font_size", 10)
	bids_lbl.text = "甲:%dg%s  乙:%dg%s" % [
		r["bids"]["phantom_a"],
		"↩" if r["winner"] != "phantom_a" else "✓",
		r["bids"]["phantom_b"],
		"↩" if r["winner"] != "phantom_b" else "✓",
	]
	vbox.add_child(bids_lbl)
	return panel

func _make_bid_card(svc: int) -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(120, 0)
	var vbox := VBoxContainer.new()
	panel.add_child(vbox)

	var name_lbl := Label.new()
	name_lbl.text = AuctionManager.SERVICE_NAMES.get(svc, "?")
	name_lbl.add_theme_font_size_override("font_size", 12)
	vbox.add_child(name_lbl)

	var desc_lbl := Label.new()
	desc_lbl.text = AuctionManager.SERVICE_DESCRIPTIONS.get(svc, "")
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc_lbl.add_theme_font_size_override("font_size", 10)
	vbox.add_child(desc_lbl)

	if _auction_manager != null:
		var int_labels: Array[String] = ["无", "低", "中", "高"]
		var ia_lbl := Label.new()
		ia_lbl.add_theme_font_size_override("font_size", 10)
		ia_lbl.text = "影子甲: %s" % int_labels[_auction_manager.phantom_a.interest(svc)]
		var ib_lbl := Label.new()
		ib_lbl.add_theme_font_size_override("font_size", 10)
		ib_lbl.text = "影子乙: %s" % int_labels[_auction_manager.phantom_b.interest(svc)]
		vbox.add_child(ia_lbl)
		vbox.add_child(ib_lbl)

	var spin := SpinBox.new()
	spin.min_value = 0
	spin.max_value = GameState.gold
	spin.step = 1
	spin.value_changed.connect(func(_v): _refresh_footer())
	_bid_inputs[svc] = spin
	vbox.add_child(spin)
	return panel
