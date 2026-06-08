extends GutTest

const GameOver = preload("res://src/ui/GameOver.gd")

var go: GameOver

func before_each() -> void:
	go = GameOver.new()

func after_each() -> void:
	go.free()

func test_win_narrative_contains_recognition_line() -> void:
	var text = go._get_narrative("win")
	assert_true(text.find("是你") >= 0)

func test_lose_narrative_contains_enough_line() -> void:
	var text = go._get_narrative("lose")
	assert_true(text.find("这已经足够了") >= 0)

func test_win_background_path() -> void:
	assert_eq(go._get_background_path("win"), "res://resources/backgrounds/bg_game_over_win.png")

func test_lose_background_path() -> void:
	assert_eq(go._get_background_path("lose"), "res://resources/backgrounds/bg_game_over_lose.png")
