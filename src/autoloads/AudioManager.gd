extends Node

enum State { EXPLORE, COMBAT, SILENT }

var state: State = State.EXPLORE

const EXPLORE_PATHS := [
	"res://resources/audio/bgm/explore_1.mp3",
	"res://resources/audio/bgm/explore_2.mp3",
]
const COMBAT_PATHS := [
	"res://resources/audio/bgm/combat_1.mp3",
	"res://resources/audio/bgm/combat_2.mp3",
]

const DEFAULT_VOLUME_DB := -6.0
const SILENT_VOLUME_DB := -80.0
const FADE_DURATION := 1.0

var _explore_player: AudioStreamPlayer
var _combat_player: AudioStreamPlayer
var _tween: Tween

func _ready() -> void:
	_explore_player = AudioStreamPlayer.new()
	_explore_player.volume_db = DEFAULT_VOLUME_DB
	_explore_player.autoplay = false
	add_child(_explore_player)

	_combat_player = AudioStreamPlayer.new()
	_combat_player.volume_db = SILENT_VOLUME_DB
	_combat_player.autoplay = false
	add_child(_combat_player)

	EventBus.player_hit.connect(_on_player_hit)
	EventBus.combat_resolved.connect(_on_combat_resolved)
	EventBus.player_died.connect(_on_player_died)
	EventBus.game_won.connect(_on_game_won)

	if not OS.has_feature("headless"):
		var explore_stream = load(EXPLORE_PATHS[randi() % EXPLORE_PATHS.size()])
		var combat_stream = load(COMBAT_PATHS[randi() % COMBAT_PATHS.size()])
		_explore_player.stream = explore_stream
		_combat_player.stream = combat_stream
		_explore_player.play()

	state = State.EXPLORE

func _on_player_hit(_damage: int) -> void:
	if state != State.EXPLORE:
		return
	state = State.COMBAT
	_crossfade(_explore_player, _combat_player)

func _on_combat_resolved() -> void:
	if state != State.COMBAT:
		return
	state = State.EXPLORE
	_crossfade(_combat_player, _explore_player)

func _on_player_died() -> void:
	state = State.SILENT
	_fade_out_all()

func _on_game_won() -> void:
	state = State.SILENT
	_fade_out_all()

func _crossfade(from: AudioStreamPlayer, to: AudioStreamPlayer) -> void:
	if OS.has_feature("headless"):
		return
	if not to.playing:
		to.play()
	if _tween:
		_tween.kill()
	_tween = create_tween().set_parallel(true)
	_tween.tween_property(from, "volume_db", SILENT_VOLUME_DB, FADE_DURATION)
	_tween.tween_property(to, "volume_db", DEFAULT_VOLUME_DB, FADE_DURATION)
	_tween.chain().tween_callback(from.stop)

func _fade_out_all() -> void:
	if OS.has_feature("headless"):
		return
	if _tween:
		_tween.kill()
	_tween = create_tween().set_parallel(true)
	_tween.tween_property(_explore_player, "volume_db", SILENT_VOLUME_DB, FADE_DURATION)
	_tween.tween_property(_combat_player, "volume_db", SILENT_VOLUME_DB, FADE_DURATION)
	var seq := _tween.chain()
	seq.tween_callback(_explore_player.stop)
	seq.tween_callback(_combat_player.stop)

func reset() -> void:
	state = State.EXPLORE
	if OS.has_feature("headless"):
		return
	if _tween:
		_tween.kill()
	_explore_player.volume_db = DEFAULT_VOLUME_DB
	_combat_player.volume_db = SILENT_VOLUME_DB
	if not _explore_player.playing:
		_explore_player.play()
