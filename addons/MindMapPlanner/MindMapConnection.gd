@tool
extends Node2D

enum End { NONE = -1, ARROW, DOUBLE_ARROW, DIAMOND, CIRCLE }
enum Style { CONTINUOUS, DASHED, DOTTED }

var label: Label
var label_pivot: Node2D
var input_handler: Control
var graph: MindMap.MindGraph

var draw_selection: bool

var node1: MindMap.MindNode
var node2: MindMap.MindNode

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
	data.node1 = graph.nodes.find(node1)
	data.node2 = graph.nodes.find(node2)
	if not label.text.is_empty():
		data.text = label.text
	if not text_color.is_equal_approx(graph.default_connection.text_color):
		data.text_color = text_color.to_html(false)
	if not color.is_equal_approx(graph.default_connection.color):
		data.color = color.to_html(false)
	if end1 != graph.default_connection.end1:
		data.end1 = end1
	if end2 != graph.default_connection.end2:
		data.end2 = end2
	if style != graph.default_connection.style:
		data.style = style
	if thickness != graph.default_connection.thickness:
		data.thickness = thickness
	return data

func set_data(data: Dictionary) -> void:
	label.text = data.get("text", "")
	text_color = Color(data.get("text_color", graph.default_connection.text_color))
	color = Color(data.get("color", graph.default_connection.color))
	end1 = data.get("end1", graph.default_connection.end1)
	end2 = data.get("end2", graph.default_connection.end2)
	style = data.get("style", graph.default_connection.style)
	thickness = data.get("thickness", graph.default_connection.thickness)

func draw_end_texture(frame: int, pos: Vector2, rot: float):
	const END_TEXTURE = preload("uid://rcg0kx1eexub")
	var frame_size := Vector2(100, 100)
	var ratio := get_texture_scale()
	var draw_size := frame_size * ratio
	
	draw_set_transform(pos, rot, Vector2.ONE)
	draw_texture_rect_region(END_TEXTURE, Rect2(-draw_size * Vector2(0.9, 0.5), draw_size), Rect2(Vector2(frame * frame_size.x, 0), frame_size), color)
	draw_set_transform_matrix(Transform2D())

func get_texture_scale() -> float:
	return 0.25 + thickness * (0.05 * 0.75)

func _ready() -> void:
	if not is_part_of_edited_scene() and node1:
		node1.changed.connect(queue_redraw)
		node1.draw.connect(queue_redraw)
		node2.changed.connect(queue_redraw)
		node2.draw.connect(queue_redraw)

func _notification(what: int) -> void:
	if what == NOTIFICATION_SCENE_INSTANTIATED:
		label = %Label
		label_pivot = %LabelPivot
		input_handler = %InputHandler

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
	
	var direction := (position - center1).normalized()
	var point1 := center1 + node1.get_tangent_point(direction) - position
	var point2 := center2 + node2.get_tangent_point(-direction) - position
	
	if end1 != End.NONE:
		draw_end_texture(end1, point1, point1.angle())
		point1 += direction * 32 ## rozmiar textury
	
	if end2 != End.NONE:
		draw_end_texture(end2, point2, point2.angle())
		point2 -= direction * 32
	
	if style == Style.CONTINUOUS:
		draw_line(point1, point2, color, thickness)
	elif style == Style.DASHED:
		var dash_size := thickness * 8
		var segments: int = point1.distance_to(point2) / dash_size
		
		if segments > 0:
			for i in segments:
				if i % 2 == 0:
					draw_line(point1 + direction * i * dash_size, point1 + direction * (i + 1) * dash_size, color, thickness)
		else:
			draw_line(point1, point2, color, thickness)
	elif style == Style.DOTTED:
		var dot_radius := thickness * 0.5
		var segments: int = point1.distance_to(point2) / (dot_radius * 4)
		
		for i in segments:
			draw_circle(point1 + direction * i * dot_radius * 4, dot_radius, color)
	
	if not draw_selection:
		return
	
	var selection_color := graph.selection_color
	
	var dir := point1.direction_to(point2)
	point1 += dir * 48
	point2 -= dir * 48
	
	dir = dir.rotated(PI * 0.5) * 8
	draw_line(point1 + dir, point2 + dir, selection_color, -1)
	draw_line(point1 - dir, point2 - dir, selection_color, -1)
