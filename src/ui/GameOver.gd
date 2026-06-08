class_name GameOver
extends CanvasLayer

var outcome: String = "lose"

@onready var phase_label: Label = $Center/VBox/PhaseLabel
@onready var loops_label: Label = $Center/VBox/LoopsLabel
@onready var kills_label: Label = $Center/VBox/KillsLabel
@onready var verdict_loops_label: Label = $Center/VBox/VerdictLoopsLabel
@onready var restart_button: Button = $Center/VBox/RestartButton
@onready var background: TextureRect = $Background
@onready var narrative_text: RichTextLabel = $Center/VBox/NarrativeText

func _get_narrative(result: String) -> String:
	if result == "win":
		return "[p align=center]梦里你们从未见过彼此的脸。\n\n但你认得出那种把石子翻到平面朝上的习惯，\n认得出那句潦草的字——\n[i]“我住的地方晚上能看见一座塔。”[/i]\n\n你在人群里停下来。\n\n是你。[/p]"
	return "[p align=center]不是每一次寻找都以相遇结束。\n\n但那些夜晚是真实的，\n那些刻在木头上的字是真实的，\n你愿意走出来——也是真实的。\n\n这已经足够了。[/p]"

func _get_background_path(result: String) -> String:
	if result == "win":
		return "res://resources/backgrounds/bg_game_over_win.png"
	return "res://resources/backgrounds/bg_game_over_lose.png"
func _ready() -> void:
	_populate()
	restart_button.pressed.connect(_on_restart)

func _populate() -> void:
	var config: GameConfig = DataTables.config
	phase_label.text = "鍒拌揪闃舵: %d" % GameState.current_phase
	loops_label.text = "鍦堟暟: %d" % GameState.loops_completed
	kills_label.text = "鍑绘潃鏁? %d" % GameState.enemies_killed
	verdict_loops_label.text = "瑁佸喅鍦堝畬鎴? %d / %d" % [
		GameState.verdict_loops_survived,
		config.verdict_survive_loops
	]

func _on_restart() -> void:
	GameState.reset()
	get_tree().reload_current_scene()


