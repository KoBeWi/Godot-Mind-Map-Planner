@tool
extends "ExtendedEditorPlugin.gd"

const PATH_SETTING = "addons/mind_map_planner/mind_map_file"

var dock: EditorDock

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

func _apply_changes() -> void:
	pass # TODO uncomment
	#dock.save_map()
