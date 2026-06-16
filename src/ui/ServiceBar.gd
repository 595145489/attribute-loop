extends VBoxContainer

const AuctionManager = preload("res://src/systems/AuctionManager.gd")

const CARD_TEX = preload("res://resources/ui/service_btn_card.png")

var MAX_SLOTS: int:
	get: return GameState.service_bar_max

var _auction_manager = null
var _activate_popup = null

func setup(am, popup) -> void:
	_auction_manager = am
	_activate_popup = popup
	EventBus.service_bar_changed.connect(_refresh)
	_refresh()

func _refresh() -> void:
	for c in get_children():
		if c.name == "Title":
			continue
		c.queue_free()

	if _auction_manager != null and _auction_manager._pending_overflow_service >= 0:
		if _activate_popup != null:
			_activate_popup.open_discard(
				GameState.service_bar.duplicate(),
				_auction_manager._pending_overflow_service,
				_auction_manager
			)
		return

	for i in MAX_SLOTS:
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(0, 28)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var style := StyleBoxTexture.new()
		style.texture = CARD_TEX
		style.content_margin_left = 6.0
		style.content_margin_right = 6.0
		style.content_margin_top = 4.0
		style.content_margin_bottom = 4.0
		btn.add_theme_stylebox_override("normal", style)
		btn.add_theme_stylebox_override("hover", style)
		btn.add_theme_color_override("font_color", Color(0.95, 0.88, 0.65, 1))
		if i < GameState.service_bar.size():
			var svc: int = GameState.service_bar[i]
			btn.text = AuctionManager.SERVICE_NAMES.get(svc, "?")
			btn.tooltip_text = AuctionManager.SERVICE_DESCRIPTIONS.get(svc, "")
			var idx := i
			btn.pressed.connect(_on_service_pressed.bind(svc, idx))
		else:
			btn.text = "—"
			btn.disabled = true
		add_child(btn)

func _on_service_pressed(svc: int, idx: int) -> void:
	if _activate_popup != null:
		_activate_popup.open(svc, idx)
