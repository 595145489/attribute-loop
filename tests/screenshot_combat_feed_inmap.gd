extends Node

const OUT_FILE := "res://tests/screenshots/current_combat_feed_inmap.png"

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(
		ProjectSettings.globalize_path("res://tests/screenshots"))
	add_child(preload("res://scenes/main.tscn").instantiate())
	await get_tree().process_frame
	await get_tree().process_frame
	# Pump a few damage events so the feed shows live entries over the map.
	EventBus.player_attacked.emit(24)
	EventBus.player_hit.emit(8)
	EventBus.player_hit.emit(15)
	EventBus.rule_fired.emit(0, "灼烧伤害", 5.0)
	EventBus.combat_enrage.emit(3)
	await get_tree().process_frame
	await get_tree().process_frame
	var img := get_viewport().get_texture().get_image()
	img.save_png(ProjectSettings.globalize_path(OUT_FILE))
	print("Screenshot saved: ", OUT_FILE)
	get_tree().quit(0)
