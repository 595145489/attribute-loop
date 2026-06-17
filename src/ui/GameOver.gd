class_name GameOver
extends CanvasLayer

@onready var phase_label: Label = $Center/VBox/PhaseLabel
@onready var loops_label: Label = $Center/VBox/LoopsLabel
@onready var kills_label: Label = $Center/VBox/KillsLabel
@onready var verdict_loops_label: Label = $Center/VBox/VerdictLoopsLabel
@onready var restart_button: Button = $Center/VBox/RestartButton

func _ready() -> void:
	var config: GameConfig = DataTables.config
	phase_label.text = "到达阶段: %d" % GameState.current_phase
	loops_label.text = "圈数: %d" % GameState.loops_completed
	kills_label.text = "击杀数: %d" % GameState.enemies_killed
	verdict_loops_label.text = "裁决圈完成: %d / %d" % [
		GameState.verdict_loops_survived,
		config.verdict_survive_loops
	]
	restart_button.pressed.connect(_on_restart)

func _on_restart() -> void:
	GameState.reset()
	get_tree().reload_current_scene()

func _get_narrative(outcome: String) -> String:
	if outcome == "win":
		return "折纸世界的裁决已落下。那个完成了循环的人，是你。愿你的折痕永远清晰。"
	else:
		return "你走过了许多圈，见过了许多折叠与展开。这已经足够了。愿你在下一次循环中走得更远。"

func _get_background_path(outcome: String) -> String:
	if outcome == "win":
		return "res://resources/backgrounds/bg_game_over_win.png"
	else:
		return "res://resources/backgrounds/bg_game_over_lose.png"
