# Difficulty Selection — Design Spec

Date: 2026-06-20
Status: Approved (pending implementation)

## Goal

When the player starts a new game, present a choice between **Easy** and **Hard** difficulty after clicking "开始游戏". Easy pre-configures the player's loadout and a subset of tiles so newcomers start with a working build; Hard keeps the current "build it yourself" behavior unchanged.

## Scope

- Easy difficulty differs from Hard **only** in the pre-filled loadout (player rule slots + 5 tile rule slots). Enemy stats, player HP, phase data, and all other numeric balance are identical between the two difficulties.
- The tutorial flow is untouched — the "教程" button still goes straight into the tutorial without a difficulty choice.

## Interaction Flow

Current: `开始游戏` → (tutorial gate) → `GameState.reset()` → load `main.tscn`.

New: `开始游戏` → (tutorial gate) → hide Start/Tutorial buttons, show **DifficultyPanel**:
- Title: "选择难度"
- Hint label (polished wording, intent preserved):
  > 熟悉构筑类玩法的玩家可直接挑战困难；初次接触建议从简单开始，系统会为你预置一套基础构筑。
- Buttons: "简单", "困难", "返回"

Clicking "简单" or "困难" → set `GameState.difficulty` → `GameState.reset()` → load `main.tscn`. "返回" re-shows the Start/Tutorial buttons and hides the panel.

### Test-mode compatibility

`tests/.test_mode` currently auto-triggers `_on_start_pressed()`. Under the new flow, test mode auto-launches directly with **Hard** difficulty (no panel), preserving existing screenshot/unit-test behavior.

## Difficulty State

- `GameState` gains `var difficulty: String = "hard"` (default Hard keeps existing + tutorial behavior unchanged).
- `LoadingScreen` sets `GameState.difficulty` **before** calling `reset()`.

## Easy Preset

### Player rule slots (3 slots for Easy; Hard stays at 2)

1. trigger `受击` + effect `治愈`
2. trigger `治愈` + effect `灼烧`
3. trigger `治愈` + effect `护盾`

`治愈` is a `both`-type component, so it can serve as a trigger (slots 2 and 3).

### Tile rule slots (5 of 12 normal tiles, 1 slot filled each; remaining slots left empty for player expansion)

| tile_index | name        | trigger    | effect |
|-----------:|-------------|------------|--------|
| 1          | 瞭望塔      | 经过       | 增伤   |
| 5          | 兵营        | 经过       | 减伤   |
| 8          | 治愈圣坛    | 经过       | 治愈   |
| 9          | 法师塔      | 经过       | 护盾   |
| 12         | 猎人小屋    | 经过       | 护盾   |

Hard: all player slots and all tile slots empty (current behavior).

## Data & Code Structure

- `DataTables.gd` gains two constants expressed as component **id strings** (resolved to instances at apply time via `get_component(id).duplicate()` to avoid sharing one resource instance across slots):
  - `EASY_PLAYER_SLOTS: Array` — three `{trigger, effect}` id pairs.
  - `EASY_TILE_RULES: Dictionary` — `{tile_index: [{trigger, effect}]}`.
- `GameState.reset()` creates rule slots based on difficulty: **3 for Easy, 2 for Hard**. `difficulty` is set by `LoadingScreen` before `reset()` runs, so the timing is correct. (Note: `GameState._ready()` calls `reset()` once at autoload init with the default "hard", creating 2 slots — harmless, since `LoadingScreen` sets difficulty and re-calls `reset()` before scene load.)
- `Main._build_tiles()` runs after scene load; tiles' `rule_slots` are created in `Tile._ready()` per `TILE_MAX_RULES`. After `_build_tiles()`, if `GameState.difficulty == "easy"`, call a new `apply_easy_preset()` that fills `GameState.rule_slots` and the corresponding `Tile.rule_slots` from the preset.
- `InventoryPanel._build_rule_slots()` is verified/adjusted to render `GameState.rule_slots.size()` slots dynamically (3 for Easy, 2 for Hard) rather than a hardcoded 2.

## UI Implementation

- `loading_screen.tscn`: add a `DifficultyPanel` container (title + hint label + 简单/困难/返回 buttons), hidden by default.
- `LoadingScreen.gd`: `_on_start_pressed` shows the panel (after passing the gate) instead of resetting directly. Add `_on_easy_pressed`, `_on_hard_pressed`, `_on_back_pressed`.

## Testing & Documentation

- Headless unit test for `apply_easy_preset`: Easy fills 3 player slots + 5 tile slots correctly; Hard leaves everything empty.
- Follow CLAUDE.md self-test protocol (syntax → headless tests → screenshot → module doc `docs/modules/difficulty-selection.md`).

## Out of Scope

- No enemy/HP/phase numeric changes for Easy.
- No mid-run difficulty switching.
- No persistence of difficulty choice across runs (chosen fresh each Start).
