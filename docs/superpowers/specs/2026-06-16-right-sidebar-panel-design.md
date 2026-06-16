# Right Sidebar Panel — Design Spec

**Date:** 2026-06-16

## Problem

The floating `RuleSlotsPanel` (anchored to screen right, vertically centered) and the `ServiceBar` (anchored top-left) both have layout problems:

- RuleSlotsPanel overlaps the game world — tiles, enemies, and the player character when walking near the right side
- ServiceBar sits at the top with no visual styling, completely inconsistent with the rest of the HUD
- Neither element feels like it belongs to the UI system

## Solution

Add a **fixed-width right sidebar panel** (160px) that contains both the rule slots and service bar in a single, unified column. The game viewport shrinks to occupy the remaining horizontal space. Nothing floats over the game world.

## Layout

```
┌─────────────────────────────┬────────────────┐
│                             │  装备规则       │
│                             │  ┌──────────┐  │
│     Game Viewport           │  │ 槽1 T·E  │  │
│     (fills remaining        │  │ 槽2 T·E  │  │
│      horizontal space)      │  └──────────┘  │
│                             │  ─────────────  │
│                             │  服务栏         │
│                             │  [词条改写]     │
│                             │  [迅捷折纸]     │
│                             │  [— 空槽]       │
├─────────────────────────────┴────────────────┤
│  Bottom HUD (full width, unchanged)           │
└───────────────────────────────────────────────┘
```

## Sidebar Spec

- **Width:** 160px, fixed
- **Background:** opaque dark parchment (`#12100e` or match `RuleSlotsPanel` existing StyleBoxFlat)
- **Border:** left edge, same gold tone as existing `RuleSlotsPanel` border (`rgba(150,115,50,0.4)`)
- **Layout:** VBoxContainer, top-to-bottom
  - Section: "装备规则" — mirrors existing `RuleSlotsPanel` content
  - HSeparator divider
  - Section: "服务栏" — mirrors existing `ServiceBar` content, vertical layout

## Rule Slots Section

- Title label: "装备规则", small caps style, gold color
- Each slot: dark card (`StyleBoxFlat`), shows trigger name + count badge + effect name
- Empty slots: italic placeholder text
- Clicking a slot: same behavior as current RuleSlotsPanel (opens InventoryPanel to equip)

## Service Bar Section

- Title label: "服务栏", small caps style, purple tone
- Each service: button with icon + name, full width, vertically stacked
- Empty slots: disabled, shows "—"
- Clicking: same behavior as current ServiceBar (opens ServiceActivatePopup)
- Icons: use existing emoji or placeholder until art assets are ready

## What Gets Removed / Moved

| Current | Change |
|---|---|
| `RuleSlotsPanel` float anchor in `hud.tscn` | Removed; content moved into sidebar |
| `ServiceBar` at `offset_top = 36` in `main.tscn` | Removed; content moved into sidebar |
| `ServiceBar` as HBoxContainer | Changed to VBoxContainer |

## Files to Change

1. `scenes/main.tscn` — add `RightSidebarPanel` node; remove `ServiceBar` top anchor; wire up setup call
2. `scenes/ui/hud.tscn` — remove `RuleSlotsPanel` float positioning
3. `scenes/ui/rule_slots_panel.tscn` — adjust min width to fit 160px column
4. `scenes/ui/service_bar.tscn` — change root to VBoxContainer
5. `src/ui/ServiceBar.gd` — update button layout (full width, icon+text)
6. `src/ui/HUD.gd` — remove RuleSlotsPanel anchor setup if any

## What Does NOT Change

- Bottom HUD (`BottomBar`) — untouched
- `InventoryPanel` — untouched
- `ServiceActivatePopup` — untouched
- All game logic, signals, GameState — untouched
- Visual style of individual rule slot / service button content — same as before, just repositioned

## Success Criteria

- No UI element floats over the game world during normal play
- Rule slot trigger counts and effect values are always visible
- Service bar buttons are reachable without opening any panel
- Visual style is consistent with existing HUD (same StyleBoxFlat family)
- All existing functionality (equip, service activate, tooltips) works identically
