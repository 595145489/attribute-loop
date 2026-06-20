class_name LoadingScreen
extends Control

@onready var _progress: ProgressBar = $UI/Progress
@onready var _status: Label = $UI/Status
@onready var _start_button: Button = $UI/StartButton
@onready var _tutorial_button: Button = $UI/TutorialButton
@onready var _particles = $ParticleLayer/Particles
@onready var _difficulty_panel: Control = _build_difficulty_panel()

const TOTAL_STEPS := 6
const HINT_TEXT := "熟悉构筑类玩法的玩家可直接挑战困难；初次接触建议从简单开始，系统会为你预置一套基础构筑。"

var _step := 0

func _ready() -> void:
	_status.text = "初始化中..."
	_start_button.pressed.connect(_on_start_pressed)
	_tutorial_button.pressed.connect(_on_tutorial_pressed)
	_start_loading()

func _build_difficulty_panel() -> Control:
	var panel := Control.new()
	panel.name = "DifficultyPanel"
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.visible = false
	add_child(panel)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.add_child(center)

	var frame := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.05, 0.02, 0.9)
	sb.border_color = Color(0.85, 0.65, 0.2, 0.9)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(12)
	sb.content_margin_left = 36.0
	sb.content_margin_right = 36.0
	sb.content_margin_top = 28.0
	sb.content_margin_bottom = 28.0
	frame.add_theme_stylebox_override("panel", sb)
	center.add_child(frame)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 16)
	frame.add_child(vbox)

	var title := Label.new()
	title.text = "选择难度"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color(0.95, 0.88, 0.55, 1))
	vbox.add_child(title)

	var hint := Label.new()
	hint.text = HINT_TEXT
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.custom_minimum_size = Vector2(440, 0)
	hint.add_theme_font_size_override("font_size", 15)
	hint.add_theme_color_override("font_color", Color(0.92, 0.86, 0.72, 1))
	vbox.add_child(hint)

	var easy_btn := _make_difficulty_button("简单")
	easy_btn.pressed.connect(_on_easy_pressed)
	vbox.add_child(easy_btn)

	var hard_btn := _make_difficulty_button("困难")
	hard_btn.pressed.connect(_on_hard_pressed)
	vbox.add_child(hard_btn)

	var back_btn := _make_difficulty_button("返回")
	back_btn.pressed.connect(_on_back_pressed)
	vbox.add_child(back_btn)

	return panel

func _make_difficulty_button(text: String) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(260, 0)
	btn.add_theme_font_size_override("font_size", 22)
	btn.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	btn.add_theme_color_override("font_hover_color", Color(0.95, 0.88, 0.55, 1))
	btn.add_theme_color_override("font_pressed_color", Color(0.7, 0.7, 0.7, 1))
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.18, 0.12, 0.05, 0.85)
	sb.border_color = Color(0.85, 0.65, 0.2, 0.7)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 24.0
	sb.content_margin_right = 24.0
	sb.content_margin_top = 12.0
	sb.content_margin_bottom = 12.0
	btn.add_theme_stylebox_override("normal", sb)
	btn.add_theme_stylebox_override("hover", sb.duplicate())
	btn.add_theme_stylebox_override("pressed", sb.duplicate())
	btn.add_theme_stylebox_override("focus", sb)
	return btn

func _start_loading() -> void:
	await Player.preload_async(get_tree(), _on_progress)
	await Enemy.preload_all_async(get_tree(), _on_progress)
	_progress.hide()
	_status.hide()
	_start_button.visible = true
	_tutorial_button.visible = true
	_particles.start()
	if FileAccess.file_exists("res://tests/.test_mode"):
		await get_tree().process_frame
		_on_start_pressed()

func _on_start_pressed() -> void:
	if _should_block_start():
		_show_must_play_tutorial_prompt()
		return
	if FileAccess.file_exists("res://tests/.test_mode"):
		_launch_game("hard")
		return
	_show_difficulty_panel()

func _show_difficulty_panel() -> void:
	_start_button.visible = false
	_tutorial_button.visible = false
	_difficulty_panel.visible = true

func _on_easy_pressed() -> void:
	_launch_game("easy")

func _on_hard_pressed() -> void:
	_launch_game("hard")

func _on_back_pressed() -> void:
	_difficulty_panel.visible = false
	_start_button.visible = true
	_tutorial_button.visible = true

func _launch_game(difficulty: String) -> void:
	GameState.difficulty = difficulty
	GameState.reset()
	GameState.is_tutorial = false
	_start_button.disabled = true
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _should_block_start() -> bool:
	return not OnboardingState.is_tutorial_completed() \
		and not FileAccess.file_exists("res://tests/.test_mode")

func _show_must_play_tutorial_prompt() -> void:
	var dialog := AcceptDialog.new()
	dialog.title = "提示"
	dialog.dialog_text = "请先完成教程后再开始游戏"
	dialog.ok_button_text = "知道了"
	dialog.confirmed.connect(dialog.queue_free)
	dialog.canceled.connect(dialog.queue_free)
	add_child(dialog)
	dialog.popup_centered()

func _on_progress(_ratio: float, label: String) -> void:
	_step += 1
	_progress.value = float(_step) / TOTAL_STEPS * 100.0
	_status.text = "正在加载: %s" % label

func _on_tutorial_pressed() -> void:
	GameState.reset()
	GameState.is_tutorial = true
	get_tree().change_scene_to_file("res://scenes/main.tscn")
