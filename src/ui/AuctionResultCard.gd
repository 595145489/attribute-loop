extends PanelContainer

const AuctionManager = preload("res://src/systems/AuctionManager.gd")

@onready var name_label: Label = $VBox/NameLabel
@onready var winner_label: Label = $VBox/WinnerLabel
@onready var bids_label: Label = $VBox/BidsLabel

func setup(result: Dictionary) -> void:
	var svc: int = result["service_type"]
	name_label.text = AuctionManager.SERVICE_NAMES.get(svc, "?")

	var pb: int = result["bids"]["player"]
	var ab: int = result["bids"]["phantom_a"]
	var bb: int = result["bids"]["phantom_b"]

	match result["winner"]:
		"player":
			winner_label.text = "✓ 你赢了  %dg" % pb
			winner_label.add_theme_color_override("font_color", Color(0.1, 0.4, 0.1))
		"phantom_a":
			winner_label.text = "✗ 影子甲赢"
			winner_label.add_theme_color_override("font_color", Color(0.5, 0.08, 0.08))
		"phantom_b":
			winner_label.text = "✗ 影子乙赢"
			winner_label.add_theme_color_override("font_color", Color(0.5, 0.08, 0.08))
		"none":
			winner_label.text = "— 无人竞价"
			winner_label.add_theme_color_override("font_color", Color(0.4, 0.35, 0.25))

	var w: String = result["winner"]
	bids_label.text = "你:%dg%s  甲:%dg%s  乙:%dg%s" % [
		pb, "" if w == "player" else "↩",
		ab, "✓" if w == "phantom_a" else "↩",
		bb, "✓" if w == "phantom_b" else "↩",
	]
