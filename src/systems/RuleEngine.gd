class_name RuleEngine
extends Node

var _log_file: FileAccess = null

func _ready() -> void:
    _log_file = FileAccess.open("res://tests/rule_debug.log", FileAccess.WRITE)
    EventBus.player_hit.connect(_on_player_hit)
    EventBus.enemy_killed.connect(_on_enemy_killed)
    EventBus.loop_completed.connect(_on_loop_completed)
    EventBus.tile_passed.connect(_on_tile_passed)
    EventBus.rule_fired.connect(_on_rule_fired)

func _log(msg: String) -> void:
    if _log_file:
        _log_file.store_line(msg)
        _log_file.flush()
    print(msg)

func _on_player_hit(_damage: int) -> void:
    _evaluate_triggers(["受击"])

func _on_rule_fired(_slot_idx: int, effect_id: String, _value: float) -> void:
    if effect_id == "治愈":
        _evaluate_triggers(["治愈"])

func _on_enemy_killed(_enemy: Enemy) -> void:
    _evaluate_triggers(["击杀"])

func _on_loop_completed() -> void:
    _evaluate_triggers(["完成圈数"])

func _on_tile_passed(_tile_idx: int) -> void:
    _evaluate_triggers(["经过"])

func _evaluate_triggers(trigger_ids: Array) -> void:
    for i in GameState.rule_slots.size():
        var slot = GameState.rule_slots[i]
        var trigger: ComponentData = slot.get("trigger")
        var effect: ComponentData = slot.get("effect")
        if trigger == null or effect == null:
            _log("[slot%d] T=%s E=%s — skipped (null)" % [i, str(trigger), str(effect)])
            continue
        if trigger.id not in trigger_ids:
            continue
        trigger.trigger_count += 1
        _log("[slot%d] T=%s count=%d/%.0f E=%s eff_val=%.2f" % [
            i, trigger.id, trigger.trigger_count, trigger.trigger_value,
            effect.id, effect.effect_value])
        if trigger.trigger_count >= trigger.trigger_value:
            trigger.trigger_count = 0
            _log("[FIRE] %s -> %s, eff_val=%.2f, hp_before=%d" % [
                trigger.id, effect.id, effect.effect_value, GameState.hp])
            _execute_effect(i, effect)
            _log("[FIRE] hp_after=%d" % GameState.hp)

func _execute_effect(slot_idx: int, effect: ComponentData) -> void:
    match effect.id:
        "治愈":
            GameState.hp = min(GameState.hp + int(effect.effect_value), GameState.hp_max)
            EventBus.rule_fired.emit(slot_idx, "治愈", effect.effect_value)
        "反射":
            GameState.pending_reflect_ratio = effect.effect_value
            EventBus.rule_fired.emit(slot_idx, "反射", effect.effect_value)
        _:
            _log("[FIRE] unknown effect id: '" + effect.id + "'")
