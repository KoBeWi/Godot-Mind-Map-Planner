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

func save_map():
	var data: Dictionary
	
	var nodes: Array[Dictionary]
	data.nodes = nodes
	for node in node_transform.get_children():
		nodes.append(node.get_data())
	
	var file := FileAccess.open("res://ProjectData/test.txt", FileAccess.WRITE)
	file.store_string(JSON.stringify(data, "	", false))

func load_map():
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://ProjectData/test.txt"))
	
	for node in node_transform.get_children():
		node.free()
	
	for node_data in data["nodes"]:
		var node: Control = preload("uid://c3hsdtwaq6jig").instantiate()
		node.ready.connect(node.set_data.bind(node_data), CONNECT_ONE_SHOT)
		node_transform.add_child(node)

func _unhandled_input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	
	var k := event as InputEventKey
	if k and k.pressed:
		if k.keycode == KEY_S:
			save_map()
		elif k.keycode == KEY_L:
			load_map()
