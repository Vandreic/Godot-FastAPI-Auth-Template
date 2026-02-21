## Loads and switches between application screens.
##
## Reads [constant SCREENS_FOLDER_PATH] for screen scenes on initialization
## and stores them in [member screens_dict]. Use [method change_screen] to
## transition between screens.
## [br][br]
## [b]Autoload:[/b] Access this singleton globally via [code]ScreenManager[/code].

extends Node


## Available screens in the application.
enum Screen {
	## The login screen where users enter access codes.
	LOGIN_SCREEN,
	## The home screen displayed after successful login.
	HOME_SCREEN,
}


## The folder path containing all screen subdirectories.
const SCREENS_FOLDER_PATH: String = "res://screens/"

## The node path to the UI container that holds the active screen.
const UI_NODE_PATH: String = "/root/Main/UI"


## Maps screen names to their scene file paths.
## [br][br]
## Keys use the format [code]"folder_name_screen"[/code] (e.g., [code]"login_screen"[/code]).[br]
## Values contain the full resource path to the [code].tscn[/code] file.
var screens_dict: Dictionary = {}


## Loads all screen scenes from the screens folder.
func _init() -> void:
	_load_screens_from_folder(SCREENS_FOLDER_PATH)


## Called when the screen manager enters the scene tree.
func _ready() -> void:
	pass


## Reads a folder for screen scenes and populates [member screens_dict].
##
## Loops through subdirectories in [param folder_path] and searches for
## [code].tscn[/code] files matching the pattern [code]folder_name_screen.tscn[/code].
## [br][br]
## For example, [code]res://screens/login/[/code] loads [code]login_screen.tscn[/code].
## Skips the [code]templates[/code] folder.
func _load_screens_from_folder(folder_path: String) -> void:
	var dir: DirAccess = DirAccess.open(folder_path)

	if dir:
		# Start reading files from the folder
		dir.list_dir_begin()
		var file_name: String = dir.get_next()
		
		# Iterate through all items in the folder
		while file_name != "":
			
			# Only process directories (skip individual files)
			if dir.current_is_dir():
				# Skip templates folder
				if file_name == "templates":
					file_name = dir.get_next()
					continue
				
				# Build the full path to this screen directory
				var full_path: String = folder_path.path_join(file_name)

				# Construct the expected scene file name: "folder_name_screen.tscn"
				# E.g., "login" directory -> "login_screen.tscn"
				var scene_path: String = full_path.path_join(file_name + "_screen.tscn")
				
				# Check if the scene file exists in this directory
				if ResourceLoader.exists(scene_path):
					# Add the scene to our screens dictionary
					# Key: "folder_name_screen" (e.g., "login_screen")
					# Value: full path to the scene file
					screens_dict[file_name + "_screen"] = scene_path
					print("Loaded screen: %s -> %s" % [file_name + "_screen.tscn", scene_path])
			
			# Move to the next file/folder in the directory
			file_name = dir.get_next()
	else:
		# Failed to open the directory - print error message
		print("Failed to open directory: %s" % folder_path)
		print("Error: %s" % DirAccess.get_open_error())


## Transitions to a different screen.
##
## Removes the current screen from the UI node and instantiates the
## screen specified by [param screen]. The new screen becomes a child
## of the node at [constant UI_NODE_PATH].
func change_screen(screen: Screen) -> void:
	# Get UI node
	var ui_node: CanvasLayer = get_node_or_null(UI_NODE_PATH)

	# Check if UI node exists
	if ui_node == null:
		print("UI node not found!")
		return
	
	# Get current screen
	var current_screen: Node = ui_node.get_child(0)

	# Determine screen name based on enum
	var screen_name: String = ""
	match screen:
		Screen.LOGIN_SCREEN:
			screen_name = "login_screen"
		Screen.HOME_SCREEN:
			screen_name = "home_screen"


	# Check if requested screen exists
	if screens_dict.has(screen_name):
		# Remove current screen
		current_screen.queue_free()
		
		# Load new screen
		var new_screen: Node = load(screens_dict[screen_name]).instantiate()
		
		# Add new screen
		ui_node.add_child(new_screen)
