extends Node

const OUT_FILE := "res://tests/screenshots/current_combat_feed.png"

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(
		ProjectSettings.globalize_path("res://tests/screenshots"))
	var feed = preload("res://scenes/ui/combat_feed.tscn").instantiate()
	add_child(feed)
	await get_tree().process_frame
	await get_tree().process_frame
	# Emit a small spread of damage events; capture before any fade completes.
	feed._on_player_attacked(24)
	feed._on_player_hit(8)
	feed._on_rule_fired(0, "灼烧伤害", 5.0)
	feed._on_combat_enrage(3)
	await get_tree().process_frame
	await get_tree().process_frame
	var img := get_viewport().get_texture().get_image()
	img.save_png(ProjectSettings.globalize_path(OUT_FILE))
	print("Screenshot saved: ", OUT_FILE)
	get_tree().quit(0)
