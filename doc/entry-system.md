# Entry System

`scripts/core/EntryComponent.gd` + `scripts/core/Rule.gd`

## Concept

An entry is the smallest building block of a game rule. Each rule is a decomposable sentence:

```
[Trigger] + [Effect]
```

The VERB slot is reserved for future use — not active in V1.

## EntryComponent

Extends `Resource` (serializable).

| Field | Type | Description |
|-------|------|-------------|
| `slot_type` | `SlotType` | TRIGGER / VERB / EFFECT |
| `label` | `String` | Display name, e.g. "On Hit" |
| `description` | `String` | Tooltip text |
| `data` | `Dictionary` | Business data, interpreted per slot_type |

### data field conventions

**TRIGGER**
```gdscript
{"event": "on_hit"}   # fires when player takes damage
```

**EFFECT**
```gdscript
{"type": "heal"}            # restore 15 HP
{"type": "reflect_damage"}  # reflect damage (stub)
{"type": "summon_clone"}    # summon clone (stub)
```

## Rule

Extends `Resource`. Holds references to one trigger and one effect EntryComponent.

- `is_active()` — returns true only when both slots are non-null
- `try_fire(event, context)` — matches trigger.data["event"], calls `_apply_effect` on hit
- `_apply_effect(context)` — emits `rule_fired(self, type)` on `context["owner"]` (the Player), delegating effect logic upward

### Trigger chain

```
Player.receive_damage()
  → Player._fire_rules("on_hit", {owner: self})
    → Rule.try_fire("on_hit", context)
      → player.emit_signal("rule_fired", rule, "heal")
        → Player._on_rule_fired() applies the effect
```

Rule never directly mutates game state — it signals the owner, which keeps effect logic centralized in `Player._on_rule_fired()`.
