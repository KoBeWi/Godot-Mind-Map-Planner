@tool
extends AcceptDialog

enum ButtonID { EDIT_GRAPH, REMOVE_GRAPH }

@onready var graph_list: Tree = %GraphList
@onready var graph_options: PanelContainer = %GraphOptions

@onready var graph_name: LineEdit = %GraphName
@onready var background_color: ColorPickerButton = %BackgroundColor
@onready var selection_color: ColorPickerButton = %SelectionColor

var graphs: Array[MindMap.MindGraph]
var edited_graph: MindMap.MindGraph

signal graph_changed(graph: MindMap.MindGraph)

func _ready() -> void:
	graph_list.create_item()
	
	if not is_part_of_edited_scene():
		graph_options.hide()

func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED:
		if not visible:
			_close_settings()
			graph_list.deselect_all()

func _unhandled_input(event: InputEvent) -> void:
	var k := event as InputEventKey
	if k and k.pressed:
		if k.is_action(&"ui_undo", true):
			if MindMap.MindDock.singleton.undo():
				set_input_as_handled()
		elif k.is_action(&"ui_redo", true):
			if MindMap.MindDock.singleton.redo():
				set_input_as_handled()

func load_graphs(graph_list: Array[MindMap.MindGraph]):
	graphs = graph_list
	for graph in graphs:
		create_graph_item(graph.name)
	
func create_graph_item(text: String) -> TreeItem:
	var graph_item := graph_list.create_item()
	graph_item.set_text(0, text)
	graph_item.set_editable(0, true)
	graph_item.add_button(0, get_theme_icon(&"Edit", &"EditorIcons"), ButtonID.EDIT_GRAPH)
	graph_item.set_button_tooltip_text(0, -1, "Edit graph properties.")
	
	if graphs.size() > 1:
		graph_item.add_button(0, get_theme_icon(&"Remove", &"EditorIcons"), ButtonID.REMOVE_GRAPH)
		graph_item.set_button_tooltip_text(0, -1, "Remove graph.")
	
	return graph_item

func reload_graphs():
	graph_list.clear()
	graph_list.create_item()
	
	for graph in graphs:
		var item := create_graph_item(graph.name)
		if graph == edited_graph:
			item.set_custom_color(0, get_theme_color(&"accent_color", &"Editor"))
	
	if not visible:
		MindMap.MindDock.singleton.update_graph_list()

func update_properties_for_graph(graph: MindMap.MindGraph):
	if graph != edited_graph:
		return
	graph_name.text = graph.name
	background_color.color = graph.background_color
	selection_color.color = graph.selection_color

func set_graph_property(property: StringName, new_value: Variant):
	var graph := edited_graph
	
	var undo_redo := MindMap.MindDock.singleton.undo_redo
	undo_redo.create_action(tr("Graph Set: %s") % property, UndoRedo.MERGE_ENDS)
	undo_redo.add_do_property(edited_graph, property, new_value)
	undo_redo.add_do_method(update_properties_for_graph.bind(edited_graph))
	undo_redo.add_do_method(func(): graph_changed.emit(graph))
	undo_redo.add_undo_property(edited_graph, property, edited_graph.get(property))
	undo_redo.add_undo_method(update_properties_for_graph.bind(edited_graph))
	undo_redo.add_undo_method(func(): graph_changed.emit(graph))
	undo_redo.commit_action()

func _add_graph() -> void:
	var graph := MindMap.MindGraph.new()
	graph.name = "New Graph"
	graphs.append(graph)
	create_graph_item(graph.name)
	
	if graphs.size() == 2:
		reload_graphs()
	
	var undo_redo := MindMap.MindDock.singleton.undo_redo
	undo_redo.create_action("Add Graph")
	#undo_redo.add_do_method(graphs.append.bind(graph))
	undo_redo.add_do_method(func(): graphs.append(graph))
	undo_redo.add_do_method(reload_graphs)
	undo_redo.add_do_reference(graph)
	#undo_redo.add_undo_method(graphs.erase.bind(graph))
	undo_redo.add_undo_method(func(): graphs.erase(graph))
	undo_redo.add_undo_method(reload_graphs)
	undo_redo.commit_action(false)

func _on_graph_list_button_clicked(item: TreeItem, column: int, id: int, mouse_button_index: int) -> void:
	if mouse_button_index != MOUSE_BUTTON_LEFT:
		return

	match id:
		ButtonID.EDIT_GRAPH:
			if edited_graph:
				_close_settings()
			
			edited_graph = graphs[item.get_index()]
			item.set_custom_color(0, get_theme_color(&"accent_color", &"Editor"))
			
			update_properties_for_graph(edited_graph)
			
			graph_options.show()
		
		ButtonID.REMOVE_GRAPH:
			var graph := graphs[item.get_index()]
			if graph == edited_graph:
				_close_settings()
			
			var index := item.get_index()
			graphs.remove_at(index)
			item.free()
			
			if graphs.size() == 1:
				reload_graphs()
			
			var undo_redo := MindMap.MindDock.singleton.undo_redo
			undo_redo.create_action("Remove Graph")
			#undo_redo.add_do_method(graphs.append.bind(graph))
			undo_redo.add_do_method(func(): graphs.remove_at(index))
			undo_redo.add_do_method(reload_graphs)
			#undo_redo.add_undo_method(graphs.erase.bind(graph))
			undo_redo.add_undo_method(func(): graphs.insert(index, graph))
			undo_redo.add_undo_method(reload_graphs)
			undo_redo.add_undo_reference(graph)
			undo_redo.commit_action(false)

func _on_graph_list_reordered(from: int, to: int) -> void:
	var graph := graphs[from]
	graphs.remove_at(from)
	graphs.insert(to, graph)
	
	var undo_redo := MindMap.MindDock.singleton.undo_redo
	undo_redo.create_action("Reorder Graphs")
	undo_redo.add_do_method(func():
		graphs.remove_at(from)
		graphs.insert(to, graph))
	undo_redo.add_do_method(reload_graphs)
	undo_redo.add_undo_method(func():
		graphs.remove_at(to)
		graphs.insert(from, graph))
	undo_redo.add_undo_method(reload_graphs)
	undo_redo.commit_action(false)

func _on_graph_list_item_edited() -> void:
	var item := graph_list.get_edited()
	if item:
		var graph := graphs[item.get_index()]
		var old_name := graph.name
		var new_name := item.get_text(0)
		graph.name = new_name
		
		var undo_redo := MindMap.MindDock.singleton.undo_redo
		undo_redo.create_action("Rename Graph")
		undo_redo.add_do_property(graph, &"name", new_name)
		undo_redo.add_do_method(reload_graphs)
		undo_redo.add_undo_property(graph, &"name", old_name)
		undo_redo.add_undo_method(reload_graphs)
		undo_redo.commit_action(false)

func _on_graph_name_text_changed(new_text: String) -> void:
	var old_name := edited_graph.name
	edited_graph.name = new_text
	
	var idx := graphs.find(edited_graph)
	graph_list.get_root().get_child(idx).set_text(0, new_text)
	
	var graph := edited_graph
	var undo_redo := MindMap.MindDock.singleton.undo_redo
	undo_redo.create_action("Rename Graph", UndoRedo.MERGE_ENDS)
	undo_redo.add_do_property(graph, &"name", new_text)
	undo_redo.add_do_method(update_properties_for_graph.bind(graph))
	undo_redo.add_do_method(reload_graphs)
	undo_redo.add_undo_property(graph, &"name", old_name)
	undo_redo.add_undo_method(update_properties_for_graph.bind(graph))
	undo_redo.add_undo_method(reload_graphs)
	undo_redo.commit_action(false)

func _on_background_color_color_changed(color: Color) -> void:
	set_graph_property(&"background_color", color)

func _on_selection_color_color_changed(color: Color) -> void:
	set_graph_property(&"selection_color", color)

func _close_settings() -> void:
	var idx := graphs.find(edited_graph)
	graph_list.get_root().get_child(idx).clear_custom_color(0)
	
	edited_graph = null
	graph_options.hide()
