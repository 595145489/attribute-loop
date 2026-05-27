extends Node

const OUT_DIR := "res://tests/screenshots"
const OUT_FILE := "res://tests/screenshots/last_run.png"

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	add_child(preload("res://scenes/main.tscn").instantiate())
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	var img := get_viewport().get_texture().get_image()
	img.save_png(ProjectSettings.globalize_path(OUT_FILE))
	print("Screenshot saved")
	get_tree().quit(0)
