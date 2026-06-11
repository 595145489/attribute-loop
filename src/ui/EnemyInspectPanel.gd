class_name EnemyInspectPanel
extends PanelContainer

var _enemy: Enemy = null
var _content: VBoxContainer

func _ready() -> void:
	hide()
	var close_btn: Button = $VBox/CloseButton
	if close_btn:
		close_btn.pressed.connect(close)

func open(enemy: Enemy) -> void:
	_enemy = enemy
	_build()
	show()
	GameState.pause_for_panel()

func close() -> void:
	hide()
	_enemy = null
	GameState.unpause_for_panel()

func _build() -> void:
	var vbox: VBoxContainer = $VBox
	for child in vbox.get_children():
		if child.name != "CloseButton":
			child.queue_free()

	var name_label := Label.new()
	name_label.text = _enemy.enemy_id
	name_label.add_theme_font_size_override("font_size", 18)
	vbox.add_child(name_label)
	vbox.move_child(name_label, 0)

	var hp_label := Label.new()
	hp_label.text = "HP: %d / %d" % [_enemy.hp, _enemy.hp_max]
	vbox.add_child(hp_label)

	var stats_label := Label.new()
	stats_label.text = "攻击: %d    间隔: %.1fs" % [_enemy.dmg, _enemy.attack_interval]
	vbox.add_child(stats_label)

	if _enemy.components.is_empty():
		var empty_label := Label.new()
		empty_label.text = "无携带组件"
		vbox.add_child(empty_label)
		return

	var sep := HSeparator.new()
	vbox.add_child(sep)

	var comps_label := Label.new()
	comps_label.text = "携带组件："
	vbox.add_child(comps_label)

	var i := 0
	while i + 1 < _enemy.components.size():
		var t: ComponentData = _enemy.components[i]
		var e: ComponentData = _enemy.components[i + 1]
		var row := HBoxContainer.new()

		var t_btn := Button.new()
		t_btn.text = "%s (×%.0f)" % [t.display_name, t.trigger_value]
		var t_icon := ComponentIcons.get_icon(t.id)
		if t_icon:
			t_btn.icon = t_icon
		t_btn.mouse_entered.connect(func(): Tooltip.show_tip(Tooltip.build_trigger_tip(t)))
		t_btn.mouse_exited.connect(Tooltip.hide_tip)
		t_btn.focus_mode = Control.FOCUS_NONE
		row.add_child(t_btn)

		var arrow := Label.new()
		arrow.text = " → "
		row.add_child(arrow)

		var e_btn := Button.new()
		e_btn.text = "%s (%.1f)" % [e.display_name, e.effect_value]
		var e_icon := ComponentIcons.get_icon(e.id)
		if e_icon:
			e_btn.icon = e_icon
		e_btn.mouse_entered.connect(func(): Tooltip.show_tip(Tooltip.build_effect_tip(e)))
		e_btn.mouse_exited.connect(Tooltip.hide_tip)
		e_btn.focus_mode = Control.FOCUS_NONE
		row.add_child(e_btn)

		vbox.add_child(row)
		i += 2
