class_name HomeScreenManager
extends BaseScreenTemplateManager
## Controls the home screen UI after successful login.
##
## Displays the main application interface. [br][br]
##
## Extends [BaseScreenTemplateManager] for consistent screen behavior.

@onready var title_label: Label = %TitleLabel


## Initializes the home screen and updates the UI with the current language.
func _ready() -> void:
	_update_ui_with_new_language()


## Refreshes the UI with the current language.
func _update_ui_with_new_language() -> void:
	title_label.text = tr("WELCOME_TO_USER").format({"name": SaveData.save_data_dict["name"]})
