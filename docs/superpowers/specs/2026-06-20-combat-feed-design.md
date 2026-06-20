# Combat Feed — Real-Time Scrolling Combat Stream

**Date:** 2026-06-20
**Status:** Approved (autonomous execution)
**Topic:** Surface damage events in real time at the map center; retain the log as history.

## Problem

Player ↔ monster damage currently appears only inside the `LogPanel` (a toggable
right-side history panel) and as single transient `FloatLabel` buff pops. Damage
flow is not legible at a glance — the player has to open the log to see what just
happened. The rectangular track loop leaves a large empty interior in the middle
of the map that is unused.

## Goal

Add a always-visible, real-time scrolling combat feed in the center of the map.
The feed shows the live damage stream; the existing `LogPanel` remains the full
retained history.

## Design

### Component: `CombatFeed`

A new UI control instanced into the HUD `CanvasLayer`, anchored over the track
loop's interior (screen center ≈ (490, 330), sized ~320×200 so it stays inside
the loop without covering the track).

- **Root:** `Control` (semi-transparent `StyleBoxFlat` background, no header, no
  scrollbar, `mouse_filter = MOUSE_FILTER_IGNORE` so it never blocks input).
- **Entries:** `VBoxContainer` (bottom-aligned, newest at bottom). Each entry is a
  `Label`.
- **Lifecycle:** Each entry fades its alpha to 0 over `LIFETIME` (~3.5s) via a
  tween, then frees itself; the VBox reflows so older entries shift up. A hard cap
  of `MAX_VISIBLE` (6) bounds height — when exceeded the oldest entry is freed
  immediately.

### Signals subscribed (damage-focused)

To avoid duplicating `FloatLabel` (buff popups) and to keep the feed legible, the
feed surfaces damage-dealing / damage-taking events plus key combat beats:

| Signal | Entry text | Color |
|--------|-----------|-------|
| `player_hit(dmg)` | `你 −{dmg}` | red `(0.85, 0.18, 0.18)` |
| `player_attacked(dmg)` | `敌 −{dmg}` | blue `(0.30, 0.55, 0.95)` |
| `rule_fired` damage effects (灼烧伤害 / 侵蚀伤害 / 蓄能释放 / 受击 / 低血 / 击杀) | compact damage text | per-type |
| `enemy_killed(enemy)` | `击杀 {id}` | orange `(0.90, 0.55, 0.18)` |
| `combat_enrage(stacks)` | `激怒 ×{n}` | orange-red `(0.95, 0.35, 0.12)` |

Pure buff-stacking effects (治愈 / 护盾 / 强化 / 增伤 / 蓄能 / 反射 / 减伤 / 吸血 /
满血 / 规则触发 / 经过) are **excluded** from the feed — they remain in
`FloatLabel` + `LogPanel`.

### Relationship to existing UI

- `LogPanel`: unchanged. Still the complete, scrollable, toggleable history.
- `FloatLabel`: unchanged. Still the single-line transient buff popup.
- `CombatFeed`: new. Live, ephemeral, always-on damage stream in the map center.

### Files

- `src/ui/CombatFeed.gd` — script.
- `scenes/ui/combat_feed.tscn` — scene (Control + VBox).
- `scenes/ui/hud.tscn` — instance `CombatFeed` as a child of the HUD root.
- `tests/unit/test_combat_feed.gd` — GUT LOG test.
- `tests/screenshot_combat_feed.gd` + `.tscn` — screenshot test.

### Constants (hardcoded in `CombatFeed.gd`)

- `MAX_VISIBLE := 6`
- `LIFETIME := 3.5` (seconds before fade-out completes)

## Testing

- **LOG test:** emit `player_hit` / `player_attacked` → assert entries created with
  expected text/color; emit > `MAX_VISIBLE` → assert cap enforced (oldest freed).
- **Screenshot test:** instantiate `CombatFeed`, emit a few signals, capture;
  visual assertions: entries rendered in the center region, correct colors, feed
  box does not overlap the track perimeter.

## Out of scope

- Config-driven cap/lifetime (hardcoded for now).
- Showing buff-stacking events in the feed.
- Changes to `LogPanel` or `FloatLabel`.
