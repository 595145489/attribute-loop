class_name CombatSystem
extends Node

var rule_engine: RuleEngine = null
var _player_timer: Timer
var _enemy_timer: Timer
var _active_enemy: Enemy = null
var _enemy_state_timer: float = 0.0
const _ENEMY_STATE_INTERVAL: float = 1.0
var _enrage_timer: float = 0.0
var _enrage_stacks: int = 0
var _burn_timer: float = 0.0

func _ready() -> void:
    _player_timer = Timer.new()
    _player_timer.one_shot = false
    _player_timer.timeout.connect(_on_player_attack)
    add_child(_player_timer)

    _enemy_timer = Timer.new()
    _enemy_timer.one_shot = false
    _enemy_timer.timeout.connect(_on_enemy_attack)
    add_child(_enemy_timer)

func start(enemy: Enemy) -> void:
    _active_enemy = enemy
    _enrage_timer = 0.0
    _enrage_stacks = 0
    if not EventBus.rule_fired.is_connected(_on_rule_fired):
        EventBus.rule_fired.connect(_on_rule_fired)
    enemy.shield = 0
    enemy.slow_stacks = 0
    enemy.lifesteal_ratio = 0.0
    enemy.pending_reflect_ratio = 0.0
    enemy.burn_stacks = 0
    enemy._rule_fire_count = 0
    enemy._firing_rule_trigger = false
    for comp in enemy.components:
        comp.trigger_count = 0
    _enemy_state_timer = 0.0
    _enrage_timer = 0.0
    _enrage_stacks = 0
    _burn_timer = 0.0
    _player_timer.wait_time = maxf(DataTables.player.attack_interval - GameState.attack_interval_bonus, 0.2)
    _enemy_timer.wait_time = enemy.attack_interval
    if rule_engine != null:
        rule_engine.set_active_enemy(enemy)
    _player_timer.start()
    _enemy_timer.start()

func stop() -> void:
    _player_timer.stop()
    _enemy_timer.stop()
    _active_enemy = null
    if rule_engine != null:
        rule_engine.set_active_enemy(null)
    if EventBus.rule_fired.is_connected(_on_rule_fired):
        EventBus.rule_fired.disconnect(_on_rule_fired)

func _process(delta: float) -> void:
    if _active_enemy == null:
        return
    _enemy_state_timer += delta
    if _enemy_state_timer >= _ENEMY_STATE_INTERVAL:
        _enemy_state_timer = 0.0
        _check_enemy_state_triggers()
    _enrage_timer += delta
    _check_enrage()
    if _active_enemy != null and _active_enemy.burn_stacks > 0:
        _burn_timer += delta
        var cfg: GameConfig = DataTables.config
        if _burn_timer >= cfg.combat_burn_interval:
            _burn_timer = 0.0
            var burn_dmg := _active_enemy.burn_stacks * cfg.combat_burn_dmg_per_stack
            _active_enemy.take_damage(burn_dmg)
            if _active_enemy.is_dead():
                _finish_combat(_active_enemy)
                return

func _check_enrage() -> void:
    var cfg: GameConfig = DataTables.config
    var threshold := cfg.combat_enrage_time + _enrage_stacks * cfg.combat_enrage_interval
    if _enrage_timer >= threshold:
        _enrage_stacks += 1
        EventBus.combat_enrage.emit(_enrage_stacks)

func _check_enemy_state_triggers() -> void:
    if float(_active_enemy.hp) / float(_active_enemy.hp_max) < 0.3:
        _evaluate_enemy_triggers(["低血"])
    if _active_enemy.hp >= _active_enemy.hp_max:
        _evaluate_enemy_triggers(["满血"])

func _on_player_attack() -> void:
    if _active_enemy == null:
        return
    _apply_player_attack(_active_enemy)

func _on_enemy_attack() -> void:
    if _active_enemy == null:
        return
    _apply_enemy_attack(_active_enemy)

func _apply_player_attack(enemy: Enemy) -> void:
    var dmg := _calc_player_dmg()
    var had_boost := GameState.dmg_boost_stacks > 0
    var charge_bonus := _calc_charge_bonus()
    GameState.charge_stacks = 0
    if enemy.slow_stacks > 0:
        var stack_cap := mini(GameState.current_phase + 1, 8)
        var capped := mini(enemy.slow_stacks, stack_cap)
        dmg = int(dmg * (1.0 - capped * 0.1))
    if enemy.shield > 0:
        var absorbed := mini(enemy.shield, dmg)
        enemy.shield -= absorbed
        dmg -= absorbed
    if dmg > 0:
        enemy.take_damage(dmg)
    if charge_bonus > 0:
        enemy.take_damage(charge_bonus)
        EventBus.rule_fired.emit(-1, "蓄能释放", float(charge_bonus))
    if GameState.lifesteal_ratio > 0.0:
        var heal := int(dmg * GameState.lifesteal_ratio)
        if heal > 0:
            GameState.hp = min(GameState.hp + heal, GameState.hp_max)
            EventBus.lifesteal_healed.emit(heal)
    if had_boost:
        EventBus.dmg_boost_consumed.emit(GameState.dmg_boost_stacks)
    if enemy.pending_reflect_ratio > 0.0:
        var reflected := int(dmg * enemy.pending_reflect_ratio)
        GameState.take_damage(reflected)
        enemy.pending_reflect_ratio = 0.0
    if enemy.is_dead():
        _finish_combat(enemy)
        return
    _evaluate_enemy_triggers(["受击"])
    if enemy.is_dead():
        _finish_combat(enemy)

func _apply_enemy_attack(enemy: Enemy) -> void:
    var dmg := enemy.dmg
    if _enrage_stacks > 0:
        dmg = int(dmg * pow(DataTables.config.combat_enrage_multiplier, _enrage_stacks))
    if GameState.slow_stacks > 0:
        var stack_cap := mini(GameState.current_phase + 1, 8)
        var capped := mini(GameState.slow_stacks, stack_cap)
        dmg = int(dmg * (1.0 - capped * 0.1))
        EventBus.slow_applied.emit(capped)
    GameState.take_damage(dmg)
    EventBus.player_hit.emit(dmg)
    if GameState.pending_reflect_ratio > 0.0:
        enemy.take_damage(int(dmg * GameState.pending_reflect_ratio))
        GameState.pending_reflect_ratio = 0.0
        if enemy.is_dead():
            _finish_combat(enemy)
            return
    if enemy.lifesteal_ratio > 0.0:
        var heal := int(dmg * enemy.lifesteal_ratio)
        enemy.hp = min(enemy.hp + heal, enemy.hp_max)
        enemy._refresh_label()

func _evaluate_enemy_triggers(trigger_ids: Array) -> void:
    if _active_enemy == null:
        return
    var comps := _active_enemy.components
    var i := 0
    while i + 1 < comps.size():
        var t: ComponentData = comps[i]
        var e: ComponentData = comps[i + 1]
        if t.id in trigger_ids:
            t.trigger_count += 1
            if t.trigger_count >= t.trigger_value:
                t.trigger_count = 0
                _execute_enemy_effect(e)
        i += 2

func _execute_enemy_effect(effect: ComponentData) -> void:
    if _active_enemy == null:
        return
    var val := effect.effect_value
    match effect.id:
        "治愈":
            _active_enemy.hp = min(_active_enemy.hp + int(val), _active_enemy.hp_max)
            _active_enemy._refresh_label()
        "护盾":
            _active_enemy.shield += int(val)
        "反射":
            _active_enemy.pending_reflect_ratio = val
        "减伤":
            _active_enemy.slow_stacks += int(val)
        "吸血":
            _active_enemy.lifesteal_ratio += val
    if not _active_enemy._firing_rule_trigger:
        _active_enemy._firing_rule_trigger = true
        _evaluate_enemy_triggers(["规则触发"])
        _active_enemy._firing_rule_trigger = false

func _calc_player_dmg() -> int:
    var pd: PlayerData = DataTables.player
    var dmg := pd.dmg_base + GameState.dmg_bonus
    if GameState.dmg_boost_stacks > 0:
        dmg = int(dmg * (1.0 + GameState.dmg_boost_stacks * 0.1))
    return dmg

func _calc_charge_bonus() -> int:
    if GameState.charge_stacks <= 0:
        return 0
    return GameState.charge_stacks * _calc_player_dmg()

func _release_charge_if_any() -> void:
    if GameState.charge_stacks <= 0:
        return
    var bonus := _calc_charge_bonus()
    GameState.charge_stacks = 0
    if _active_enemy != null and bonus > 0:
        _active_enemy.take_damage(bonus)
        EventBus.rule_fired.emit(-1, "蓄能释放", float(bonus))

func _on_rule_fired(_slot_idx: int, effect_id: String, value: float) -> void:
    if _active_enemy == null:
        return
    match effect_id:
        "灼烧":
            _active_enemy.burn_stacks += int(value)
        "侵蚀":
            _active_enemy.hp_max = max(1, _active_enemy.hp_max - int(value))
            _active_enemy.hp = min(_active_enemy.hp, _active_enemy.hp_max)
            _active_enemy._refresh_label()
            if _active_enemy.is_dead():
                _finish_combat(_active_enemy)

func reset_enrage() -> void:
    _enrage_timer = 0.0
    _enrage_stacks = 0

func _finish_combat(enemy: Enemy = null) -> void:
    var resolved := enemy if enemy != null else _active_enemy
    if resolved == null:
        return
    stop()
    reset_enrage()
    GameState.lifesteal_ratio = 0.0
    GameState.enemies_killed += 1
    EventBus.enemy_killed.emit(resolved)
