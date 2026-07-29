@tool
extends EditorDock

@onready var node_transform: Node2D = %NodeTransform
@onready var connection_transform: Node2D = %ConnectionTransform

@onready var setting_container: PanelContainer = %SettingContainer
@onready var node_settings: VBoxContainer = %NodeSettings
@onready var connection_settings: VBoxContainer = %ConnectionSettings

var panning_from := Vector2.INF
var panning_origin: Vector2

var selected_node: Control
var selected_connection: Node2D

func create_node() -> Control:
	var node: Control = preload("uid://c3hsdtwaq6jig").instantiate()
	node.reset_size()
	node.selected.connect(_on_node_selected.bind(node))
	node.connected.connect(_attempt_connection.bind(node))
	return node

func create_connection(node1: Node, node2: Node) -> Node2D:
	var connection: Node2D = preload("uid://b64kn0iru4hto").instantiate()
	connection.node1 = node1
	connection.node2 = node2
	connection.selected.connect(_on_connection_selected.bind(connection))
	return connection

func set_active_settings(settings: Control):
	node_settings.visible = settings == node_settings
	connection_settings.visible = settings == connection_settings
	setting_container.visible = settings != null

func save_map():
	var data: Dictionary
	
	var nodes: Array[Dictionary]
	data.nodes = nodes
	for node in node_transform.get_children():
		nodes.append(node.get_data())
	
	var connections: Array[Dictionary]
	data.connections = connections
	for node in connection_transform.get_children():
		connections.append(node.get_data())
	
	var file := FileAccess.open("res://ProjectData/test.txt", FileAccess.WRITE)
	file.store_string(JSON.stringify(data, "	", false))

func load_map():
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://ProjectData/test.txt"))
	
	for node in node_transform.get_children():
		node.free()
	for node in connection_transform.get_children():
		node.free()
	
	for node_data in data["nodes"]:
		var node := create_node()
		node.ready.connect(node.set_data.bind(node_data), CONNECT_ONE_SHOT)
		node_transform.add_child(node)
	
	for connection_data in data["connections"]:
		var node1 := node_transform.get_child(connection_data["node1"])
		var node2 := node_transform.get_child(connection_data["node2"])
		var connection := create_connection(node1, node2)
		connection_transform.add_child(connection)

func _ready() -> void:
	if not is_part_of_edited_scene():
		set_active_settings(null)

func _unhandled_input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	
	var k := event as InputEventKey
	if k and k.pressed:
		if k.keycode == KEY_S:
			save_map()
		elif k.keycode == KEY_L:
			load_map()

func _on_add_node() -> void:
	var node := create_node()
	node.position = -node_transform.position + size * 0.5 - node.size * 0.5
	node_transform.add_child(node)
	
	if node_transform.get_child_count() > 1:
		var previous := node_transform.get_child(-2)
		var connection := create_connection(previous, node)
		connection_transform.add_child(connection)

func _on_node_selected(node: Control):
	selected_node = node
	selected_connection = null
	node_settings.set_node(node)
	set_active_settings(node_settings)

func _on_connection_selected(connection: Node2D):
	selected_node = null
	selected_connection = connection
	connection_settings.set_connection(connection)
	set_active_settings(connection_settings)

func _attempt_connection(to_node: Control):
	if not selected_node or selected_node == to_node:
		return
	
	for connection in connection_transform.get_children():
		if (connection.node1 == selected_node and connection.node2 == to_node) or (connection.node1 == to_node and connection.node2 == selected_node):
			connection.queue_free()
			return
	
	var connection := create_connection(selected_node, to_node)
	connection_transform.add_child(connection)

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
			selected_node = null
			selected_connection = null
			set_active_settings(null)
		
		return
	
	if not panning_from.is_finite():
		return
	
	var mm := event as InputEventMouseMotion
	if mm:
		node_transform.position = panning_origin + (mm.position - panning_from)
		connection_transform.position = node_transform.position
