class_name GameWin
extends CanvasLayer

@onready var narrative_text: RichTextLabel = $Center/VBox/NarrativeText
@onready var restart_button: Button = $Center/VBox/RestartButton

func _ready() -> void:
	narrative_text.text = "[p align=center]梦里你们从未见过彼此的脸。\n\n但你认得出那种把石子翻到平面朝上的习惯，\n认得出那句潦草的字——\n[i]\"我住的地方晚上能看见一座塔。\"[/i]\n\n你在人群里停下来。\n\n是你。[/p]"
	restart_button.pressed.connect(_on_restart)

func _on_restart() -> void:
	GameState.reset()
	get_tree().reload_current_scene()
