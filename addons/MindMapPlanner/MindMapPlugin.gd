@tool
extends "ExtendedEditorPlugin.gd"

var dock: EditorDock

func _init() -> void:
	dock = preload("uid://bj0an0kogyscp").instantiate()
	set_main_screen_dock(dock)
