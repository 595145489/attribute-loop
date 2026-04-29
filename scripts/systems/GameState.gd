class_name GameState
extends Node

enum State { RUNNING, PAUSED }

signal state_changed(new_state: State)

var current: State = State.RUNNING

func pause() -> void:
	if current == State.RUNNING:
		current = State.PAUSED
		get_tree().paused = true
		state_changed.emit(current)

func resume() -> void:
	if current == State.PAUSED:
		current = State.RUNNING
		get_tree().paused = false
		state_changed.emit(current)

func toggle() -> void:
	if current == State.RUNNING:
		pause()
	else:
		resume()
