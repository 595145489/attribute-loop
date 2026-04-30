extends Node

const LOG_PATH := "res://game.log"

var _file: FileAccess = null

func _ready() -> void:
	_file = FileAccess.open(LOG_PATH, FileAccess.WRITE)
	if _file:
		_write("=== Session Start " + Time.get_datetime_string_from_system() + " ===")

func info(msg: String, tag: String = "") -> void:
	_write("[INFO]" + (" [%s] " % tag if tag else " ") + msg)

func warn(msg: String, tag: String = "") -> void:
	_write("[WARN]" + (" [%s] " % tag if tag else " ") + msg)

func error(msg: String, tag: String = "") -> void:
	_write("[ERR] " + (" [%s] " % tag if tag else " ") + msg)

func _write(line: String) -> void:
	if _file == null:
		return
	_file.store_line(Time.get_time_string_from_system() + " " + line)
	_file.flush()

func _exit_tree() -> void:
	if _file:
		_write("=== Session End ===")
		_file.close()
		_file = null
