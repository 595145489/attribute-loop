class_name HUD
extends CanvasLayer

@onready var hp_bar: ProgressBar = $HPBar
@onready var hp_label: Label = $HPLabel
@onready var pause_label: Label = $PauseLabel

func update_hp(current: float, maximum: float) -> void:
	hp_bar.max_value = maximum
	hp_bar.value = current
	hp_label.text = "HP: %d / %d" % [int(current), int(maximum)]

func set_paused(paused: bool) -> void:
	pause_label.visible = paused
