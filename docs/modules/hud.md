# HUD Module

## Responsibility

Renders the full-width pill-style bottom bar and the floating rule-fired text. Reads `GameState` every frame to keep all labels current. Bridges the bag button to `InventoryPanel`.

## Node Structure

```
HUD (CanvasLayer)
  BottomBar (PanelContainer) — full-width, anchored to bottom edge
    HContent (HBoxContainer)
      HPPill       → HPLabel          — ❤ hp / hp_max
      LoopPill     → LoopLabel        — 圈 × n
      PhasePill    → PhaseLabel       — 阶段n · name
      RulePanel0   (PanelContainer, EXPAND) → RuleVBox0
        TRow0      — TTag0 | TName0 | TBar0 (ProgressBar) | TCount0
        ERow0      — ETag0 | EName0 | EValue0
      RulePanel1   (same structure, slot index 1)
      BagButton    — right-aligned, opens InventoryPanel
  FloatLabel       — center-upper, fades out on rule_fired
```

## Key Methods

| Method | Purpose |
|---|---|
| `setup(inv_panel)` | Called by Main after scene ready; stores InventoryPanel ref |
| `_process()` | Updates all labels and calls `_update_rule_panel(i)` for each slot |
| `_update_rule_panel(i)` | Writes trigger name/count/bar and effect name/value into slot i's nodes |

## `_update_rule_panel` Flow

1. Read `GameState.rule_slots[i]` for trigger (`t`) and effect (`e`).
2. If either is null → show "— 空槽 —", clear other labels, reset bar.
3. Otherwise: set `TName` = `t.display_name`, `TBar.max_value` = `t.trigger_value`, `TBar.value` = `t.trigger_count`, `TCount` = `count/max`.
4. Format `EValue` by effect id: 治愈 → `+n`, 反射 → `n%`, others → empty.

## Signals Consumed

- `EventBus.rule_fired(slot_idx, effect_id, value)` — triggers FloatLabel fade animation

## Dependencies

- `GameState` — hp, hp_max, loops_completed, current_phase, inventory, rule_slots
- `DataTables` — phase name lookup, inventory_cap
- `EventBus` — rule_fired signal
- `InventoryPanel` — toggled by BagButton / keyboard shortcut handled in InventoryPanel itself
