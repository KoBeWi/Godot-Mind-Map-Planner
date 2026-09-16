@tool
extends EditorDock

@onready var node_transform: Node2D = %NodeTransform
@onready var connection_transform: Node2D = %ConnectionTransform

@onready var setting_container: PanelContainer = %SettingContainer
@onready var node_settings: VBoxContainer = %NodeSettings
@onready var connection_settings: VBoxContainer = %ConnectionSettings

var map_path: String
var graphs: Array[MindGraph]
var active_graph: MindGraph

var panning_from := Vector2.INF
var panning_origin: Vector2

var selected_node: Control
var selected_connection: Node2D

func set_active_graph(graph: MindGraph):
	for node in node_transform.get_children():
		node_transform.remove_child(node)
	for node in connection_transform.get_children():
		connection_transform.remove_child(node)
	
	for node in graph.nodes:
		node_transform.add_child(node)
	for node in graph.connections:
		connection_transform.add_child(node)
	
	active_graph = graph

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
	var data: Array[Dictionary]
	
	for graph in graphs:
		var graph_data: Dictionary[String, Variant]
		graph_data["name"] = graph.name
		
		var nodes: Array[Dictionary]
		for node in graph.nodes:
			nodes.append(node.get_data())
		graph_data["nodes"] = nodes
		
		var connections: Array[Dictionary]
		for node in connection_transform.get_children():
			connections.append(node.get_data())
		graph_data["connections"] = connections
		
		data.append(graph_data)
	
	var file := FileAccess.open(map_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(data, "	", false))

func _ready() -> void:
	if is_part_of_edited_scene():
		return
	
	set_active_settings(null)
	
	if not FileAccess.file_exists(map_path):
		graphs.append(MindGraph.new())
		return
	
	var data: Array = JSON.parse_string(FileAccess.get_file_as_string(map_path))
	
	for graph: Dictionary in data:
		var mind_graph := MindGraph.new()
		mind_graph.name = graph["name"]
		
		for node_data in graph["nodes"]:
			var node := create_node()
			node.ready.connect(node.set_data.bind(node_data), CONNECT_ONE_SHOT)
			mind_graph.nodes.append(node)
		
		for connection_data in graph["connections"]:
			var node1 := mind_graph.nodes[connection_data["node1"]]
			var node2 := mind_graph.nodes[connection_data["node2"]]
			var connection := create_connection(node1, node2)
			mind_graph.connections.append(connection)
		
		graphs.append(mind_graph)
	
	set_active_graph(graphs[0])

func _unhandled_input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	
	var k := event as InputEventKey
	if k and not k.pressed:
		if k.keycode == KEY_S:
			save_map()

func _on_add_node() -> void:
	var node := create_node()
	node.position = -node_transform.position + size * 0.5 - node.size * 0.5
	active_graph.nodes.append(node)
	node_transform.add_child(node)
	
	if node_transform.get_child_count() > 1:
		var previous := node_transform.get_child(-2)
		var connection := create_connection(previous, node)
		active_graph.connections.append(connection)
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
	active_graph.connections.append(connection)
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

class MindGraph:
	var name: String
	var nodes: Array[Node]
	var connections: Array[Node]
