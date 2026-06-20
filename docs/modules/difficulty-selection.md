# Difficulty Selection

## Responsibility

Presents an Easy/Hard choice after the player clicks "开始游戏". Easy starts the
player with a pre-built loadout (3 player rule slots + 5 tile rule slots) so
newcomers begin with a working build; Hard leaves everything empty for the
player to construct themselves. Enemy stats, player HP, and all other balance
are identical between difficulties — Easy differs from Hard **only** in the
pre-filled loadout.

## Key components

- `GameState.difficulty` (`"easy"` / `"hard"`, default `"hard"`) — chosen by
  `LoadingScreen` before `reset()`, persists for the run. Drives rule-slot
  count (3 Easy / 2 Hard).
- `DataTables.EASY_PLAYER_SLOTS` — constant array of 3 `{trigger, effect,
  trigger_value, effect_value}` specs for the player's slots:
  1. 受击 (trigger, every 5) → 治愈 (effect, heal 12)
  2. 治愈 (trigger, every 3) → 灼烧 (effect, 2)
  3. 治愈 (trigger, every 3) → 护盾 (effect, shield 15)
- `DataTables.EASY_TILE_RULES` — constant `{tile_index: spec}` for 5 tiles
  (indices 1 瞭望塔, 5 兵营, 8 治愈圣坛, 9 法师塔, 12 猎人小屋), one rule each,
  all `经过 (every 6) → <effect>`.
- `DataTables.make_easy_slot(spec)` — duplicates `ComponentData` resources into
  a `{"trigger", "effect"}` slot dict with fixed values, so each slot owns its
  own instance.
- `DataTables.apply_easy_tile_rules(tiles)` — fills `rule_slots[0]` on the 5
  preset tiles.
- `GameState.apply_easy_player_slots()` — rebuilds the player's `rule_slots`
  from the preset.
- `LoadingScreen` difficulty panel (built in code) — Easy / Hard / Back buttons
  with a hint label.

## Execution flow

1. `LoadingScreen._on_start_pressed()` passes the tutorial gate, then shows the
   difficulty panel. In test mode (`tests/.test_mode`) it skips the panel and
   launches Hard directly, preserving automated screenshot/unit tests.
2. Choosing a difficulty calls `_launch_game(difficulty)`, which sets
   `GameState.difficulty`, calls `GameState.reset()` (creating 3 slots for
   Easy / 2 for Hard), then loads `main.tscn`.
3. `Main._finish_setup()` calls `_build_tiles()`; if difficulty is Easy it then
   calls `GameState.apply_easy_player_slots()` and
   `DataTables.apply_easy_tile_rules(_tiles)`. Tiles' `rule_slots` already
   exist from `Tile._ready()` (sized per `DataTables.TILE_MAX_RULES`).
4. The rule engine evaluates pre-filled player and tile slots like any
   player-placed rule; pre-filled tiles also display their building graphic via
   `Tile._refresh_visual()`.

## Dependencies

- `GameState` (autoload) — difficulty flag, player slots, `reset()`.
- `DataTables` (autoload) — preset constants and apply helpers.
- `Main` — applies the preset after tile construction.
- `LoadingScreen` — difficulty selection UI and launch routing.

## Testing

- `tests/unit/test_game_state.gd` — `difficulty` default, slot count per
  difficulty, `reset()` does not clear difficulty.
- `tests/unit/test_difficulty_preset.gd` — preset constants, `make_easy_slot`,
  `apply_easy_player_slots`, `apply_easy_tile_rules`.
- Visual: Layer 3 screenshot (test-mode boots Hard through the new start flow).
