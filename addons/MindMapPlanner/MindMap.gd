@tool
extends EditorDock

enum Mode { SELECT, RECONNECT, STYLE }
enum NewFlags { CONNECT_TO_LAST = 1, COPY_LAST_STYLE = 2 }

@export var tool_group: ButtonGroup
@onready var new_options: MenuButton = %NewOptions

@onready var graph_select: OptionButton = %GraphSelect
@onready var graph_dialog: AcceptDialog = %GraphDialog

@onready var node_transform: Node2D = %NodeTransform
@onready var connection_transform: Node2D = %ConnectionTransform

@onready var setting_container: PanelContainer = %SettingContainer
@onready var node_settings: VBoxContainer = %NodeSettings
@onready var connection_settings: VBoxContainer = %ConnectionSettings

var save_shortcut: Shortcut

var current_mode: int = Mode.SELECT
var new_flags: int = 0

var map_path: String
var graphs: Array[MindGraph]
var active_graph: MindGraph

var panning_from := Vector2.INF
var panning_origin: Vector2

var selected_node: Control:
	set(sn):
		if selected_node == sn:
			return
		
		if selected_node:
			selected_node.unselect()
		selected_node = sn
		if selected_node:
			last_selected = selected_node
			selected_node.draw_selection = true
			selected_node.queue_redraw()

var selected_connection: Node2D:
	set(sc):
		if selected_connection == sc:
			return
		
		if selected_connection:
			selected_connection.draw_selection = false
			selected_connection.queue_redraw()
		selected_connection = sc
		if selected_connection:
			selected_connection.draw_selection = true
			selected_connection.queue_redraw()

var last_selected: Control

func update_graph_list():
	graph_select.clear()
	
	for graph in graphs:
		graph_select.add_item(graph.name)
		if graph == active_graph:
			graph_select.select(graph_select.item_count - 1)

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
	node.check_edit = _can_edit
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
		for node in graph.connections:
			connections.append(node.get_data())
		graph_data["connections"] = connections
		
		data.append(graph_data)
	
	var file := FileAccess.open(map_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(data, "	", false))

func _ready() -> void:
	if is_part_of_edited_scene():
		return
	
	save_shortcut = EditorInterface.get_editor_settings().get_shortcut("script_editor/save")
	graph_dialog.hide()
	set_active_settings(null)
	
	tool_group.pressed.connect(_on_tool_changed)
	
	if not FileAccess.file_exists(map_path):
		var default_graph := MindGraph.new()
		default_graph.name = "New Graph"
		graphs.append(default_graph)
	else:
		var data: Array = JSON.parse_string(FileAccess.get_file_as_string(map_path))
		
		for graph: Dictionary in data:
			var mind_graph := MindGraph.new()
			mind_graph.name = graph["name"]
			
			for node_data in graph["nodes"]:
				var node := create_node()
				node.set_data(node_data)
				mind_graph.nodes.append(node)
			
			for connection_data in graph["connections"]:
				var node1 := mind_graph.nodes[connection_data["node1"]]
				var node2 := mind_graph.nodes[connection_data["node2"]]
				var connection := create_connection(node1, node2)
				connection.set_data(connection_data)
				mind_graph.connections.append(connection)
			
			graphs.append(mind_graph)
	
	graph_dialog.load_graphs(graphs)
	
	var popup := new_options.get_popup()
	popup.hide_on_checkable_item_selection = false
	popup.set_item_tooltip(popup.get_item_index(NewFlags.CONNECT_TO_LAST), "If enabled, the new node will be connected to the last selected node.")
	popup.set_item_tooltip(popup.get_item_index(NewFlags.COPY_LAST_STYLE), "If enabled, the new node will copy the style of last selected node.")
	popup.index_pressed.connect(_on_new_flag_toggled)
	
	set_active_graph(graphs[0])
	update_graph_list()

func _unhandled_input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	
	if save_shortcut.matches_event(event):
		save_map() ## TODO uncomment
		EditorInterface.get_editor_toaster().push_toast("MindMap saved.")
		accept_event()

func _on_tool_changed(tool: Button) -> void:
	current_mode = tool.get_index()
	
	if current_mode == Mode.SELECT:
		if selected_node:
			set_active_settings(node_settings)
		elif selected_connection:
			set_active_settings(connection_settings)
	else:
		set_active_settings(null)

func _on_add_node() -> void:
	var node := create_node()
	node.position = -node_transform.position + size * 0.5 - node.size * 0.5
	active_graph.nodes.append(node)
	node_transform.add_child(node)
	
	if new_flags & NewFlags.CONNECT_TO_LAST and last_selected:
		var connection := create_connection(last_selected, node)
		active_graph.connections.append(connection)
		connection_transform.add_child(connection)
	
	if new_flags & NewFlags.COPY_LAST_STYLE and last_selected:
		node.copy_style(last_selected)
	
	tool_group.get_buttons()[Mode.SELECT].press()
	_on_node_selected(node)

func _manage_graphs() -> void:
	graph_dialog.popup_centered()

func _on_graph_dialog_visibility_changed() -> void:
	if not graph_dialog or graph_dialog.visible:
		return
	update_graph_list()

func _on_graph_selected(index: int) -> void:
	set_active_graph(graphs[index])

func _on_node_selected(node: Control):
	if selected_node == node:
		return
	
	if selected_node:
		match current_mode:
			Mode.RECONNECT:
				_attempt_connection(node)
				return
			
			Mode.STYLE:
				node.copy_style(selected_node)
				return
	
	selected_node = node
	selected_connection = null
	node_settings.set_node(node)
	
	if current_mode == Mode.SELECT:
		set_active_settings(node_settings)
	else:
		set_active_settings(null)

func _on_connection_selected(connection: Node2D):
	if selected_connection == connection:
		return
	
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

func _on_new_flag_toggled(idx: int):
	var popup := new_options.get_popup()
	var pressed := not popup.is_item_checked(idx)
	popup.set_item_checked(idx, pressed)
	
	var flag := popup.get_item_id(idx)
	if pressed:
		new_flags |= flag
	else:
		new_flags ^= flag

func _can_edit() -> bool:
	return current_mode == Mode.SELECT

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
	
	func _to_string() -> String:
		return "MindGraph@%s" % name
