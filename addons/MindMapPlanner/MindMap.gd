@tool
extends EditorDock

@onready var node_transform: Node2D = %NodeTransform

var panning_from := Vector2.INF
var panning_origin: Vector2

func _on_add_node() -> void:
	var node: Control = preload("uid://c3hsdtwaq6jig").instantiate()
	node.position = -node_transform.position + size * 0.5 - node.size * 0.5
	node_transform.add_child(node)

func _on_canvas_gui_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb:
		if mb.button_index == MOUSE_BUTTON_MIDDLE:
			if mb.pressed:
				panning_from = mb.position
				panning_origin = node_transform.position
			else:
				panning_from = Vector2.INF
		
		elif mb.button_index == MOUSE_BUTTON_LEFT:
			pass
		
		return
	
	if not panning_from.is_finite():
		return
	
	var mm := event as InputEventMouseMotion
	if mm:
		node_transform.position = panning_origin + (mm.position - panning_from)
