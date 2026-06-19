extends Node

const CONFIG_PATH := "user://onboarding.cfg"
const SECTION := "onboarding"
const KEY := "tutorial_completed"

var _completed: bool = false

func _ready() -> void:
	reload()

func reload() -> void:
	var cfg := ConfigFile.new()
	var err := cfg.load(CONFIG_PATH)
	if err == OK:
		_completed = bool(cfg.get_value(SECTION, KEY, false))
	else:
		_completed = false

func is_tutorial_completed() -> bool:
	return _completed

func mark_tutorial_completed() -> void:
	_completed = true
	var cfg := ConfigFile.new()
	cfg.set_value(SECTION, KEY, true)
	var err := cfg.save(CONFIG_PATH)
	if err != OK:
		push_warning("OnboardingState: failed to save tutorial completion (code %d)" % err)
