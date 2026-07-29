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
	for i in end1.item_count:
		end2.add_item(end1.get_item_text(i))
	end2.selected = 0

func set_connection(c: Node2D):
	connection = c
	
	label_edit.text = connection.label.text

func _on_label_edit_text_changed(new_text: String) -> void:
	connection.label.text = new_text
