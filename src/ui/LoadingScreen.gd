extends Control

@onready var _progress: ProgressBar = $Center/VBox/Progress
@onready var _status: Label = $Center/VBox/Status
@onready var _start_button: Button = $Center/VBox/StartButton
@onready var _tutorial_button: Button = $Center/VBox/TutorialButton

const TOTAL_STEPS := 6

var _step := 0

func _ready() -> void:
	_status.text = "初始化中..."
	_start_button.pressed.connect(_on_start_pressed)
	_tutorial_button.pressed.connect(_on_tutorial_pressed)
	_start_loading()

func _start_loading() -> void:
	await Player.preload_async(get_tree(), _on_progress)
	await Enemy.preload_all_async(get_tree(), _on_progress)
	_status.text = "准备就绪"
	_start_button.visible = true
	_tutorial_button.visible = true
	_start_button.grab_focus()
	if FileAccess.file_exists("res://tests/.test_mode"):
		await get_tree().process_frame
		_on_start_pressed()

func _on_start_pressed() -> void:
	GameState.is_tutorial = false
	_start_button.disabled = true
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_progress(_ratio: float, label: String) -> void:
	_step += 1
	_progress.value = float(_step) / TOTAL_STEPS * 100.0
	_status.text = "正在加载: %s" % label

func _on_tutorial_pressed() -> void:
	GameState.is_tutorial = true
	get_tree().change_scene_to_file("res://scenes/main.tscn")
