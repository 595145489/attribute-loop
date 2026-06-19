extends Node

enum ServiceType {
	COMP_REWRITE   = 1,
	COMP_MERGE     = 2,
	ENEMY_PARDON   = 3,
	DELETE_PARDON  = 4,
	PRESSURE_DELAY = 5,
	STAT_DMG       = 6,
	STAT_HP        = 7,
	STAT_SPEED     = 8,
	STAT_AMPLIFY   = 9,
	SLOT_RULE      = 10,
	SLOT_SERVICE   = 11,
}

const SERVICE_NAMES: Dictionary = {
	ServiceType.COMP_REWRITE:   "词条改写",
	ServiceType.COMP_MERGE:     "词条融合",
	ServiceType.ENEMY_PARDON:   "敌人赦免",
	ServiceType.DELETE_PARDON:  "删除特赦",
	ServiceType.PRESSURE_DELAY: "压力延缓",
	ServiceType.STAT_DMG:       "战意磨砺",
	ServiceType.STAT_HP:        "筋骨强化",
	ServiceType.STAT_SPEED:     "迅捷折纸",
	ServiceType.STAT_AMPLIFY:   "强化潜能",
	ServiceType.SLOT_RULE:      "装备槽扩容",
	ServiceType.SLOT_SERVICE:   "服务栏扩容",
}

const SERVICE_DESCRIPTIONS: Dictionary = {
	ServiceType.COMP_REWRITE:   "修改某个词条的N值(1-3)或基础数值(最多+50%)",
	ServiceType.COMP_MERGE:     "将两个同类词条合并为一个（结果 = 总和×0.8）",
	ServiceType.ENEMY_PARDON:   "下3只指定类型敌人不战斗，自动掉落词条",
	ServiceType.DELETE_PARDON:  "下次删除词条0费用且不计入全局计数",
	ServiceType.PRESSURE_DELAY: "世界压力计时 -1 圈",
	ServiceType.STAT_DMG:       "永久 基础攻击 +2",
	ServiceType.STAT_HP:        "永久 最大HP +15，立即回复等量血量",
	ServiceType.STAT_SPEED:     "永久 攻击间隔 -0.05s（最低0.2s）",
	ServiceType.STAT_AMPLIFY:   "永久 强化层上限 +1",
	ServiceType.SLOT_RULE:      "永久 装备规则槽 +1",
	ServiceType.SLOT_SERVICE:   "永久 服务栏容量 +1",
}

const SERVICE_SUBTITLES: Dictionary = {
	ServiceType.COMP_REWRITE:   "效果词条 · 效果值 +20%",
	ServiceType.COMP_MERGE:     "效果词条 · 总和 × 0.8",
	ServiceType.ENEMY_PARDON:   "指定敌人 · 持续 3 次遭遇",
	ServiceType.DELETE_PARDON:  "下次删除 · 0 费用",
	ServiceType.PRESSURE_DELAY: "世界压力 · 计时 -1 圈",
	ServiceType.STAT_DMG:       "属性提升 · 永久生效",
	ServiceType.STAT_HP:        "属性提升 · 永久生效",
	ServiceType.STAT_SPEED:     "属性提升 · 永久生效",
	ServiceType.STAT_AMPLIFY:   "属性提升 · 永久生效",
	ServiceType.SLOT_RULE:      "槽位扩容 · 永久生效",
	ServiceType.SLOT_SERVICE:   "槽位扩容 · 永久生效",
}

const SERVICE_FLAVOUR: Dictionary = {
	ServiceType.COMP_REWRITE:   "折痕可以修正，但代价是更深的刻印。",
	ServiceType.COMP_MERGE:     "两愿合一，形合则意合，意合则力合。",
	ServiceType.ENEMY_PARDON:   "折纸之道，非战而胜，乃折而化之。",
	ServiceType.DELETE_PARDON:  "有些错误，可以抹去，不留痕迹。",
	ServiceType.PRESSURE_DELAY: "时间是最好的折叠工具，只需多一轮。",
	ServiceType.STAT_DMG:       "以战磨砺，以血铸意。每一次挥剑，折痕更深。",
	ServiceType.STAT_HP:        "筋骨强化，承压而不折。",
	ServiceType.STAT_SPEED:     "迅如流水，折纸无声。",
	ServiceType.STAT_AMPLIFY:   "潜能深埋，一旦唤醒，层叠无尽。",
	ServiceType.SLOT_RULE:      "规则愈多，折叠愈深，世界愈复杂。",
	ServiceType.SLOT_SERVICE:   "容量扩张，选择增多，道路更宽。",
}

var current_services: Array[int] = []
var carried_over: Array[int] = []
var player_bids: Dictionary = {}
var player_bids_locked: Dictionary = {}
var last_results: Array = []

var phantom_a: PhantomBuyer
var phantom_b: PhantomBuyer

var _kills_this_loop: Array[String] = []
var _pending_overflow_service: int = -1
var _first_loop_done: bool = false

func _ready() -> void:
	phantom_a = PhantomBuyer.new()
	phantom_a.init(PhantomBuyer.Personality.AGGRESSIVE, [ServiceType.STAT_DMG, ServiceType.STAT_HP, ServiceType.STAT_SPEED])
	phantom_b = PhantomBuyer.new()
	phantom_b.init(PhantomBuyer.Personality.PATIENT, [ServiceType.COMP_REWRITE, ServiceType.COMP_MERGE])
	EventBus.loop_completed.connect(_on_loop_completed)

func register_kill(enemy_id: String) -> void:
	_kills_this_loop.append(enemy_id)

func set_player_bid(service_type: int, amount: int) -> void:
	player_bids[service_type] = max(0, amount)

func pop_overflow_service() -> int:
	var svc := _pending_overflow_service
	_pending_overflow_service = -1
	return svc

func _on_loop_completed() -> void:
	if not _first_loop_done:
		_first_loop_done = true
		current_services = generate_pool(_kills_this_loop, carried_over)
		_kills_this_loop = []
		last_results = []
		EventBus.auction_settled.emit(last_results)
		phantom_a.earn(GameState.current_phase)
		phantom_b.earn(GameState.current_phase)
		return

	# Save services player bet on, then generate next loop's services
	var services_to_settle: Array[int] = current_services.duplicate()
	current_services = generate_pool(_kills_this_loop, carried_over)
	_kills_this_loop = []

	var bid_a: Dictionary = {}
	var bid_b: Dictionary = {}
	for svc in services_to_settle:
		bid_a[svc] = phantom_a.calculate_bid(svc, services_to_settle)
		bid_b[svc] = phantom_b.calculate_bid(svc, services_to_settle)

	last_results = settle(services_to_settle, player_bids, bid_a, bid_b)

	carried_over = []
	for r in last_results:
		match r["winner"]:
			"player":
				# Gold already deducted when bid was placed
				_award_service_to_player(r["service_type"])
			"phantom_a":
				phantom_a.pay(r["bids"]["phantom_a"])
				GameState.gold += r["bids"]["player"]
			"phantom_b":
				phantom_b.pay(r["bids"]["phantom_b"])
				GameState.gold += r["bids"]["player"]
			"none":
				GameState.gold += r["bids"]["player"]
				carried_over.append(r["service_type"])

	var b_priority_seen := current_services.has(phantom_b.preferred_types[0])
	phantom_b.tick_patience(b_priority_seen)
	if phantom_b.patience_overflow():
		phantom_b.patience_streak = 0

	player_bids = {}
	player_bids_locked = {}
	EventBus.auction_settled.emit(last_results)
	phantom_a.earn(GameState.current_phase)
	phantom_b.earn(GameState.current_phase)
	EventBus.gold_changed.emit(GameState.gold)

func _award_service_to_player(service_type: int) -> void:
	if GameState.service_bar.size() < GameState.service_bar_max:
		GameState.service_bar.append(service_type)
		EventBus.service_bar_changed.emit()
	else:
		_pending_overflow_service = service_type
		EventBus.service_bar_changed.emit()

func execute_service(service_type: int, params: Dictionary) -> void:
	match service_type:
		ServiceType.COMP_REWRITE:
			var c: ComponentData = params["component"]
			if params.has("new_trigger_n"):
				c.trigger_value = clampf(params["new_trigger_n"], 1.0, 3.0)
			if params.has("new_effect_delta"):
				c.effect_value = c.effect_value * (1.0 + clampf(params["new_effect_delta"], 0.0, 0.5))
		ServiceType.COMP_MERGE:
			var a: ComponentData = params["comp_a"]
			var b: ComponentData = params["comp_b"]
			var merged: ComponentData = a.duplicate()
			merged.effect_value = (a.effect_value + b.effect_value) * DataTables.config.auction_comp_merge_ratio
			merged.trigger_value = (a.trigger_value + b.trigger_value) * DataTables.config.auction_comp_merge_ratio
			GameState.remove_from_inventory(a)
			GameState.remove_from_inventory(b)
			GameState.add_to_inventory(merged)
		ServiceType.ENEMY_PARDON:
			GameState.enemy_pardon_type = params["enemy_id"]
			GameState.enemy_pardon_remaining = DataTables.config.auction_enemy_pardon_count
		ServiceType.DELETE_PARDON:
			GameState.deletion_free = true
		ServiceType.PRESSURE_DELAY:
			GameState.loops_in_phase = max(0, GameState.loops_in_phase - 1)
		ServiceType.STAT_DMG:
			GameState.dmg_bonus += DataTables.config.auction_dmg_per_purchase
		ServiceType.STAT_HP:
			var delta := DataTables.config.auction_hp_per_purchase
			GameState.hp_max += delta
			GameState.hp = mini(GameState.hp + delta, GameState.hp_max)
		ServiceType.STAT_SPEED:
			GameState.attack_interval_bonus += DataTables.config.auction_speed_delta
		ServiceType.STAT_AMPLIFY:
			GameState.amplify_max_stacks += DataTables.config.auction_amplify_per_purchase
		ServiceType.SLOT_RULE:
			GameState.rule_slots.append({"trigger": null, "effect": null})
			EventBus.rule_slots_changed.emit()
		ServiceType.SLOT_SERVICE:
			GameState.service_bar_max += 1
	EventBus.service_bar_changed.emit()

## Pure functions

static func generate_pool(kills: Array[String], carried: Array[int]) -> Array[int]:
	var pool: Array[int] = carried.duplicate()
	var all_types: Array[int] = [
		ServiceType.COMP_REWRITE, ServiceType.COMP_MERGE,
		ServiceType.ENEMY_PARDON, ServiceType.DELETE_PARDON, ServiceType.PRESSURE_DELAY,
		ServiceType.STAT_DMG, ServiceType.STAT_HP, ServiceType.STAT_SPEED, ServiceType.STAT_AMPLIFY,
		ServiceType.SLOT_RULE, ServiceType.SLOT_SERVICE,
	]
	var rule_max: int = DataTables.config.rule_slot_count_max
	var bar_max: int = DataTables.config.auction_service_bar_cap + DataTables.config.auction_service_bar_max_purchases
	var cur_rule_slots: int = GameState.rule_slots.size()
	var cur_bar_max: int = GameState.service_bar_max
	all_types = all_types.filter(func(t: int) -> bool:
		if t == ServiceType.SLOT_RULE:
			return cur_rule_slots < rule_max
		if t == ServiceType.SLOT_SERVICE:
			return cur_bar_max < bar_max
		return true
	)
	for _kill in kills:
		if pool.size() >= DataTables.config.auction_pool_size:
			break
		var available: Array[int] = all_types.filter(func(t): return not pool.has(t))
		if available.is_empty():
			break
		pool.append(available[randi() % available.size()])
	while pool.size() < 3:
		var available: Array[int] = all_types.filter(func(t): return not pool.has(t))
		if available.is_empty():
			break
		pool.append(available[randi() % available.size()])
	pool.sort()
	return pool.slice(0, 3)

static func settle(services: Array[int],
		player_bids_map: Dictionary,
		bid_a: Dictionary,
		bid_b: Dictionary) -> Array:
	var results: Array = []
	for svc in services:
		var pb: int = player_bids_map.get(svc, 0)
		var ab: int = bid_a.get(svc, 0)
		var bb: int = bid_b.get(svc, 0)
		var winner := "none"
		var max_bid := 0
		if pb > max_bid:
			max_bid = pb
			winner = "player"
		if ab > max_bid:
			max_bid = ab
			winner = "phantom_a"
		if bb > max_bid:
			max_bid = bb
			winner = "phantom_b"
		results.append({
			"service_type": svc,
			"winner": winner,
			"bids": {"player": pb, "phantom_a": ab, "phantom_b": bb}
		})
	return results


class PhantomBuyer:
	enum Personality { AGGRESSIVE, PATIENT }

	var personality: Personality
	var gold: int = 0
	var preferred_types: Array[int] = []
	var patience_streak: int = 0

	var PATIENT_THRESHOLD: int:
		get: return DataTables.config.auction_phantom_b_threshold
	var PATIENT_TIMEOUT_LOOPS: int:
		get: return DataTables.config.auction_phantom_b_timeout_loops

	func init(p: Personality, prefs: Array[int]) -> void:
		personality = p
		preferred_types = prefs

	func earn(phase: int) -> void:
		var income_table: Array[int] = DataTables.config.auction_phantom_income_per_phase
		gold += income_table[clampi(phase, 1, income_table.size() - 1)]

	func interest(service_type: int) -> int:
		if personality == Personality.AGGRESSIVE:
			return 3 if preferred_types.has(service_type) else 1
		else:
			if preferred_types.has(service_type):
				return 3 if gold >= PATIENT_THRESHOLD else 2
			return 0

	func calculate_bid(service_type: int, pool: Array[int]) -> int:
		if personality == Personality.AGGRESSIVE:
			var spend_budget := int(gold * DataTables.config.auction_phantom_a_spend_ratio)
			if not preferred_types.has(service_type):
				return min(DataTables.config.auction_phantom_a_token_bid, gold)
			var pref_in_pool := pool.filter(func(t): return preferred_types.has(t)).size()
			if pref_in_pool == 0:
				return min(DataTables.config.auction_phantom_a_token_bid, gold)
			return int(spend_budget / pref_in_pool)
		else:
			if not preferred_types.has(service_type):
				return min(randi_range(10, 20), gold)
			if gold < PATIENT_THRESHOLD:
				return min(randi_range(10, 20), gold)
			return int(gold * DataTables.config.auction_phantom_b_allin_ratio)

	func pay(amount: int) -> void:
		gold = max(0, gold - amount)

	func tick_patience(priority_seen: bool) -> void:
		if personality != Personality.PATIENT:
			return
		if priority_seen:
			patience_streak = 0
		else:
			patience_streak += 1

	func patience_overflow() -> bool:
		return personality == Personality.PATIENT and patience_streak >= PATIENT_TIMEOUT_LOOPS
