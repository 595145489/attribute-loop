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

	var player_mark := "✓" if w == "player" else ("↩" if pb > 0 else "—")
	var a_mark := "✓" if w == "phantom_a" else ("↩" if ab > 0 else "—")
	var b_mark := "✓" if w == "phantom_b" else ("↩" if bb > 0 else "—")

	# Sort 3 entries by amount descending (manual bubble)
	var names: Array[String] = ["你", "甲", "乙"]
	var amounts: Array[int] = [pb, ab, bb]
	var marks: Array[String] = [player_mark, a_mark, b_mark]
	for pass_n in 2:
		for j in 2:
			if amounts[j] < amounts[j + 1]:
				var tmp_n: String = names[j]; names[j] = names[j + 1]; names[j + 1] = tmp_n
				var tmp_a: int = amounts[j]; amounts[j] = amounts[j + 1]; amounts[j + 1] = tmp_a
				var tmp_m: String = marks[j]; marks[j] = marks[j + 1]; marks[j + 1] = tmp_m

	bids_label.text = "%s: %dg %s\n%s: %dg %s\n%s: %dg %s" % [
		names[0], amounts[0], marks[0],
		names[1], amounts[1], marks[1],
		names[2], amounts[2], marks[2],
	]
