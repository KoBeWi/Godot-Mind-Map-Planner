@tool
extends Tree

var data_identifier: String

signal reordered(from: int, to: int)

func _init() -> void:
	data_identifier = str("ReorderingTree#", get_instance_id())

func _get_drag_data(at_position: Vector2) -> Variant:
	var item := get_selected()
	if not item:
		return null
	
	var data: Dictionary
	data["type"] = data_identifier
	data["index"] = item.get_index()
	
	return data

func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	if data.get("type", "") == data_identifier:
		drop_mode_flags = Tree.DROP_MODE_INBETWEEN
		return true
	return false

func _drop_data(at_position: Vector2, data: Variant) -> void:
	var target_item := get_item_at_position(at_position)
	if not target_item:
		return
	
	var source_index: int = data["index"]
	var drop_index := target_item.get_index()
	if source_index == drop_index:
		return
	
	if drop_index == 0:
		get_root().get_child(source_index).move_before(target_item)
	else:
		get_root().get_child(source_index).move_after(target_item)
	
	reordered.emit(source_index, drop_index)
