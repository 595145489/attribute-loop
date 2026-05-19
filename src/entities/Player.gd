class_name Player
extends Node2D

var _path_follow: PathFollow2D
var _walk_speed: float = 0.0
var _path_length: float = 0.0
var _loop_count: int = 0

func setup(path_follow: PathFollow2D, path: Path2D) -> void:
	_path_follow = path_follow
	_walk_speed = DataTables.player.walk_speed
	_path_length = path.curve.get_baked_length()

func _process(delta: float) -> void:
	if GameState.is_paused:
		return
	_path_follow.progress += _walk_speed * delta
	var new_loop = int(_path_follow.progress / _path_length)
	if new_loop > _loop_count:
		_loop_count = new_loop
		GameState.loops_completed += 1
		EventBus.loop_completed.emit()
