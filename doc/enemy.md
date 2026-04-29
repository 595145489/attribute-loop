# Enemy Scene

`scenes/enemy/Enemy.gd` + `scenes/enemy/Enemy.tscn`

## Responsibility

Sits at a point on the track, attacks the player on a timer, holds a list of strippable EntryComponents.

## Key Properties

| Property | Default | Description |
|----------|---------|-------------|
| `hp` | 40.0 | Dies and queue_free at 0 |
| `attack_damage` | 8.0 | Damage per attack |
| `attack_interval` | 2.0 | Seconds between attacks |
| `components` | [] | Held EntryComponent list |
| `player_ref` | null | Assigned by `Main._spawn_enemy()` |

## API

| Method | Description |
|--------|-------------|
| `setup_components(list)` | Initialize component list immediately after spawn |
| `strip_component(component)` | Called by drag UI; removes component and emits signal |
| `receive_damage(amount)` | Take damage; emits `enemy_defeated` and queue_free at 0 HP |

## Signals

| Signal | When |
|--------|------|
| `component_stripped(component)` | After strip; drag UI listens to confirm transfer |
| `enemy_defeated` | On death |

## Attack Logic

`_process` accumulates `_attack_timer` each frame. On interval, calls `player_ref.receive_damage()` via `has_method` duck-type check to avoid a hard dependency on the Player class.
