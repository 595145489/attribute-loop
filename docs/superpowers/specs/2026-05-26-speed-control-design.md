# Speed Control Design

**Date:** 2026-05-26  
**Status:** Approved

## Overview

A persistent speed-control panel in the top-left corner of the HUD lets the player choose between four time scales: Pause / 1× / 2× / 3×. All game systems (player movement, combat timers) are affected uniformly via `Engine.time_scale`.

## Architecture

### Data Layer — GameState

Add `speed_multiplier: float = 1.0` to `GameState.gd`. Valid values: `0.0, 1.0, 2.0, 3.0`.

Add `_apply_time_scale()` called whenever `speed_multiplier` or `is_paused` changes:

```gdscript
func _apply_time_scale() -> void:
    Engine.time_scale = 0.0 if is_paused else speed_multiplier
```

Both pause concepts (system panel pause vs player speed choice) funnel into a single `Engine.time_scale` write. No changes to Player.gd or CombatSystem.gd — existing `is_paused` guards remain harmless with delta=0, and Timer nodes stop automatically when time_scale=0.

### UI Component — SpeedControl

New `src/ui/SpeedControl.gd` + scene with four `Button` nodes in an `HBoxContainer`, labels: `⏸ · 1× · 2× · 3×`.

- `toggle_mode = true` on each button, shared `ButtonGroup` so only one is active at a time
- Default active: `1×`
- On press: `GameState.speed_multiplier = SPEEDS[index]; GameState._apply_time_scale()`
- Active button styled with a distinct color via `theme_override`

```gdscript
const SPEEDS := [0.0, 1.0, 2.0, 3.0]
```

### HUD Integration

In `HUD.tscn`, add an `HBoxContainer` anchored to the top-left and instance the SpeedControl scene into it. No changes to `HUD.gd` logic.

## Edge Cases

| Situation | Behavior |
|---|---|
| Panel opens (altar / bag / drop) | `is_paused = true` → `time_scale = 0`; SpeedControl button state unchanged; restores player's chosen speed on close |
| Player selects Pause, then opens panel | Both want time_scale=0; no conflict |
| Game Over | GameLoop stops combat; speed multiplier has no effect on GAME_OVER screen |
| HUD tweens (floating rule text) | Animate faster at 2×/3× — intentional, matches game pace |

## Files Changed

| File | Change |
|---|---|
| `src/autoloads/GameState.gd` | Add `speed_multiplier`, update `is_paused` setter, add `_apply_time_scale()` |
| `src/ui/SpeedControl.gd` | New script |
| `src/ui/SpeedControl.tscn` | New scene (4 buttons in HBoxContainer) |
| `scenes/ui/HUD.tscn` | Add SpeedControl instance to top-left |

No changes to Player.gd, CombatSystem.gd, or any other system.
