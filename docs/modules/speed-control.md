# Speed Control

## Responsibility
Lets the player choose game speed: Pause / 1x / 2x / 3x. Affects all game systems uniformly via `Engine.time_scale`.

## Key pieces
- `GameState.speed_multiplier` (float, 0/1/2/3) — player's chosen speed; setter calls `_apply_time_scale()`
- `GameState._apply_time_scale()` — single writer for `Engine.time_scale`; formula: `0.0 if is_paused else speed_multiplier`
- `SpeedControl` (HBoxContainer, `src/ui/SpeedControl.gd`) — self-contained UI; creates 4 toggle buttons in `_ready()`, calls `GameState.speed_multiplier = v` on press
- `scenes/ui/hud.tscn > SpeedControl` — direct child of HUD CanvasLayer, anchored top-left (0,0)-(160,36)

## Execution flow
1. `SpeedControl._ready()` creates buttons + ButtonGroup; sets 1x active by default
2. Player clicks a button -> `_on_speed_pressed(index)` -> `GameState.speed_multiplier = SPEEDS[index]`
3. `speed_multiplier` setter calls `_apply_time_scale()` -> `Engine.time_scale` updated
4. All Timers, `_process` delta, and animations scale automatically

## Interaction with panel-pause
When a panel opens, `GameLoop` sets `GameState.is_paused = true`.
`is_paused` setter calls `_apply_time_scale()` -> `Engine.time_scale = 0`.
On panel close, `is_paused = false` -> `Engine.time_scale` restores to `speed_multiplier`.
SpeedControl button state is unaffected by panel pause.

## Dependencies
- `GameState` (autoload)
- No dependency on Player, CombatSystem, or any other system