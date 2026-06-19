extends Node

const OUT_FILE := "res://tests/screenshots/current_loading_screen.png"

func _ready():
	DirAccess.make_dir_recursive_absolute(
		ProjectSettings.globalize_path("res://tests/screenshots"))
	var scene = preload("res://scenes/ui/loading_screen.tscn").instantiate()
	add_child(scene)
	await get_tree().process_frame
	scene.get_node("UI/StartButton").visible = true
	scene.get_node("UI/TutorialButton").visible = true
	scene.get_node("UI/Progress").hide()
	scene.get_node("UI/Status").hide()
	scene.get_node("ParticleLayer/Particles").start()
	await get_tree().process_frame
	await get_tree().process_frame
	var img := get_viewport().get_texture().get_image()
	img.save_png(ProjectSettings.globalize_path(OUT_FILE))
	get_tree().quit(0)
