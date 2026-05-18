# AI Self-Test Infrastructure — Design Spec

**Date:** 2026-05-18
**Status:** Approved

---

## Overview

This spec defines the testing infrastructure that allows AI to fully verify its own work — syntax check, unit tests, visual screenshot verification, and module documentation — before notifying the user for acceptance. The user only needs to keep the Godot editor open while work is in progress.

---

## Architecture

Three-layer verification pipeline:

```
Layer 1: Syntax Check (automatic, per-file)
  PostToolUse hook → scripts/syntax-check.ps1 → godot --headless --check-only

Layer 2: GUT Unit Tests (AI-triggered after implementation)
  scripts/self-test.ps1 → MCP execute_editor_script plays GUT scene
  → GUT writes tests/results.json → AI reads pass/fail

Layer 3: Visual Integration Test (AI-triggered after unit tests pass)
  MCP plays main.tscn → TestHelper.gd saves screenshot to tests/screenshots/
  → AI reads image via Read tool → visual verification
```

After all three layers pass, AI writes module documentation and notifies the user.

---

## Directory Structure

```
S:\attribute-loop\
├── addons\
│   ├── gut\                        ← GUT v9.6.0 (downloaded by AI during setup)
│   └── godot_mcp\                  ← Copied from C:\Users\happyelements\Godot-MCP\addons\godot_mcp\
├── tests\
│   ├── unit\                       ← One test file per system
│   │   ├── test_combat.gd
│   │   ├── test_rule_engine.gd
│   │   └── test_economy.gd
│   ├── screenshots\                ← Visual integration test output
│   └── results.json                ← GUT writes here; AI reads to check pass/fail
├── scripts\
│   ├── syntax-check.ps1            ← Called by PostToolUse hook
│   └── self-test.ps1               ← Full self-test entry point (GUT + screenshot)
├── src\
│   └── autoloads\
│       └── TestHelper.gd           ← Screenshot + log writer; active only in test mode
└── docs\
    └── modules\                    ← AI writes one .md per implemented module
```

---

## Component Details

### `.claude/settings.json` (project-level, not committed)

```json
{
  "env": {
    "GODOT_EXE": "S:\\Godot_v4.6.2-stable_win64_temp\\Godot_v4.6.2-stable_win64.exe"
  },
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [{
          "type": "command",
          "command": "powershell -File scripts/syntax-check.ps1"
        }]
      }
    ]
  }
}
```

- `GODOT_EXE` is the only value to update when upgrading Godot versions.
- Hook is project-level only (`.claude/` is already in `.gitignore`).

### `scripts/syntax-check.ps1`

- Reads the written file path from stdin (JSON from Claude Code hook event).
- Skips non-`.gd` files silently.
- Runs `$env:GODOT_EXE --headless --check-only <file>`.
- Exits with code 1 and writes to stderr on error — Claude Code surfaces this to AI immediately.

### `scripts/self-test.ps1`

Handles the headless CLI portion of self-testing. Steps:
1. Run `$env:GODOT_EXE --headless --path . --script addons/gut/gut_cmdln.gd -gdir=res://tests/unit/ -gjson -gpo` to execute GUT tests.
2. Parse GUT's JSON output for pass/fail counts and failure details.
3. Exit 0 if all pass, exit 1 with failure details if any test failed.

Note: The visual integration test (screenshot) is NOT handled by this script. It is performed directly by the AI using MCP tool calls after `self-test.ps1` passes.

### `src/autoloads/TestHelper.gd`

Active only when the sentinel file `res://tests/.test_mode` exists on disk.

Activation sequence (managed by AI via MCP + Bash):
1. AI creates `tests/.test_mode` via Write tool before playing.
2. `TestHelper._ready()` checks if the file exists; if yes, enters test mode.
3. Waits 3 seconds, captures `get_viewport().get_texture().get_image()`, saves to `res://tests/screenshots/last_run.png`.
4. Writes `res://tests/screenshots/last_run.log`.
5. Calls `get_tree().quit()`.
6. AI deletes `tests/.test_mode` after the screenshot is read.

### GUT test files (`tests/unit/test_*.gd`)

- Written by AI alongside each implementation.
- Cover: pure logic only (combat formulas, rule trigger evaluation, economy calculations, phase advancement math).
- Do not test UI rendering — that is covered by screenshot layer.
- Follow GUT 9.x conventions: `extends GutTest`, use `assert_eq`, `assert_true`, etc.

### `docs/modules/<module>.md`

Written by AI after every implementation passes all three test layers.

Contents:
- What this module is responsible for.
- Key classes, nodes, and signals it exposes.
- Rough execution flow in plain language.
- Dependencies on other modules.

---

## AI Completion Protocol

Encoded in `CLAUDE.md`. AI must follow this sequence before reporting any implementation task as done:

```
1. Implement code
2. Confirm PostToolUse syntax checks passed (no errors in hook output)
3. Run: powershell -File scripts/self-test.ps1
4. If self-test fails → fix → re-run; do NOT notify user
5. If self-test passes → write docs/modules/<module>.md
6. Notify user for acceptance
```

---

## One-Time Setup (performed by AI during Phase 1 kickoff)

| Task | Action |
|------|--------|
| Copy `godot_mcp` files | From `C:\Users\happyelements\Godot-MCP\addons\godot_mcp\` to project `addons\godot_mcp\` |
| Install GUT v9.6.0 | Download zip from GitHub, extract to `addons\gut\` |
| Enable addons | Add both to `project.godot` `[editor_plugins]` section |
| Create `tests/` structure | `unit/`, `screenshots/` subdirectories |
| Create `scripts/` | `syntax-check.ps1`, `self-test.ps1` |
| Create `.claude/settings.json` | Hook config + `GODOT_EXE` path |
| Create `TestHelper.gd` | Autoload for screenshot capture |
| Update `CLAUDE.md` | Add self-test protocol |

---

## Runtime Requirement

Godot editor must be open and the AttributeLoop project loaded whenever AI is working on implementation. The MCP communicates with the editor via WebSocket — if the editor is closed, Layer 2 and Layer 3 cannot run.
