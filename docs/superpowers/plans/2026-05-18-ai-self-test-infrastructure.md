# AI Self-Test Infrastructure Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Set up the complete AI self-test infrastructure so that after every implementation task, AI automatically runs syntax checks, GUT unit tests, and a screenshot integration test before writing module docs and notifying the user for acceptance.

**Architecture:** Three-layer pipeline: (1) PostToolUse hook triggers `scripts/syntax-check.ps1` for per-file `godot --headless --check-only` on every `.gd` write; (2) AI runs `scripts/self-test.ps1` which executes GUT headlessly and writes `tests/results.json`; (3) AI uses MCP to play the game, `TestHelper.gd` autoload saves a screenshot then quits. All layers must pass before AI writes module docs and notifies the user.

**Tech Stack:** Godot 4.6.2, GUT 9.6.0, GDScript, PowerShell, Claude Code hooks, Godot MCP (`mcp__godot__execute_editor_script`)

---

## File Map

| File | Action | Responsibility |
|------|--------|---------------|
| `addons/godot_mcp/*.gd` | Copy from source | MCP bridge between Claude Code and Godot editor |
| `addons/gut/` | Download + extract | GUT unit test framework |
| `project.godot` | Modify | Enable both addons; register TestHelper autoload |
| `tests/unit/.gitkeep` | Create | Placeholder for unit test files |
| `tests/screenshots/.gitkeep` | Create | Placeholder for integration screenshots |
| `scripts/syntax-check.ps1` | Create | Per-file syntax checker called by PostToolUse hook |
| `scripts/self-test.ps1` | Create | Headless GUT runner; writes pass/fail exit code |
| `.claude/settings.json` | Create | Project-level hook config + GODOT_EXE env var |
| `src/autoloads/TestHelper.gd` | Create | Screenshot autoload activated by sentinel file |
| `CLAUDE.md` | Create | Self-test protocol AI must follow before reporting completion |
| `docs/modules/.gitkeep` | Create | Placeholder for per-module documentation |

---

## Task 1: Copy godot_mcp Addon Files

**Files:**
- Modify: `addons/godot_mcp/` (currently empty subdirs)

- [ ] **Step 1: Copy all source files from the reference installation**

```powershell
$src = "C:\Users\happyelements\Godot-MCP\addons\godot_mcp"
$dst = "S:\attribute-loop\addons\godot_mcp"
Copy-Item "$src\plugin.cfg" $dst -Force
Copy-Item "$src\command_handler.gd" $dst -Force
Copy-Item "$src\command_handler.gd.uid" $dst -Force
Copy-Item "$src\mcp_server.gd" $dst -Force
Copy-Item "$src\mcp_server.gd.uid" $dst -Force
Copy-Item "$src\websocket_server.gd" $dst -Force
Copy-Item "$src\websocket_server.gd.uid" $dst -Force
Copy-Item "$src\commands\*" "$dst\commands\" -Force
Copy-Item "$src\ui\*" "$dst\ui\" -Force
Copy-Item "$src\utils\*" "$dst\utils\" -Force
```

- [ ] **Step 2: Verify plugin.cfg is present**

```powershell
Get-Content "S:\attribute-loop\addons\godot_mcp\plugin.cfg"
```

Expected output: a file containing `[plugin]`, `name=`, `script=` fields.

- [ ] **Step 3: Commit**

```bash
cd "S:/attribute-loop"
git add addons/godot_mcp/
git commit -m "chore: complete godot_mcp addon installation"
```

---

## Task 2: Download and Install GUT v9.6.0

**Files:**
- Create: `addons/gut/` (full addon directory)

- [ ] **Step 1: Download GUT zip**

```powershell
Invoke-WebRequest `
  -Uri "https://github.com/bitwes/Gut/releases/download/v9.6.0/GUT-9.6.0.zip" `
  -OutFile "S:\attribute-loop\gut-temp.zip"
```

- [ ] **Step 2: Extract and copy into project**

```powershell
Expand-Archive -Path "S:\attribute-loop\gut-temp.zip" -DestinationPath "S:\attribute-loop\gut-temp" -Force
Copy-Item -Path "S:\attribute-loop\gut-temp\addons\gut" -Destination "S:\attribute-loop\addons\gut" -Recurse -Force
Remove-Item -Recurse -Force "S:\attribute-loop\gut-temp", "S:\attribute-loop\gut-temp.zip"
```

- [ ] **Step 3: Verify GUT structure**

```powershell
Test-Path "S:\attribute-loop\addons\gut\plugin.cfg"
Test-Path "S:\attribute-loop\addons\gut\gut_cmdln.gd"
```

Both must output `True`.

- [ ] **Step 4: Commit**

```bash
git add addons/gut/
git commit -m "chore: install GUT v9.6.0 unit test framework"
```

---

## Task 3: Enable Addons and Register TestHelper in project.godot

**Files:**
- Modify: `project.godot`

- [ ] **Step 1: Add editor_plugins and autoload sections**

Open `S:\attribute-loop\project.godot`. The current file ends with the `[rendering]` section. Append the following two sections at the end:

```ini
[autoload]

TestHelper="*res://src/autoloads/TestHelper.gd"

[editor_plugins]

enabled=PackedStringArray("res://addons/godot_mcp/plugin.cfg", "res://addons/gut/plugin.cfg")
```

- [ ] **Step 2: Verify the file parses correctly**

Open the file and confirm it reads:

```ini
[autoload]

TestHelper="*res://src/autoloads/TestHelper.gd"

[editor_plugins]

enabled=PackedStringArray("res://addons/godot_mcp/plugin.cfg", "res://addons/gut/plugin.cfg")
```

- [ ] **Step 3: Commit**

```bash
git add project.godot
git commit -m "chore: enable godot_mcp and gut addons, register TestHelper autoload"
```

---

## Task 4: Create Directory Structure

**Files:**
- Create: `tests/unit/.gitkeep`
- Create: `tests/screenshots/.gitkeep`
- Create: `docs/modules/.gitkeep`
- Create: `scripts/` (directory)

- [ ] **Step 1: Create directories and placeholder files**

```bash
mkdir -p "S:/attribute-loop/tests/unit"
mkdir -p "S:/attribute-loop/tests/screenshots"
mkdir -p "S:/attribute-loop/docs/modules"
mkdir -p "S:/attribute-loop/scripts"
touch "S:/attribute-loop/tests/unit/.gitkeep"
touch "S:/attribute-loop/tests/screenshots/.gitkeep"
touch "S:/attribute-loop/docs/modules/.gitkeep"
```

- [ ] **Step 2: Commit**

```bash
git add tests/ docs/modules/ scripts/
git commit -m "chore: create tests/, docs/modules/, scripts/ directory structure"
```

---

## Task 5: Create .claude/settings.json (Project-Level Hook Config)

**Files:**
- Create: `.claude/settings.json`

Note: `.claude/` is in `.gitignore` — this file is local-only, which is correct since it contains a machine-specific path.

- [ ] **Step 1: Create the settings file**

Create `S:\attribute-loop\.claude\settings.json`:

```json
{
  "env": {
    "GODOT_EXE": "S:\\Godot_v4.6.2-stable_win64_temp\\Godot_v4.6.2-stable_win64.exe"
  },
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "powershell -NoProfile -File scripts/syntax-check.ps1"
          }
        ]
      }
    ]
  }
}
```

- [ ] **Step 2: Verify the file exists (not committed, that's expected)**

```bash
ls "S:/attribute-loop/.claude/"
```

Expected: `settings.json` listed.

---

## Task 6: Create scripts/syntax-check.ps1

**Files:**
- Create: `scripts/syntax-check.ps1`

This script is called by the PostToolUse hook after every Write or Edit. It reads the tool event from stdin, extracts the file path, and runs `godot --headless --check-only` on `.gd` files only.

- [ ] **Step 1: Create the script**

Create `S:\attribute-loop\scripts\syntax-check.ps1`:

```powershell
# Read hook event from stdin
$inputJson = $input | Out-String
if ([string]::IsNullOrWhiteSpace($inputJson)) { exit 0 }

try {
    $event = $inputJson | ConvertFrom-Json
} catch {
    exit 0
}

# Extract file path from tool input
$filePath = $event.tool_input.file_path
if ([string]::IsNullOrWhiteSpace($filePath)) { exit 0 }

# Only check .gd files
if (-not $filePath.EndsWith(".gd")) { exit 0 }

# Resolve to absolute path
$absPath = $filePath
if (-not [System.IO.Path]::IsPathRooted($absPath)) {
    $absPath = Join-Path (Get-Location) $filePath
}

# Verify file exists
if (-not (Test-Path $absPath)) { exit 0 }

# Run syntax check
$godotExe = $env:GODOT_EXE
if ([string]::IsNullOrWhiteSpace($godotExe)) {
    Write-Error "GODOT_EXE environment variable not set"
    exit 1
}

$result = & $godotExe --headless --check-only $absPath 2>&1
$exitCode = $LASTEXITCODE

if ($exitCode -ne 0) {
    Write-Error "GDScript syntax error in $filePath :`n$result"
    exit 1
}

exit 0
```

- [ ] **Step 2: Verify the script runs without error on a non-.gd file**

```bash
echo '{"tool_name":"Write","tool_input":{"file_path":"README.md"},"tool_result":"ok"}' | powershell -NoProfile -File scripts/syntax-check.ps1
echo "Exit code: $?"
```

Expected: exit code 0, no output.

- [ ] **Step 3: Commit**

```bash
git add scripts/syntax-check.ps1
git commit -m "chore: add PostToolUse syntax-check hook script"
```

---

## Task 7: Create scripts/self-test.ps1

**Files:**
- Create: `scripts/self-test.ps1`

This script runs GUT headlessly and reports results. The AI calls this via Bash after implementation. Visual screenshot testing is handled separately by the AI via MCP.

- [ ] **Step 1: Create the script**

Create `S:\attribute-loop\scripts\self-test.ps1`:

```powershell
param(
    [string]$TestDir = "res://tests/unit/"
)

$godotExe = $env:GODOT_EXE
if ([string]::IsNullOrWhiteSpace($godotExe)) {
    Write-Error "GODOT_EXE environment variable not set. Check .claude/settings.json."
    exit 1
}

$projectPath = "S:\attribute-loop"
$resultsFile = Join-Path $projectPath "tests\results.json"

# Remove old results
if (Test-Path $resultsFile) { Remove-Item $resultsFile -Force }

Write-Host "Running GUT unit tests..."

# Run GUT headlessly
$gutArgs = @(
    "--headless",
    "--path", $projectPath,
    "-s", "res://addons/gut/gut_cmdln.gd",
    "-gdir=$TestDir",
    "-gjson=res://tests/results.json",
    "-gpo",
    "-gexit"
)

& $godotExe @gutArgs 2>&1 | Write-Host
$exitCode = $LASTEXITCODE

# Check if results file was written
if (-not (Test-Path $resultsFile)) {
    Write-Error "GUT did not produce results.json — test runner may have crashed"
    exit 1
}

# Parse results
$results = Get-Content $resultsFile | ConvertFrom-Json
$total = $results.totals.tests
$passing = $results.totals.passing
$failing = $results.totals.failing
$errors = $results.totals.errors

Write-Host "`nResults: $passing/$total passed, $failing failed, $errors errors"

if ($failing -gt 0 -or $errors -gt 0) {
    Write-Error "Self-test FAILED: $failing failures, $errors errors"
    exit 1
}

if ($total -eq 0) {
    Write-Host "No tests found in $TestDir — pass (no tests yet)"
    exit 0
}

Write-Host "All $total tests passed."
exit 0
```

- [ ] **Step 2: Verify the script runs (no tests yet = pass)**

```bash
cd "S:/attribute-loop" && powershell -NoProfile -File scripts/self-test.ps1
```

Expected: "No tests found in res://tests/unit/ — pass (no tests yet)" and exit 0.

If GUT crashes with a rendering error on headless, add `--rendering-driver opengl3` to `$gutArgs`. Check the output and adjust if needed.

- [ ] **Step 3: Commit**

```bash
git add scripts/self-test.ps1
git commit -m "chore: add self-test.ps1 GUT headless runner"
```

---

## Task 8: Create src/autoloads/TestHelper.gd

**Files:**
- Create: `src/autoloads/TestHelper.gd`

This autoload is always registered in project.godot but only activates when `tests/.test_mode` sentinel file exists.

- [ ] **Step 1: Create the directory**

```bash
mkdir -p "S:/attribute-loop/src/autoloads"
```

- [ ] **Step 2: Create TestHelper.gd**

Create `S:\attribute-loop\src\autoloads\TestHelper.gd`:

```gdscript
extends Node

const SENTINEL := "res://tests/.test_mode"
const SCREENSHOT_PATH := "res://tests/screenshots/last_run.png"
const LOG_PATH := "res://tests/screenshots/last_run.log"
const WAIT_SECONDS := 3.0

func _ready() -> void:
	if not FileAccess.file_exists(SENTINEL):
		return
	await get_tree().create_timer(WAIT_SECONDS).timeout
	_capture_and_quit()

func _capture_and_quit() -> void:
	var image := get_viewport().get_texture().get_image()
	image.save_png(SCREENSHOT_PATH)

	var log_file := FileAccess.open(LOG_PATH, FileAccess.WRITE)
	if log_file:
		log_file.store_line("screenshot saved: %s" % SCREENSHOT_PATH)
		log_file.store_line("time: %s" % Time.get_datetime_string_from_system())
		log_file.close()

	get_tree().quit()
```

- [ ] **Step 3: Verify syntax by reading back the file**

Check the file looks correct at `S:\attribute-loop\src\autoloads\TestHelper.gd`.

- [ ] **Step 4: Commit**

```bash
git add src/autoloads/TestHelper.gd
git commit -m "chore: add TestHelper autoload for screenshot-based integration testing"
```

---

## Task 9: Create CLAUDE.md with Self-Test Protocol

**Files:**
- Create: `CLAUDE.md`

- [ ] **Step 1: Create CLAUDE.md at project root**

Create `S:\attribute-loop\CLAUDE.md`:

```markdown
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
If the editor is not open, Layers 2 (MCP GUT) and 3 (screenshot) will fail.
Syntax checking (Layer 1) works without the editor.

## Language

- All code and documentation: English
- Conversation with user: Chinese
```

- [ ] **Step 2: Commit**

```bash
git add CLAUDE.md
git commit -m "chore: add CLAUDE.md with mandatory AI self-test protocol"
```

---

## Task 10: Verify Full Pipeline End-to-End

- [ ] **Step 1: Verify syntax-check hook fires correctly**

Write a test `.gd` file with a deliberate syntax error:

```bash
echo 'extends Node
func broken
  pass' > "S:/attribute-loop/test_syntax_error.gd"
```

Then manually trigger the hook:

```bash
echo '{"tool_name":"Write","tool_input":{"file_path":"S:\\attribute-loop\\test_syntax_error.gd"},"tool_result":"ok"}' | powershell -NoProfile -File scripts/syntax-check.ps1
echo "Exit code: $?"
```

Expected: exit code 1, error message about syntax error.

Clean up:
```bash
rm "S:/attribute-loop/test_syntax_error.gd"
```

- [ ] **Step 2: Verify self-test.ps1 runs end-to-end**

```bash
cd "S:/attribute-loop" && powershell -NoProfile -File scripts/self-test.ps1
```

Expected: exit 0 with "No tests found" message (no unit tests exist yet for Phase 1).

- [ ] **Step 3: Verify TestHelper sentinel detection (requires Godot editor open)**

Create sentinel file, play game, check screenshot appears:

```bash
touch "S:/attribute-loop/tests/.test_mode"
```

Use MCP `execute_editor_script`:
```gdscript
var plugin = Engine.get_meta("GodotMCPPlugin")
plugin.get_editor_interface().play_main_scene()
```

Wait up to 20 seconds, then check:
```bash
ls "S:/attribute-loop/tests/screenshots/"
```

Expected: `last_run.png` and `last_run.log` present.

Clean up:
```bash
rm "S:/attribute-loop/tests/.test_mode"
```

Note: Step 3 requires an actual playable scene. If `main.tscn` doesn't exist yet, skip this step and mark it as "to be verified at Phase 1 completion."

- [ ] **Step 4: Final commit**

```bash
git add -A
git commit -m "chore: verify AI self-test infrastructure complete"
```

---

## Self-Review Notes

- Task 3 registers `TestHelper` as autoload before `TestHelper.gd` is created (Task 8). The Godot editor will show a missing-script warning until Task 8 is done — this is fine, the warning clears when the file is created.
- `scripts/self-test.ps1` uses GUT's `-gjson` flag which writes JSON to a path. If GUT 9.6.0 uses a different flag name, check `addons/gut/gut_cmdln.gd` for the correct flag and update accordingly.
- Task 10 Step 3 depends on a playable `main.tscn` existing. This infrastructure is being set up before Phase 1 code exists, so skip the screenshot step and validate it at Phase 1 completion.
