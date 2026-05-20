class_name GameOver
extends CanvasLayer

@onready var loops_label: Label = $Panel/VBox/LoopsLabel
@onready var kills_label: Label = $Panel/VBox/KillsLabel
@onready var restart_button: Button = $Panel/VBox/RestartButton

func _ready() -> void:
	loops_label.text = "Loops survived: %d" % GameState.loops_completed
	kills_label.text = "Enemies killed: %d" % GameState.enemies_killed
	restart_button.pressed.connect(_on_restart)

func _on_restart() -> void:
	GameState.reset()
	get_tree().reload_current_scene()
