class_name Player
extends Node2D

var _path_follow: PathFollow2D
var _walk_speed: float = 0.0
var _path_length: float = 0.0
var _prev_progress: float = 0.0

func setup(path_follow: PathFollow2D, path: Path2D) -> void:
	_path_follow = path_follow
	_walk_speed = DataTables.player.walk_speed
	_path_length = path.curve.get_baked_length()
	_prev_progress = 0.0

func _process(delta: float) -> void:
	if GameState.is_paused:
		return
	_path_follow.progress += _walk_speed * delta
	if _path_follow.progress < _prev_progress:
		GameState.loops_completed += 1
		EventBus.loop_completed.emit()
	_prev_progress = _path_follow.progress