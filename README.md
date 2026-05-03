# FastNodeSync CLI (fns-cli)

A command-line client for syncing Obsidian vaults and configuration files to a remote FastNodeSync server via WebSocket.

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

## Installation

```bash
# Clone the repository
git clone https://github.com/yourusername/fns-cli.git
cd fns-cli

# Install dependencies
pip install -r requirements.txt

# Run directly
python -m fns_cli.main --help
```

## Configuration

Create a `config.yaml` in the project root:

```yaml
server:
  api: "http://your-server:9000"   # FastNodeSync server address
  token: "your-jwt-token"           # Authentication token
  vault: "My Vault"                 # Vault name on server

vault_path: "/path/to/your/vault"   # Local Obsidian vault path

sync:
  sync_notes: true                  # Enable note sync
  sync_files: true                  # Enable file sync
  sync_config: false                # Disable config sync
  exclude_patterns:                 # Glob patterns to exclude
    - ".git/**"
    - ".trash/**"
    - "*.tmp"
    - ".fns_state.json"

logging:
  level: "INFO"                    # DEBUG / INFO / WARNING / ERROR
  file: "fns.log"
```

### Environment Variables (alternative)

| Variable | Description |
|---|---|
| `FNS_API` | Server WebSocket / HTTP address |
| `FNS_TOKEN` | JWT authentication token |
| `FNS_VAULT` | Vault name |
| `FNS_WATCH_PATH` | Local vault path |
| `FNS_SYNC_NOTES` | Enable note sync (`true`/`false`) |
| `FNS_SYNC_FILES` | Enable file sync (`true`/`false`) |
| `FNS_SYNC_CONFIG` | Enable config sync (`true`/`false`) |
| `FNS_EXCLUDE_PATTERNS` | Comma-separated exclusion patterns |

## Usage

```bash
# Start continuous watch + sync mode
python -m fns_cli.main run

# Run a single full bidirectional sync
python -m fns_cli.main sync

# Push all local files to server
python -m fns_cli.main push

# Pull all remote files to local vault
python -m fns_cli.main pull

# Show sync status and configuration
python -m fns_cli.main status

# Use custom config file
python -m fns_cli.main -c config.prod.yaml run
```

## Docker

```bash
# Build
docker build -t fns-cli .

# Run
docker run --rm -it \
  -v $(pwd)/vault:/app/vault \
  -e FNS_API=http://server:9000 \
  -e FNS_TOKEN=your-token \
  -e FNS_VAULT="My Vault" \
  fns-cli run
```

Or use the included `docker-compose.yml` for a full stack deployment.

## License

MIT