extends Control

const AuctionManager = preload("res://src/systems/AuctionManager.gd")
const BidCardScene = preload("res://scenes/ui/components/auction_bid_card.tscn")
const ResultCardScene = preload("res://scenes/ui/components/auction_result_card.tscn")

var _auction_manager = null

@onready var last_results_container: HBoxContainer = $VBox/LastSection/HBox
@onready var current_container: HBoxContainer = $VBox/CurrentSection/HBox
@onready var gold_label: Label = $VBox/Footer/GoldLabel
@onready var close_btn: Button = $VBox/TitleBar/CloseBtn
@onready var phantom_a_label: Label = $VBox/Footer/PhantomALabel
@onready var phantom_b_label: Label = $VBox/Footer/PhantomBLabel

var _bid_cards: Array = []

func setup(am) -> void:
	_auction_manager = am
	EventBus.auction_settled.connect(_on_settled)
	EventBus.gold_changed.connect(_refresh_footer)
	close_btn.pressed.connect(close)
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
	if _auction_manager != null:
		var pa_gold: int = _auction_manager.phantom_a.gold
		var pb_gold: int = _auction_manager.phantom_b.gold
		phantom_a_label.text = "影子甲: %dg%s" % [pa_gold, " ⚠" if pa_gold >= 180 else ""]
		phantom_b_label.text = "影子乙: %dg%s" % [pb_gold, " ⚠" if pb_gold >= 180 else ""]

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
		var is_carried: bool = _auction_manager.carried_over.has(svc)
		var saved_bid: int = _auction_manager.player_bids.get(svc, 0)
		var card = BidCardScene.instantiate()
		current_container.add_child(card)
		card.setup(svc, _auction_manager, is_carried, saved_bid, Callable())
		_bid_cards.append(card)
