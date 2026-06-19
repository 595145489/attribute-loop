class_name EnemyInspectPanel
extends PanelContainer

var _enemy: Enemy = null

func _ready() -> void:
	hide()
	$Margin/VBox/CloseButton.pressed.connect(close)

func open(enemy: Enemy) -> void:
	# Idempotent: only pause on the hidden→visible transition. Re-opening
	# (e.g. clicking another enemy while already inspecting) must NOT push the
	# panel-pause refcount again, or unpause_for_panel() on close leaves the
	# count stuck > 0 and freezes Engine.time_scale.
	var was_visible := visible
	_enemy = enemy
	_build()
	if not was_visible:
		show()
		GameState.pause_for_panel()
	EventBus.enemy_inspected.emit()

func close() -> void:
	hide()
	_enemy = null
	GameState.unpause_for_panel()

func _build() -> void:
	var vbox: VBoxContainer = $Margin/VBox
	var close_btn: Button = vbox.get_node("CloseButton")
	vbox.remove_child(close_btn)
	for child in vbox.get_children():
		child.free()

	var name_lbl := Label.new()
	name_lbl.text = _enemy.enemy_id
	name_lbl.add_theme_font_size_override("font_size", 18)
	vbox.add_child(name_lbl)

	var hp_lbl := Label.new()
	hp_lbl.text = "HP %d / %d" % [_enemy.hp, _enemy.hp_max]
	vbox.add_child(hp_lbl)

	var stats_lbl := Label.new()
	stats_lbl.text = "攻击 %d    间隔 %.1fs" % [_enemy.dmg, _enemy.attack_interval]
	vbox.add_child(stats_lbl)

	if not _enemy.components.is_empty():
		var sep := HSeparator.new()
		vbox.add_child(sep)

		var comp_lbl := Label.new()
		comp_lbl.text = "携带词条："
		vbox.add_child(comp_lbl)

		var i := 0
		while i + 1 < _enemy.components.size():
			var t: ComponentData = _enemy.components[i]
			var e: ComponentData = _enemy.components[i + 1]
			var row := HBoxContainer.new()
			row.add_theme_constant_override("separation", 4)
			row.add_child(_make_comp_widget(t, true))
			var arrow := Label.new()
			arrow.text = "→"
			row.add_child(arrow)
			row.add_child(_make_comp_widget(e, false))
			vbox.add_child(row)
			i += 2

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)
	vbox.add_child(close_btn)

func _make_comp_widget(comp: ComponentData, is_trigger: bool) -> HBoxContainer:
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 4)

	var icon_rect := TextureRect.new()
	icon_rect.custom_minimum_size = Vector2(28, 28)
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	var tex := ComponentIcons.get_icon(comp.id)
	if tex:
		icon_rect.texture = tex
	hbox.add_child(icon_rect)

	var lbl := Label.new()
	if is_trigger:
		lbl.text = "%s(×%.0f)" % [comp.display_name, comp.trigger_value]
	else:
		lbl.text = "%s(%.1f)" % [comp.display_name, comp.effect_value]
	lbl.add_theme_font_size_override("font_size", 12)
	hbox.add_child(lbl)

	hbox.mouse_entered.connect(func():
		if is_trigger:
			Tooltip.show_tip(Tooltip.build_trigger_tip(comp))
		else:
			Tooltip.show_tip(Tooltip.build_effect_tip(comp)))
	hbox.mouse_exited.connect(Tooltip.hide_tip)
	return hbox
