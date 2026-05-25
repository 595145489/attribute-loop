extends GutTest

const EconomyManagerScript = preload("res://src/systems/EconomyManager.gd")

func before_each() -> void:
	GameState.reset()

func test_calc_gold_drop_phase1_min() -> void:
	var ed := EnemyData.new()
	ed.gold_min = 5
	ed.gold_max = 5
	ed.gold_scale = 0.3
	var amount = EconomyManagerScript.calc_gold_drop(ed, 1)
	assert_eq(amount, 5)

func test_calc_gold_drop_scales_with_phase() -> void:
	var ed := EnemyData.new()
	ed.gold_min = 10
	ed.gold_max = 10
	ed.gold_scale = 0.3
	var amount = EconomyManagerScript.calc_gold_drop(ed, 3)
	assert_eq(amount, 16)

func test_gold_added_to_gamestate_on_enemy_killed() -> void:
	var mgr = EconomyManagerScript.new()
	add_child_autofree(mgr)
	GameState.gold = 0
	var enemy := Enemy.new()
	enemy.init("汲取者")
	DataTables.get_enemy("汲取者").gold_min = 10
	DataTables.get_enemy("汲取者").gold_max = 10
	GameState.current_phase = 1
	EventBus.enemy_killed.emit(enemy)
	assert_eq(GameState.gold, 10)
	DataTables.get_enemy("汲取者").gold_min = 5
	DataTables.get_enemy("汲取者").gold_max = 15