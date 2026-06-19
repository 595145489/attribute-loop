extends Node

const OUT_DIR := "res://tests/screenshots"
const OUT_FILE := "res://tests/screenshots/current_enemy_hp.png"

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	var enemy: Enemy = preload("res://scenes/entities/enemy.tscn").instantiate()
	add_child(enemy)
	enemy.position = Vector2(200, 150)
	enemy.init("汲取者", 1)
	enemy.take_damage(int(enemy.hp_max * 0.4))
	await get_tree().process_frame
	await get_tree().process_frame
	var img := get_viewport().get_texture().get_image()
	img.save_png(ProjectSettings.globalize_path(OUT_FILE))
	print("Screenshot saved: " + OUT_FILE)
	get_tree().quit(0)
