extends GutTest

func before_each() -> void:
	AudioManager.state = AudioManager.State.PLAYING

func test_audio_manager_exists() -> void:
	assert_true(AudioManager != null, "AudioManager autoload should exist")

func test_initial_state_is_playing() -> void:
	assert_eq(AudioManager.state, AudioManager.State.PLAYING,
		"AudioManager should start in PLAYING state")

func test_player_died_transitions_to_silent() -> void:
	AudioManager.state = AudioManager.State.PLAYING
	EventBus.player_died.emit()
	assert_eq(AudioManager.state, AudioManager.State.SILENT,
		"player_died should transition to SILENT")

func test_game_won_transitions_to_silent() -> void:
	AudioManager.state = AudioManager.State.PLAYING
	EventBus.game_won.emit()
	assert_eq(AudioManager.state, AudioManager.State.SILENT,
		"game_won should transition to SILENT")
