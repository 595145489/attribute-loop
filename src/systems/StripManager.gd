class_name StripManager
extends Node

var _strip_panel = null  # StripPanel — set via setup()

func _ready() -> void:
    EventBus.enemy_killed.connect(_on_enemy_killed)

func setup(panel) -> void:
    _strip_panel = panel

func _on_enemy_killed(enemy: Enemy) -> void:
    if enemy.components.is_empty():
        EventBus.combat_resolved.emit()
        return
    if _strip_panel != null:
        _strip_panel.show_for_enemy(enemy, _on_strip_completed)

func _on_strip_completed() -> void:
    EventBus.combat_resolved.emit()
