# Server (FastAPI)

The backend API built with **Python** and **FastAPI**. Handles access key authentication and provides endpoints for the Godot client.

## Features

- 🔐 Access key authentication via HTTP headers
- 📡 RESTful API with versioning (`/api/v1`)
- 📖 Auto-generated API docs (Swagger UI)
- ⚙️ Environment-based configuration

## How It Communicates with the Client

The server receives HTTP requests from the Godot client and returns JSON responses.

### Request Flow

```
Client Request                          Server Processing
─────────────────                       ─────────────────
GET /api/v1/auth/verify      ───▶      1. Extract Access-Key header
Header: Access-Key: xxx                 2. Validate against .env secret
                                        3. Return JSON response
                             ◀───      
{                                       
  "status": "ok",                       
  "role": "user"                        
}
```

### Authentication Flow

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Client    │     │  security   │     │   .env      │
│  (Godot)    │     │  .py        │     │   file      │
└──────┬──────┘     └──────┬──────┘     └──────┬──────┘
       │                   │                   │
       │ Access-Key: xxx   │                   │
       │──────────────────▶│                   │
       │                   │ GLOBAL_ACCESS_KEY │
       │                   │◀──────────────────│
       │                   │                   │
       │                   │ Compare keys      │
       │                   │                   │
       │ 200 OK / 403 Error│                   │
       │◀──────────────────│                   │
```

### API Endpoints

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | `/` | Welcome message | No |
| GET | `/api/v1/system/health` | Server health check | No |
| GET | `/api/v1/auth/verify` | Verify access key | Yes |

### Example Requests

Use `localhost:8000` or your configured `HOST:PORT` from `.env`:

**Health Check (no auth):**
```bash
curl http://localhost:8000/api/v1/system/health
```

**Verify Access Key:**
```bash
curl -H "Access-Key: your-secret-key" http://localhost:8000/api/v1/auth/verify
```

*Note: Replace `localhost:8000` with your configured `HOST:PORT` if you changed them in `.env`.*

## Project Structure

```
server/
├── .env                    # Environment variables (create this; do not commit)
├── requirements.in         # Dependency input (pip-compile to regenerate requirements.txt)
├── requirements.txt        # Python dependencies
└── app/
    ├── main.py             # FastAPI app entry point
    ├── api/
    │   ├── schemas/        # Pydantic response models
    │   └── v1/routers/     # API route handlers
    │       ├── auth.py     # /auth/verify endpoint
    │       └── system.py   # /system/health endpoint
    └── core/
        ├── config.py       # Settings from .env
        └── security.py     # Access key validation
```

## Setup

1. Navigate to this folder:
   ```bash
   cd server
   ```

2. Install dependencies:
   ```bash
   python -m pip install -r requirements.txt
   ```

3. Create `.env` file:
   ```env
   GLOBAL_ACCESS_KEY=your-secret-key-here
   TITLE=Server API
   DESCRIPTION=A backend API for the Godot-Python stack, built with FastAPI.
   VERSION=0.0.1
   HOST=0.0.0.0
   PORT=8000
   DEBUG=false
   ```

   **All variables are required—there are no defaults.** You create the `.env` file and must set each variable. Settings are read via `pydantic-settings`. Set `HOST=0.0.0.0` to allow connections from other devices (e.g., phone on same network). Set `DEBUG=true` for auto-reload during development.

   **Phone testing:** Use `HOST=0.0.0.0` so the server accepts connections from your network. Set the client's `HOST_EXPORTED` in [api_manager.gd](../client/autoload/api_manager.gd) to your PC's IP (see root [README](../README.md#testing-ide-vs-phone) for details).

4. Run the server:
   ```bash
   python -m app.main
   ```

5. Open API docs: http://localhost:8000/docs (use your configured HOST:PORT if different)

## Configuration

Edit `.env` to configure. **All variables are required—there are no defaults.** You create the file and must set each one:

| Variable | Description |
|----------|-------------|
| `GLOBAL_ACCESS_KEY` | Secret key for authentication |
| `TITLE` | API title (shown in docs) |
| `DESCRIPTION` | API description |
| `VERSION` | API version |
| `HOST` | Server host. Use `0.0.0.0` to accept connections from other devices on your network (e.g., Godot app on phone). Use `localhost` for local-only. |
| `PORT` | Server port (must match client, e.g. `8000`) |
| `DEBUG` | When `true`, enables auto-reload when code changes. Set `false` for production. |