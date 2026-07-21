@tool
extends Control

@onready var text_edit: LineEdit = %TextEdit
@onready var shape_button: OptionButton = %ShapeButton
@onready var node_color: ColorPickerButton = %NodeColor
@onready var border_color: ColorPickerButton = %BorderColor
@onready var text_color: ColorPickerButton = %TextColor
@onready var size_slider: HSlider = %Size

var node: Control

func set_node(n: Control):
	node = n
	
	text_edit.text = node.label.text
	shape_button.selected = node.shape
	node_color.color = node.color
	border_color.color = node.border_color
	text_color.color = node.text_color
	size_slider.set_value_no_signal(node.node_size)

func _on_text_edit_text_changed(new_text: String) -> void:
	node.label.text = new_text

func _on_shape_button_item_selected(index: int) -> void:
	node.shape = index
	node.queue_redraw()

func _on_node_color_color_changed(color: Color) -> void:
	node.color = color
	node.queue_redraw()

func _on_border_color_color_changed(color: Color) -> void:
	node.border_color = color
	node.queue_redraw()

func _on_text_color_color_changed(color: Color) -> void:
	node.text_color = color

func _on_size_value_changed(value: float) -> void:
	node.node_size = value
