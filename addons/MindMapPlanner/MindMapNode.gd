@tool
extends PanelContainer

var dragging_from := Vector2.INF
var dragging_origin: Vector2
var dragging_active: bool

var try_select: bool

signal selected

func _gui_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb:
		if mb.button_index != MOUSE_BUTTON_LEFT:
			return
		
		if mb.pressed and not mb.double_click:
			dragging_from = mb.global_position
			dragging_origin = position
			try_select = true
		elif not mb.pressed:
			dragging_from = Vector2.INF
			dragging_active = false
			
			if try_select:
				selected.emit()
		
		return
	
	if not dragging_from.is_finite():
		return
	
	var mm := event as InputEventMouseMotion
	if mm:
		if not dragging_active and mm.global_position.distance_squared_to(dragging_from) < 64:
			return
		dragging_active = true
		try_select = false
		position = dragging_origin + (mm.global_position - dragging_from)
