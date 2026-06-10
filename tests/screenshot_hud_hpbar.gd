extends Node

const OUT_FILE := "res://tests/screenshots/current_hud_hpbar.png"

func _ready():
	DirAccess.make_dir_recursive_absolute(
		ProjectSettings.globalize_path("res://tests/screenshots"))
	var hud_scene = preload("res://scenes/ui/hud.tscn").instantiate()
	add_child(hud_scene)
	await get_tree().process_frame
	await get_tree().process_frame
	var img := get_viewport().get_texture().get_image()
	img.save_png(ProjectSettings.globalize_path(OUT_FILE))
	get_tree().quit(0)
