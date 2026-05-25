# Tile System — Phase 3

## Responsibilities

This module adds permanent tile rules, an Altar mechanic for Phase advancement, and a gold economy to the game loop.

## Key Classes

### `Tile` (`src/entities/Tile.gd`)
Extends Node2D. Each of the 13 track positions is a Tile.
- `tile_index: int` — position index (0 = altar, 1–12 = normal tiles)
- `is_altar: bool` — marks tile 0 as the altar
- `pass_count: int` — how many times the player has stepped on this tile (persists across loops)
- `rule_slots: Array` — array of `{trigger, effect}` dicts; size determined by `DataTables.TILE_MAX_RULES[tile_index]`
- `altar_slots: Array` — only on altar tile; size = current phase's `altar_requirement`
- `resize_altar_for_phase(phase)` — called when phase advances to expand altar slots

### `EconomyManager` (`src/systems/EconomyManager.gd`)
Autoload-style Node added to `$Systems` in main.tscn.
- Listens to `EventBus.enemy_killed` and drops gold based on `EnemyData.gold_scale` and current phase.
- `static calc_gold_drop(ed, phase) -> int` — `floor(rand(gold_min, gold_max) * (1 + (phase-1) * gold_scale))`
- Emits `EventBus.gold_changed` after each drop.

### `TileRulePanel` (`src/ui/TileRulePanel.gd`)
Modal panel opened by clicking a normal tile.
- Shows each rule slot with T (经过-trigger) and E (effect) buttons.
- Allows placing components from inventory into tile slots.
- Removal costs gold via `GameState.pay_deletion_cost()`.
- Displays scaled effect value based on current `pass_count`.

### `AltarPanel` (`src/ui/AltarPanel.gd`)
Modal panel opened by clicking the altar tile (index 0).
- Shows E-component slots for the current phase requirement.
- Preview shows `effect_value * altar_ratio` bonus per slot.
- "激活祭坛" fires when all slots are filled — applies bonuses to `GameState.altar_bonuses`, advances `GameState.current_phase`, emits `EventBus.phase_changed`.

## Execution Flow

1. **Player steps on tile** → `Main._check_player_tile()` increments `tile.pass_count`, emits `EventBus.tile_passed(tile_index)`
2. **RuleEngine receives tile_passed** → evaluates player 经过-rules AND tile rules for that tile
3. **Tile rule fires** → `RuleEngine._execute_effect(slot_idx=-1, effect, pass_count)` applies growth scaling + altar bonus
4. **Enemy killed** → `EconomyManager._on_enemy_killed()` drops gold, updates `GameState.gold`
5. **Player clicks tile** → `Main._unhandled_input()` opens `TileRulePanel` or `AltarPanel`
6. **Altar activated** → `AltarPanel._on_activate()` commits bonuses, increments phase, closes panel

## Dependencies

- `DataTables.TILE_MAX_RULES` — per-tile rule capacity config
- `DataTables.get_phase(n).altar_requirement` — how many E-slots the altar needs
- `GameState.gold`, `deletion_count`, `altar_bonuses` — economy and altar state
- `ComponentData.growth_rate`, `scale_exponent`, `max_scale`, `altar_ratio` — scaling fields added in Phase 3
- `EventBus.gold_changed`, `phase_changed` — new signals for UI reactivity
