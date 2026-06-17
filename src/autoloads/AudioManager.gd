extends Node

enum State { PLAYING, SILENT }

var state: State = State.PLAYING

const BGM_PATH := "res://resources/audio/bgm/idle_1.mp3"
const DEFAULT_VOLUME_DB := -6.0
const SILENT_VOLUME_DB := -80.0
const FADE_DURATION := 1.0

var _player: AudioStreamPlayer
var _tween: Tween

func _ready() -> void:
	_player = AudioStreamPlayer.new()
	_player.volume_db = DEFAULT_VOLUME_DB
	_player.autoplay = false
	add_child(_player)

	EventBus.player_died.connect(_on_stop)
	EventBus.game_won.connect(_on_stop)

	if not OS.has_feature("headless"):
		_player.stream = load(BGM_PATH)
		_player.play()

	state = State.PLAYING

func _on_stop() -> void:
	state = State.SILENT
	if OS.has_feature("headless"):
		return
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(_player, "volume_db", SILENT_VOLUME_DB, FADE_DURATION)
	_tween.tween_callback(_player.stop)

func reset() -> void:
	state = State.PLAYING
	if OS.has_feature("headless"):
		return
	if _tween:
		_tween.kill()
	_player.volume_db = DEFAULT_VOLUME_DB
	if not _player.playing:
		_player.play()
