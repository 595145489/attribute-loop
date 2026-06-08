extends Control

@onready var close_btn: Button = $Panel/VBox/TitleBar/CloseBtn

func _ready() -> void:
	close_btn.pressed.connect(_on_close)
	hide()

func open() -> void:
	GameState.pause_for_panel()
	show()

func _on_close() -> void:
	GameState.unpause_for_panel()
	hide()
