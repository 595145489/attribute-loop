class_name TutorialSteps

static func get_steps() -> Array:
	return [
		{
			"id": "speed_intro",
			"text": "左上角是速度控制按钮\n可随时调整游戏速度或暂停\n点击任意速度按钮继续",
			"highlight_node": "SpeedControl",
			"complete_signal": "speed_changed",
			"pause_on_enter": true,
			"block_outside_input": true
		},
		{
			"id": "track_intro",
			"text": "角色会自动沿轨道行走，走完一圈为一个「循环」\n观察第一圈...",
			"highlight_node": "",
			"complete_signal": "loop_completed",
			"block_outside_input": false
		},
		{
			"id": "enemy_inspect",
			"text": "前方有敌人！走近会自动触发战斗\n先点击敌人查看它的属性",
			"highlight_node": "Enemy",
			"complete_signal": "enemy_inspected",
			"pause_on_enter": true,
			"block_outside_input": true
		},
		{
			"id": "combat",
			"text": "走近敌人后自动开始战斗，移动暂停\n等待击败敌人...",
			"highlight_node": "",
			"complete_signal": "enemy_killed",
			"block_outside_input": false
		},
		{
			"id": "strip_component",
			"text": "击败敌人后可剥取词条\n点击「取走」按钮逐一取走全部4个词条",
			"highlight_node": "",
			"highlight_contains": "取走",
			"complete_signal": "component_stripped",
			"complete_count": 4,
			"block_outside_input": true
		},
		{
			"id": "open_bag",
			"text": "打开背包查看取到的词条\n点击左上角「背包」按钮",
			"highlight_node": "",
			"highlight_contains": "背包",
			"complete_signal": "inventory_opened",
			"block_outside_input": true
		},
		{
			"id": "rule_slot_trigger",
			"text": "点击「经过」词条选中，再点击规则槽 T 格放入\n装在人物身上时：每走过任意 N 个地块计一次，累计 N 次触发一次\n（N = 词条的触发值）",
			"highlight_node": "",
			"highlight_contains": "经过",
			"switch_highlight_on_select": "[T 空]",
			"complete_signal": "rule_equipped",
			"block_outside_input": true
		},
		{
			"id": "rule_slot_effect",
			"text": "点击「治愈」词条，放入规则槽 E 格\n效果词条：决定触发后做什么 —— 恢复生命值\n组合效果：每走过 N 个地块，自动回血",
			"highlight_node": "",
			"highlight_contains": "治愈 (T",
			"switch_highlight_on_select": "[E 空]",
			"complete_signal": "rule_equipped",
			"block_outside_input": true
		},
		{
			"id": "delete_component_select",
			"text": "背包里的词条可以选中后删除\n点击「治愈」词条将其选中",
			"highlight_node": "",
			"highlight_contains": "治愈 (T",
			"complete_signal": "tutorial_component_selected",
			"block_outside_input": true
		},
		{
			"id": "delete_component_info",
			"text": "选中后底部出现「删除」按钮\n可花费金币永久移除词条，删除费用随次数递增，谨慎使用\n点击高亮处了解即可，不会真正删除",
			"highlight_node": "",
			"highlight_contains": "删除",
			"confirm_to_advance": true,
			"complete_signal": "tutorial_info_confirmed",
			"block_outside_input": true
		},
		{
			"id": "close_bag",
			"text": "了解完毕，关闭背包继续",
			"highlight_node": "",
			"highlight_contains": "关闭 [B]",
			"complete_signal": "inventory_closed",
			"block_outside_input": true
		},
		{
			"id": "close_strip",
			"text": "关闭剥取面板，回到地图",
			"highlight_node": "",
			"highlight_contains": "继续 →",
			"complete_signal": "strip_panel_closed",
			"block_outside_input": true
		},
		{
			"id": "tile_rule",
			"text": "点击地图上的格子，可以为格子安装永久效果\n点击第4格（右侧第一个格子）",
			"highlight_node": "tile_3",
			"complete_signal": "tile_rule_panel_opened",
			"pause_on_enter": true,
			"block_outside_input": true
		},
		{
			"id": "tile_rule_equip",
			"text": "点击 T 槽，再从列表选择「经过」词条放入\n装在地块上时：每经过该格 N 次触发一次\n注意：是针对这个地块单独计数，和装在人物身上不同\n特殊：灼烧/侵蚀/吸血/反射装在地块上时，改为每触发 N 场战斗触发一次",
			"highlight_node": "",
			"highlight_contains": "[T 空 — 放入经过]",
			"highlight_next": "每",
			"complete_signal": "tile_rule_set",
			"block_outside_input": true
		},
		{
			"id": "tile_rule_equip_effect",
			"text": "再点击 E 槽，从列表选择「治愈」词条放入\n效果词条决定触发后执行什么操作",
			"highlight_node": "",
			"highlight_contains": "[E 空]",
			"highlight_next": "治愈",
			"complete_signal": "tile_rule_set",
			"block_outside_input": true
		},
		{
			"id": "close_tile_rule",
			"text": "地块规则已设置！点击「关闭」退出面板",
			"highlight_node": "",
			"highlight_contains": "关闭",
			"complete_signal": "tile_rule_panel_closed",
			"block_outside_input": true
		},
		{
			"id": "auction_intro",
			"text": "每圈末结算后，「残市」会刷新3个竞价服务\n你和影子买家甲乙竞价争夺，出价最高者获得\n点击「残市」按钮进入",
			"highlight_node": "",
			"highlight_contains": "残市",
			"complete_signal": "auction_panel_opened",
			"pause_on_enter": true,
			"block_outside_input": true
		},
		{
			"id": "auction_gold_info",
			"text": "底栏显示各方金币\n◆ 你的金币  ◆ 影子甲（约45g）  ◆ 影子乙（约45g）\n点击高亮区继续",
			"highlight_node": "",
			"highlight_contains": "金币:",
			"confirm_to_advance": true,
			"complete_signal": "tutorial_info_confirmed",
			"block_outside_input": true
		},
		{
			"id": "auction_interest_info",
			"text": "每张卡片显示甲乙对该服务的购买意愿\n无/低/中/高 代表他们的出价力度\n点击高亮区继续",
			"highlight_node": "",
			"highlight_contains": "影子甲:",
			"confirm_to_advance": true,
			"complete_signal": "tutorial_info_confirmed",
			"block_outside_input": true
		},
		{
			"id": "auction_bid",
			"text": "在第一个服务填入出价金额，点击「出价」\n出价需 > 45g 才能胜过甲乙",
			"highlight_node": "BidRow",
			"highlight_contains": "",
			"complete_signal": "auction_bid_placed",
			"block_outside_input": true
		},
		{
			"id": "close_auction",
			"text": "出价已锁定！圈末自动结算，出价最高者获胜\n点击「X」关闭面板",
			"highlight_node": "",
			"highlight_contains": "X",
			"complete_signal": "auction_panel_closed",
			"block_outside_input": true
		},
		{
			"id": "loop_2_wait",
			"text": "继续观察游戏运行，等待第二圈完成...",
			"highlight_node": "",
			"complete_signal": "loop_completed",
			"block_outside_input": false
		},
		{
			"id": "altar_gift",
			"text": "【教程赠礼】已为你添加2个治愈词条\n祭坛可将词条永久转化为阶段加成\n点击「祭坛」按钮进入",
			"highlight_node": "",
			"highlight_contains": "祭坛",
			"complete_signal": "altar_panel_opened",
			"pause_on_enter": true,
			"block_outside_input": true
		},
		{
			"id": "altar_slot",
			"text": "点击空槽放入治愈词条\n祭坛会将其效果值转化为永久加成",
			"highlight_node": "",
			"highlight_contains": "[空 — 放入E词条]",
			"highlight_next": "治愈 (",
			"complete_signal": "altar_component_added",
			"block_outside_input": true
		},
		{
			"id": "altar_activate",
			"text": "词条已放入！点击「激活祭坛」将其永久转化为规则加成\n激活后祭坛面板自动关闭，加成立即生效",
			"highlight_node": "",
			"highlight_contains": "激活祭坛",
			"complete_signal": "altar_activated",
			"block_outside_input": true
		},
		{
			"id": "view_auction_open",
			"text": "第二圈结束后残市已自动结算\n点击「残市」按钮查看本次竞拍结果",
			"highlight_node": "",
			"highlight_contains": "残市",
			"complete_signal": "auction_panel_opened",
			"pause_on_enter": true,
			"block_outside_input": true
		},
		{
			"id": "view_auction_results",
			"text": "高亮处是你赢得的服务结果\n出价最高者获得服务，金币不退还\n点击高亮处继续",
			"highlight_node": "",
			"highlight_contains": "√ 你赢了",
			"confirm_to_advance": true,
			"complete_signal": "tutorial_info_confirmed",
			"block_outside_input": true
		},
		{
			"id": "view_auction_close",
			"text": "查看完毕，点击「X」关闭残市面板",
			"highlight_node": "",
			"highlight_contains": "X",
			"complete_signal": "auction_panel_closed",
			"block_outside_input": true
		},
		{
			"id": "pressure_info",
			"text": "高亮处是当前压力进度\n走完压力条所示的圈数后，自动进入下一 Phase\n也可在祭坛放入词条激活，立即推进\n点击高亮处继续",
			"highlight_node": "",
			"highlight_contains": "压力:",
			"confirm_to_advance": true,
			"complete_signal": "tutorial_info_confirmed",
			"pause_on_enter": true,
			"block_outside_input": true
		},
		{
			"id": "phase_info",
			"text": "高亮处是当前阶段名称\n经历若干阶段后，进入「裁决圈」\n裁决圈中规则对决，存活规则越多，胜利越稳固\n点击高亮处继续",
			"highlight_node": "",
			"highlight_contains": "阶段",
			"confirm_to_advance": true,
			"complete_signal": "tutorial_info_confirmed",
			"pause_on_enter": true,
			"block_outside_input": true
		},
		{
			"id": "complete",
			"text": "你已掌握全部核心机制！\n点击「开始冒险」返回主菜单",
			"highlight_node": "",
			"complete_signal": "",
			"block_outside_input": false
		},
	]
