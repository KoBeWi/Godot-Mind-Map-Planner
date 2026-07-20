@tool
extends ImageTexture

var empty := true

@export var icon_name: StringName:
	set(name):
		if name == icon_name:
			return
		icon_name = name
		
		if EditorInterface.get_editor_theme().has_icon(icon_name, &"EditorIcons"):
			empty = false
			_update_image()
		elif not empty:
			empty = true
			set_image(Image.create(1, 1, false, Image.FORMAT_RGBA8))

func _init() -> void:
	EditorInterface.get_base_control().theme_changed.connect(_update_image)

func _update_image():
	if not empty:
		set_image(EditorInterface.get_editor_theme().get_icon(icon_name, &"EditorIcons").get_image())

func _validate_property(property: Dictionary) -> void:
	if property["name"] == "image":
		property["usage"] = PROPERTY_USAGE_NONE
