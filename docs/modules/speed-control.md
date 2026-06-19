# Speed Control

## Responsibility
Lets the player choose game speed: Pause / 1x / 2x / 3x. Affects all game systems uniformly via `Engine.time_scale`.

## Key pieces
- `GameState.speed_multiplier` (float, 0/1/2/3) — player's chosen speed; setter calls `_apply_time_scale()`
- `GameState._apply_time_scale()` — single writer for `Engine.time_scale`; formula: `0.0 if _panel_pause_count > 0 else speed_multiplier`
- `HUD` (`src/ui/HUD.gd`) — owns the speed UI: the four toggle buttons live as direct children `SpeedControl/Pause`, `SpeedControl/Speed1x`, `SpeedControl/Speed2x`, `SpeedControl/Speed3x` in `scenes/ui/HUD.tscn` (in a `ButtonGroup`, mutually exclusive). `HUD._on_speed_pressed(index)` is the single entry point for both clicks and keyboard.
- `SpeedControl` (`src/ui/SpeedControl.gd`) — empty placeholder; the container node exists in the scene but all logic is in `HUD`.

## Controls
| Input | Effect |
|-------|--------|
| Click Pause button / `Space` | Toggle pause (resume to last non-pause speed) |
| Click 1x button / `1` | 1x speed |
| Click 2x button / `2` | 2x speed |
| Click 3x button / `3` | 3x speed |

`Space` is a toggle: pressing it pauses (sets speed to 0); pressing again resumes to the last non-zero speed used (default 1x). The active button's pressed state is mirrored via `HUD._sync_speed_buttons()` so the button row stays in sync with keyboard input.

## Execution flow
1. `HUD._ready()` connects each speed button's `pressed` signal to `_on_speed_pressed.bind(index)`.
2. Player clicks a button or presses `1`/`2`/`3`/`Space` → `_on_speed_pressed(index)` (keys go through `_try_set_speed` / `_try_toggle_pause`).
3. `_on_speed_pressed` records the speed in `_last_speed` (non-zero only), sets `GameState.speed_multiplier = SPEEDS[index]`, syncs the button row, and emits `EventBus.speed_changed`.
4. `speed_multiplier` setter calls `_apply_time_scale()` → `Engine.time_scale` updated.
5. All Timers, `_process` delta, and animations scale automatically.

## Interaction with panel-pause
When a modal panel opens it calls `GameState.pause_for_panel()` (ref-counted `_panel_pause_count`). `_apply_time_scale()` forces `Engine.time_scale = 0.0` while any panel is open, regardless of `speed_multiplier`. On the last panel close, `unpause_for_panel()` restores `Engine.time_scale` to `speed_multiplier`.

The keyboard speed shortcuts (`1`/`2`/`3`/`Space`) are ignored while a panel is open (`HUD._try_set_speed` / `_try_toggle_pause` early-return on `GameState.is_panel_paused`), so a key press never fights the panel-pause system. The on-screen buttons are not guarded the same way, but panels overlay them.

Note: `GameState.is_paused` is a separate combat flag and does **not** affect `Engine.time_scale`.

### Panel-pause refcount must stay balanced (freeze hazard)
Because the panel-pause system is a plain integer refcount, **every `pause_for_panel()` must be matched by exactly one `unpause_for_panel()`**. If a panel's `open()` calls `pause_for_panel()` twice without two matching closes, `_panel_pause_count` drifts above zero permanently: `Engine.time_scale` is pinned to `0.0` and the speed/pause shortcuts silently no-op (they early-return on `is_panel_paused`). Symptom: the game looks frozen and "adjusting speed does nothing."

The drift historically came from `open()` functions that paused unconditionally without checking `visible`:
- `EnemyInspectPanel.open()`, `AltarPanel.open()`, `TileRulePanel.open()` — `Main._on_tile_clicked` calls these without a visibility check, and `Tile._input` only blocks clicks on non-enemy tiles while a panel is open, so clicking an enemy tile while its inspect panel was already open pushed the refcount a second time.
- `ServiceActivatePopup.open()` / `open_discard()` — `ServiceBar._refresh` is signal-driven (`service_bar_changed`); a single auction settlement awarding multiple services to a full bar re-invoked `open_discard()` while the popup was already open.

**Fix (applied):** every `open()` is now idempotent — it captures `was_visible := visible` up front and only calls `pause_for_panel()` + `show()` on the hidden→visible transition. Re-opening an already-visible panel just refreshes its content. Any new modal panel added to the project must follow the same pattern (or use `toggle()`-style paired open/close). `unpause_for_panel()` clamps with `max(0, …)` so a stray extra close cannot push the count negative, but there is no clamp against over-pausing — the `open()` guard is the protection.

## Dependencies
- `GameState` (autoload)
- `EventBus` (autoload, `speed_changed` signal)
- No dependency on Player, CombatSystem, or any other system
