class_name HUD
extends CanvasLayer

@onready var hp_label: Label = $HPLabel
@onready var loops_label: Label = $LoopsLabel
@onready var phase_label: Label = $PhaseLabel

func _process(_delta: float) -> void:
	hp_label.text = "HP: %d / %d" % [GameState.hp, GameState.hp_max]
	loops_label.text = "Loops: %d" % GameState.loops_completed
	var phase_data: PhaseData = DataTables.get_phase(GameState.current_phase)
	phase_label.text = "Phase %d — %s" % [GameState.current_phase, phase_data.phase_name]
