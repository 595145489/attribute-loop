extends Node

const SENTINEL := "res://tests/.test_mode"
const SCREENSHOT_PATH := "res://tests/screenshots/last_run.png"
const LOG_PATH := "res://tests/screenshots/last_run.log"
const WAIT_SECONDS := 25.0

func _ready() -> void:
	if not FileAccess.file_exists(SENTINEL):
		return
	await get_tree().create_timer(WAIT_SECONDS, true, false, true).timeout
	_capture_and_quit()

func _capture_and_quit() -> void:
	var image := get_viewport().get_texture().get_image()
	image.save_png(SCREENSHOT_PATH)

	var log_file := FileAccess.open(LOG_PATH, FileAccess.WRITE)
	if log_file:
		log_file.store_line("screenshot saved: %s" % SCREENSHOT_PATH)
		log_file.store_line("time: %s" % Time.get_datetime_string_from_system())
		log_file.close()

	get_tree().quit()
