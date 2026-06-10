extends Node

const OUT_FILE := "res://tests/screenshots/current_components_preview.png"

func _ready():
	DirAccess.make_dir_recursive_absolute(
		ProjectSettings.globalize_path("res://tests/screenshots"))

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 16)
	add_child(vbox)

	var label1 := Label.new()
	label1.text = "slot_button:"
	vbox.add_child(label1)

	var slot := preload("res://scenes/ui/components/slot_button.tscn").instantiate()
	vbox.add_child(slot)

	var label2 := Label.new()
	label2.text = "strip_card:"
	vbox.add_child(label2)

	var card := preload("res://scenes/ui/components/strip_card.tscn").instantiate()
	vbox.add_child(card)

	await get_tree().process_frame
	await get_tree().process_frame

	var img := get_viewport().get_texture().get_image()
	img.save_png(ProjectSettings.globalize_path(OUT_FILE))
	print("Screenshot saved: ", OUT_FILE)
	get_tree().quit(0)
