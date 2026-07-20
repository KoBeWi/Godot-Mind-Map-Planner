@tool
extends MarginContainer

enum Shape{ CIRCLE, OVAL, RECT, ROUND_RECT, PARRALLELOGRAM, RHOMB}

@onready var label: Label = %Label
@onready var line_edit: LineEdit = %LineEdit

var shape := Shape.RECT
var color := Color.WHITE

var dragging_from := Vector2.INF
var dragging_origin: Vector2
var dragging_active: bool

var try_select: bool

signal selected

func get_data() -> Dictionary:
	var data: Dictionary
	data.position = position
	data.text = label.text
	data.color = color.to_html(false)
	return data

func set_data(data: Dictionary):
	var pos: String = data["position"].substr(1)
	position.x = pos.get_slice(",", 0).to_float()
	position.y = pos.get_slice(",", 1).to_float()
	label.text = data["text"]
	color = Color(data["color"])

func _gui_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb:
		if mb.button_index != MOUSE_BUTTON_LEFT:
			return
		
		if mb.pressed:
			if mb.double_click:
				line_edit.text = label.text
				label.hide()
				line_edit.show()
				line_edit.edit()
				line_edit.select_all()
			else:
				dragging_from = mb.global_position
				dragging_origin = position
				try_select = true
		elif not mb.pressed:
			dragging_from = Vector2.INF
			dragging_active = false
			
			if try_select:
				selected.emit()
		
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

func _draw() -> void:
	match shape:
		Shape.RECT:
			draw_rect(Rect2(Vector2(), size), color)

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
