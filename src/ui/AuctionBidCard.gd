extends PanelContainer

const AuctionManager = preload("res://src/systems/AuctionManager.gd")
const INTEREST_LABELS: Array[String] = ["无", "低", "中", "高"]

@onready var name_label: Label = $VBox/NameLabel
@onready var desc_label: Label = $VBox/DescLabel
@onready var interest_a_label: Label = $VBox/InterestRow/InterestA
@onready var interest_b_label: Label = $VBox/InterestRow/InterestB
@onready var bid_input: SpinBox = $VBox/BidRow/BidInput
@onready var bid_btn: Button = $VBox/BidRow/BidBtn
@onready var all_in_btn: Button = $VBox/BidRow/AllInBtn
@onready var carried_badge: Label = $VBox/CarriedBadge

var service_type: int = -1
var _auction_manager = null

func setup(svc: int, am, is_carried: bool, initial_bid: int, _unused: Callable) -> void:
	service_type = svc
	_auction_manager = am

	name_label.text = AuctionManager.SERVICE_NAMES.get(svc, "?")
	desc_label.text = AuctionManager.SERVICE_DESCRIPTIONS.get(svc, "")
	carried_badge.visible = is_carried

	if am != null:
		var ia: int = am.phantom_a.interest(svc)
		var ib: int = am.phantom_b.interest(svc)
		interest_a_label.text = "影子甲: %s" % INTEREST_LABELS[ia]
		interest_b_label.text = "影子乙: %s" % INTEREST_LABELS[ib]
	else:
		interest_a_label.text = "影子甲: —"
		interest_b_label.text = "影子乙: —"

	bid_input.max_value = GameState.gold
	bid_input.value = initial_bid
	bid_btn.pressed.connect(_on_bid_pressed)
	all_in_btn.pressed.connect(_on_all_in_pressed)

	# If already locked (initial_bid > 0 and was pre-paid), restore locked state
	if _auction_manager != null and _auction_manager.player_bids_locked.get(svc, false):
		_set_locked(initial_bid)

func get_bid() -> int:
	return int(bid_input.value)

func _on_bid_pressed() -> void:
	var amount := int(bid_input.value)
	if amount <= 0:
		return
	if amount > GameState.gold:
		return
	# Deduct gold immediately
	GameState.gold -= amount
	EventBus.gold_changed.emit(GameState.gold)
	# Store bid in manager
	if _auction_manager != null:
		_auction_manager.set_player_bid(service_type, amount)
		_auction_manager.player_bids_locked[service_type] = true
	_set_locked(amount)

func _set_locked(amount: int) -> void:
	bid_input.editable = false
	bid_input.value = amount
	bid_btn.disabled = true
	all_in_btn.disabled = true
	bid_btn.text = "已出价 %dg" % amount

func _on_all_in_pressed() -> void:
	bid_input.value = GameState.gold
	_on_bid_pressed()
