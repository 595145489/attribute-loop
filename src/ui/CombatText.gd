class_name CombatText
extends RefCounted

# Single source of truth for combat event descriptions.
# Both the real-time CombatFeed and the LogPanel (history) render these strings
# so the two surfaces never drift apart. FloatLabel keeps its own short popup
# phrasing (different purpose).

static func player_hit(damage: int) -> String:
	return "怪物对你造成 %d 点伤害" % damage


static func player_attacked(damage: int) -> String:
	return "你对怪物造成 %d 点伤害" % damage


static func enemy_killed(enemy: Enemy) -> String:
	return "击杀 %s" % enemy.enemy_id


static func combat_enrage(stacks: int) -> String:
	return "怪物激怒 ×%d" % stacks


static func rule_effect(effect_id: String, value: float) -> String:
	match effect_id:
		"治愈":     return "你 回复 %.0f 点生命" % value
		"反射":     return "你 反射 %.0f%% 伤害" % (value * 100.0)
		"护盾":     return "你 获得 %.0f 点护盾" % value
		"减伤":     return "你 叠加 %.0f 层减伤" % value
		"吸血":     return "你 吸血率 +%.0f%%" % (value * 100.0)
		"强化":     return "你 强化 ×%d 层" % GameState.amplify_stacks
		"增伤":     return "你 增伤 ×%.0f 层" % value
		"蓄能":     return "你 蓄能 %d 层" % GameState.charge_stacks
		"蓄能释放": return "蓄能释放对怪物造成 %.0f 点伤害" % value
		"灼烧":     return "对怪物施加灼烧 ×%.0f 层" % value
		"灼烧伤害": return "怪物受到灼烧伤害 %.0f 点" % value
		"侵蚀":     return "对怪物施加侵蚀 −%.0f" % value
		"侵蚀伤害": return "怪物受到侵蚀伤害 %.0f 点" % value
		"受击":     return "你受到 %.0f 点伤害" % value
		"低血":     return "你受到 %.0f 点伤害" % value
		"满血":     return "你 叠层各 +1"
		"规则触发": return "你 触发计数 +1"
		"击杀":     return "你对怪物斩首 %.0f%%" % value
		"经过":     return "你 地块额外触发"
		_:          return "%s +%.1f" % [effect_id, value]
