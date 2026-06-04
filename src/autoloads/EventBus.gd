extends Node

signal enemy_killed(enemy: Enemy)
signal combat_resolved
signal loop_completed
signal player_died
signal player_hit(damage: int)
signal tile_passed(tile_idx: int)
signal rule_fired(slot_idx: int, effect_id: String, value: float)
signal gold_changed(new_amount: int)
signal phase_changed(new_phase: int)
signal verdict_loop_entered
signal game_won
signal auction_settled(results: Array)
signal service_bar_changed
signal enemy_pardoned(enemy_id: String)
