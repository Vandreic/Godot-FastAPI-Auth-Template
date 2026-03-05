extends Node
## Stores and manages persistent user data for the application.
##
## Holds [member save_data_dict] with the user's name and language. Use
## [method save_data_to_file] to persist data and [method load_save_data_from_file]
## to load it and navigate to the appropriate screen based on what is stored.
## [br][br]
## [b]Autoload:[/b] Access this singleton globally via [code]SaveData[/code].


## Preloaded reference to the [FileHandler] utility.
const FILE_HANDLER: Resource = preload("res://utilities/file_handler.gd")


## Dictionary containing persistent user data (e.g. [code]name[/code], [code]language[/code]).
## [code]api_cooldown_until[/code] is a unix timestamp; cooldown is active while [code]Time.get_unix_time_from_system()[/code] < this value.
## [code]api_cooldown_endpoint[/code] is [code]"health"[/code] or [code]"verify"[/code] depending on which endpoint triggered the cooldown.
var save_data_dict: Dictionary = {
	"name": "",
	"language": "",
	"api_cooldown_until": 0.0,
	"api_cooldown_endpoint": "",
}


## Writes [member save_data_dict] to the save file.
##
## Calls [method FileHandler.save_data_to_json_file] with the current save data.
func save_data_to_file() -> void:
	FILE_HANDLER.save_data_to_json_file(save_data_dict)


## Loads save data from the file and navigates to the appropriate screen.
##
## Reads the save file via [method FileHandler.load_data_from_json_file]. Updates
## [member save_data_dict] and [method TranslationServer.set_locale] with loaded
## values. If the file is empty or missing, creates a new save file.
## [br][br]
## Screen navigation: goes to the language selection screen if [code]language[/code]
## is empty, to the login screen if [code]name[/code] is empty, or to the home
## screen if both are set.
func load_save_data_from_file() -> void:

	var _save_file_data: Dictionary = FILE_HANDLER.load_data_from_json_file()

	if _save_file_data.is_empty() != true:
		# Update save data dict from save file data
		save_data_dict["name"] = _save_file_data["name"]
		save_data_dict["language"] = _save_file_data["language"]
		save_data_dict["api_cooldown_until"] = _save_file_data["api_cooldown_until"]
		save_data_dict["api_cooldown_endpoint"] = _save_file_data["api_cooldown_endpoint"]

		# Update language
		TranslationServer.set_locale(save_data_dict["language"])

		# Change to language selection screen if user has not selected any language (First app opening)
		if _save_file_data["language"].is_empty():
			ScreenManager.change_screen(ScreenManager.Screen.LANGUAGE_SELECTION_SCREEN)
		# Change to login screen if user has not entered their name
		elif _save_file_data["name"].is_empty():
			ScreenManager.change_screen(ScreenManager.Screen.LOGIN_SCREEN)
		else:
		# Change to home screen if user has selected a language and entered a name
			ScreenManager.change_screen(ScreenManager.Screen.HOME_SCREEN)

	else:
		FILE_HANDLER.create_new_save_file()
