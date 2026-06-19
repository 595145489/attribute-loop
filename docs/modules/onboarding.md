# Onboarding

## Responsibility

Tracks whether the player has completed the tutorial at least once, persisted to disk so the first-launch forced-tutorial gate only triggers once per machine.

## Key API

- `OnboardingState.is_tutorial_completed() -> bool` — true after the tutorial has been finished or skipped.
- `OnboardingState.mark_tutorial_completed() -> void` — writes `tutorial_completed=true` to `user://onboarding.cfg`.
- `OnboardingState.reload() -> void` — re-reads the config file (used by `_ready` and tests).

## Persistence

A `ConfigFile` at `user://onboarding.cfg`, section `onboarding`, key `tutorial_completed` (bool). Load failure (missing/corrupt/permission) is treated as `false`; save failure emits a `push_warning` but still sets the in-memory flag for the session — persistence failures never block play (worst case the tutorial repeats).

## Flow

1. On boot, `OnboardingState._ready()` calls `reload()`, reading `user://onboarding.cfg`.
2. `LoadingScreen._on_start_pressed()` checks `_should_block_start()`: if the tutorial is not completed and the test-mode sentinel is absent, it shows an `AcceptDialog` ("请先完成教程后再开始游戏") and refuses to start.
3. The player enters the tutorial via the "教程" button. On finish (`TutorialManager._on_confirm_pressed`, the terminal "开始冒险 →" button) or skip (`TutorialManager.skip`, wired to `TutorialOverlay`'s "跳过教程" button via a confirmation dialog), `_complete_and_exit()` calls `OnboardingState.mark_tutorial_completed()`, then returns to the loading screen.
4. On subsequent launches the gate passes and "开始游戏" starts the game directly.

## Components

- `src/autoloads/OnboardingState.gd` — the persistence autoload.
- `src/ui/LoadingScreen.gd` — reads the flag via `_should_block_start()` + `_show_must_play_tutorial_prompt()`.
- `src/autoloads/TutorialManager.gd` — writes the flag via `_mark_completed()` / `_complete_and_exit()` on both finish and skip paths.
- `src/tutorial/TutorialOverlay.gd` + `scenes/tutorial/tutorial_overlay.tscn` — the "跳过教程" button and its confirmation dialog.

## Dependencies

- `LoadingScreen` (reads the flag).
- `TutorialManager` + `TutorialOverlay` (write the flag via the skip/finish paths).
- Config file at `user://onboarding.cfg` (created on first completion).

## Test Mode

The `tests/.test_mode` sentinel exempts the gate (`_should_block_start` returns false when it exists) so the CLAUDE.md self-test screenshot flow auto-starts the game without being blocked.

## Tests

- `tests/unit/test_onboarding_state.gd` — default-false, in-memory flip, persistence across reload, reset-to-false when file deleted.
- `tests/unit/test_loading_screen_gate.gd` — blocks when not completed/not test-mode; passes when completed; passes in test-mode.
- `tests/unit/test_tutorial_manager.gd` — `_mark_completed()` flips `OnboardingState`; `skip()` method exists.
