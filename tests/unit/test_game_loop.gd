extends GutTest

# Verdict-threshold flow: reaching the pressure window at verdict_trigger_phase
# must queue a boss circle (the 裁决前夜Boss) — NOT jump straight into the verdict
# loop. The verdict loop (and its phase-6 narrative) only starts after the boss is
# beaten, mirroring how a normal phase's narrative plays after its boss dies.
func _make_loop_with_altar() -> GameLoop:
    var gl := GameLoop.new()
    var altar := Tile.new()
    altar.is_altar = true
    altar.altar_slots = []
    gl._tiles = [altar]
    add_child_autofree(gl)
    # Tutorial mode short-circuits spawn_enemies so we can test the decision
    # logic without spinning up real enemies.
    GameState.is_tutorial = true
    return gl

func test_verdict_threshold_queues_boss_circle() -> void:
    GameState.reset()
    var gl := _make_loop_with_altar()
    GameState.current_phase = DataTables.config.verdict_trigger_phase
    # One short of the pressure window so the +1 inside _on_loop_completed trips it.
    var pw: int = DataTables.get_phase(GameState.current_phase).world_pressure_window
    GameState.loops_in_phase = pw - 1
    watch_signals(EventBus)
    EventBus.loop_completed.connect(gl._on_loop_completed)
    EventBus.loop_completed.emit()
    assert_true(GameState.boss_circle_pending, "verdict threshold should queue a boss circle")
    assert_true(GameState.pending_phase_advance)
    assert_false(GameState.in_verdict_loop, "verdict loop must not start before the boss is beaten")
    assert_signal_not_emitted(EventBus, "verdict_loop_entered")
    GameState.is_tutorial = false

func test_verdict_loop_starts_after_boss_beaten() -> void:
    GameState.reset()
    var gl := _make_loop_with_altar()
    GameState.current_phase = DataTables.config.verdict_trigger_phase
    GameState.pending_phase_advance = true
    GameState.boss_circle_pending = false
    watch_signals(EventBus)
    EventBus.loop_completed.connect(gl._on_loop_completed)
    EventBus.loop_completed.emit()
    assert_true(GameState.in_verdict_loop)
    assert_signal_emitted(EventBus, "verdict_loop_entered")
    GameState.is_tutorial = false

func test_roll_spawn_count_within_range() -> void:
    var phase: PhaseData = DataTables.get_phase(1)
    for i in 100:
        var count = GameLoop._roll_spawn_count(phase)
        assert_gte(count, phase.spawn_count_min)
        assert_lte(count, phase.spawn_count_max)

func test_pick_enemy_id_only_unlocked() -> void:
    var phase: PhaseData = DataTables.get_phase(1)
    for i in 50:
        var id = GameLoop._pick_enemy_id(phase, 1)
        var enemy_data: EnemyData = DataTables.get_enemy(id)
        assert_lte(enemy_data.unlock_phase, 1)

func test_pick_enemy_id_from_weights() -> void:
    var phase: PhaseData = DataTables.get_phase(1)
    var id = GameLoop._pick_enemy_id(phase, 1)
    assert_true(id == "汲取者" or id == "守卫者")

func test_pick_distinct_tile_indices_correct_count() -> void:
    var indices = GameLoop._pick_tile_indices(3, 12)
    assert_eq(indices.size(), 3)

func test_pick_distinct_tile_indices_no_duplicates() -> void:
    var indices = GameLoop._pick_tile_indices(5, 12)
    var unique = {}
    for i in indices:
        unique[i] = true
    assert_eq(unique.size(), 5)

func test_weighted_pick_with_modifiers_returns_valid_id() -> void:
    var weights = {"受击": 50, "击杀": 50}
    var phase_data: PhaseData = DataTables.get_phase(1)
    var result = GameLoop._weighted_pick_with_modifiers(weights, phase_data)
    assert_true(result == "受击" or result == "击杀")

func test_weighted_pick_excludes_zero_weight() -> void:
    var weights = {"受击": 100, "击杀": 0}
    var phase_data: PhaseData = DataTables.get_phase(1)
    for i in 20:
        var result = GameLoop._weighted_pick_with_modifiers(weights, phase_data)
        assert_eq(result, "受击")

func test_create_component_受击_sets_trigger_and_effect_values() -> void:
    var preset: DropPreset = DataTables.get_drop_preset(1)
    var comp = GameLoop._create_component("受击", preset)
    assert_gt(comp.trigger_value, 0.0)
    assert_gt(comp.effect_value, 0.0)

func test_create_component_both_sets_both_values() -> void:
    var preset: DropPreset = DataTables.get_drop_preset(1)
    var comp = GameLoop._create_component("治愈", preset)
    assert_gt(comp.trigger_value, 0.0)
    assert_gt(comp.effect_value, 0.0)

func test_create_component_returns_duplicate_not_original() -> void:
    var preset: DropPreset = DataTables.get_drop_preset(1)
    var original: ComponentData = DataTables.get_component("受击")
    var comp = GameLoop._create_component("受击", preset)
    assert_ne(comp, original)
    assert_eq(comp.id, "受击")

func test_roll_tier_preset_returns_valid_preset() -> void:
    var phase_data: PhaseData = DataTables.get_phase(1)
    var preset = GameLoop._roll_tier_preset(phase_data)
    assert_not_null(preset)

func test_pick_tile_indices_never_returns_zero() -> void:
    for i in 200:
        var indices = GameLoop._pick_tile_indices(5, 13)
        assert_false(0 in indices, "Starting tile index 0 must never be in spawn pool")

func test_pick_tile_indices_correct_count_with_13_tiles() -> void:
    var indices = GameLoop._pick_tile_indices(3, 13)
    assert_eq(indices.size(), 3)

func test_altar_is_full_false_when_empty_array() -> void:
    var tile := Tile.new()
    tile.altar_slots = []
    assert_false(GameLoop._altar_is_full(tile))
    tile.free()

func test_altar_is_full_false_when_any_slot_null() -> void:
    var tile := Tile.new()
    var c := ComponentData.new()
    tile.altar_slots = [c, null]
    assert_false(GameLoop._altar_is_full(tile))
    tile.free()

func test_altar_is_full_true_when_all_slots_filled() -> void:
    var tile := Tile.new()
    var c1 := ComponentData.new()
    var c2 := ComponentData.new()
    tile.altar_slots = [c1, c2]
    assert_true(GameLoop._altar_is_full(tile))
    tile.free()

func test_pick_enemy_id_phase7_includes_all_five_types() -> void:
    var phase_7: PhaseData = DataTables.get_phase(7)
    var found: Dictionary = {}
    for i in 300:
        found[GameLoop._pick_enemy_id(phase_7, 7)] = true
    assert_true(found.has("汲取者"), "汲取者 should appear in 裁决圈 spawns")
    assert_true(found.has("守卫者"), "守卫者 should appear in 裁决圈 spawns")
    assert_true(found.has("急袭者"), "急袭者 should appear in 裁决圈 spawns")
    assert_true(found.has("复制者"), "复制者 should appear in 裁决圈 spawns")
    assert_true(found.has("先驱者"), "先驱者 should appear in 裁决圈 spawns")

func test_assign_components_pair_count_scales_with_phase() -> void:
    # Regression: pair count must come from the phase's enemy_component_count_min/max
    # (spec 5.1), not a flat 1-2 default. Phase 1 = 1-2, Phase 6 = 4-4.
    for phase in [1, 6]:
        var pd: PhaseData = DataTables.get_phase(phase)
        for i in 50:
            var enemy := Enemy.new()
            enemy.enemy_id = "汲取者"
            GameLoop._assign_components(enemy, phase)
            var pairs := enemy.components.size() / 2
            assert_gte(pairs, pd.enemy_component_count_min, "phase %d pairs below min" % phase)
            assert_lte(pairs, pd.enemy_component_count_max, "phase %d pairs above max" % phase)
            enemy.free()

func test_assign_components_boss_bonus_adds_pairs() -> void:
    # Spec 7.4: boss gets +2 rule pairs on top of the phase range.
    var pd: PhaseData = DataTables.get_phase(1)
    for i in 50:
        var enemy := Enemy.new()
        enemy.enemy_id = "汲取者"
        GameLoop._assign_components(enemy, 1, 2)
        var pairs := enemy.components.size() / 2
        assert_gte(pairs, pd.enemy_component_count_min + 2)
        assert_lte(pairs, pd.enemy_component_count_max + 2)
        enemy.free()

func test_append_bonus_pair_adds_passage_and_effect() -> void:
    # Every-other-loop bonus loot: appends a 经过 trigger + a random effect,
    # so the player can strip a 经过 to enable a tile rule.
    var enemy := Enemy.new()
    enemy.enemy_id = "汲取者"
    var phase_data: PhaseData = DataTables.get_phase(1)
    var before := enemy.components.size()
    GameLoop._append_bonus_pair(enemy, phase_data)
    assert_eq(enemy.components.size(), before + 2, "bonus pair should add 2 components")
    assert_eq(enemy.components[before].id, "经过", "first bonus component must be 经过")
    enemy.free()

func test_apply_boss_modifiers_scales_hp() -> void:
    var enemy := Enemy.new()
    enemy.hp_max = 100
    enemy.hp = 100
    enemy.dmg = 20
    var phase_data := PhaseData.new()
    phase_data.boss_hp_multiplier = 3.0
    phase_data.boss_damage_multiplier = 2.0
    phase_data.boss_scale = 1.5
    GameLoop._apply_boss_modifiers(enemy, phase_data)
    assert_eq(enemy.hp_max, 300)
    assert_eq(enemy.hp, 300)
    enemy.free()

func test_apply_boss_modifiers_scales_dmg() -> void:
    var enemy := Enemy.new()
    enemy.hp_max = 100
    enemy.hp = 100
    enemy.dmg = 20
    var phase_data := PhaseData.new()
    phase_data.boss_hp_multiplier = 2.0
    phase_data.boss_damage_multiplier = 2.0
    phase_data.boss_scale = 1.0
    GameLoop._apply_boss_modifiers(enemy, phase_data)
    assert_eq(enemy.dmg, 40)
    enemy.free()

func test_apply_boss_modifiers_sets_scale() -> void:
    var enemy := Enemy.new()
    enemy.hp_max = 100
    enemy.hp = 100
    enemy.dmg = 10
    var phase_data := PhaseData.new()
    phase_data.boss_hp_multiplier = 1.0
    phase_data.boss_damage_multiplier = 1.0
    phase_data.boss_scale = 2.0
    GameLoop._apply_boss_modifiers(enemy, phase_data)
    assert_almost_eq(enemy.scale.x, 2.0, 0.001)
    assert_almost_eq(enemy.scale.y, 2.0, 0.001)
    enemy.free()
