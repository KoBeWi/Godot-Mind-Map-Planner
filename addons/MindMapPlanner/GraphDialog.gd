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
			graph_list.deselect_all()

func load_graphs(graph_list: Array[MindMap.MindGraph]):
	graphs = graph_list
	for graph in graphs:
		create_graph_item(graph.name)
	
func create_graph_item(text: String):
	var graph_item := graph_list.create_item()
	graph_item.set_text(0, text)
	graph_item.set_editable(0, true)
	graph_item.add_button(0, get_theme_icon(&"Edit", &"EditorIcons"), ButtonID.EDIT_GRAPH)
	graph_item.set_button_tooltip_text(0, -1, "Edit graph properties.")
	graph_item.add_button(0, get_theme_icon(&"Remove", &"EditorIcons"), ButtonID.REMOVE_GRAPH)
	graph_item.set_button_tooltip_text(0, -1, "Remove graph.")

func _add_graph() -> void:
	var graph := MindMap.MindGraph.new()
	graph.name = "New Graph"
	graphs.append(graph)
	
	create_graph_item(graph.name)

func _on_graph_list_button_clicked(item: TreeItem, column: int, id: int, mouse_button_index: int) -> void:
	if mouse_button_index != MOUSE_BUTTON_LEFT:
		return

	match id:
		ButtonID.EDIT_GRAPH:
			if edited_graph:
				_close_settings()
			
			edited_graph = graphs[item.get_index()]
			item.set_custom_color(0, get_theme_color(&"accent_color", &"Editor"))
			
			graph_name.text = edited_graph.name
			background_color.color = edited_graph.background_color
			selection_color.color = edited_graph.selection_color
			
			graph_options.show()
		
		ButtonID.REMOVE_GRAPH:
			var graph := graphs[item.get_index()]
			if graph == edited_graph:
				_close_settings()
			
			graphs.remove_at(item.get_index())
			item.free()

func _on_graph_list_reordered(from: int, to: int) -> void:
	var graph := graphs[from]
	graphs.remove_at(from)
	graphs.insert(to, graph)

func _on_graph_list_item_edited() -> void:
	var item := graph_list.get_edited()
	if item:
		graphs[item.get_index()].name = item.get_text(0)

func _on_graph_name_text_changed(new_text: String) -> void:
	edited_graph.name = new_text
	
	var idx := graphs.find(edited_graph)
	graph_list.get_root().get_child(idx).set_text(0, new_text)

func _on_background_color_color_changed(color: Color) -> void:
	edited_graph.background_color = color
	graph_changed.emit(edited_graph)

func _on_selection_color_color_changed(color: Color) -> void:
	edited_graph.selection_color = color
	graph_changed.emit(edited_graph)

func _close_settings() -> void:
	var idx := graphs.find(edited_graph)
	graph_list.get_root().get_child(idx).clear_custom_color(0)
	
	edited_graph = null
	graph_options.hide()
