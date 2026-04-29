# Player Scene

`scenes/player/Player.gd` + `scenes/player/Player.tscn`

## Responsibility

Auto-moves along the track, holds the active rule list, and executes rule effects when damage events fire.

## Key Properties

| Property | Default | Description |
|----------|---------|-------------|
| `speed` | 80.0 | px/s along track |
| `track` | null | Assigned by `Main._ready()` |
| `track_t` | 0.0 | Track progress, loops 0–1 |
| `hp / max_hp` | 100.0 | Current / max health |
| `rules` | [] | Active Rule list |
| `inventory` | Inventory | Created and added as child in `_ready()` |

## Movement

Each frame: `track_t += (speed / track.get_total_length()) * delta`. Wraps at 1.0.

## Damage & Rule Trigger

`receive_damage(amount)` called by Enemy → deduct HP → `_fire_rules("on_hit", context)` → iterate rules → `Rule.try_fire()` → on match, emits `rule_fired` → `_on_rule_fired()` applies effect.

### Implemented effects

| effect type | Behavior |
|-------------|----------|
| `heal` | Restore 15 HP |
| `reflect_damage` | Stub, not implemented |
| `summon_clone` | Stub, not implemented |

## Signals

| Signal | When |
|--------|------|
| `rule_fired(rule, effect_type)` | Rule triggers (internal use) |
| `took_damage(amount)` | After taking damage; Main refreshes HUD |
| `healed(amount)` | After healing; Main refreshes HUD |
