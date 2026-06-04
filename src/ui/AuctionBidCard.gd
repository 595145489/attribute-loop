extends PanelContainer

const AuctionManager = preload("res://src/systems/AuctionManager.gd")
const INTEREST_LABELS: Array[String] = ["无", "低", "中", "高"]

@onready var name_label: Label = $VBox/NameLabel
@onready var desc_label: Label = $VBox/DescLabel
@onready var interest_a_label: Label = $VBox/InterestRow/InterestA
@onready var interest_b_label: Label = $VBox/InterestRow/InterestB
@onready var bid_input: SpinBox = $VBox/BidInput
@onready var carried_badge: Label = $VBox/CarriedBadge

var service_type: int = -1
var _on_value_changed_cb: Callable

func setup(svc: int, am, is_carried: bool, on_value_changed: Callable) -> void:
	service_type = svc
	_on_value_changed_cb = on_value_changed

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
	bid_input.value = 0
	bid_input.value_changed.connect(_on_bid_changed)

func get_bid() -> int:
	return int(bid_input.value)

func _on_bid_changed(_v: float) -> void:
	bid_input.max_value = GameState.gold
	if _on_value_changed_cb.is_valid():
		_on_value_changed_cb.call()
