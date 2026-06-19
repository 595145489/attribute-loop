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
- `EventBus.combat_enrage(stacks)` — shows enrage float text
- `EventBus.speed_changed` — emitted after any speed change (button or key)

## Keyboard Shortcuts (`_input`)

HUD is the central keyboard dispatcher during gameplay. All keys are consumed via `get_viewport().set_input_as_handled()`.

| Key | Action |
|-----|--------|
| `C` | Toggle CharacterPanel |
| `A` | Toggle AltarPanel |
| `L` | Toggle LogPanel |
| `M` | Toggle AuctionPanel |
| `B` | Toggle InventoryPanel (open and close) |
| `1` / `2` / `3` | Set game speed to 1x / 2x / 3x |
| `Space` | Toggle pause (resume to last speed) |

Speed keys (`1`/`2`/`3`/`Space`) are ignored while a modal panel is open (`GameState.is_panel_paused`). `B` (inventory toggle) is intentionally **not** guarded, so it can open the bag from the strip panel's `[B] 打开背包` button context. Because HUD is a default-pausable CanvasLayer, none of these fire during a phase transition (`get_tree().paused = true`); the `PhaseTransition` overlay owns input then. See [speed-control.md](speed-control.md).

## Dependencies

- `GameState` — hp, hp_max, loops_completed, current_phase, inventory, rule_slots, speed_multiplier, is_panel_paused
- `DataTables` — phase name lookup, inventory_cap
- `EventBus` — rule_fired, combat_enrage, speed_changed signals
- `InventoryPanel` — toggled by BagButton or `B` key (both via `HUD._on_bag_pressed`)
