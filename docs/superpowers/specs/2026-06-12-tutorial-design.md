# Tutorial System Design

**Date:** 2026-06-12  
**Status:** Approved

## Overview

A sandbox tutorial run accessible from the main menu. Targets players with existing roguelike experience who only need to learn AttributeLoop's unique mechanics. The tutorial is a fully controlled, separate run with a fixed map and no RNG — playable any time from the main menu, independent of normal runs.

## Target Player

Experienced roguelike players. They understand HP, gold, combat, and inventory management. They do not need to be taught genre conventions — only AttributeLoop's unique systems: the circular track, component stripping, rule slots, tile rules, the altar, the auction house, and effect deletion.

## Entry Point

The main menu has two buttons: **Tutorial** and **New Game**. They are independent. Completing the tutorial does not start a new game; it returns the player to the main menu. The tutorial is always replayable.

## Architecture

### New Files

| File | Role |
|------|------|
| `src/autoloads/TutorialManager.gd` | Autoload. Drives tutorial flow: tracks current step, triggers highlights, listens for completion signals. |
| `src/tutorial/TutorialOverlay.gd` | CanvasLayer (layer 20). Renders the darkened overlay, gold highlight border, text box, and input interception. |
| `scenes/tutorial/tutorial_overlay.tscn` | Scene for TutorialOverlay. |
| `src/tutorial/tutorial_steps.gd` | Static step definitions — an array of dictionaries, one per tutorial step. |
| `scenes/tutorial/tutorial_main.tscn` | Tutorial scene. Based on main.tscn but with a fixed map, pre-placed enemies, and no RNG. |

### Modified Files

| File | Change |
|------|--------|
| Main menu scene | Add Tutorial button that loads `tutorial_main.tscn`. |
| `src/autoloads/GameState.gd` | Add `is_tutorial: bool` flag so systems can suppress game-over and pressure mechanics during tutorial. |

### Data Flow

```
Main menu "Tutorial" button
  → change_scene_to_file(tutorial_main.tscn)
  → TutorialManager._ready() loads tutorial_steps, enters step[0]
  → Notifies TutorialOverlay: highlight NodePath + display text
  → TutorialOverlay: intercepts input outside highlighted region, draws overlay
  → Player completes action in highlighted region
  → EventBus emits completion signal
  → TutorialManager.advance_step() → enters step[n+1]
  → Repeat until all steps complete
  → Show completion screen → return to main menu
```

### Step Data Structure

Each tutorial step is a dictionary:

```gdscript
{
  "id": "strip_component",
  "text": "击败敌人后，选择一个组件剥取",
  "highlight_node": "%StripPanel",   # NodePath or null; null = no highlight, text centered
  "complete_signal": "component_stripped",  # EventBus signal name
  "block_outside_input": true        # whether to intercept input outside highlight
}
```

When `highlight_node` is null, TutorialOverlay shows no darkened overlay and renders the text box centered on screen. This is used for "observe" steps where the player watches rather than acts (e.g., step 1). `block_outside_input` must also be false for observe steps.

## Tutorial Overlay

`TutorialOverlay` is a `CanvasLayer` at layer 20 (above all game UI). It:

- Renders a full-screen dark overlay (alpha 0.72)
- Draws a gold border + glow around the highlighted node's screen rect
- Positions a text box adjacent to the highlighted node (auto top/bottom based on space)
- Text box shows the step instruction and step number (e.g., "步骤 3 / 9")
- When `block_outside_input = true`: captures all `_input` events and only forwards them to the game if the click falls within the highlighted node's rect

There is no skip button. The player can press ESC at any time to exit to the main menu (with a confirmation dialog).

## Step Sequence

| # | Mechanic | Highlight Target | Completion Signal |
|---|---------|-----------------|------------------|
| 1 | Circular track | null (observe step — text centered, no input block) | `loop_completed` |
| 2 | Combat | First enemy | `enemy_died` |
| 3 | Component stripping | `StripPanel` | `component_stripped` |
| 4 | Rule slots | HUD rule slot area | `rule_equipped` |
| 5 | Effect deletion | InventoryPanel delete area | `component_deleted` |
| 6 | Tile rules | A specific highlighted track tile | `tile_rule_set` |
| 7 | Auction house | Auction tile + `AuctionPanel` | `auction_completed` |
| 8 | Altar | Altar tile + `AltarPanel` | `altar_component_added` |
| 9 | Completion | — | Player clicks confirm |

Steps follow the natural game flow: walk → fight → strip → equip → delete → tile → auction → altar.

## Sandbox Scenario Setup

The tutorial scene overrides normal gameplay with a fixed, controlled environment:

- **3 enemies** pre-placed at fixed tile positions (not spawned by GameLoop)
- **Auction house** fixed at tile 8
- **Starting gold:** 150g (enough to participate in auction)
- **Enemy drops:** deterministic components (no RNG) — chosen to give the player something useful for each subsequent step
- **Altar requirement:** reduced to 1 component (just enough to demonstrate the mechanic)
- **No pressure mechanic:** `GameState.is_tutorial = true` suppresses the pressure meter and disables game-over

## EventBus Signals Required

The following signals must exist on EventBus for completion detection. Most already exist; new ones are marked:

| Signal | Status |
|--------|--------|
| `loop_completed` | Exists |
| `enemy_died` | Exists |
| `component_stripped` | Exists |
| `rule_equipped` | Exists |
| `component_deleted` | **New** |
| `tile_rule_set` | Exists |
| `auction_completed` | Exists |
| `altar_component_added` | Exists |

## Out of Scope

- Localization (tutorial text is Chinese only for now)
- Animated characters or voiced narration
- Tutorial progress tracking across sessions (no "resume tutorial" — always restarts from step 1)
- Hints during normal gameplay (this system is tutorial-only)
