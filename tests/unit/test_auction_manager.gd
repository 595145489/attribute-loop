extends GutTest

const AuctionManager = preload("res://src/systems/AuctionManager.gd")

func before_each() -> void:
	GameState.reset()

# --- Pool generation ---

func test_generate_pool_size_is_3() -> void:
	var kills: Array[String] = ["汲取者", "守卫者", "急袭者"]
	var pool = AuctionManager.generate_pool(kills, [])
	assert_eq(pool.size(), 3)

func test_generate_pool_no_duplicates() -> void:
	var kills: Array[String] = ["汲取者", "守卫者", "急袭者", "守卫者"]
	var pool = AuctionManager.generate_pool(kills, [])
	var unique: Dictionary = {}
	for t in pool:
		unique[t] = true
	assert_eq(unique.size(), pool.size())

func test_generate_pool_fills_when_no_kills() -> void:
	var pool = AuctionManager.generate_pool([], [])
	assert_eq(pool.size(), 3)

func test_generate_pool_includes_carried_over() -> void:
	var carried: Array[int] = [AuctionManager.ServiceType.PRESSURE_DELAY]
	var pool = AuctionManager.generate_pool([], carried)
	assert_true(pool.has(AuctionManager.ServiceType.PRESSURE_DELAY))

# --- Settlement ---

func test_settle_player_wins_highest_bid() -> void:
	var services: Array[int] = [AuctionManager.ServiceType.PRESSURE_DELAY]
	var results = AuctionManager.settle(services, {AuctionManager.ServiceType.PRESSURE_DELAY: 100}, {AuctionManager.ServiceType.PRESSURE_DELAY: 50}, {AuctionManager.ServiceType.PRESSURE_DELAY: 30})
	assert_eq(results[0]["winner"], "player")

func test_settle_phantom_a_wins_when_higher() -> void:
	var services: Array[int] = [AuctionManager.ServiceType.COMP_MERGE]
	var results = AuctionManager.settle(services, {AuctionManager.ServiceType.COMP_MERGE: 20}, {AuctionManager.ServiceType.COMP_MERGE: 200}, {AuctionManager.ServiceType.COMP_MERGE: 10})
	assert_eq(results[0]["winner"], "phantom_a")

func test_settle_none_when_all_zero() -> void:
	var services: Array[int] = [AuctionManager.ServiceType.DELETE_PARDON]
	var results = AuctionManager.settle(services, {}, {}, {})
	assert_eq(results[0]["winner"], "none")

func test_settle_bids_preserved_in_result() -> void:
	var services: Array[int] = [AuctionManager.ServiceType.COMP_REWRITE]
	var results = AuctionManager.settle(services, {AuctionManager.ServiceType.COMP_REWRITE: 80}, {AuctionManager.ServiceType.COMP_REWRITE: 120}, {})
	assert_eq(results[0]["bids"]["player"], 80)
	assert_eq(results[0]["bids"]["phantom_a"], 120)

# --- PhantomBuyer ---

func test_phantom_aggressive_earns_70g_phase1() -> void:
	var p := AuctionManager.PhantomBuyer.new()
	p.init(AuctionManager.PhantomBuyer.Personality.AGGRESSIVE, [0, 1])
	p.earn(1)
	assert_eq(p.gold, 70)

func test_phantom_aggressive_earns_110g_phase5() -> void:
	var p := AuctionManager.PhantomBuyer.new()
	p.init(AuctionManager.PhantomBuyer.Personality.AGGRESSIVE, [0, 1])
	p.earn(5)
	assert_eq(p.gold, 110)

func test_phantom_aggressive_earns_200g_phase10() -> void:
	var p := AuctionManager.PhantomBuyer.new()
	p.init(AuctionManager.PhantomBuyer.Personality.AGGRESSIVE, [0, 1])
	p.earn(10)
	assert_eq(p.gold, 200)

func test_phantom_aggressive_bids_75pct_on_preferred() -> void:
	var p := AuctionManager.PhantomBuyer.new()
	p.init(AuctionManager.PhantomBuyer.Personality.AGGRESSIVE, [0])
	p.gold = 100
	var pool: Array[int] = [0, 1, 2]
	assert_eq(p.calculate_bid(0, pool), 75)

func test_phantom_patient_low_bid_below_threshold() -> void:
	var p := AuctionManager.PhantomBuyer.new()
	p.init(AuctionManager.PhantomBuyer.Personality.PATIENT, [1])
	p.gold = 100
	var pool: Array[int] = [0, 1, 2]
	assert_lte(p.calculate_bid(1, pool), 20)

func test_phantom_patient_all_in_above_threshold() -> void:
	var p := AuctionManager.PhantomBuyer.new()
	p.init(AuctionManager.PhantomBuyer.Personality.PATIENT, [1])
	p.gold = 250
	var pool: Array[int] = [0, 1, 2]
	assert_gte(p.calculate_bid(1, pool), 200)

func test_phantom_interest_high_for_preferred() -> void:
	var p := AuctionManager.PhantomBuyer.new()
	p.init(AuctionManager.PhantomBuyer.Personality.AGGRESSIVE, [2])
	assert_eq(p.interest(2), 3)

func test_phantom_patience_overflow_after_5_loops() -> void:
	var p := AuctionManager.PhantomBuyer.new()
	p.init(AuctionManager.PhantomBuyer.Personality.PATIENT, [1])
	for i in 5:
		p.tick_patience(false)
	assert_true(p.patience_overflow())

func test_phantom_patience_resets_on_priority_seen() -> void:
	var p := AuctionManager.PhantomBuyer.new()
	p.init(AuctionManager.PhantomBuyer.Personality.PATIENT, [1])
	for i in 3:
		p.tick_patience(false)
	p.tick_patience(true)
	assert_eq(p.patience_streak, 0)

# --- execute_service ---

func test_execute_delete_pardon_sets_flag() -> void:
	var am := AuctionManager.new()
	am.execute_service(AuctionManager.ServiceType.DELETE_PARDON, {})
	assert_true(GameState.deletion_free)

func test_execute_pressure_delay_decrements_loops_in_phase() -> void:
	GameState.loops_in_phase = 3
	var am := AuctionManager.new()
	am.execute_service(AuctionManager.ServiceType.PRESSURE_DELAY, {})
	assert_eq(GameState.loops_in_phase, 2)

func test_execute_pressure_delay_not_below_zero() -> void:
	GameState.loops_in_phase = 0
	var am := AuctionManager.new()
	am.execute_service(AuctionManager.ServiceType.PRESSURE_DELAY, {})
	assert_eq(GameState.loops_in_phase, 0)

func test_execute_enemy_pardon_sets_type_and_count() -> void:
	var am := AuctionManager.new()
	am.execute_service(AuctionManager.ServiceType.ENEMY_PARDON, {"enemy_id": "汲取者"})
	assert_eq(GameState.enemy_pardon_type, "汲取者")
	assert_eq(GameState.enemy_pardon_remaining, 3)

func test_execute_comp_merge_combines_values() -> void:
	var am := AuctionManager.new()
	var a := ComponentData.new()
	a.effect_value = 10.0
	a.slot_type = ComponentData.SlotType.EFFECT_ONLY
	var b := ComponentData.new()
	b.effect_value = 10.0
	b.slot_type = ComponentData.SlotType.EFFECT_ONLY
	GameState.add_to_inventory(a)
	GameState.add_to_inventory(b)
	am.execute_service(AuctionManager.ServiceType.COMP_MERGE, {"comp_a": a, "comp_b": b})
	assert_eq(GameState.inventory.size(), 1)
	assert_eq(GameState.inventory[0].effect_value, 16.0)

func test_new_service_types_have_names() -> void:
	assert_true(AuctionManager.SERVICE_NAMES.has(AuctionManager.ServiceType.STAT_DMG))
	assert_true(AuctionManager.SERVICE_NAMES.has(AuctionManager.ServiceType.STAT_HP))
	assert_true(AuctionManager.SERVICE_NAMES.has(AuctionManager.ServiceType.STAT_SPEED))
	assert_true(AuctionManager.SERVICE_NAMES.has(AuctionManager.ServiceType.STAT_AMPLIFY))
	assert_true(AuctionManager.SERVICE_NAMES.has(AuctionManager.ServiceType.SLOT_RULE))
	assert_true(AuctionManager.SERVICE_NAMES.has(AuctionManager.ServiceType.SLOT_SERVICE))

func test_pool_never_contains_rule_copy_int() -> void:
	var pool = AuctionManager.generate_pool(["汲取者", "守卫者", "急袭者"], [])
	assert_false(pool.has(0))

func test_execute_stat_dmg_increases_dmg_bonus() -> void:
	var am := AuctionManager.new()
	GameState.dmg_bonus = 0
	am.execute_service(AuctionManager.ServiceType.STAT_DMG, {})
	assert_eq(GameState.dmg_bonus, DataTables.config.auction_dmg_per_purchase)

func test_execute_stat_dmg_accumulates() -> void:
	var am := AuctionManager.new()
	GameState.dmg_bonus = 0
	am.execute_service(AuctionManager.ServiceType.STAT_DMG, {})
	am.execute_service(AuctionManager.ServiceType.STAT_DMG, {})
	assert_eq(GameState.dmg_bonus, DataTables.config.auction_dmg_per_purchase * 2)

func test_execute_stat_hp_increases_hp_max() -> void:
	var am := AuctionManager.new()
	var hp_before := GameState.hp_max
	am.execute_service(AuctionManager.ServiceType.STAT_HP, {})
	assert_eq(GameState.hp_max, hp_before + DataTables.config.auction_hp_per_purchase)

func test_execute_stat_hp_heals_by_delta() -> void:
	var am := AuctionManager.new()
	GameState.hp = GameState.hp_max
	am.execute_service(AuctionManager.ServiceType.STAT_HP, {})
	assert_eq(GameState.hp, GameState.hp_max)

func test_execute_stat_speed_increases_interval_bonus() -> void:
	var am := AuctionManager.new()
	GameState.attack_interval_bonus = 0.0
	am.execute_service(AuctionManager.ServiceType.STAT_SPEED, {})
	assert_almost_eq(GameState.attack_interval_bonus, DataTables.config.auction_speed_delta, 0.001)

func test_execute_stat_amplify_increases_max_stacks() -> void:
	var am := AuctionManager.new()
	var before := GameState.amplify_max_stacks
	am.execute_service(AuctionManager.ServiceType.STAT_AMPLIFY, {})
	assert_eq(GameState.amplify_max_stacks, before + DataTables.config.auction_amplify_per_purchase)

func test_execute_slot_rule_adds_rule_slot() -> void:
	var am := AuctionManager.new()
	var before := GameState.rule_slots.size()
	am.execute_service(AuctionManager.ServiceType.SLOT_RULE, {})
	assert_eq(GameState.rule_slots.size(), before + 1)

func test_execute_slot_rule_new_slot_is_empty() -> void:
	var am := AuctionManager.new()
	am.execute_service(AuctionManager.ServiceType.SLOT_RULE, {})
	var last = GameState.rule_slots[-1]
	assert_null(last["trigger"])
	assert_null(last["effect"])

func test_execute_slot_service_increases_service_bar_max() -> void:
	var am := AuctionManager.new()
	var before := GameState.service_bar_max
	am.execute_service(AuctionManager.ServiceType.SLOT_SERVICE, {})
	assert_eq(GameState.service_bar_max, before + 1)

func test_pool_excludes_slot_rule_when_maxed() -> void:
	while GameState.rule_slots.size() < DataTables.config.rule_slot_count_max:
		GameState.rule_slots.append({"trigger": null, "effect": null})
	var pool = AuctionManager.generate_pool([], [])
	assert_false(pool.has(AuctionManager.ServiceType.SLOT_RULE))

func test_pool_includes_slot_rule_when_not_maxed() -> void:
	assert_eq(GameState.rule_slots.size(), 2)
	var found := false
	for i in 200:
		var pool = AuctionManager.generate_pool([], [])
		if pool.has(AuctionManager.ServiceType.SLOT_RULE):
			found = true
			break
	assert_true(found)

func test_pool_excludes_slot_service_when_maxed() -> void:
	var cap: int = DataTables.config.auction_service_bar_cap
	var max_extra: int = DataTables.config.auction_service_bar_max_purchases
	GameState.service_bar_max = cap + max_extra
	var pool = AuctionManager.generate_pool([], [])
	assert_false(pool.has(AuctionManager.ServiceType.SLOT_SERVICE))

func test_pool_includes_slot_service_when_not_maxed() -> void:
	GameState.service_bar_max = DataTables.config.auction_service_bar_cap
	var found := false
	for i in 200:
		var pool = AuctionManager.generate_pool([], [])
		if pool.has(AuctionManager.ServiceType.SLOT_SERVICE):
			found = true
			break
	assert_true(found)

func test_phantom_a_prefers_stat_dmg() -> void:
	var p := AuctionManager.PhantomBuyer.new()
	p.init(AuctionManager.PhantomBuyer.Personality.AGGRESSIVE,
		[AuctionManager.ServiceType.STAT_DMG, AuctionManager.ServiceType.STAT_HP])
	assert_eq(p.interest(AuctionManager.ServiceType.STAT_DMG), 3)

func test_slot_rule_purchase_emits_rule_slots_changed() -> void:
	watch_signals(EventBus)
	var am := AuctionManager.new()
	am.execute_service(AuctionManager.ServiceType.SLOT_RULE, {})
	assert_signal_emitted(EventBus, "rule_slots_changed")
