# HUD Bottom Bar & Starting Tile Spawn Fix

**Date:** 2026-05-22

---

## Overview

Two independent changes:
1. Redesign the HUD from a vertical stack into a full-width pill-style bottom bar with real-time rule progress.
2. Fix enemy spawning to exclude the starting tile (index 0), and add one tile to compensate.

---

## 1. HUD Bottom Bar Redesign

### Current State

`hud.tscn` contains a `VBoxContainer` anchored to the bottom-left with five children stacked vertically: HPLabel, LoopsLabel, PhaseLabel, RulesLabel, BagButton. This reads as two disconnected blocks rather than a unified UI strip.

### Target Layout

Replace the `VBoxContainer` with a full-width `HBoxContainer` anchored to the bottom edge of the screen (left=0, right=1, bottom=1). Bar height ~44px. Background: near-opaque dark (`#08081880`), top border `#336`.

Items from left to right:

| Element | Style | Content |
|---|---|---|
| HP pill | Red (`#a33` border, `#2a0a0a` bg) | `❤ {hp} / {hp_max}` |
| 圈数 pill | Dark blue (`#446` border) | `圈 × {loops}` |
| 阶段 pill | Green (`#474` border) | `阶段{n}·{name}` |
| Rule slot 1 panel | Blue (`#447` border), `size_flags_h = EXPAND` | Two-line: T row + E row |
| Rule slot 2 panel | Same | Same |
| 背包 button | Right-aligned, `#55a` border | `背包 [B] {count}/{cap}` |

**Rule panel (two-line layout):**
- **T row:** `T:` label + trigger display_name + `{trigger_count}/{trigger_value}` + thin horizontal ProgressBar (min=0, max=`trigger_value`, value=`trigger_count`)
- **E row:** `E:` label + effect display_name + formatted value (`+{n}` for 治愈, `{n}%` for 反射)
- When slot is empty: single centered label `— 空槽 —`

**FloatLabel:** keep at screen center-upper area, unchanged.

### Implementation Scope

- Rewrite `scenes/ui/hud.tscn`: swap VBoxContainer → HBoxContainer with pill children. Rule panels are `PanelContainer` > `VBoxContainer` > two `HBoxContainer` rows each.
- Update `src/ui/HUD.gd`:
  - Update all `@onready` paths to match new node tree.
  - Replace `_build_rules_summary()` (String) with `_update_rule_panel(i, panel)` that writes directly into each panel's child labels and sets ProgressBar value.
  - `_process` calls `_update_rule_panel` for each slot index.

No other files change.

---

## 2. Starting Tile Spawn Fix

### Problem

`GameLoop._pick_tile_indices(count, total)` builds a pool from `range(total)` = `[0, 1, ..., 11]`. Tile index 0 is the player's starting position. Enemies can currently be spawned there, which is wrong — the player should never encounter combat the moment the game starts.

### Fix

**`src/systems/GameLoop.gd` — `_pick_tile_indices`:**

```
Before: var pool = range(total)
After:  var pool = range(1, total)   # exclude index 0 (starting tile)
```

This makes 12 tiles yield an 11-tile spawn pool, reducing effective encounters.

**`src/Main.gd` — `_build_tiles`:**

```
Before: for i in 12:
After:  for i in 13:
```

13 total tiles → indices 0–12 → spawn pool `range(1, 13)` = 12 spawnable tiles, same as original intent.

The `tile_index` assignment (`tile.tile_index = i`) and all downstream logic are unaffected.

---

## Test Impact

- `test_game_loop.gd`: add a test asserting `_pick_tile_indices(n, total)` never returns 0.
- Existing spawn count tests remain valid (they test count ranges, not indices).

---

## Non-goals

- No changes to combat logic, phase data, or enemy stats.
- No visual polish to tiles (indices still uniformly styled).
- No HUD animation beyond the existing FloatLabel fade.
