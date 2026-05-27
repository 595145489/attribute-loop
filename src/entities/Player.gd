class_name Player
extends Node2D

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D

var _path_follow: PathFollow2D
var _walk_speed: float = 0.0
var _path_length: float = 0.0
var _prev_progress: float = 0.0

func _ready() -> void:
	_load_walk_animation()

func _load_walk_animation() -> void:
	var frames := SpriteFrames.new()
	frames.add_animation("walk")
	frames.set_animation_speed("walk", 8.0)
	frames.set_animation_loop("walk", true)
	for i in range(1, 29):
		var tex: Texture2D = load("res://resources/sprites/player/walk/frame_%04d.png" % i)
		frames.add_frame("walk", tex)
	_sprite.sprite_frames = frames
	_sprite.play("walk")

func setup(path_follow: PathFollow2D, path: Path2D) -> void:
	_path_follow = path_follow
	_walk_speed = DataTables.player.walk_speed
	_path_length = path.curve.get_baked_length()
	_prev_progress = 0.0

func _process(delta: float) -> void:
	if GameState.is_paused:
		_sprite.pause()
		return
	_sprite.play("walk")
	_path_follow.progress += _walk_speed * delta
	if _path_follow.progress < _prev_progress:
		GameState.loops_completed += 1
		EventBus.loop_completed.emit()
	_prev_progress = _path_follow.progress
