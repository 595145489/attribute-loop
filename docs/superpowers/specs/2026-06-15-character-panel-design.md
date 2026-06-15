# Character Panel — Design Spec

**Date:** 2026-06-15
**Status:** Approved

## Overview

A player-facing attribute panel that shows all current combat stats in one place. Opened on demand via keyboard shortcut; does not persist on screen during gameplay.

## Entry Point

- A new **「角色[C]」** button is added to the HUD bottom bar, immediately to the right of the existing 「背包[B]」 button.
- Pressing **C** toggles the panel open/closed.
- The panel is mutually exclusive with the inventory panel: opening one closes the other.

## Panel Behaviour

- Positioned as a centered overlay (same layer as `inventory_panel`).
- On open: reads all stat values once from `GameState` and `GameState.player_data`, then displays them. No per-frame `_process` updates.
- On close: hides immediately.

## Layout — Grouped List

Two sections separated by a section label:

### 生存 (Survival)

| Label | Source | Format |
|-------|--------|--------|
| 生命 | `GameState.hp` / `GameState.hp_max` | `8500 / 10000` |
| 护盾 | `GameState.shield` | `200` — or `—` (grey) when 0 |
| 减伤 | `GameState.slow_stacks` | `×2 层` — or `—` (grey) when 0 |
| 反射 | `GameState.pending_reflect_ratio` | `20%` — or `—` (grey) when 0 |

### 攻击 (Offense)

| Label | Source | Format |
|-------|--------|--------|
| 攻击力 | `GameState.player_data.dmg_base` | `1000` |
| 攻击间隔 | `GameState.player_data.attack_interval` | `0.8 秒` |
| 强化 | `GameState.amplify_stacks` | `×3 层` — or `—` (grey) when 0 |
| 吸血 | `GameState.lifesteal_ratio` | `15%` — or `—` (grey) when 0 |

Zero-value effect stats (shield, slow_stacks, pending_reflect_ratio, amplify_stacks, lifesteal_ratio) render as a grey `—` to avoid confusing new players with a column of zeros.

## Tooltips

Each stat row shows a one-line tooltip on mouse hover, reusing the existing `Tooltip` autoload (same pattern as `EnemyInspectPanel`).

| Stat | Tooltip text |
|------|-------------|
| 生命 | 当前生命 / 上限，归零即游戏结束 |
| 护盾 | 先于生命值承受伤害，耗尽后不再生效 |
| 减伤 | 每层降低你对敌人造成的伤害 |
| 反射 | 将受到伤害的一定比例反弹给攻击者 |
| 攻击力 | 每次攻击造成的基础伤害 |
| 攻击间隔 | 两次攻击之间的间隔（秒），越低越快 |
| 强化 | 每层提升你对敌人造成的伤害 |
| 吸血 | 每次造成伤害时按比例回复生命 |

Implementation: each stat row node listens to `mouse_entered` / `mouse_exited` and calls `Tooltip.show(text, global_position)` / `Tooltip.hide()`.

## Files Changed / Added

| File | Change |
|------|--------|
| `scenes/ui/character_panel.tscn` | New — panel scene (PanelContainer) |
| `src/ui/CharacterPanel.gd` | New — panel script |
| `scenes/ui/hud.tscn` | Add 「角色」 button next to 「背包」 |
| `src/ui/HUD.gd` | Wire C key, mutual-exclusion logic with inventory panel |

## Out of Scope

- Per-frame live updates (panel is opened at a decision point, not during active combat)
- Move speed (not meaningful to display)
- Critical hit rate (not yet implemented)
- Mobile / gamepad support
