extends Node

@onready var _main: Node2D = $GameRow/SubViewportContainer/GameViewport/Main
@onready var _game_viewport: SubViewport = $GameRow/SubViewportContainer/GameViewport
@onready var _hud: HUD = $UI/HUD
@onready var _strip_panel: StripPanel = $UI/StripPanel
@onready var _inventory_panel: InventoryPanel = $UI/InventoryPanel
@onready var _tile_rule_panel = $UI/TileRulePanel
@onready var _altar_panel = $UI/AltarPanel
@onready var _auction_panel = $UI/AuctionPanel
@onready var _right_sidebar: RightSidebarPanel = $GameRow/RightSidebarPanel
@onready var _service_activate_popup = $UI/ServiceActivatePopup
@onready var _ui: Node = $UI

func _ready() -> void:
	_main.setup_ui({
		"strip_panel": _strip_panel,
		"inventory_panel": _inventory_panel,
		"tile_rule_panel": _tile_rule_panel,
		"altar_panel": _altar_panel,
		"hud": _hud,
		"auction_panel": _auction_panel,
		"right_sidebar": _right_sidebar,
		"service_activate_popup": _service_activate_popup,
		"ui_node": _ui,
	})
