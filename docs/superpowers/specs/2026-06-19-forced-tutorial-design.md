# Forced Tutorial (First-Launch) — Design

**Date:** 2026-06-19
**Status:** Approved (brainstormed)
**Phase:** Phase 1 — 可行走的世界

## Goal

Force every new player to play the tutorial on their first launch. After completing (or skipping) the tutorial once, the game remembers and the player may start the game directly on subsequent launches.

## Current Flow (baseline)

- Entry scene: `scenes/ui/loading_screen.tscn` (set in `project.godot`).
- `LoadingScreen.gd` preloads Player/Enemy assets, then shows two buttons:
  - "开始游戏" → `GameState.is_tutorial = false` → load `scenes/main.tscn`.
  - "教程" → `GameState.is_tutorial = true` → load `scenes/main.tscn`.
- `TutorialManager` (autoload) drives a 31-step tutorial via `TutorialOverlay`.
  - Terminal step (`id == "complete"`) calls `_overlay.show_complete()` which shows a "开始冒险 →" button.
  - Pressing that button → `TutorialManager._on_confirm_pressed()` → `stop()` → `change_scene_to_file("res://scenes/ui/loading_screen.tscn")`.
- ESC during tutorial (`TutorialOverlay._input`) returns to loading screen **without** marking completion.
- **No persistence exists.** `GameState` is runtime-only with a `reset()`; nothing is written to disk.

## Requirements

1. First launch (no completion record on disk):
   - Loading screen shows both buttons as today.
   - Clicking "开始游戏" shows a prompt "请先完成教程后再开始游戏" and does **not** leave the loading screen.
   - Clicking "教程" enters the tutorial as today.
   - Tutorial completion (finish all steps **or** skip) writes a completion record to disk, then returns to the loading screen.
2. Subsequent launches (completion record present):
   - Both buttons functional. "开始游戏" enters the game directly. "教程" replays the tutorial (does not clear the record).
3. A "跳过教程" (skip) button is available during the tutorial. Skipping prompts a confirmation dialog; confirming marks the tutorial completed and returns to the loading screen (same exit path as finishing).
4. Persistence failures never block play — worst case the tutorial repeats.

## Architecture (Approach A — dedicated autoload)

### New file: `src/autoloads/OnboardingState.gd`

A small autoload owning onboarding persistence via `ConfigFile` at `user://onboarding.cfg`.

```
extends Node

const CONFIG_PATH := "user://onboarding.cfg"
const SECTION := "onboarding"
const KEY := "tutorial_completed"

var _completed: bool = false

func _ready() -> void:
    _load()

func _load() -> void:
    var cfg := ConfigFile.new()
    var err := cfg.load(CONFIG_PATH)
    if err == OK:
        _completed = cfg.get_value(SECTION, KEY, false) as bool
    else:
        _completed = false   # missing/corrupt file → treat as not completed

func is_tutorial_completed() -> bool:
    return _completed

func mark_tutorial_completed() -> void:
    _completed = true
    var cfg := ConfigFile.new()
    cfg.set_value(SECTION, KEY, true)
    var err := cfg.save(CONFIG_PATH)
    if err != OK:
        push_warning("OnboardingState: failed to save tutorial completion (code %d)" % err)
```

### Registration

Add to `project.godot` `[autoload]`, placed **before** `TutorialManager` (which depends on it):

```
OnboardingState="*res://src/autoloads/OnboardingState.gd"
```

Insert after the `GameState` line so the final order is:
`TestHelper, EventBus, GameState, OnboardingState, DataTables, Tooltip, TutorialManager, AudioManager`.

### Changes to `src/ui/LoadingScreen.gd`

Gate `_on_start_pressed()` on completion, **exempting test mode** so the self-test screenshot flow still auto-starts:

```
func _on_start_pressed() -> void:
    if not OnboardingState.is_tutorial_completed() \
            and not FileAccess.file_exists("res://tests/.test_mode"):
        _show_must_play_tutorial_prompt()
        return
    GameState.reset()
    GameState.is_tutorial = false
    _start_button.disabled = true
    get_tree().change_scene_to_file("res://scenes/main.tscn")
```

`_show_must_play_tutorial_prompt()` creates and pops an `AcceptDialog` (or reuses a node added to the scene) with text "请先完成教程后再开始游戏" and a single OK button. On close, the player remains on the loading screen. `_on_tutorial_pressed()` is unchanged.

### Changes to `src/autoloads/TutorialManager.gd`

Mark completion on the terminal confirm. Refactor the exit path so both "finish" and "skip" share it:

```
func _on_confirm_pressed() -> void:
    _complete_and_exit()

func skip() -> void:
    _complete_and_exit()

func _complete_and_exit() -> void:
    OnboardingState.mark_tutorial_completed()
    stop()
    get_tree().change_scene_to_file("res://scenes/ui/loading_screen.tscn")
```

`stop()` is unchanged. The existing ESC path (`TutorialOverlay._input`) remains an uncompleted exit — no mark, returns to loading screen, player still gated. This is intentional and consistent.

### Changes to `src/tutorial/TutorialOverlay.gd` + `scenes/tutorial/tutorial_overlay.tscn`

Add a secondary "跳过教程" button:
- Node: a `Button` added to `tutorial_overlay.tscn`, positioned top-right of the viewport, low visual weight (transparent/outline style).
- Visible throughout the tutorial (shown in `show_step`, hidden in `hide_overlay`).
- `@onready var _skip_btn: Button = $SkipButton`
- In `_ready`: `_skip_btn.pressed.connect(_on_skip_pressed)`.
- `_on_skip_pressed()`: pop a confirmation `AcceptDialog` "确定跳过教程？跳过后将返回主菜单". On confirm → `TutorialManager.skip()`. On cancel → dismiss, stay.
- `show_complete()` hides `_skip_btn` (terminal screen has its own "开始冒险 →" exit; no need for skip there).

## Data Flow

```
First launch (no record):
  LoadingScreen._ready() → preload → show both buttons
  click "开始游戏" → OnboardingState.is_tutorial_completed()==false (and not test_mode)
                 → AcceptDialog "请先完成教程" → stay
  click "教程"    → GameState.is_tutorial=true → main.tscn → TutorialManager.start()
    ├─ finish last step → show_complete() → press "开始冒险 →"
    │     → _on_confirm_pressed() → _complete_and_exit()
    │       → OnboardingState.mark_tutorial_completed() (writes user://onboarding.cfg)
    │       → stop() → loading_screen.tscn
    └─ press "跳过教程" → confirm dialog → TutorialManager.skip()
          → _complete_and_exit() → mark + stop + loading_screen.tscn

Subsequent launch (record present):
  OnboardingState._ready() loads tutorial_completed=true
  click "开始游戏" → gate passes → normal game
  click "教程"    → replay tutorial (record untouched)
```

## Error Handling

- `OnboardingState._load()` failure (missing/corrupt/permission) → `_completed = false`; no crash.
- `OnboardingState.mark_tutorial_completed()` save failure → `push_warning`, `_completed` still set `true` in memory for this session. Next launch re-runs tutorial. Acceptable.
- `LoadingScreen` gate never blocks test mode (exempted by `tests/.test_mode` check), so CLAUDE.md self-test screenshot flow is unaffected.
- Dialog creation uses Godot built-in `AcceptDialog`/`ConfirmationDialog`; if popup fails to instantiate, the worst case is the button does nothing visible — the player can still click "教程".

## Testing

Headless unit tests via the existing `scripts/self-test.ps1` / gut framework:

1. `OnboardingState`:
   - Fresh temp config (or ensure `user://onboarding.cfg` absent) → `is_tutorial_completed() == false`.
   - After `mark_tutorial_completed()` → `== true`.
   - Re-instantiate the autoload (simulate restart) → still `== true`.
   - Cleanup: delete `user://onboarding.cfg` after the test to avoid polluting the dev machine.
2. `LoadingScreen`:
   - With completion false and **not** test mode → calling `_on_start_pressed()` does **not** change scene (assert scene tree root unchanged / a flag set).
   - With completion true → scene change proceeds.
   - With test mode sentinel present → gate bypassed even if completion false.
3. `TutorialManager`:
   - `_on_confirm_pressed()` calls `OnboardingState.mark_tutorial_completed()` (spy/mock the call) and changes scene.
   - `skip()` calls `mark_tutorial_completed()` and changes scene.

After unit tests pass, run the CLAUDE.md three-layer self-test (syntax hook → headless tests → editor screenshot). For the screenshot layer, test mode bypasses the gate, so the game window should render normally.

## Out of Scope

- General save system / run progress persistence (YAGNI; only the onboarding flag is persisted).
- "Reset onboarding" debug button (can be added later by deleting `user://onboarding.cfg` manually during development).
- Changing ESC behavior during the tutorial.
- Forcing the tutorial again after a major version change.
