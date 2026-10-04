@tool
extends Node2D

enum End { NONE, ARROW, DOUBLE_ARROW, DIAMOND, CIRCLE }
enum Style { CONTINUOUS, DASHED, DOTTED }

var label: Label
@onready var label_pivot: Node2D = %LabelPivot
@onready var input_handler: Control = %InputHandler

var draw_selection: bool

var node1: Control
var node2: Control

var text_color := Color.WHITE:
	set(tc):
		text_color = tc
		label.add_theme_color_override(&"font_color", tc)

var color := Color.WHITE
var end1 := End.NONE
var end2 := End.NONE
var style := Style.CONTINUOUS
var thickness := 2

signal selected

func get_data() -> Dictionary:
	var data: Dictionary
	data.node1 = node1.get_index()
	data.node2 = node2.get_index()
	data.text = label.text
	data.text_color = text_color.to_html(false)
	data.color = color.to_html(false)
	data.end1 = end1
	data.end2 = end2
	data.style = style
	data.thickness = thickness
	return data

func set_data(data: Dictionary) -> void:
	label.text = data["text"]
	text_color = data["text_color"]
	color = data["color"]
	end1 = data["end1"]
	end2 = data["end2"]
	style = data["style"]
	thickness = data["thickness"]

func _ready() -> void:
	if not is_part_of_edited_scene():
		node1.changed.connect(queue_redraw)
		node2.changed.connect(queue_redraw)

func _notification(what: int) -> void:
	if what == NOTIFICATION_SCENE_INSTANTIATED:
		label = %Label

func _on_input_handler_gui_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
		selected.emit()
		get_viewport().set_input_as_handled()

func _draw() -> void:
	if is_part_of_edited_scene():
		return
	
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
	
	var point1 := center1 - position
	var point2 := center2 - position
	draw_line(point1, point2, color, thickness)
	
	if not draw_selection:
		return
	
	var selection_color := Color.WHITE
	
	var dir := point1.direction_to(point2)
	point1 += dir * 48
	point2 -= dir * 48
	
	dir = dir.rotated(PI * 0.5) * 8
	draw_line(point1 + dir, point2 + dir, selection_color, -1)
	draw_line(point1 - dir, point2 - dir, selection_color, -1)
