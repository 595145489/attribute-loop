extends GutTest

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

func test_resolve_drop_preset_picks_closest_lower_phase() -> void:
    var enemy_data: EnemyData = DataTables.get_enemy("汲取者")
    var preset = GameLoop._resolve_drop_preset(enemy_data, 2)
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

func test_pick_enemy_id_phase11_includes_all_five_types() -> void:
    var phase_11: PhaseData = DataTables.get_phase(11)
    var found: Dictionary = {}
    for i in 300:
        found[GameLoop._pick_enemy_id(phase_11, 10)] = true
    assert_true(found.has("汲取者"), "汲取者 should appear in 裁决圈 spawns")
    assert_true(found.has("守卫者"), "守卫者 should appear in 裁决圈 spawns")
    assert_true(found.has("急袭者"), "急袭者 should appear in 裁决圈 spawns")
    assert_true(found.has("复制者"), "复制者 should appear in 裁决圈 spawns")
    assert_true(found.has("先驱者"), "先驱者 should appear in 裁决圈 spawns")

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
