# Combat Feed Module

## Responsibility

`CombatFeed` is the real-time, always-visible scrolling combat stream displayed in
the empty center of the map loop. It surfaces the live damage flow between player
and monsters so combat is legible at a glance, without opening the log.

It complements two other UI elements:

- **`LogPanel`** — the complete, retained, toggable history (right side).
- **`FloatLabel`** — a single transient buff popup (center-top).

`CombatFeed` is the third leg: a live, ephemeral, fading stream of damage events.

## Key Nodes / Class

- `src/ui/CombatFeed.gd` (`class_name CombatFeed extends Control`)
- `scenes/ui/combat_feed.tscn` — root `Panel` (semi-transparent, `mouse_filter =
  IGNORE`) with an `Entries` `VBoxContainer` (bottom-aligned).
- Instanced into `scenes/ui/hud.tscn` as a child of the HUD `CanvasLayer`,
  anchored to screen center over the track-loop interior.

### Exposed surface

- `_add_entry(text: String, color: Color)` — push a new fading entry (used by the
  signal handlers; also called directly by tests).

### Constants

- `MAX_VISIBLE = 6` — hard cap on simultaneous entries.
- `LIFETIME = 3.5s` — entry holds ~55% then fades alpha to 0 over the remaining
  ~45%, then frees itself.

## Signals Subscribed (via `EventBus`)

| Signal | Entry | Color |
|--------|-------|-------|
| `player_hit(dmg)` | `你 −{dmg}` | red |
| `player_attacked(dmg)` | `敌 −{dmg}` | blue |
| `rule_fired` (灼烧伤害 / 侵蚀伤害 / 蓄能释放 / 受击 / 低血 / 击杀) | compact damage text | per-type |
| `enemy_killed(enemy)` | `击杀 {id}` | orange |
| `combat_enrage(stacks)` | `激怒 ×{n}` | orange-red |

Buff-stacking effects (治愈 / 护盾 / 强化 / 增伤 / 蓄能 / 反射 / 减伤 / 吸血 / 满血 /
规则触发 / 经过) are intentionally excluded — they remain in `FloatLabel` and
`LogPanel` to keep the feed focused on damage.

## Execution Flow

1. An EventBus damage signal fires from `CombatSystem` (or rule engine).
2. `CombatFeed`'s handler formats a short string + color and calls `_add_entry`.
3. `_add_entry` creates a `Label`, appends it to the bottom of `Entries`, trims
   the oldest entry if the count exceeds `MAX_VISIBLE` (killing its fade tween),
   then starts a fade tween for the new entry.
4. After `LIFETIME`, the tween fades the label's alpha to 0 and frees it; the
   VBox reflows so remaining entries shift down.

## Dependencies

- `EventBus` (autoload) — signal source.
- `Enemy` — type used in the `enemy_killed` handler signature.
- Hosted by `HUD` (`scenes/ui/hud.tscn`).

## Tests

- `tests/unit/test_combat_feed.gd` — entry text, color, `MAX_VISIBLE` cap
  enforcement, and exclusion of buff-only `rule_fired` effects.
- `tests/screenshot_combat_feed.gd` / `.tscn` — visual render check.
