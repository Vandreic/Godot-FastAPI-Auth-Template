## Manages the login screen UI and server connection.
##
## Displays server status, handles access code input, and verifies credentials with the backend.[br] 
## Transitions to the home screen (managed by [HomeScreenManager]) on successful authentication.
## [br][br]
## Extends [BaseScreenTemplateManager] to apply safe area margins for notches and curved screen edges.

# BUG:
# If the connect button is spammed rapidly, multiple cooldown timers may be started simultaneously.
# This causes the cooldown to stack, requiring the user to wait multiple cooldown periods before trying again.
# When the cooldown timer reaches 00:00, it may immediately restart if multiple timers are active.

class_name LoginScreenManager
extends BaseScreenTemplateManager


## Label displaying the application version.
@onready var app_version_label: Label = %AppVersionLabel

## Indicator showing the server connection status color.
## [br][br]
## Retrieves its color from the [member server_status_colors] dictionary.
@onready var server_status_indicator: TextureRect = %ServerStatusIndicator

## Label displaying the server status title.
@onready var server_status_label: Label = %ServerStatusLabel

## Label displaying additional server status details.
@onready var server_status_description: Label = %ServerStatusDescription

## Button to retry server connection.
@onready var reconnect_button: TextureButton = %ReconnectButton

## Text input field for the access code.
@onready var access_code_input: TextEdit = %AccessCodeInput

## Button to submit the access code.
@onready var connect_button: Button = %ConnectButton

## Server online status flag.
## [br][br]
## If [code]true[/code], the server is online and accessible.
var server_online: bool = true

## Color mapping for different server statuses.
## [br][br]
## Keys correspond to [enum APIManager.ServerHealthStatus] values. The [param default] key is used for the initial state. [br]
## Each color uses the [code]Color(0xRRGGBBAA)[/code] format (See [method Color.hex] for more details).
var server_status_colors: Dictionary = {
	"default": Color(0x9e9e9eFF),
	"healthy": Color(0x4CAF50FF),
	"no_internet": Color(0xF44336FF),
	"server_unreachable": Color(0xF44336FF),
	"timeout": Color(0xFB8C00FF),
	"error": Color(0xF44336FF)
}

## Initializes the login screen and checks server health.
func _ready() -> void:
	_set_app_version()
	_connect_signals()
	
	APIManager.check_server_health()


## Sets the application version label from [code]application/config/version[/code] (Project Settings).
func _set_app_version() -> void:
	app_version_label.text = "v%s" % ProjectSettings.get_setting("application/config/version")


## Connects UI components and API signals to their handlers.
func _connect_signals() -> void:
	# Scene Nodes
	access_code_input.text_changed.connect(_on_access_code_input_text_changed)
	reconnect_button.pressed.connect(_on_reconnect_button_pressed)
	connect_button.pressed.connect(_on_connect_button_pressed)

	# API Manager
	APIManager.check_server_health_completed.connect(_on_check_server_health_completed)
	APIManager.verify_access_code_completed.connect(_on_verify_access_code_completed)


## Handles text changes in the [member access_code_input] input field.
## [br][br]
## Toggles the [member connect_button] based on input validity.
func _on_access_code_input_text_changed() -> void:
	var user_input: String = access_code_input.text
	
	if server_online == true:
		if user_input.is_empty() == true or user_input.length() < 3:
			connect_button.disabled = true
		else:
			connect_button.disabled = false


## Applies the server health check result to the UI.
## [br][br]
## Sets the status indicator color, label text, and reconnect button visibility
## based on [param status].
func _on_check_server_health_completed(status: APIManager.ServerHealthStatus, title: String, description: String) -> void:
	server_status_label.text = title

	if description.is_empty() != true:
		server_status_description.text = description
		server_status_description.visible = true
	else:
		server_status_description.visible = false
	
	match status:
		APIManager.ServerHealthStatus.HEALTHY:
			server_status_indicator.modulate = server_status_colors["healthy"]
		APIManager.ServerHealthStatus.NO_INTERNET:
			server_status_indicator.modulate = server_status_colors["no_internet"]
		APIManager.ServerHealthStatus.SERVER_UNREACHABLE:
			server_status_indicator.modulate = server_status_colors["server_unreachable"]
		APIManager.ServerHealthStatus.TIMEOUT:
			server_status_indicator.modulate = server_status_colors["timeout"]
		APIManager.ServerHealthStatus.ERROR:
			server_status_indicator.modulate = server_status_colors["error"]
	if status == APIManager.ServerHealthStatus.HEALTHY:
		server_online = true
		reconnect_button.visible = false
	else:
		server_online = false
		reconnect_button.visible = true
	
	# Disable connect button if API call limit reached
	if title == "API Call Limit Reached!":
		reconnect_button.visible = false


## Sends the access code to the server for verification.
func _on_connect_button_pressed() -> void:
	connect_button.disabled = true
	var access_code: String = access_code_input.text
	
	APIManager.verify_access_code(access_code)


## Processes the server's access code verification response.
## [br][br]
## Displays the server response in the UI. Transitions to the home screen 
## (managed by [HomeScreenManager]) if [param access_granted] is [code]true[/code].
func _on_verify_access_code_completed(access_granted: bool, message: String, response_data: Dictionary) -> void:
	server_status_description.visible = true
	if access_granted == true:
		if message.is_empty() == true:
			server_status_description.text = "Access Granted!" # Not needed
		
		# Change to home screen
		ScreenManager.change_screen(ScreenManager.Screen.HOME_SCREEN)
	else:
		server_status_description.text = message
		connect_button.disabled = false

	# Inform user if API call limit has been reached
	if message == "API Call Limit Reached!":
		server_status_indicator.modulate = server_status_colors["error"]
		server_status_label.text = message
		server_status_description.text = response_data["description"]
		access_code_input.text = ""
		connect_button.disabled = true


## Resets the UI to its initial state and retries the server connection.
func _on_reconnect_button_pressed() -> void:
	server_status_indicator.modulate = server_status_colors["default"]
	server_status_label.text = "Checking Server Status..."
	server_status_description.text = ""
	server_status_description.visible = false
	reconnect_button.visible = false
	
	APIManager.check_server_health()
