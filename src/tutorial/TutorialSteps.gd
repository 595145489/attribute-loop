class_name TutorialSteps

static func get_steps() -> Array:
	return [
		{
			"id": "track_intro",
			"text": "角色会自动沿轨道行走，走完一圈为一个「循环」。观察第一圈...",
			"highlight_node": "",
			"complete_signal": "loop_completed",
			"block_outside_input": false
		},
		{
			"id": "combat",
			"text": "遇到敌人会自动开始战斗，移动暂停。可点击敌人查看属性",
			"highlight_node": "",
			"complete_signal": "enemy_killed",
			"block_outside_input": false
		},
		{
			"id": "strip_component",
			"text": "击败敌人后，在剥取面板中选择一个组件",
			"highlight_node": "%StripPanel",
			"complete_signal": "component_stripped",
			"block_outside_input": true
		},
		{
			"id": "rule_slot",
			"text": "打开背包（TAB），把组件拖入规则槽激活效果",
			"highlight_node": "%InventoryPanel",
			"complete_signal": "rule_equipped",
			"block_outside_input": true
		},
		{
			"id": "delete_component",
			"text": "在背包中选中组件，点击「删除」按钮删除不需要的组件",
			"highlight_node": "%InventoryPanel",
			"complete_signal": "component_deleted",
			"block_outside_input": true
		},
		{
			"id": "tile_rule",
			"text": "点击任意轨道格子，把组件安装为永久格效果",
			"highlight_node": "",
			"complete_signal": "tile_rule_set",
			"block_outside_input": false
		},
		{
			"id": "auction",
			"text": "特殊拍卖格：可购买或卖出组件。走到拍卖行格点击进入",
			"highlight_node": "",
			"complete_signal": "auction_settled",
			"block_outside_input": false
		},
		{
			"id": "altar",
			"text": "点击祭坛格，将一个组件放入祭坛，填满即可推进阶段",
			"highlight_node": "",
			"complete_signal": "altar_component_added",
			"block_outside_input": false
		},
		{
			"id": "complete",
			"text": "你已掌握全部核心机制！点击「开始冒险」返回主菜单",
			"highlight_node": "",
			"complete_signal": "",
			"block_outside_input": false
		},
	]
