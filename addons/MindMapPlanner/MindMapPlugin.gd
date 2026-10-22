@tool
extends "ExtendedEditorPlugin.gd"

const PATH_SETTING = "addons/mind_map_planner/mind_map_file"

var dock: MindMap.MindDock

func _init() -> void:
	track_project_setting(PATH_SETTING)

func _enter_tree() -> void:
	dock = preload("uid://bj0an0kogyscp").instantiate()
	dock.map_path = define_project_setting(PATH_SETTING, "res://MindMap.json", PROPERTY_HINT_SAVE_FILE)
	add_dock(dock)

func _exit_tree() -> void:
	remove_dock(dock)

func _on_setting_changed(setting: String, new_value: Variant) -> void:
	dock.map_path = new_value

func _save_external_data() -> void:
	dock.save_map()

func _get_unsaved_status(for_scene: String) -> String:
	if not for_scene.is_empty():
		return ""
	
	if dock.undo_redo.get_version() != dock.last_saved_version:
		return "MindMap has unsaved changed."
	
	return ""
