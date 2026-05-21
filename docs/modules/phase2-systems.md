# Phase 2 Systems

## ComponentData & DropPreset

`ComponentData` (`src/resources/ComponentData.gd`) defines a single component instance. Each component has:
- `slot_type`: TRIGGER_ONLY / EFFECT_ONLY / BOTH
- `trigger_value` / `effect_value`: rolled at spawn from DropPreset ranges
- `trigger_count`: runtime counter, increments toward trigger_value

`DropPreset` (`src/resources/DropPreset.gd`) stores value ranges per component per tier:
```
component_ranges = { "受击": { "trigger": Vector2(min, max) }, ... }
```
Three tiers live in `data/drop_presets/drop_tier_0N.tres`. EnemyData maps phases to tiers.

## Drop Assignment Flow

`GameLoop._assign_components(enemy)` runs after `enemy.init()` at spawn:
1. Resolves the correct DropPreset via `_resolve_drop_preset` (closest-lower-phase key in enemy_data.phase_drop_presets)
2. Rolls a number of T+E pairs based on `component_pair_min/max + phase.component_count_bonus`
3. Picks component IDs via `_weighted_pick_with_modifiers` (enemy base weights × phase multipliers)
4. Calls `_create_component(id, preset)` which duplicates the base ComponentData and rolls trigger/effect values

## RuleEngine

`RuleEngine` (`src/systems/RuleEngine.gd`) is a Node child of `Systems` in main.tscn.

**Connects to:** `player_hit`, `enemy_killed`, `loop_completed`, `tile_passed` on EventBus.

**Trigger map:**
| Signal | Evaluated trigger IDs |
|--------|----------------------|
| player_hit | 受击, 治愈 |
| enemy_killed | 击杀 |
| loop_completed | 完成圈数 |
| tile_passed | 经过 |

**Evaluation:** For each rule slot where both trigger and effect are filled, if the slot's trigger.id matches the event, increment trigger_count. When trigger_count >= trigger_value, reset to 0 and call `_execute_effect`.

**Effects (Phase 2):**
- `治愈`: heals `int(effect_value)` HP (capped at hp_max), emits `rule_fired`
- `反射`: sets `GameState.pending_reflect_ratio`, emits `rule_fired`; CombatSystem applies reflect on next enemy attack

## StripManager

`StripManager` (`src/systems/StripManager.gd`) bridges combat end to the resume-walk signal.

**Signal chain:**
```
CombatSystem.enemy_killed(enemy)
  → StripManager._on_enemy_killed(enemy)
    → if no components: emit combat_resolved immediately
    → else: StripPanel.show_for_enemy(enemy, callback)
      → player interacts
      → "继续" button → callback → emit combat_resolved
  → GameLoop._on_combat_resolved() → free enemy, resume walking
```

**Dependencies:** `StripManager.setup(panel)` must be called from `Main._ready()`.
