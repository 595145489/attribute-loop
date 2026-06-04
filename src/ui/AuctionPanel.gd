extends Control

const AuctionManager = preload("res://src/systems/AuctionManager.gd")
const BidCardScene = preload("res://scenes/ui/components/auction_bid_card.tscn")
const ResultCardScene = preload("res://scenes/ui/components/auction_result_card.tscn")

var _auction_manager = null

@onready var last_results_container: HBoxContainer = $VBox/LastSection/HBox
@onready var current_container: HBoxContainer = $VBox/CurrentSection/HBox
@onready var gold_label: Label = $VBox/Footer/GoldLabel
@onready var allocated_label: Label = $VBox/Footer/AllocatedLabel
@onready var lock_btn: Button = $VBox/Footer/LockBtn
@onready var title_label: Label = $VBox/TitleBar/TitleLabel

var _bid_cards: Array = []

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
	_refresh_footer()
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
	for card in _bid_cards:
		alloc += card.get_bid()
	allocated_label.text = "已分配: %dg" % alloc

func _on_lock_pressed() -> void:
	if _auction_manager == null:
		return
	for card in _bid_cards:
		_auction_manager.set_player_bid(card.service_type, card.get_bid())
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
		var card = ResultCardScene.instantiate()
		last_results_container.add_child(card)
		card.setup(r)

func _refresh_current() -> void:
	for c in current_container.get_children():
		c.queue_free()
	_bid_cards = []
	if _auction_manager == null or _auction_manager.current_services.is_empty():
		var lbl := Label.new()
		lbl.text = "（等待圈末刷新）"
		current_container.add_child(lbl)
		return
	for svc in _auction_manager.current_services:
		var is_carried := _auction_manager.carried_over.has(svc)
		var card = BidCardScene.instantiate()
		current_container.add_child(card)
		card.setup(svc, _auction_manager, is_carried, _refresh_footer)
		_bid_cards.append(card)
