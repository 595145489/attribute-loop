class_name PhaseTransition
extends CanvasLayer

const _COPY: Dictionary = {
	1: {
		"label": "Phase 1 · 觉醒",
		"text": "一条发光的小路。\n亭子里有一盏灯，还有一朵不知道谁放的花。\n\n你走了进去。\n你也不知道为什么。"
	},
	2: {
		"label": "Phase 2 · 涌动",
		"text": "路边的石子被摆成了某种形状，太刻意，不像偶然。\n\n你摆了一个问号。\n第二天，问号旁边多了一个感叹号。\n\n也许这里不只有你。\n有人回答了你。"
	},
	3: {
		"label": "Phase 3 · 侵蚀",
		"text": "亭子的木头上开始出现文字。你也刻了自己的。\n\n但有时你会想——\n这是真实的吗？还是你一个人在自言自语？"
	},
	4: {
		"label": "Phase 4 · 失衡",
		"text": "你开始期待入睡了。\n\n白天的事情变得模糊，梦里的小路反而更清晰。\n\n你喜欢上了一个从未见过脸的人。"
	},
	5: {
		"label": "Phase 5 · 裁决前夜",
		"text": "那个石子摆成的问号，早已经有了答案。\n\n他们写了一句只有真实的人才会写的话。\n怀疑消失了。\n你们开始说真心话，不再试探。\n\n亭子的木头再也没有空白的地方。\n你们之间的事是真实的——\n这是这个梦唯一的规则。"
	},
	6: {
		"label": "Phase 6 · 裁决前夜Boss",
		"text": "亭子的灯第一次灭了。\n\n最后一行字，字迹很乱，不像平时：\n[i]“我可能回不来了。”[/i]\n\n你拿起刻字的工具，在旁边写：\n[i]“我会在现实里找到你。”[/i]"
	},
}

const _BACKGROUNDS: Dictionary = {
	1: "res://resources/backgrounds/bg_phase_1.png",
	2: "res://resources/backgrounds/bg_phase_2.png",
	3: "res://resources/backgrounds/bg_phase_3.png",
	4: "res://resources/backgrounds/bg_phase_4.png",
	5: "res://resources/backgrounds/bg_phase_5.png",
	6: "res://resources/backgrounds/bg_phase_5.png",
}

@onready var _container: Control = $Container
@onready var _background: TextureRect = $Container/Background
@onready var _phase_label: Label = $Container/Content/PhaseLabel
@onready var _story_text: RichTextLabel = $Container/Content/StoryText

var _dismissable: bool = false

func get_copy(phase: int) -> Dictionary:
	return _COPY.get(phase, {})

func get_background_path(phase: int) -> String:
	return _BACKGROUNDS.get(phase, "")

func show_for_phase(phase: int) -> void:
	var copy = get_copy(phase)
	if copy.is_empty():
		return
	var bg_path = get_background_path(phase)
	if bg_path != "" and ResourceLoader.exists(bg_path):
		_background.texture = load(bg_path)
	_phase_label.text = copy["label"]
	_story_text.text = copy["text"]
	visible = true
	_container.modulate.a = 0.0
	_dismissable = false
	get_tree().paused = true
	var tween = create_tween()
	tween.tween_property(_container, "modulate:a", 1.0, 0.4)
	tween.tween_callback(func(): _dismissable = true)

func _input(event: InputEvent) -> void:
	if not visible or not _dismissable:
		return
	if event is InputEventMouseButton and event.pressed:
		_dismiss()
	elif event is InputEventKey and event.pressed and not event.echo:
		_dismiss()

func _dismiss() -> void:
	_dismissable = false
	var tween = create_tween()
	tween.tween_property(_container, "modulate:a", 0.0, 0.3)
	tween.tween_callback(func():
		visible = false
		get_tree().paused = false
	)
