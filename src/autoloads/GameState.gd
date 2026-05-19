extends Node

var hp: int
var hp_max: int = 100
var loops_completed: int = 0
var enemies_killed: int = 0
var current_phase: int = 1
var is_paused: bool = false

func _ready() -> void:
    reset()

func take_damage(amount: int) -> void:
    hp = max(0, hp - amount)
    if hp == 0:
        EventBus.player_died.emit()

func reset() -> void:
    hp = hp_max
    loops_completed = 0
    enemies_killed = 0
    current_phase = 1
    is_paused = false
