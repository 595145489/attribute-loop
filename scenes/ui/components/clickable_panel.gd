extends PanelContainer

signal pressed

var _hover_color := Color(0.82, 0.72, 0.6, 1.0)
var _pressed_color := Color(0.62, 0.52, 0.4, 1.0)

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_STOP

func _gui_input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
        if event.pressed:
            modulate = _pressed_color
        else:
            modulate = Color.WHITE
            pressed.emit()
        accept_event()

func _notification(what: int) -> void:
    match what:
        NOTIFICATION_MOUSE_ENTER:
            modulate = _hover_color
        NOTIFICATION_MOUSE_EXIT:
            modulate = Color.WHITE
