# TestHelper

## Responsibility

Autoload node that enables screenshot-based integration testing. When a sentinel file is present at startup, it waits briefly for the scene to render, captures a screenshot, logs metadata, then quits — allowing headless CI or AI-driven test runs to verify the rendered output without human interaction.

## Key Classes / Nodes / Signals

| Symbol | Type | Description |
|--------|------|-------------|
| `TestHelper` | `Node` (Autoload) | Registered as `TestHelper` in Project Settings |
| `SENTINEL` | `const String` | `res://tests/.test_mode` — presence triggers capture |
| `SCREENSHOT_PATH` | `const String` | `res://tests/screenshots/last_run.png` |
| `LOG_PATH` | `const String` | `res://tests/screenshots/last_run.log` |
| `WAIT_SECONDS` | `const float` | `3.0` — seconds to wait before capture |

No signals are emitted; the node quits the engine after capture.

## Execution Flow

1. `_ready()` — checks for sentinel file; returns immediately if absent (normal gameplay).
2. If sentinel exists: awaits a 3-second timer so the first frame fully renders.
3. `_capture_and_quit()` — grabs the viewport texture, saves it as PNG, writes a log with timestamp, then calls `get_tree().quit()`.

The calling process (AI or CI) then reads `last_run.png` to verify the game rendered correctly.

## Dependencies

- No runtime dependencies beyond Godot's built-in `FileAccess` and `Viewport` APIs.
- The `scripts/self-test.ps1` runner uses GUT (`addons/gut/`) for unit tests separately; TestHelper handles visual integration only.
- Sentinel file is created/deleted by the test orchestrator (CLAUDE.md Step 3 protocol or CI scripts).
