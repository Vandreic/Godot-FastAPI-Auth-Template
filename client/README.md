# Client (Godot)

The frontend application built with **Godot 4.x** and **GDScript**. Handles user interface and communicates with the backend via HTTP requests.

## Features

- 🔐 Access key authentication
- 🏥 Server health checking
- 📱 Screen-based navigation
- ⚡ API rate limiting (client-side)

## How It Communicates with the Server

The client uses Godot's `HTTPRequest` node to send requests to the FastAPI backend.

### Request Flow

```
┌──────────────┐      ┌──────────────┐      ┌──────────────┐
│  UI Screen   │ ───▶ │  APIManager  │ ───▶ │   Server     │
│  (Button)    │      │  (Autoload)  │      │  (FastAPI)   │
└──────────────┘      └──────────────┘      └──────────────┘
                             │                     │
                             │◀────────────────────│
                             ▼                JSON Response
                      Emit Signal
                             │
                             ▼
                   ┌──────────────┐
                   │  UI Updates  │
                   └──────────────┘
```

### APIManager (Autoload Singleton)

Located at `autoload/api_manager.gd`, this handles all server communication:

| Method | Purpose | Signal Emitted |
|--------|---------|----------------|
| `check_server_health()` | Check if server is online | `check_server_health_completed` |
| `verify_access_code(code)` | Validate access key | `verify_access_code_completed` |

### Example: Verifying Access Key

```gdscript
# Send the access key to server
APIManager.verify_access_code("my-secret-key")

# Listen for the response
APIManager.verify_access_code_completed.connect(_on_verify_completed)

func _on_verify_completed(access_granted: bool, message: String, data: Dictionary):
    if access_granted:
        print("Access granted!")
    else:
        print("Access denied: ", message)
```

### HTTP Headers Sent

```
Content-Type: application/json
Access-Key: <user-provided-key>
```

## Project Structure

```
client/
├── autoload/
│   ├── api_manager.gd      # HTTP requests & server communication
│   └── screen_manager.gd   # Screen navigation
├── screens/
│   ├── home/               # Main screen after login
│   ├── login/              # Access key input screen
│   └── templates/          # Base screen template
└── assets/
    ├── icons/              # SVG icons
    └── themes/             # UI themes
```

## Setup

1. Open Godot 4.x
2. Import this folder as a project
3. Update `HOST` in `autoload/api_manager.gd` to match your server:
   ```gdscript
   const HOST: String = "http://localhost"  # or your server IP
   const PORT: int = 8000
   ```
4. Run the project (F5)

## Configuration

Edit `autoload/api_manager.gd` to configure:

| Constant | Default | Description |
|----------|---------|-------------|
| `HOST` | `http://localhost` | Server address |
| `PORT` | `8000` | Server port |
| `API_PREFIX` | `/api/v1` | API version prefix |
| `HTTP_REQUEST_TIMEOUT_DURATION` | `1` | Request timeout (seconds) |
| `API_CALL_COOLDOWN_DURATION` | `5` | Cooldown after rate limit (seconds) |