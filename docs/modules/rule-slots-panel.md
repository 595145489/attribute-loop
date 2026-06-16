# Rule Slots Panel

## Responsibility
Displays the player's active rule slots (trigger + effect pairs) as a persistent right-side panel during gameplay. Supports 2–5 slots dynamically as the player purchases expansions.

## Key Nodes / Scripts
- `scenes/ui/rule_slots_panel.tscn` / `src/ui/RuleSlotsPanel.gd` — right-side container; rebuilds children on `rule_slots_changed`
- `scenes/ui/rule_slot_entry.tscn` / `src/ui/RuleSlotEntry.gd` — single slot row; `refresh(slot: Dictionary)` updates labels

## Signals Consumed
- `EventBus.rule_slots_changed` — triggers full rebuild (slot added via shop)
- `EventBus.rule_equipped` — triggers full rebuild (component equipped/removed)
- `EventBus.rule_fired` — triggers refresh of all entry values

## Execution Flow
1. `RuleSlotsPanel._ready()` connects signals and calls `_rebuild()`
2. `_rebuild()` clears `SlotsContainer`, then instantiates one `RuleSlotEntry` per `GameState.rule_slots` entry
3. `_process()` calls `_refresh_all()` every frame to keep trigger counts and stack values current
4. On slot purchase, `AuctionManager` appends to `GameState.rule_slots` and emits `rule_slots_changed`

## Dependencies
- `GameState.rule_slots` — source of truth for slot data
- `DataTables.player.dmg_base` — used by 蓄能 effect value calculation
- `GameState.amplify_stacks / amplify_max_stacks` — used by 强化 effect display
