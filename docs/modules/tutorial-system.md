# Tutorial System

## Responsibility

Guides first-time players through all 8 core mechanics via a 9-step sandbox run. The tutorial reuses the main game scene with a fixed scenario (3 preset enemies, 1-slot altar, 150g starting gold) and shows a translucent overlay with step instructions and a highlighted UI region.

## Key Classes / Nodes / Signals

| Item | Location | Role |
|------|----------|------|
| `TutorialManager` | `src/autoloads/TutorialManager.gd` | Autoload; owns step sequencing and EventBus one-shot bindings |
| `TutorialOverlay` | `src/tutorial/TutorialOverlay.gd` | CanvasLayer (layer 20); 4-panel dark mask + gold highlight border + text box |
| `TutorialSteps` | `src/tutorial/TutorialSteps.gd` | Static class; returns the 9-step Array |
| `GameState.is_tutorial` | `src/autoloads/GameState.gd` | Flag that gates tutorial behaviour across systems |
| `EventBus.tutorial_spawn_enemies` | `src/autoloads/EventBus.gd` | Signal → `Main._spawn_tutorial_enemies()` |
| `EventBus.tutorial_setup_altar` | `src/autoloads/EventBus.gd` | Signal → `Main._setup_tutorial_altar()` |

Completion signals wired to steps: `loop_completed`, `enemy_killed`, `component_stripped`, `rule_equipped`, `component_deleted`, `tile_rule_set`, `auction_settled`, `altar_component_added`.

## Execution Flow

1. **Menu** — player clicks "教程"; `LoadingScreen._on_tutorial_pressed()` sets `GameState.is_tutorial = true` and loads `main.tscn`.
2. **Main._ready()** — after all systems initialise, detects `is_tutorial` and calls `TutorialManager.start($TutorialOverlay)`.
3. **TutorialManager.start()** — sets `is_active = true`, calls `_setup_scenario()` (deferred: emits `tutorial_spawn_enemies` + `tutorial_setup_altar`), connects `confirm_pressed`, enters step 0.
4. **Each step** — `_enter_step(i)` calls `TutorialOverlay.show_step()` and connects the step's `complete_signal` on EventBus with `CONNECT_ONE_SHOT` via a variadic lambda.
5. **Step completion** — lambda fires, calls `_advance()` → `_enter_step(i+1)`.
6. **Final step ("complete")** — `TutorialOverlay.show_complete()` reveals the "开始冒险" button.
7. **Confirm** — `TutorialManager._on_confirm_pressed()` calls `stop()` (clears flags, hides overlay) then changes scene to `loading_screen.tscn`.

## Tutorial-Specific Suppressions

- `GameLoop.spawn_enemies()` — returns early when `is_tutorial`; tutorial enemies are placed by `Main._spawn_tutorial_enemies()`.
- `GameLoop._on_loop_completed()` — game-over / phase-advance logic skipped; only `loop_completed` signal propagates.
- `GameLoop._on_player_died()` — heals player to full instead of triggering game-over screen.

## Dependencies

- `EventBus`, `GameState`, `DataTables` — standard autoloads
- `TutorialSteps` — step data (no runtime deps)
- `main.tscn` must contain a `TutorialOverlay` child node (`scenes/tutorial/tutorial_overlay.tscn`)
