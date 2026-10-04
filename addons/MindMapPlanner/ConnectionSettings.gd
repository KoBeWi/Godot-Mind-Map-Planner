@tool
extends Control

@onready var label_edit: LineEdit = %LabelEdit
@onready var label_color: ColorPickerButton = %LabelColor
@onready var end1: OptionButton = %End1
@onready var end2: OptionButton = %End2
@onready var line_color: ColorPickerButton = %LineColor
@onready var line_style: OptionButton = %LineStyle
@onready var thickness: SpinBox = %Thickness

var connection: Node2D

func _ready() -> void:
	if is_part_of_edited_scene():
		return
	
	for i in end1.item_count:
		end2.add_item(end1.get_item_text(i))
	end2.selected = 0

func set_connection(c: Node2D):
	connection = c
	
	label_edit.text = connection.label.text
	label_color.color = connection.text_color
	end1.selected = connection.end1
	end2.selected = connection.end2
	line_color.color = connection.color
	line_style.selected = connection.style
	thickness.value = connection.thickness

func _on_label_edit_text_changed(new_text: String) -> void:
	connection.label.text = new_text

func _on_label_color_color_changed(color: Color) -> void:
	connection.text_color = color

func _on_end_1_item_selected(index: int) -> void:
	connection.end1 = index
	connection.queue_redraw()

func _on_end_2_item_selected(index: int) -> void:
	connection.end2 = index
	connection.queue_redraw()

func _on_line_color_color_changed(color: Color) -> void:
	connection.color = color
	connection.queue_redraw()

func _on_line_style_item_selected(index: int) -> void:
	connection.style = index
	connection.queue_redraw()

func _on_thickness_value_changed(value: float) -> void:
	connection.thickness = value
	connection.queue_redraw()
