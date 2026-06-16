class_name RightSidebarPanel
extends PanelContainer

@onready var rule_slots_panel: RuleSlotsPanel = $VBox/RuleSlotsPanel
@onready var service_bar = $VBox/ServiceBar

func setup(auction_manager, service_activate_popup) -> void:
	service_bar.setup(auction_manager, service_activate_popup)
