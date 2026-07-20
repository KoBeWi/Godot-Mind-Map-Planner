@tool
extends EditorPlugin

var dock: EditorDock

func _has_main_screen() -> bool:
	return true

func _get_plugin_name() -> String:
	return dock.name

func _get_plugin_icon() -> Texture2D:
	return EditorInterface.get_editor_theme().get_icon(dock.icon_name, &"EditorIcons")

func _init() -> void:
	dock = preload("uid://bj0an0kogyscp").instantiate()
	dock.hide()

func _enter_tree() -> void:
	EditorInterface.get_editor_main_screen().add_child(dock)

func _exit_tree() -> void:
	dock.queue_free()

func _make_visible(visible: bool) -> void:
	dock.visible = visible
