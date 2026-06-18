class_name GameConfig
extends Resource

# stat = base × (1 + (phase - 1) × stat_scale_factor)
@export var stat_scale_factor: float = 0.25
@export var inventory_cap: int = 12
@export var rule_slot_count_base: int = 2
@export var rule_slot_count_max: int = 5
@export var low_hp_threshold: float = 0.3
@export var deletion_cost_sequence: Array[int] = [15, 35, 70]
@export var deletion_cost_multiplier: float = 2.0
@export var verdict_trigger_phase: int = 5
@export var verdict_survive_loops: int = 5
@export var verdict_enemy_phase: int = 6
@export var verdict_spawn_phase: int = 7
@export var combat_log_max_entries: int = 50
@export var amplify_max_stacks_base: int = 1
@export var combat_enrage_time: float = 10.0
@export var combat_enrage_bonus_per_stack: float = 0.30
@export var combat_enrage_interval: float = 2.0
@export var combat_burn_dmg_per_stack: int = 2
@export var combat_burn_interval: float = 1.0

# --- Auction (梦境残市) ---
@export var auction_service_bar_cap: int = 5
@export var auction_pool_size: int = 3
@export var auction_enemy_pardon_count: int = 3
@export var auction_comp_merge_ratio: float = 0.8
@export var auction_comp_rewrite_delta: float = 0.2
@export var auction_phantom_income_per_phase: Array[int] = [0, 40, 40, 70, 70, 110, 110]
@export var auction_phantom_a_spend_ratio: float = 0.75
@export var auction_phantom_a_token_bid: int = 15
@export var auction_phantom_b_threshold: int = 200
@export var auction_phantom_b_timeout_loops: int = 5
@export var auction_phantom_b_allin_ratio: float = 0.85
@export var auction_dmg_per_purchase: int = 2
@export var auction_hp_per_purchase: int = 15
@export var auction_speed_delta: float = 0.05
@export var auction_amplify_per_purchase: int = 1
@export var auction_service_bar_max_purchases: int = 3
