extends Node

const OUT_FILE := "res://tests/screenshots/current_log_panel.png"

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(
		ProjectSettings.globalize_path("res://tests/screenshots"))
	var panel = preload("res://scenes/ui/log_panel.tscn").instantiate()
	add_child(panel)
	panel.show()
	panel.offset_left = -280.0
	await get_tree().process_frame
	await get_tree().process_frame
	var img := get_viewport().get_texture().get_image()
	img.save_png(ProjectSettings.globalize_path(OUT_FILE))
	print("Screenshot saved: ", OUT_FILE)
	get_tree().quit(0)
