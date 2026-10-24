@tool
extends Control

@onready var text_edit: LineEdit = %TextEdit
@onready var shape_button: OptionButton = %ShapeButton
@onready var node_color: ColorPickerButton = %NodeColor
@onready var border_color: ColorPickerButton = %BorderColor
@onready var text_color: ColorPickerButton = %TextColor
@onready var size_slider: HSlider = %Size

var node: MindMap.MindNode

func set_node(n: MindMap.MindNode):
	node = n
	update_properties_for_node(node)

func update_properties_for_node(for_node: MindMap.MindNode):
	if for_node != node:
		return
	
	if not text_edit.is_editing():
		text_edit.text = for_node.label.text
	shape_button.selected = for_node.shape
	node_color.color = for_node.color
	border_color.color = for_node.border_color
	text_color.color = for_node.text_color
	size_slider.set_value_no_signal(for_node.node_size)

func set_node_property(property: StringName, new_value: Variant):
	var edited_node := node
	
	var undo_redo := MindMap.MindDock.singleton.undo_redo
	undo_redo.create_action(tr("Graph Node: %s") % property, UndoRedo.MERGE_ENDS)
	undo_redo.add_do_property(edited_node, property, new_value)
	undo_redo.add_do_method(update_properties_for_node.bind(edited_node))
	undo_redo.add_undo_property(edited_node, property, edited_node.get(property))
	undo_redo.add_undo_method(update_properties_for_node.bind(edited_node))
	
	if property == &"text":
		undo_redo.add_do_method(node.reset_size)
		undo_redo.add_undo_method(node.reset_size)
	elif property != &"text_color":
		undo_redo.add_do_method(node.queue_redraw)
		undo_redo.add_undo_method(node.queue_redraw)
	
	undo_redo.commit_action()

func _on_text_edit_text_changed(new_text: String) -> void:
	set_node_property(&"text", new_text)

func _on_shape_button_item_selected(index: int) -> void:
	set_node_property(&"shape", index)

func _on_node_color_color_changed(color: Color) -> void:
	set_node_property(&"color", color)

func _on_border_color_color_changed(color: Color) -> void:
	set_node_property(&"border_color", color)

func _on_text_color_color_changed(color: Color) -> void:
	set_node_property(&"text_color", color)

func _on_size_value_changed(value: float) -> void:
	set_node_property(&"node_size", value)
