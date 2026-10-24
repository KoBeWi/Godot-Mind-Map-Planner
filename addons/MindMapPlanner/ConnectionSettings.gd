@tool
extends Control

@onready var label_edit: LineEdit = %LabelEdit
@onready var label_color: ColorPickerButton = %LabelColor
@onready var end1: OptionButton = %End1
@onready var end2: OptionButton = %End2
@onready var line_color: ColorPickerButton = %LineColor
@onready var line_style: OptionButton = %LineStyle
@onready var thickness: SpinBox = %Thickness

var connection: MindMap.MindConnection

func _ready() -> void:
	if is_part_of_edited_scene():
		return
	
	for i in end1.item_count:
		end2.add_item(end1.get_item_text(i))
		var id := end1.get_item_id(i) - 1
		end1.set_item_id(i, id)
		end2.set_item_id(i, id)
	end2.selected = 0

func set_connection(c: MindMap.MindConnection):
	connection = c
	update_properties_for_connection(connection)

func update_properties_for_connection(for_connection: MindMap.MindConnection):
	if for_connection != connection:
		return
	
	if not label_edit.is_editing():
		label_edit.text = connection.label.text
	label_color.color = connection.text_color
	end1.selected = connection.end1 + 1
	end2.selected = connection.end2 + 1
	line_color.color = connection.color
	line_style.selected = connection.style
	thickness.set_value_no_signal(connection.thickness)

func set_connection_property(property: StringName, new_value: Variant):
	var edited_connection := connection
	
	var undo_redo := MindMap.MindDock.singleton.undo_redo
	undo_redo.create_action(tr("Graph Connection: %s") % property, UndoRedo.MERGE_ENDS)
	undo_redo.add_do_property(edited_connection, property, new_value)
	undo_redo.add_do_method(update_properties_for_connection.bind(edited_connection))
	undo_redo.add_undo_property(edited_connection, property, edited_connection.get(property))
	undo_redo.add_undo_method(update_properties_for_connection.bind(edited_connection))
	
	if property != &"text" and property != &"text_color":
		undo_redo.add_do_method(connection.queue_redraw)
		undo_redo.add_undo_method(connection.queue_redraw)
	
	undo_redo.commit_action()

func _on_label_edit_text_changed(new_text: String) -> void:
	set_connection_property(&"text", new_text)

func _on_label_color_color_changed(color: Color) -> void:
	set_connection_property(&"text_color", color)

func _on_end_1_item_selected(index: int) -> void:
	set_connection_property(&"end1", end1.get_item_id(index))

func _on_end_2_item_selected(index: int) -> void:
	set_connection_property(&"end2", end2.get_item_id(index))

func _on_line_color_color_changed(color: Color) -> void:
	set_connection_property(&"color", color)

func _on_line_style_item_selected(index: int) -> void:
	set_connection_property(&"style", index)

func _on_thickness_value_changed(value: float) -> void:
	set_connection_property(&"thickness", value as int)
