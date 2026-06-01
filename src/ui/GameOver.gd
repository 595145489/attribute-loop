class_name GameOver
extends CanvasLayer

var outcome: String = "lose"

@onready var phase_label: Label = $Center/VBox/PhaseLabel
@onready var loops_label: Label = $Center/VBox/LoopsLabel
@onready var kills_label: Label = $Center/VBox/KillsLabel
@onready var verdict_loops_label: Label = $Center/VBox/VerdictLoopsLabel
@onready var restart_button: Button = $Center/VBox/RestartButton

func _ready() -> void:
	_populate()
	restart_button.pressed.connect(_on_restart)

func _populate() -> void:
	var config: GameConfig = DataTables.config
	phase_label.text = "到达阶段: %d" % GameState.current_phase
	loops_label.text = "圈数: %d" % GameState.loops_completed
	kills_label.text = "击杀数: %d" % GameState.enemies_killed
	verdict_loops_label.text = "裁决圈完成: %d / %d" % [
		GameState.verdict_loops_survived,
		config.verdict_survive_loops
	]

func _on_restart() -> void:
	GameState.reset()
	get_tree().reload_current_scene()
