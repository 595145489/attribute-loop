extends Node

const OUT_FILE := "res://tests/screenshots/current_strip_panel.png"

func _ready():
	DirAccess.make_dir_recursive_absolute(
		ProjectSettings.globalize_path("res://tests/screenshots"))

	var bg := ColorRect.new()
	bg.color = Color(0.82, 0.72, 0.52, 1.0)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var panel = preload("res://scenes/ui/strip_panel.tscn").instantiate()
	add_child(panel)
	panel.show()

	var card_scene = preload("res://scenes/ui/components/strip_card.tscn")
	var grid = panel.get_node("VBox/ComponentScroll/ComponentGrid")
	for i in 3:
		var card = card_scene.instantiate()
		card.get_node("VBox/InfoRow/Label").text = ["受击·治愈 (T:3/E:1.5)", "击杀·反射 (T:1/E:0.5)", "经过·加速 (T:5/E:2.0)"][i]
		grid.add_child(card)

	await get_tree().process_frame
	await get_tree().process_frame

	var img := get_viewport().get_texture().get_image()
	img.save_png(ProjectSettings.globalize_path(OUT_FILE))
	print("Screenshot saved: ", OUT_FILE)
	get_tree().quit(0)
