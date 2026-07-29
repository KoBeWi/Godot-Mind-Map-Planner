@tool
extends Node2D

@onready var label: Label = %Label
@onready var label_pivot: Node2D = %LabelPivot
@onready var input_handler: Control = %InputHandler

var node1: Control
var node2: Control

signal selected

func get_data() -> Dictionary:
	var data: Dictionary
	data.node1 = node1.get_index()
	data.node2 = node2.get_index()
	data.text = label.text
	return data

func set_data(data: Dictionary) -> void:
	pass

func _ready() -> void:
	node1.changed.connect(queue_redraw)
	node2.changed.connect(queue_redraw)

func _on_input_handler_gui_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
		selected.emit()
		get_viewport().set_input_as_handled()

func _draw() -> void:
	var center1 := node1.position + node1.size * 0.5
	var center2 := node2.position + node2.size * 0.5
	
	position = (center1 + center2) * 0.5
	
	label_pivot.rotation = center1.angle_to_point(center2)
	if absf(label_pivot.rotation) > PI / 2:
		label_pivot.rotation += PI
	
	label.custom_minimum_size.x = center1.distance_to(center2)
	label_pivot.position = Vector2.from_angle(label_pivot.rotation - PI/2) * label.size.y
	
	input_handler.custom_minimum_size.x = label.custom_minimum_size.x
	input_handler.rotation = label_pivot.rotation
	
	draw_line(center1 - position, center2 - position, Color.WHITE, 2)
