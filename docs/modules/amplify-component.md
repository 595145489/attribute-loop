# 强化 (Amplify) Component

## Responsibility

The 强化 effect component adds a stackable charge system to the rule engine. When triggered, it accumulates "amplify stacks." The next non-amplify effect that fires consumes all stacks and has its final value multiplied.

## Key Classes and State

- `data/components/effect_强化.tres` — component data file, `effect_formula = "amplify"`
- `GameState.amplify_stacks: int` — current charge count, reset to 0 on game reset and on consume
- `GameState.amplify_max_stacks: int` — runtime cap, initialized from `GameConfig.amplify_max_stacks_base` (default: 1), upgradeable through gameplay

## Execution Flow

1. A rule with 强化 as its effect fires via `RuleEngine._execute_effect()`
2. `amplify_stacks` increments by 1, capped at `amplify_max_stacks`
3. `rule_fired` emits with current stack count as value
4. On the next `_execute_effect()` call for any other effect:
   - If `amplify_stacks > 0`: multiply `final_value` by `1.0 + amplify_stacks * 0.5`
   - Reset `amplify_stacks` to 0
5. The multiplied value is used in the effect's match case as normal

## Multiplier Table

| Stacks | Multiplier |
|--------|-----------|
| 1 | 1.5× |
| 2 | 2.0× |
| 3 | 2.5× |
| 4 | 3.0× |
| 5 | 3.5× |

## Upgrade Path

`GameState.amplify_max_stacks` starts at 1. Altar buffs, auction services, or phase rewards can increment it to allow higher stack accumulation before the next effect consumes them.

## Dependencies

- `RuleEngine.gd` — hosts the amplify consumption logic in `_execute_effect()`
- `GameState.gd` — holds `amplify_stacks` and `amplify_max_stacks`
- `GameConfig.gd` — `amplify_max_stacks_base` provides the reset value
