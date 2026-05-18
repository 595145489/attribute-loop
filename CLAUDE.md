# AttributeLoop — Claude Code Instructions

## Self-Test Protocol (MANDATORY)

After completing any implementation task, you MUST follow this sequence before reporting work as done:

### Step 1 — Confirm syntax checks passed
Check that the PostToolUse hook produced no errors for the files you wrote.
If any syntax error was reported, fix it before continuing.

### Step 2 — Run headless unit tests
```bash
cd "S:/attribute-loop" && powershell -NoProfile -File scripts/self-test.ps1
```
If any test fails: fix the code, re-run. Do NOT notify the user until this passes.

### Step 3 — Visual integration test (requires Godot editor open)
1. Create sentinel file: write an empty file to `tests/.test_mode`
2. Use MCP `execute_editor_script` to play main scene:
```gdscript
var plugin = Engine.get_meta("GodotMCPPlugin")
plugin.get_editor_interface().play_main_scene()
```
3. Poll every 2 seconds until `tests/screenshots/last_run.png` appears (timeout 20s)
4. Read the screenshot with the Read tool and verify:
   - Game window rendered (not black/blank)
   - No obvious error dialogs
5. Delete `tests/.test_mode`

If the screenshot shows errors or is blank: stop the game, investigate, fix, re-run.

### Step 4 — Write module documentation
After all three layers pass, write `docs/modules/<module-name>.md` covering:
- What this module is responsible for
- Key classes, nodes, signals it exposes
- Rough execution flow in plain language
- Dependencies on other modules

### Step 5 — Notify the user
Only after Steps 1–4 are complete, notify the user for acceptance.

---

## Project Context

- **Game:** AttributeLoop — a Godot 4 roguelike (see `docs/superpowers/specs/2026-05-16-gdd-design.md`)
- **Architecture:** See `docs/superpowers/specs/2026-05-18-project-architecture.md`
- **Phase Roadmap:** 5 phases; build one phase at a time; each ends in a playable build
- **Current phase:** Phase 1 — 可行走的世界

## Godot Editor Requirement

The Godot MCP requires the Godot editor to be open with this project loaded.
If the editor is not open, Layer 3 (screenshot) will fail — skip it and note this to the user.

## Language

- All code and documentation: English
- Conversation with user: Chinese
