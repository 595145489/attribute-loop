extends Node

const OUT_FILE := "res://tests/screenshots/current_ui_skin.png"

func _ready():
	DirAccess.make_dir_recursive_absolute(
		ProjectSettings.globalize_path("res://tests/screenshots"))
	add_child(preload("res://scenes/ui/hud.tscn").instantiate())
	await get_tree().process_frame
	await get_tree().process_frame
	var img := get_viewport().get_texture().get_image()
	img.save_png(ProjectSettings.globalize_path(OUT_FILE))
	print("Screenshot saved: ", OUT_FILE)
	get_tree().quit(0)
