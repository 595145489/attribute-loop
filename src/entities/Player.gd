class_name Player
extends Node2D

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D

var _path_follow: PathFollow2D
var _walk_speed: float = 0.0
var _path_length: float = 0.0
var _prev_progress: float = 0.0
var _in_combat: bool = false

static var _frames_cache: SpriteFrames = null

func _ready() -> void:
	_load_animations()

static func preload_async(tree: SceneTree, on_progress: Callable = Callable()) -> void:
	if _frames_cache != null:
		if on_progress.is_valid():
			on_progress.call(1.0, "玩家")
		return
	var frames := SpriteFrames.new()
	_load_anim(frames, "res://resources/sprites/player/walk/", "walk", true)
	_load_anim(frames, "res://resources/sprites/player/idle/", "idle", true)
	_frames_cache = frames
	await tree.process_frame
	if on_progress.is_valid():
		on_progress.call(1.0, "玩家")

static func _load_anim(frames: SpriteFrames, path: String, anim: String, loop: bool) -> void:
	if not ResourceLoader.exists(path + "frame_0001.png"):
		return
	frames.add_animation(anim)
	frames.set_animation_speed(anim, 8.0)
	frames.set_animation_loop(anim, loop)
	var i := 1
	while true:
		var file := path + "frame_%04d.png" % i
		if not ResourceLoader.exists(file):
			break
		frames.add_frame(anim, load(file))
		i += 1

func _load_animations() -> void:
	if _frames_cache != null:
		_sprite.sprite_frames = _frames_cache
		_sprite.play("walk")
		return
	var frames := SpriteFrames.new()
	_load_anim(frames, "res://resources/sprites/player/walk/", "walk", true)
	_load_anim(frames, "res://resources/sprites/player/idle/", "idle", true)
	_frames_cache = frames
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
	if _path_follow == null:
		return
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
	var prev_pos := _path_follow.global_position
	_path_follow.progress += _walk_speed * delta
	var delta_pos := _path_follow.global_position - prev_pos
	if delta_pos.length() > 0.01:
		if abs(delta_pos.y) > abs(delta_pos.x):
			_sprite.flip_h = delta_pos.y < 0
		else:
			_sprite.flip_h = delta_pos.x > 0
	if _path_follow.progress < _prev_progress:
		GameState.loops_completed += 1
		EventBus.loop_completed.emit()
	_prev_progress = _path_follow.progress
