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
	var w: String = result["winner"]

	match w:
		"player":
			winner_label.text = "✓ 你赢了"
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

	# Build sorted bid list (high → low)
	var entries: Array = [
		{"name": "你", "amount": pb, "mark": "✓" if w == "player" else ("↩" if pb > 0 else "—")},
		{"name": "甲", "amount": ab, "mark": "✓" if w == "phantom_a" else ("↩" if ab > 0 else "—")},
		{"name": "乙", "amount": bb, "mark": "✓" if w == "phantom_b" else ("↩" if bb > 0 else "—")},
	]
	entries.sort_custom(func(a, b): return a["amount"] > b["amount"])

	var lines: Array = []
	for e in entries:
		lines.append("%s: %dg %s" % [e["name"], e["amount"], e["mark"]])
	bids_label.text = "\n".join(lines)
