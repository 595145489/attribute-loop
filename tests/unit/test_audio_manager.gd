extends GutTest

func before_each() -> void:
	AudioManager.state = AudioManager.State.EXPLORE

func test_audio_manager_exists() -> void:
	assert_true(AudioManager != null, "AudioManager autoload should exist")

func test_initial_state_is_explore() -> void:
	assert_eq(AudioManager.state, AudioManager.State.EXPLORE,
		"AudioManager should start in EXPLORE state")

func test_player_hit_transitions_to_combat() -> void:
	AudioManager.state = AudioManager.State.EXPLORE
	EventBus.player_hit.emit(10)
	assert_eq(AudioManager.state, AudioManager.State.COMBAT,
		"player_hit should transition to COMBAT")

func test_combat_resolved_transitions_to_explore() -> void:
	AudioManager.state = AudioManager.State.COMBAT
	EventBus.combat_resolved.emit()
	assert_eq(AudioManager.state, AudioManager.State.EXPLORE,
		"combat_resolved should transition to EXPLORE")

func test_player_died_transitions_to_silent() -> void:
	AudioManager.state = AudioManager.State.EXPLORE
	EventBus.player_died.emit()
	assert_eq(AudioManager.state, AudioManager.State.SILENT,
		"player_died should transition to SILENT")

func test_game_won_transitions_to_silent() -> void:
	AudioManager.state = AudioManager.State.EXPLORE
	EventBus.game_won.emit()
	assert_eq(AudioManager.state, AudioManager.State.SILENT,
		"game_won should transition to SILENT")
