extends Node

var is_active: bool = false
var current_step: int = 0

var _steps: Array = []
var _overlay: TutorialOverlay = null
var _completion_callable: Callable

func _ready() -> void:
	_steps = TutorialSteps.get_steps()

func get_step_count() -> int:
	return _steps.size()

func start(overlay: TutorialOverlay) -> void:
	_overlay = overlay
	is_active = true
	current_step = 0
	_setup_scenario()
	_overlay.confirm_pressed.connect(_on_confirm_pressed)
	_enter_step(0)

func stop() -> void:
	if not is_active:
		return
	is_active = false
	if _overlay != null:
		_overlay.hide_overlay()
	GameState.is_tutorial = false

func _setup_scenario() -> void:
	GameState.gold = 150
	call_deferred("_deferred_scenario_setup")

func _deferred_scenario_setup() -> void:
	EventBus.tutorial_spawn_enemies.emit()
	EventBus.tutorial_setup_altar.emit()

func _enter_step(index: int) -> void:
	current_step = index
	if index >= _steps.size():
		_overlay.show_complete()
		return

	var step: Dictionary = _steps[index]

	if step["id"] == "complete":
		_overlay.show_complete()
		return

	_overlay.show_step(step, index, _steps.size())

	var sig_name: String = step["complete_signal"]
	if sig_name == "":
		return

	_completion_callable = func(_a = null, _b = null, _c = null): _advance()
	EventBus.connect(sig_name, _completion_callable, CONNECT_ONE_SHOT)

func _advance() -> void:
	_enter_step(current_step + 1)

func _on_confirm_pressed() -> void:
	stop()
	get_tree().change_scene_to_file("res://scenes/ui/loading_screen.tscn")
