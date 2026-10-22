@tool
extends MarginContainer

enum Shape { RECT, ROUND_RECT, PARRALLELOGRAM, RHOMB, OVAL, CIRCLE }

var label: Label
var line_edit: LineEdit
var graph: MindMap.MindGraph

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
		line_edit_dirty = true

var node_size := 14:
	set(s):
		node_size = s
		rounded_sb = null
		label.add_theme_font_size_override(&"font_size", s)
		line_edit_dirty = true
		reset_size.call_deferred()

var dragging_from := Vector2.INF
var dragging_origin: Vector2
var dragging_active: bool
var rounded_sb: StyleBoxFlat

var last_text: String
var line_edit_dirty := true

signal selected
signal connected
signal changed

func get_data() -> Dictionary:
	var defaults := graph.default_node
	
	var data: Dictionary
	data.position = position + size * 0.5
	if not label.text.is_empty():
		data.text = label.text
	if not text_color.is_equal_approx(defaults.text_color):
		data.text_color = text_color.to_html(false)
	if not color.is_equal_approx(defaults.color):
		data.color = color.to_html(false)
	if not border_color.is_equal_approx(defaults.border_color):
		data.border_color = border_color.to_html(false)
	if shape != defaults.shape:
		data.shape = shape
	if node_size != defaults.node_size:
		data.size = node_size
	return data

func set_data(data: Dictionary) -> void:
	var defaults := graph.default_node
	
	var pos: String = data["position"].substr(1)
	position.x = pos.get_slice(",", 0).to_float()
	position.y = pos.get_slice(",", 1).to_float()
	label.text = data.get("text", "")
	text_color = Color(data.get("text_color", defaults.text_color))
	color = Color(data.get("color", defaults.color))
	border_color = Color(data.get("border_color", defaults.border_color))
	shape = data.get("shape", defaults.shape)
	node_size = data.get("size", defaults.node_size)
	
	reset_size()

func copy_style(from: MindMap.MindNode):
	text_color = from.text_color
	color = from.color
	border_color = from.border_color
	shape = from.shape
	node_size = from.node_size
	queue_redraw()

func get_tangent_point(direction: Vector2) -> Vector2:
	match shape:
		Shape.RECT, Shape.ROUND_RECT:
			return _get_rect_intersection(size * 0.5, direction)
		
		Shape.PARRALLELOGRAM:
			# TODO
			return _get_rect_intersection(size * 0.5, direction)
		
		Shape.RHOMB:
			var center_shift := size * 0.5
			var polygon: PackedVector2Array = [
				Vector2(-node_size, size.y * 0.5) - center_shift,
				Vector2(size.x * 0.5, -node_size - size.x * 0.2) - center_shift,
				Vector2(size.x + node_size, size.y * 0.5) - center_shift,
				Vector2(size.x * 0.5, size.y + node_size + size.x * 0.2) - center_shift
			]
			
			if direction.x < 0 and direction.y > 0:
				return Geometry2D.line_intersects_line(Vector2(), direction, polygon[0], (polygon[3] - polygon[0]).normalized())
			elif direction.x < 0 and direction.y < 0:
				return Geometry2D.line_intersects_line(Vector2(), direction, polygon[0], (polygon[1] - polygon[0]).normalized())
			elif direction.x > 0 and direction.y < 0:
				return Geometry2D.line_intersects_line(Vector2(), direction, polygon[2], (polygon[1] - polygon[2]).normalized())
			elif direction.x > 0 and direction.y > 0:
				return Geometry2D.line_intersects_line(Vector2(), direction, polygon[2], (polygon[3] - polygon[2]).normalized())
		
		Shape.OVAL:
			# TODO
			return _get_rect_intersection(Vector2(size.x, size.y + size.x * 0.2) * 0.5, direction)
		
		Shape.CIRCLE:
			var radius := maxf(size.x, size.y) * 0.5
			return direction * radius
	
	return Vector2()

func unselect():
	draw_selection = false
	if line_edit.is_editing():
		line_edit.unedit()
		_end_edit(true)
	queue_redraw()

func _get_rect_intersection(extents: Vector2, direction: Vector2) -> Vector2:
			var x := 0
			var y := 0
			
			if direction.x < 0:
				y = Geometry2D.line_intersects_line(-extents, Vector2.DOWN, Vector2(), direction).y
			elif direction.x > 0:
				y = Geometry2D.line_intersects_line(extents, Vector2.UP, Vector2(), direction).y
			
			if direction.y < 0:
				x = Geometry2D.line_intersects_line(-extents, Vector2.RIGHT, Vector2(), direction).x
			elif direction.y > 0:
				x = Geometry2D.line_intersects_line(extents, Vector2.LEFT, Vector2(), direction).x
			
			return Vector2(clampf(x, -extents.x, extents.x), clampf(y, -extents.y, extents.y))
		

func _notification(what: int) -> void:
	if what == NOTIFICATION_SCENE_INSTANTIATED:
		label = %Label
		line_edit = %LineEdit

func _gui_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb:
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				if mb.double_click and check_edit.call():
					line_edit.text = label.text
					if line_edit_dirty:
						line_edit.begin_bulk_theme_override()
						line_edit.add_theme_font_size_override(&"font_size", node_size)
						line_edit.add_theme_color_override(&"font_color", text_color)
						line_edit.add_theme_color_override(&"caret_color", text_color)
						line_edit.end_bulk_theme_override()
						line_edit_dirty = false
					
					label.modulate.a = 0
					line_edit.show()
					line_edit.edit()
					line_edit.select_all()
				else:
					if check_edit.call():
						dragging_from = mb.global_position
						dragging_origin = position
					selected.emit()
			elif not mb.pressed:
				var undo_redo := MindMap.MindDock.singleton.undo_redo
				undo_redo.create_action("Move Node")
				undo_redo.add_do_property(self, &"position", position)
				undo_redo.add_undo_property(self, &"position", dragging_origin)
				undo_redo.commit_action(false)
				
				dragging_from = Vector2.INF
				dragging_active = false
			
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
		position = dragging_origin + (mm.global_position - dragging_from)
		changed.emit()
		accept_event()

func _draw() -> void:
	if is_part_of_edited_scene():
		return
	
	var selection_color := graph.selection_color
	
	var border_size := node_size / 7
	match shape:
		Shape.CIRCLE:
			draw_circle(size * 0.5, maxf(size.x, size.y) * 0.5, color)
			draw_circle(size * 0.5, maxf(size.x, size.y) * 0.5, border_color, false, border_size)
			
			if draw_selection:
				draw_circle(size * 0.5, maxf(size.x, size.y) * 0.5 + 8, selection_color, false)
		
		Shape.OVAL:
			var oval_size := Vector2(size.x, size.y + size.x * 0.2)
			draw_ellipse(size * 0.5, oval_size.x * 0.5, oval_size.y * 0.5, color)
			draw_ellipse(size * 0.5, oval_size.x * 0.5, oval_size.y * 0.5, border_color, false, border_size)
			
			if draw_selection:
				draw_ellipse(size * 0.5, oval_size.x * 0.5 + 8, oval_size.y * 0.5 + 8, selection_color, false)
		
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
				Vector2(0, 0),
				Vector2(size.x * 1.15, 0),
				Vector2(size.x, size.y),
				Vector2(-size.x * 0.15, size.y)
			]
			draw_polygon(polygon, [color])
			
			polygon.append(polygon[0])
			draw_polyline(polygon, border_color, border_size)
			
			if draw_selection:
				draw_rect(Rect2(polygon[3].x - 8, polygon[0].y - 8, polygon[1].x - polygon[3].x + 16, polygon[2].y - polygon[0].y + 16), selection_color, false)
		
		Shape.RHOMB:
			var polygon: PackedVector2Array = [
				Vector2(-node_size, size.y * 0.5),
				Vector2(size.x * 0.5, -node_size - size.x * 0.2),
				Vector2(size.x + node_size, size.y * 0.5),
				Vector2(size.x * 0.5, size.y + node_size + size.x * 0.2)
			]
			draw_polygon(polygon, [color])
			
			polygon.append(polygon[0])
			draw_polyline(polygon, border_color, border_size)
			
			if draw_selection:
				draw_rect(Rect2(polygon[0].x - 8, polygon[1].y - 8, polygon[2].x - polygon[0].x + 16, polygon[3].y - polygon[1].y + 16), selection_color, false)

func _end_edit(accepted := true) -> void:
	if not line_edit.visible:
		return
	
	if not accepted:
		label.text = last_text
	
	label.modulate.a = 1
	line_edit.hide()

func _on_line_edit_editing_toggled(toggled_on: bool) -> void:
	if toggled_on:
		last_text = label.text
	else:
		_end_edit(not Input.is_action_pressed(&"ui_cancel"))

func _on_line_edit_text_changed(new_text: String) -> void:
	label.text = new_text
	reset_size()

func _on_line_edit_text_submitted(new_text: String) -> void:
	_end_edit()
