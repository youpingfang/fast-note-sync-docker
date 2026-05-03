# FastNodeSync CLI (fns-cli)

A command-line client for syncing Obsidian vaults and configuration files to a remote FastNodeSync server via WebSocket.

> **Background** — This project is a containerized Linux client for [fast-note-sync-service](https://github.com/haierkeys/fast-note-sync-service). The original service was designed for macOS; fns-cli brings the same sync capability to Linux through Docker, enabling Linux users to sync their Obsidian vaults with the FastNodeSync server.

## Features

- **Bidirectional file sync** — push local changes and pull remote updates
- **Real-time monitoring** — watch mode detects file changes instantly via `watchdog`
- **Note & file sync** — dedicated handling for `.md` notes, attachments, and settings
- **Configurable exclusions** — pattern-based ignore rules (e.g. `.git/`, `*.tmp`)
- **WebSocket-based protocol** — low-overhead real-time communication
- **Chunked file transfer** — large files are transferred in chunks for stability
- **Conflict detection** — tracks modification times and handles sync conflicts

## Architecture

```
fns-cli (client)
    ├── SyncEngine        — orchestrates watch / push / pull
    ├── FileWatcher       — monitors local vault via watchdog
    ├── SyncClient        — WebSocket client for server communication
    └── protocol.py       — encodes / decodes WS message frames
         │
         └── WebSocket connection
              │
         FastNodeSync Server
```

## Protocol Overview

The client communicates with the server using a pipe-delimited (`|`) text protocol over WebSocket, with binary frames for chunked file transfers.

| Action (Client → Server) | Description |
|---|---|
| `NoteSync` / `NoteModify` / `NoteDelete` / `NoteRename` | Note CRUD operations |
| `FileSync` / `FileUploadCheck` / `FileDelete` / `FileChunkDownload` | File sync operations |
| `FolderSync` / `FolderModify` / `FolderDelete` / `FolderRename` | Folder operations |
| `SettingSync` / `SettingModify` / `SettingDelete` | Config sync |

| Action (Server → Client) | Description |
|---|---|
| `NoteSyncModify` / `NoteSyncDelete` / `NoteSyncRename` | Remote note change events |
| `FileSyncUpdate` / `FileSyncDelete` / `FileSyncRename` | Remote file change events |
| `NoteSyncNeedPush` | Server requests client to push a note |
| `FileUpload` | Server requests file upload from client |
| `FileSyncEnd` / `NoteSyncEnd` | End-of-sync markers |

## Dependencies

| Library | Version | Purpose |
|---|---|---|
| [click](https://click.palletsprojects.com/) | ≥8.1 | CLI framework |
| [websockets](https://github.com/python-websockets/websockets) | ≥12.0 | WebSocket client |
| [watchdog](https://github.com/gorakhargosh/watchdog) | ≥4.0 | File system monitoring |
| [PyYAML](https://pyyaml.org/) | ≥6.0 | YAML config parsing |

## Quick Start

### 1. Clone the repo

```bash
git clone https://github.com/youpingfang/fast-note-sync-docker.git
cd fast-note-sync-docker
```

### 2. Configure environment variables

```bash
mkdir -p vault
cp .env.example .env
```

Edit `.env` with your server info:

```env
FNS_API=http://your-server:9000
FNS_TOKEN=your-jwt-token
FNS_VAULT=Obsidian Vault
FNS_WATCH_PATH=/app/vault
FNS_SYNC_NOTES=true
FNS_SYNC_FILES=true
FNS_SYNC_CONFIG=false
FNS_EXCLUDE_PATTERNS=.git/**,.trash/**,*.tmp,.fns_state.json
FNS_FILE_CHUNK_SIZE=524288
FNS_RECONNECT_MAX_RETRIES=15
FNS_RECONNECT_BASE_DELAY=3
FNS_HEARTBEAT_INTERVAL=30
FNS_LOG_LEVEL=INFO
```

### 3. Build and run

```bash
docker-compose up -d
```

View logs:

```bash
docker-compose logs -f
```

## Environment Variables

| Variable | Default | Description |
|---|---|---|
| `FNS_API` | — | FastNodeSync server address |
| `FNS_TOKEN` | — | JWT authentication token |
| `FNS_VAULT` | — | Vault name on server |
| `FNS_WATCH_PATH` | `/app/vault` | Local vault mount path |
| `FNS_SYNC_NOTES` | `true` | Enable note sync |
| `FNS_SYNC_FILES` | `true` | Enable file sync |
| `FNS_SYNC_CONFIG` | `false` | Enable config sync |
| `FNS_EXCLUDE_PATTERNS` | `.git/**,...` | Comma-separated exclusion patterns |
| `FNS_FILE_CHUNK_SIZE` | `524288` | File chunk size (bytes) |
| `FNS_RECONNECT_MAX_RETRIES` | `15` | Max reconnect attempts |
| `FNS_RECONNECT_BASE_DELAY` | `3` | Reconnect base delay (seconds) |
| `FNS_HEARTBEAT_INTERVAL` | `30` | Heartbeat interval (seconds) |
| `FNS_LOG_LEVEL` | `INFO` | Log level |
| `FNS_LOG_FILE` | `""` | Log file path (empty = stdout) |

## Direct Run (non-Docker)

```bash
# Install dependencies
pip install -r requirements.txt

# Set environment variables
export FNS_API=http://your-server:9000
export FNS_TOKEN=your-token
export FNS_VAULT="My Vault"
export FNS_WATCH_PATH=/path/to/vault

# Run
python -m fns_cli.main run
```

## CLI Commands

```bash
# Start continuous watch + sync mode
python -m fns_cli.main run

# Run a single full bidirectional sync
python -m fns_cli.main sync

# Push all local files to server
python -m fns_cli.main push

# Pull all remote files to local vault
python -m fns_cli.main pull

# Show sync status
python -m fns_cli.main status
```

## License

MIT
