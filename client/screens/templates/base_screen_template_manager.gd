class_name BaseScreenTemplateManager
extends Node
## Base template for all screen.
##
## Applies safe area margins to handle device notches and curved screen edges.[br]
## Extend this class to create new screens with consistent safe area handling.


## Returns the application version from [code]application/config/version[/code] (Project Settings).
func _get_app_version() -> String:
	return ProjectSettings.get_setting("application/config/version")


## Called to refresh the screen's UI with the new language.
func _update_ui_with_new_language() -> void:
	pass
