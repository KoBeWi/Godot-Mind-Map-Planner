@tool
extends MarginContainer

enum Shape { RECT, ROUND_RECT, PARRALLELOGRAM, RHOMB, OVAL, CIRCLE }

var label: Label
var line_edit: LineEdit

var check_edit: Callable
var draw_selection: bool

var shape := Shape.RECT
var color := Color.WHITE:
	set(c):
		color = c
		rounded_sb = null

var border_color := Color.BLACK:
	set(c):
		border_color = c
		rounded_sb = null

var text_color := Color.BLACK:
	set(tc):
		text_color = tc
		label.add_theme_color_override(&"font_color", tc)

var node_size := 14:
	set(s):
		node_size = s
		rounded_sb = null
		label.add_theme_font_size_override(&"font_size", s)
		reset_size()

var dragging_from := Vector2.INF
var dragging_origin: Vector2
var dragging_active: bool
var rounded_sb: StyleBoxFlat

var try_select: bool

signal selected
signal connected
signal changed

func get_data() -> Dictionary:
	var data: Dictionary
	data.position = position
	data.text = label.text
	data.text_color = text_color.to_html(false)
	data.color = color.to_html(false)
	data.border_color = border_color.to_html(false)
	data.shape = shape
	data.size = node_size
	return data

func set_data(data: Dictionary) -> void:
	var pos: String = data["position"].substr(1)
	position.x = pos.get_slice(",", 0).to_float()
	position.y = pos.get_slice(",", 1).to_float()
	label.text = data["text"]
	text_color = Color(data["text_color"])
	color = Color(data["color"])
	border_color = Color(data["border_color"])
	shape = data["shape"]
	node_size = data["size"]
	
	reset_size()

func copy_style(from: Control):
	text_color = from.text_color
	color = from.color
	border_color = from.border_color
	shape = from.shape
	node_size = from.node_size
	queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_SCENE_INSTANTIATED:
		label = %Label
		line_edit = %LineEdit

func _gui_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb:
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				if mb.double_click:
					if not check_edit.call():
						return
					
					line_edit.text = label.text
					label.hide()
					line_edit.show()
					line_edit.edit()
					line_edit.select_all()
				else:
					if check_edit.call():
						dragging_from = mb.global_position
						dragging_origin = position
					try_select = true
			elif not mb.pressed:
				dragging_from = Vector2.INF
				dragging_active = false
				
				if try_select:
					selected.emit()
			
			accept_event()
		
		elif mb.button_index == MOUSE_BUTTON_RIGHT and mb.pressed:
			connected.emit()
			accept_event()
		
		return
	
	if not dragging_from.is_finite():
		return
	
	var mm := event as InputEventMouseMotion
	if mm:
		if not dragging_active and mm.global_position.distance_squared_to(dragging_from) < 64:
			return
		dragging_active = true
		try_select = false
		position = dragging_origin + (mm.global_position - dragging_from)
		changed.emit()
		accept_event()

func _draw() -> void:
	var selection_color := Color.WHITE
	
	var border_size := node_size / 7
	match shape:
		Shape.CIRCLE:
			draw_circle(size * 0.5, maxf(size.x, size.y) * 0.5, color)
			draw_circle(size * 0.5, maxf(size.x, size.y) * 0.5, border_color, false, border_size)
			
			if draw_selection:
				draw_circle(size * 0.5, maxf(size.x, size.y) * 0.5 + 8, selection_color, false)
		
		Shape.OVAL:
			draw_ellipse(size * 0.5, size.x * 0.5, size.y * 0.5, color)
			draw_ellipse(size * 0.5, size.x * 0.5, size.y * 0.5, border_color, false, border_size)
			
			if draw_selection:
				draw_ellipse(size * 0.5, size.x * 0.5 + 8, size.y * 0.5 + 8, selection_color, false)
		
		Shape.RECT:
			draw_rect(Rect2(Vector2(), size), color)
			draw_rect(Rect2(Vector2(), size), border_color, false, border_size)
			
			if draw_selection:
				draw_rect(Rect2(Vector2(), size).grow(8), selection_color, false)
		
		Shape.ROUND_RECT:
			if not rounded_sb:
				rounded_sb = StyleBoxFlat.new()
				rounded_sb.bg_color = color
				rounded_sb.border_color = border_color
				rounded_sb.set_corner_radius_all(node_size / 2 + 9)
				rounded_sb.set_border_width_all(border_size)
			
			draw_style_box(rounded_sb, Rect2(Vector2(), size))
			if draw_selection:
				draw_rect(Rect2(Vector2(), size).grow(8), selection_color, false)
		
		Shape.PARRALLELOGRAM:
			var polygon: PackedVector2Array = [
				Vector2(size.x * 0.15, 0),
				Vector2(size.x, 0),
				Vector2(size.x * 0.85, size.y),
				Vector2(0, size.y)
			]
			draw_polygon(polygon, [color])
			
			polygon.append(polygon[0])
			draw_polyline(polygon, border_color, border_size)
			
			if draw_selection:
				for i in 4:
					var p := polygon[i]
					p += (p - size * 0.5).normalized() * 8
					polygon[i] = p
				
				polygon[4] = polygon[0]
				draw_polyline(polygon, selection_color)
		
		Shape.RHOMB:
			var polygon: PackedVector2Array = [
				Vector2(0, size.y * 0.5),
				Vector2(size.x * 0.5, 0),
				Vector2(size.x, size.y * 0.5),
				Vector2(size.x * 0.5, size.y)
			]
			draw_polygon(polygon, [color])
			
			polygon.append(polygon[0])
			draw_polyline(polygon, border_color, border_size)
			
			if draw_selection:
				for i in 4:
					var p := polygon[i]
					p += (p - size * 0.5).normalized() * 8
					polygon[i] = p
				
				polygon[4] = polygon[0]
				draw_polyline(polygon, selection_color)

func _end_edit(accepted := true) -> void:
	if not line_edit.visible:
		return
	
	if accepted:
		label.text = line_edit.text
	
	label.show()
	line_edit.hide()

func _on_line_edit_editing_toggled(toggled_on: bool) -> void:
	if not toggled_on:
		_end_edit(not Input.is_action_pressed(&"ui_cancel"))

func _on_line_edit_text_submitted(new_text: String) -> void:
	_end_edit()
