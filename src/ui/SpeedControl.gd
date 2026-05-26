class_name SpeedControl
extends HBoxContainer

const SPEEDS: Array[float] = [0.0, 1.0, 2.0, 3.0]
const LABELS: Array[String] = ["⏸", "1×", "2×", "3×"]

var _buttons: Array[Button] = []

func _ready() -> void:
	var group := ButtonGroup.new()
	for i in SPEEDS.size():
		var btn := Button.new()
		btn.text = LABELS[i]
		btn.toggle_mode = true
		btn.button_group = group
		btn.pressed.connect(_on_speed_pressed.bind(i))
		add_child(btn)
		_buttons.append(btn)
	_buttons[1].button_pressed = true

func _on_speed_pressed(index: int) -> void:
	GameState.speed_multiplier = SPEEDS[index]