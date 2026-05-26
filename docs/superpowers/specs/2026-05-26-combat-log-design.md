# Combat Log Design

**Date:** 2026-05-26
**Status:** Approved

---

## 1. Overview

A toggleable right-side log panel accessible via a "日志" button in the HUD bottom bar. Displays the last N combat events (configurable) so the player can review what happened during a run.

---

## 2. Configuration

**GameConfig.gd** — new field:

```
combat_log_max_entries: int = 50
```

Set in `data/game_config.tres`. When the entry count exceeds this limit, the oldest entry is removed before adding the new one.

---

## 3. Log Entry Format

Each entry is a `Dictionary`:

```gdscript
{ "text": String, "color": Color }
```

| EventBus Signal | Condition | Display Text | Color |
|-----------------|-----------|--------------|-------|
| `player_hit(damage)` | always | `受击 −{damage} HP` | `Color.RED` |
| `rule_fired(slot, effect_id, value)` | always | `规则: {effect_id} +{value:.1f}` | `Color.GREEN` |
| `enemy_killed(enemy)` | always | `击杀 {enemy.enemy_id}` | `Color.YELLOW` |
| `gold_changed(new_amount)` | only when gold increased | `+{delta} 金` | `Color(1.0, 0.8, 0.0)` |
| `phase_changed(n)` | always | `→ Phase {n}` | `Color.CYAN` |
| `verdict_loop_entered` | always | `进入裁决圈` | `Color(0.7, 0.4, 1.0)` |

Gold delta is computed by comparing `new_amount` against a tracked `_last_gold` field. Entries are only added when `new_amount > _last_gold`.

---

## 4. LogPanel

### Files
- `src/ui/LogPanel.gd`
- `scenes/ui/log_panel.tscn`

### Scene Structure

```
LogPanel (PanelContainer)
  VBox (VBoxContainer)
    Header (HBoxContainer)
      Title (Label — "战斗日志")
      CloseBtn (Button — "×")
    Divider (HSeparator)
    Scroll (ScrollContainer)
      Entries (VBoxContainer)
```

### Positioning

- Anchored to right edge: `anchor_left = 1`, `anchor_right = 1`, `anchor_top = 0`, `anchor_bottom = 1`
- `offset_right = 0` (right edge flush with viewport right)
- **Hidden state:** `offset_left = 0` (panel's left edge = viewport right = fully off-screen)
- **Visible state:** `offset_left = -280` (panel 280 px wide, fully visible)
- Slide animation: Tween on `offset_left` from 0 → -280 (open) and -280 → 0 (close), duration 0.15 s

### LogPanel.gd API

```gdscript
func toggle() -> void      # open if closed, close if open
func _add_entry(text: String, color: Color) -> void  # append + trim + autoscroll
```

`_ready()` connects to all six EventBus signals listed above.

---

## 5. HUD Integration

### hud.tscn changes
- Add `LogPanel` instance (from `scenes/ui/log_panel.tscn`) as child of the HUD CanvasLayer root
- Add `LogButton` (Button, text "日志") to `BottomBar/HContent` — rightmost item

### HUD.gd changes (minimal)
```gdscript
@onready var log_panel: LogPanel = $LogPanel
@onready var log_btn: Button = $BottomBar/HContent/LogButton

# in _ready():
log_btn.pressed.connect(log_panel.toggle)
```

LogPanel is fully self-contained; HUD only wires the button.

---

## 6. File Summary

| File | Change |
|------|--------|
| `src/resources/GameConfig.gd` | Add `combat_log_max_entries: int = 50` |
| `data/game_config.tres` | Set `combat_log_max_entries = 50` |
| `src/ui/LogPanel.gd` | New — log data + display logic |
| `scenes/ui/log_panel.tscn` | New — panel scene |
| `scenes/ui/hud.tscn` | Add LogPanel instance + LogButton |
| `src/ui/HUD.gd` | Wire log_btn → log_panel.toggle() |

---

## 7. Out of Scope

- Persisting log across game restarts
- Filtering by event type
- Timestamps per entry (loop count is sufficient context)
- Search / copy functionality
