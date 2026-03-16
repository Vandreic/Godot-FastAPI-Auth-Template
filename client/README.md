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

func _on_verify_completed(access_granted: bool, title: String, description: String):
    if access_granted:
        print("Access granted!")
    else:
        print("Access denied: ", description)
```

*Note: `title` and `description` contain status or error messages from the server when `access_granted` is false.*

### HTTP Headers Sent

```
Content-Type: application/json
Access-Key: <user-provided-key>
```

## Autoloads

| Autoload | Purpose |
|----------|---------|
| `APIManager` | HTTP requests and server communication |
| `ScreenManager` | Screen navigation and transitions |
| `SaveData` | Persists user name, language, and API cooldown state |

## Screen Flow

1. **Language Selection** — User picks a language (first launch).
2. **Login** — User enters the access key and clicks "Connect".
3. **Name Entry** — After successful verification, user enters their name.
4. **Home** — Main screen after completing the flow.

On subsequent launches, if language and name are already saved, the app goes directly to the appropriate screen.

## Project Structure

```
client/
├── autoload/
│   ├── api_manager.gd      # HTTP requests & server communication
│   ├── save_data.gd        # Persists name, language, cooldown
│   └── screen_manager.gd   # Screen navigation
├── utilities/
│   └── file_handler.gd     # File I/O for save data
├── screens/
│   ├── home/               # Main screen after login
│   ├── language_selection/ # Language picker (first launch)
│   ├── login/              # Access key input screen
│   ├── name_entry/         # Name input (after successful login)
│   └── templates/          # Base screen template
└── assets/
    ├── icons/              # SVG icons
    ├── localization/      # CSV translations (translations.csv)
    └── themes/             # UI themes
```

## Setup

1. Open Godot 4.x
2. Import this folder as a project
3. Configure server connection in `autoload/api_manager.gd`:
   - **IDE testing**: Uses `HOST_EDITOR` (localhost). No change needed.
   - **Phone testing**: Set `HOST_EXPORTED` to your PC's IP (e.g. `http://10.0.0.7`). See Configuration below.
   - `PORT` must match the server (e.g. `8000`).
4. Run the project (F5)

## Configuration

Edit `autoload/api_manager.gd` to configure server connection. The client picks the host automatically:

- **Godot IDE**: Uses `HOST_EDITOR` (localhost). Client and server run on the same PC.
- **Exported app (e.g. phone)**: Uses `HOST_EXPORTED`. Set this to your PC's IP so the app can reach the server.

**How to get your PC's IP:**
- **Windows:** CMD → `ipconfig` → IPv4 under WiFi/Ethernet (e.g. `10.0.0.7`)
- **macOS/Linux:** `ifconfig` or `ip addr` → IPv4 on active adapter

**Phone testing checklist:**
- Set `HOST_EXPORTED` in `api_manager.gd` to your PC's IP (e.g. `http://10.0.0.7`)
- Server `server/.env`: `HOST=0.0.0.0` so it accepts network connections
- PC and phone on same WiFi
- Windows Firewall: allow inbound TCP on port 8000 (or your PORT)

| Constant | Default | Description |
|----------|---------|-------------|
| `HOST_EDITOR` | `http://localhost` | Server address when running in Godot IDE |
| `HOST_EXPORTED` | `http://10.0.0.7` | Server address when running exported app (e.g. phone); your PC's IP |
| `PORT` | `8000` | Server port (must match server) |
| `API_PREFIX` | `/api/v1` | API version prefix |
| `HTTP_REQUEST_TIMEOUT_DURATION` | `1` | Request timeout (seconds) |
| `API_CALL_COOLDOWN_DURATION` | `5` | Cooldown after rate limit (seconds) |