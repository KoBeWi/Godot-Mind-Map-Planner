@tool
extends AcceptDialog

const MindGraph = preload("uid://dyjdl348y6pt4").MindGraph

enum ButtonID { EDIT_GRAPH, REMOVE_GRAPH }

@onready var graph_list: Tree = %GraphList

var graphs: Array[MindGraph]

func _ready() -> void:
	graph_list.create_item()

func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED:
		if not visible:
			graph_list.deselect_all()

func load_graphs(graph_list: Array[MindGraph]):
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
	var graph := MindGraph.new()
	graph.name = "New Graph"
	graphs.append(graph)
	
	create_graph_item(graph.name)

func _on_graph_list_button_clicked(item: TreeItem, column: int, id: int, mouse_button_index: int) -> void:
	if mouse_button_index != MOUSE_BUTTON_LEFT:
		return

	match id:
		ButtonID.EDIT_GRAPH:
			pass
		
		ButtonID.REMOVE_GRAPH:
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
