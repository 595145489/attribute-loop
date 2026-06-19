# BGM Integration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add background music to AttributeLoop — explore and combat BGM, randomly selected per session, with 1-second crossfade transitions driven by EventBus signals.

**Architecture:** New `AudioManager` autoload (`src/autoloads/AudioManager.gd`) with two child `AudioStreamPlayer` nodes. A three-state machine (EXPLORE/COMBAT/SILENT) responds to EventBus signals and uses Tween for crossfade. Registered in `project.godot`.

**Tech Stack:** Godot 4 GDScript, AudioStreamMP3, AudioStreamPlayer, Tween, GUT for unit tests.

---

### Task 1: Write failing unit tests for AudioManager

**Files:**
- Create: `tests/unit/test_audio_manager.gd`

AudioManager is an autoload that doesn't exist yet — the test will fail because `AudioManager` is not defined. We test state transitions only (no audio playback in headless).

- [ ] **Step 1: Write the failing test**

Create `tests/unit/test_audio_manager.gd`:

```gdscript
extends GutTest

func test_audio_manager_exists() -> void:
	assert_true(AudioManager != null, "AudioManager autoload should exist")

func test_initial_state_is_explore() -> void:
	assert_eq(AudioManager.state, AudioManager.State.EXPLORE,
		"AudioManager should start in EXPLORE state")

func test_player_hit_transitions_to_combat() -> void:
	AudioManager.state = AudioManager.State.EXPLORE
	EventBus.player_hit.emit(10)
	assert_eq(AudioManager.state, AudioManager.State.COMBAT,
		"player_hit should transition to COMBAT")

func test_combat_resolved_transitions_to_explore() -> void:
	AudioManager.state = AudioManager.State.COMBAT
	EventBus.combat_resolved.emit()
	assert_eq(AudioManager.state, AudioManager.State.EXPLORE,
		"combat_resolved should transition to EXPLORE")

func test_player_died_transitions_to_silent() -> void:
	AudioManager.state = AudioManager.State.EXPLORE
	EventBus.player_died.emit()
	assert_eq(AudioManager.state, AudioManager.State.SILENT,
		"player_died should transition to SILENT")

func test_game_won_transitions_to_silent() -> void:
	AudioManager.state = AudioManager.State.EXPLORE
	EventBus.game_won.emit()
	assert_eq(AudioManager.state, AudioManager.State.SILENT,
		"game_won should transition to SILENT")
```

- [ ] **Step 2: Run tests to confirm they fail**

```powershell
cd "S:/attribute-loop"
powershell -NoProfile -File scripts/self-test.ps1
```

Expected: FAIL — `AudioManager` not found / identifier unknown.

---

### Task 2: Create AudioManager autoload

**Files:**
- Create: `src/autoloads/AudioManager.gd`
- Modify: `project.godot` (add autoload entry)

- [ ] **Step 1: Create `src/autoloads/AudioManager.gd`**

```gdscript
extends Node

enum State { EXPLORE, COMBAT, SILENT }

var state: State = State.EXPLORE

const EXPLORE_TRACKS := [
	preload("res://resources/audio/bgm/explore_1.mp3"),
	preload("res://resources/audio/bgm/explore_2.mp3"),
]
const COMBAT_TRACKS := [
	preload("res://resources/audio/bgm/combat_1.mp3"),
	preload("res://resources/audio/bgm/combat_2.mp3"),
]

const DEFAULT_VOLUME_DB := -6.0
const SILENT_VOLUME_DB := -80.0
const FADE_DURATION := 1.0

var _explore_player: AudioStreamPlayer
var _combat_player: AudioStreamPlayer
var _tween: Tween

func _ready() -> void:
	_explore_player = AudioStreamPlayer.new()
	_explore_player.stream = EXPLORE_TRACKS[randi() % EXPLORE_TRACKS.size()]
	_explore_player.volume_db = DEFAULT_VOLUME_DB
	_explore_player.autoplay = false
	add_child(_explore_player)

	_combat_player = AudioStreamPlayer.new()
	_combat_player.stream = COMBAT_TRACKS[randi() % COMBAT_TRACKS.size()]
	_combat_player.volume_db = SILENT_VOLUME_DB
	_combat_player.autoplay = false
	add_child(_combat_player)

	EventBus.player_hit.connect(_on_player_hit)
	EventBus.combat_resolved.connect(_on_combat_resolved)
	EventBus.player_died.connect(_on_player_died)
	EventBus.game_won.connect(_on_game_won)

	_explore_player.play()
	state = State.EXPLORE

func _on_player_hit(_damage: int) -> void:
	if state == State.COMBAT:
		return
	state = State.COMBAT
	_crossfade(_explore_player, _combat_player)

func _on_combat_resolved() -> void:
	if state != State.COMBAT:
		return
	state = State.EXPLORE
	_crossfade(_combat_player, _explore_player)

func _on_player_died() -> void:
	state = State.SILENT
	_fade_out_all()

func _on_game_won() -> void:
	state = State.SILENT
	_fade_out_all()

func _crossfade(from: AudioStreamPlayer, to: AudioStreamPlayer) -> void:
	if not to.playing:
		to.play()
	if _tween:
		_tween.kill()
	_tween = create_tween().set_parallel(true)
	_tween.tween_property(from, "volume_db", SILENT_VOLUME_DB, FADE_DURATION)
	_tween.tween_property(to, "volume_db", DEFAULT_VOLUME_DB, FADE_DURATION)
	_tween.chain().tween_callback(from.stop)

func _fade_out_all() -> void:
	if _tween:
		_tween.kill()
	_tween = create_tween().set_parallel(true)
	_tween.tween_property(_explore_player, "volume_db", SILENT_VOLUME_DB, FADE_DURATION)
	_tween.tween_property(_combat_player, "volume_db", SILENT_VOLUME_DB, FADE_DURATION)
	_tween.chain().tween_callback(_explore_player.stop)
	_tween.chain().tween_callback(_combat_player.stop)
```

- [ ] **Step 2: Register AudioManager in `project.godot`**

Open `project.godot`. Find the `[autoload]` section (currently ends with `TutorialManager`). Add one line after it:

```ini
AudioManager="*res://src/autoloads/AudioManager.gd"
```

The section should now look like:

```ini
[autoload]

Log="*res://src/autoloads/Log.gd"
TestHelper="*res://src/autoloads/TestHelper.gd"
EventBus="*res://src/autoloads/EventBus.gd"
GameState="*res://src/autoloads/GameState.gd"
DataTables="*res://src/autoloads/DataTables.gd"
Tooltip="*res://src/autoloads/Tooltip.gd"
TutorialManager="*res://src/autoloads/TutorialManager.gd"
AudioManager="*res://src/autoloads/AudioManager.gd"
```

- [ ] **Step 3: Run tests — expect most to pass, state tests may still fail**

```powershell
cd "S:/attribute-loop"
powershell -NoProfile -File scripts/self-test.ps1
```

The `test_audio_manager_exists` test should now pass. State transition tests may fail because signal connections fire `_crossfade` which calls `to.play()` — in headless the AudioStreamPlayer exists but `playing` state might differ. If state transitions pass, continue. If not, see Task 3.

---

### Task 3: Fix state tests — decouple state from playback

**Files:**
- Modify: `src/autoloads/AudioManager.gd`

The GUT tests emit EventBus signals directly and check `state`. If `_crossfade`/`_fade_out_all` crash in headless (no audio device), we need to guard audio calls.

- [ ] **Step 1: Add headless guard to audio calls**

In `src/autoloads/AudioManager.gd`, update `_crossfade` and `_fade_out_all` to guard playback:

```gdscript
func _crossfade(from: AudioStreamPlayer, to: AudioStreamPlayer) -> void:
	if OS.has_feature("headless"):
		return
	if not to.playing:
		to.play()
	if _tween:
		_tween.kill()
	_tween = create_tween().set_parallel(true)
	_tween.tween_property(from, "volume_db", SILENT_VOLUME_DB, FADE_DURATION)
	_tween.tween_property(to, "volume_db", DEFAULT_VOLUME_DB, FADE_DURATION)
	_tween.chain().tween_callback(from.stop)

func _fade_out_all() -> void:
	if OS.has_feature("headless"):
		return
	if _tween:
		_tween.kill()
	_tween = create_tween().set_parallel(true)
	_tween.tween_property(_explore_player, "volume_db", SILENT_VOLUME_DB, FADE_DURATION)
	_tween.tween_property(_combat_player, "volume_db", SILENT_VOLUME_DB, FADE_DURATION)
	_tween.chain().tween_callback(_explore_player.stop)
	_tween.chain().tween_callback(_combat_player.stop)
```

- [ ] **Step 2: Run tests to confirm all pass**

```powershell
cd "S:/attribute-loop"
powershell -NoProfile -File scripts/self-test.ps1
```

Expected: All tests pass including the 6 new audio_manager tests.

- [ ] **Step 3: Commit**

```bash
git add src/autoloads/AudioManager.gd project.godot tests/unit/test_audio_manager.gd
git commit -m "feat: add AudioManager autoload with explore/combat BGM and crossfade"
```

---

### Task 4: Write module documentation

**Files:**
- Create: `docs/modules/audio-manager.md`

- [ ] **Step 1: Write the module doc**

Create `docs/modules/audio-manager.md`:

```markdown
# AudioManager

Autoload responsible for background music playback and state-driven track switching.

## Responsibilities

- Randomly selects one explore track and one combat track at game start (fixed for the session)
- Maintains a three-state machine: EXPLORE → COMBAT → SILENT
- Crossfades between tracks on state transitions (1-second Tween fade)
- Stops music on game-over or game-won

## Key Classes / Nodes

- `AudioManager` (autoload, `src/autoloads/AudioManager.gd`)
  - `state: State` — current playback state (EXPLORE / COMBAT / SILENT)
  - `_explore_player: AudioStreamPlayer` — plays explore BGM
  - `_combat_player: AudioStreamPlayer` — plays combat BGM

## Execution Flow

1. `_ready`: create players, randomly assign streams, connect EventBus signals, start explore BGM
2. `EventBus.player_hit` → `_on_player_hit` → crossfade to combat
3. `EventBus.combat_resolved` → `_on_combat_resolved` → crossfade back to explore
4. `EventBus.player_died` / `game_won` → `_fade_out_all` → silence

## Dependencies

- `EventBus` — listens to `player_hit`, `combat_resolved`, `player_died`, `game_won`
- Audio assets: `resources/audio/bgm/explore_1.mp3`, `explore_2.mp3`, `combat_1.mp3`, `combat_2.mp3`
```

- [ ] **Step 2: Commit**

```bash
git add docs/modules/audio-manager.md
git commit -m "docs: add AudioManager module documentation"
```
