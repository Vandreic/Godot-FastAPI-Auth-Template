## Communicates with the backend server through HTTP requests.
##
## Performs server health checks and verifies access codes. Emits
## [signal check_server_health_completed] and [signal verify_access_code_completed]
## to report request results.
## [br][br]
## The server URL combines [constant HOST], [constant PORT], and [constant API_PREFIX].
## Configure endpoints in the [member endpoints] dictionary.
## [br][br]
## [b]Autoload:[/b] Access this singleton globally via [code]APIManager[/code].

extends Node

## Represents the server's health status after a connection attempt.
enum ServerHealthStatus {
	## The server responded and operates normally.
	HEALTHY,
	## The client cannot resolve the host (no internet connection).
	NO_INTERNET,
	## The client cannot connect to the server.
	SERVER_UNREACHABLE,
	## The request exceeded the timeout duration.
	TIMEOUT,
	## An unexpected error occurred.
	ERROR,
}

## Emitted when [method check_server_health] finishes.
##
## [param status] contains the [enum ServerHealthStatus] result.
## [param title] provides a short status message.
## [param description] provides additional details about the status.
signal check_server_health_completed(status: ServerHealthStatus, title: String, description: String)

## Emitted when [method verify_access_code] finishes.
##
## If [param access_granted] is [code]true[/code], the access code is valid.
## [param message] contains the server's response message.
## [param response_data] contains the full parsed JSON response.
signal verify_access_code_completed(access_granted: bool, message: String, response_data: Dictionary)


## The server's host address including the protocol.
const HOST: String = "http://localhost"

## The server's port number.
const PORT: int = 8000

## The API version path prefix.
const API_PREFIX: String = "/api/v1"

## The timeout duration for HTTP requests in seconds.
const HTTP_REQUEST_TIMEOUT_DURATION: int = 5

## The cooldown duration when API call limit is reached, in seconds.
const API_CALL_COOLDOWN_DURATION: int = 30

## The complete base URL for all API requests.
##
## Constructed from [constant HOST], [constant PORT], and [constant API_PREFIX].
var url: String = "%s:%s%s" % [HOST, PORT, API_PREFIX]

## Maps endpoint names to their URL paths.
## [br][br]
## Contains the following endpoints:[br]
## - [code]"health"[/code]: Server health check endpoint.[br]
## - [code]"verify"[/code]: Access code verification endpoint.
var endpoints: Dictionary = {
	"health": "/system/health",
	"verify": "/auth/verify",
}

## Tracks API call counts and limits for each endpoint.
var api_call_limits: Dictionary = {
	"health_check": {"count": 0, "limit": 2},
	"verify_access_code": {"count": 0, "limit": 2},
}


## Sends a health check request to the server.
##
## Creates an [HTTPRequest] node, sends a GET request to the health endpoint,
## and emits [signal check_server_health_completed] with the result. Times out
## after [constant HTTP_REQUEST_TIMEOUT_DURATION].
func check_server_health() -> void:

	if api_call_limits["health_check"]["count"] >= api_call_limits["health_check"]["limit"]:
		
		_create_cooldown_timer("health")
		return
	
	else:
		var request_headers: Array = ["Content-Type: application/json"]
		_make_api_request("health", request_headers, Callable(self, "_on_check_server_health_completed"))
		# Increment the API call count for health_check
		api_call_limits["health_check"]["count"] += 1


## Verifies an access code with the server.
##
## Sends [param access_code] to the verification endpoint and emits
## [signal verify_access_code_completed] with the result. Times out
## after [constant HTTP_REQUEST_TIMEOUT_DURATION].
func verify_access_code(access_code: String) -> void:

	if api_call_limits["verify_access_code"]["count"] >= api_call_limits["verify_access_code"]["limit"]:
		_create_cooldown_timer("verify")
		return
	
	else:
		var request_headers: Array = [
			"Content-Type: application/json",
			"Access-Key: %s" % access_code,
		]
		_make_api_request("verify", request_headers, Callable(self, "_on_verify_access_code_completed"))
		# Increment the API call count for verify_access_code
		api_call_limits["verify_access_code"]["count"] += 1


## Create a timer to manage API call cooldowns when limits are reached.
##
## [param endpoint] determines which endpoint cooldown to manage.
func _create_cooldown_timer(endpoint: String) -> void:
	
	# Create main cooldown timer
	var cooldown_timer: Timer = Timer.new()
	cooldown_timer.name = "APICallCooldownTimer"
	cooldown_timer.wait_time = float(API_CALL_COOLDOWN_DURATION)
	cooldown_timer.one_shot = true
	add_child(cooldown_timer)
	cooldown_timer.start()

	# Create timer for ticking every second
	var tick_timer: Timer = Timer.new()
	tick_timer.name = "CooldownTickTimer"
	tick_timer.wait_time = 1.0
	tick_timer.one_shot = false
	tick_timer.timeout.connect(_on_cooldown_tick.bind(endpoint, cooldown_timer, tick_timer))
	add_child(tick_timer)
	tick_timer.start()


## Processes each tick of the cooldown timer.
##
## Emits status signals with the remaining time. Resets the API call count
## and triggers a health check when the cooldown ends.
func _on_cooldown_tick(endpoint: String, cooldown_timer: Timer, tick_timer: Timer) -> void:

	# Format remaining time to MM:SS
	var time_left = int(round(cooldown_timer.time_left))
	var minutes = time_left / 60
	var seconds = time_left % 60
	var time_string = "%02d:%02d" % [minutes, seconds]

	match endpoint:
				"health":
					check_server_health_completed.emit(
						ServerHealthStatus.ERROR,
						"API Call Limit Reached!",
						"You have reached the maximum number of allowed API calls for this endpoint.
						
						Try again in %s" % time_string
					)
				"verify":
					verify_access_code_completed.emit(
						false,
						"API Call Limit Reached!",
						{"description": "You have reached the maximum number of allowed API calls for this endpoint.
						
						Try again in %s" % time_string}
					)
				# _:
				# 	print("Unknown endpoint key: %s" % endpoint_key)

	# Check if cooldown has ended
	if cooldown_timer.time_left <= 0:
		# Stop and free the tick timer
		tick_timer.stop()
		tick_timer.queue_free()
		# Stop and free the main cooldown timer
		cooldown_timer.stop()
		cooldown_timer.queue_free()


		# Reset API call count for the endpoint and re-check server health
		match endpoint:
			"health":
				api_call_limits["health_check"]["count"] = 0
				check_server_health()
			"verify":
				api_call_limits["verify_access_code"]["count"] = 0
				check_server_health() # Re-check server health after cooldown


## Sends an API request to the specified endpoint.
##
## Creates an [HTTPRequest] node and connects it to [param callback].
## Frees the node and emits an error signal if the request fails.
func _make_api_request(endpoint: String, headers: Array, callback: Callable, method: int = HTTPClient.METHOD_GET, body: String = "") -> void:
	
	# Create and configure HTTPRequest node
	var http_request: HTTPRequest = HTTPRequest.new()
	http_request.timeout = HTTP_REQUEST_TIMEOUT_DURATION
	http_request.name = "APIRequest_%s" % endpoint
	add_child(http_request)
	http_request.request_completed.connect(callback.bind(http_request))
	
	# Construct full URL and send request
	var request_url: String = url + endpoints[endpoint]
	var error: Error = http_request.request(request_url, headers, method, body)	

	# Handle request error
	if error != OK:
		http_request.queue_free()

		# Get the signal name from the callback
		var signal_name = str(callback).split("_on_", false, 1)[1] # e.g., "check_server_health_completed"

		# Emit appropriate signal based on endpoint
		match endpoint:
			"health":
				emit_signal(signal_name, ServerHealthStatus.ERROR, "An error occurred.", "Failed to send health check request.")
			"verify":
				emit_signal(signal_name, false, "An error occurred.", {"description": "Failed to send access code verification request."})
			# _:
			# 	print("Unknown endpoint key: %s" % endpoint_key)


## Processes the server health check response.
##
## Parses the HTTP result and emits [signal check_server_health_completed]
## with the appropriate [enum ServerHealthStatus].
func _on_check_server_health_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray, http_request: HTTPRequest) -> void:
	http_request.queue_free()
	
	# Check for connection/DNS errors
	if result == HTTPRequest.RESULT_CANT_RESOLVE: # Request failed while resolving
		check_server_health_completed.emit(
			ServerHealthStatus.NO_INTERNET, 
			"No internet connection!",
			"Please connect to the internet and try again."
		)
		return
	# Check for Connection Errors
	elif result == HTTPRequest.RESULT_CANT_CONNECT: # Request failed while connecting
		check_server_health_completed.emit(
			ServerHealthStatus.SERVER_UNREACHABLE,
			"Server is offline",
			"Server is temporarily offline. Please try again later."
		)
		return
	# Check for Timeout specifically
	elif result == HTTPRequest.RESULT_TIMEOUT: # Request failed due to a timeout
		check_server_health_completed.emit(
			ServerHealthStatus.TIMEOUT,
			"Connection timed out.",
			"Please check your connection and try again."
		)
		return

	# Check the Server Response Code
	if response_code == 200:
		# Check status (optional)
		var server_response: Variant = JSON.parse_string(body.get_string_from_utf8())
		if server_response["status"] == "ok":
			check_server_health_completed.emit(
				ServerHealthStatus.HEALTHY,
				"Server Status: Online",
				""
			)
			return
	else:
		check_server_health_completed.emit(
			ServerHealthStatus.ERROR,
			"An error occurred.",
			"Server responded with code: %s" % response_code
		)
		return


## Processes the access code verification response.
##
## Parses the HTTP result and emits [signal verify_access_code_completed]
## with the verification status and server message.
func _on_verify_access_code_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray, http_request: HTTPRequest) -> void:
	http_request.queue_free()
	
	# Check for connection/DNS errors
	if result == HTTPRequest.RESULT_CANT_RESOLVE: # Request failed while resolving
		check_server_health_completed.emit(
			ServerHealthStatus.NO_INTERNET, 
			"No internet connection!",
			"Please connect to the internet and try again"
		)
		return
	# Check for Connection Errors
	elif result == HTTPRequest.RESULT_CANT_CONNECT: # Request failed while connecting
		check_server_health_completed.emit(
			ServerHealthStatus.SERVER_UNREACHABLE,
			"Server is offline",
			"Server is temporarily offline. Please try again later."
		)
		return
	# Check for Timeout specifically
	elif result == HTTPRequest.RESULT_TIMEOUT: # Request failed due to a timeout
		check_server_health_completed.emit(
			ServerHealthStatus.TIMEOUT,
			"Connection timed out.",
			"Please check your connection or try again."
		)
		return

	# Check the Server Response Code
	var server_response: Variant = JSON.parse_string(body.get_string_from_utf8())
	if response_code == 200:
		# Check status (optional)
		if server_response["status"] == "ok":
			verify_access_code_completed.emit(true, "", server_response)
			return
		
	# Access Denied
	elif response_code == 403:
		verify_access_code_completed.emit(false, str(server_response["detail"]), server_response)
		return
