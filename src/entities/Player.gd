class_name Player
extends Node2D

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D

var _path_follow: PathFollow2D
var _walk_speed: float = 0.0
var _path_length: float = 0.0
var _prev_progress: float = 0.0
var _in_combat: bool = false

func _ready() -> void:
	_load_animations()

func _load_animations() -> void:
	var frames := SpriteFrames.new()

	frames.add_animation("walk")
	frames.set_animation_speed("walk", 8.0)
	frames.set_animation_loop("walk", true)
	for i in range(1, 29):
		frames.add_frame("walk", load("res://resources/sprites/player/walk/frame_%04d.png" % i))

	frames.add_animation("idle")
	frames.set_animation_speed("idle", 8.0)
	frames.set_animation_loop("idle", true)
	for i in range(1, 17):
		frames.add_frame("idle", load("res://resources/sprites/player/idle/frame_%04d.png" % i))

	_sprite.sprite_frames = frames
	_sprite.play("walk")

func setup(path_follow: PathFollow2D, path: Path2D) -> void:
	_path_follow = path_follow
	_walk_speed = DataTables.player.walk_speed
	_path_length = path.curve.get_baked_length()
	_prev_progress = 0.0

func enter_combat() -> void:
	_in_combat = true
	_sprite.play("idle")

func exit_combat() -> void:
	_in_combat = false
	_sprite.play("walk")

func _process(delta: float) -> void:
	if GameState.is_paused:
		if _in_combat:
			_sprite.play("idle")
		else:
			_sprite.pause()
		return
	if _in_combat:
		_sprite.play("idle")
		return
	_sprite.play("walk")
	var prev_x := _path_follow.global_position.x
	_path_follow.progress += _walk_speed * delta
	var dx := _path_follow.global_position.x - prev_x
	if abs(dx) > 0.01:
		_sprite.flip_h = dx < 0
	if _path_follow.progress < _prev_progress:
		GameState.loops_completed += 1
		EventBus.loop_completed.emit()
	_prev_progress = _path_follow.progress
