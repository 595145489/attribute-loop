extends Control

@onready var _progress: ProgressBar = $Center/VBox/Progress
@onready var _status: Label = $Center/VBox/Status

const TOTAL_STEPS := 6

var _step := 0

func _ready() -> void:
	_status.text = "初始化中..."
	_start_loading()

func _start_loading() -> void:
	await Player.preload_async(get_tree(), _on_progress)
	await Enemy.preload_all_async(get_tree(), _on_progress)
	await get_tree().create_timer(0.5).timeout
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_progress(_ratio: float, label: String) -> void:
	_step += 1
	_progress.value = float(_step) / TOTAL_STEPS * 100.0
	_status.text = "正在加载: %s" % label