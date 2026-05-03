# FastNodeSync CLI (fns-cli)

命令行客户端，通过 WebSocket 将 Obsidian 笔记库和配置文件同步到远程 FastNodeSync 服务器。

> **背景** —— 本项目是为 [fast-note-sync-service](https://github.com/haierkeys/fast-note-sync-service) 打造的容器化 Linux 客户端。原有服务面向 macOS 设计，fns-cli 通过 Docker 将相同的同步能力带入 Linux，让 Linux 用户也能将 Obsidian 笔记库与 FastNodeSync 服务器同步。

## 功能特性

- **双向文件同步** — 推送本地变更，拉取远程更新
- **实时监控** — 监听模式通过 `watchdog` 即时检测文件变动
- **笔记与文件同步** — 专门处理 `.md` 笔记、附件和配置
- **可配置排除规则** — 支持 glob 模式忽略文件（如 `.git/`、`*.tmp`）
- **WebSocket 通信协议** — 低开销实时通信
- **分块文件传输** — 大文件分块传输，保证稳定性
- **冲突检测** — 记录修改时间戳，处理同步冲突

## 架构

```
fns-cli (客户端)
    ├── SyncEngine        — 协调 watch / push / pull
    ├── FileWatcher       — 通过 watchdog 监控本地 vault
    ├── SyncClient        — WebSocket 客户端，与服务器通信
    └── protocol.py       — 编解码 WS 消息帧
         │
         └── WebSocket 连接
              │
         FastNodeSync 服务器
```

## 协议概述

客户端通过 WebSocket 使用 pipe 分隔（`|`）的文本协议通信，二进制帧用于分块文件传输。

| 客户端 → 服务器动作 | 说明 |
|---|---|
| `NoteSync` / `NoteModify` / `NoteDelete` / `NoteRename` | 笔记 CRUD 操作 |
| `FileSync` / `FileUploadCheck` / `FileDelete` / `FileChunkDownload` | 文件同步操作 |
| `FolderSync` / `FolderModify` / `FolderDelete` / `FolderRename` | 文件夹操作 |
| `SettingSync` / `SettingModify` / `SettingDelete` | 配置同步 |

| 服务器 → 客户端动作 | 说明 |
|---|---|
| `NoteSyncModify` / `NoteSyncDelete` / `NoteSyncRename` | 远程笔记变更事件 |
| `FileSyncUpdate` / `FileSyncDelete` / `FileSyncRename` | 远程文件变更事件 |
| `NoteSyncNeedPush` | 服务器请求客户端推送笔记 |
| `FileUpload` | 服务器请求客户端上传文件 |
| `NoteSyncEnd` / `FileSyncEnd` | 同步结束标记 |

## 依赖

| 库 | 版本 | 用途 |
|---|---|---|
| [click](https://click.palletsprojects.com/) | ≥8.1 | CLI 框架 |
| [websockets](https://github.com/python-websockets/websockets) | ≥12.0 | WebSocket 客户端 |
| [watchdog](https://github.com/gorakhargosh/watchdog) | ≥4.0 | 文件系统监控 |
| [PyYAML](https://pyyaml.org/) | ≥6.0 | YAML 配置文件解析 |

## 安装

```bash
# 克隆仓库
git clone https://github.com/youpingfang/fns-sync-docker.git
cd fns-sync-docker

# 安装依赖
pip install -r requirements.txt

# 直接运行
python -m fns_cli.main --help
```

## 配置

在项目根目录创建 `config.yaml`：

```yaml
server:
  api: "http://your-server:9000"   # FastNodeSync 服务器地址
  token: "your-jwt-token"          # 认证 Token
  vault: "My Vault"                # 服务器上的保险库名称

vault_path: "/path/to/your/vault"  # 本地 Obsidian 保险库路径

sync:
  sync_notes: true                  # 启用笔记同步
  sync_files: true                  # 启用文件同步
  sync_config: false                # 禁用配置同步
  exclude_patterns:                 # 排除规则（glob 模式）
    - ".git/**"
    - ".trash/**"
    - "*.tmp"
    - ".fns_state.json"

logging:
  level: "INFO"                    # DEBUG / INFO / WARNING / ERROR
  file: "fns.log"
```

### 环境变量（替代方案）

| 变量 | 说明 |
|---|---|
| `FNS_API` | 服务器 WebSocket / HTTP 地址 |
| `FNS_TOKEN` | JWT 认证 Token |
| `FNS_VAULT` | 保险库名称 |
| `FNS_WATCH_PATH` | 本地 vault 路径 |
| `FNS_SYNC_NOTES` | 启用笔记同步（`true`/`false`） |
| `FNS_SYNC_FILES` | 启用文件同步（`true`/`false`） |
| `FNS_SYNC_CONFIG` | 启用配置同步（`true`/`false`） |
| `FNS_EXCLUDE_PATTERNS` | 逗号分隔的排除规则 |

## 使用

```bash
# 启动持续监听 + 同步模式
python -m fns_cli.main run

# 执行一次完整双向同步
python -m fns_cli.main sync

# 推送所有本地文件到服务器
python -m fns_cli.main push

# 拉取所有远程文件到本地
python -m fns_cli.main pull

# 查看同步状态和配置
python -m fns_cli.main status

# 指定自定义配置文件
python -m fns_cli.main -c config.prod.yaml run
```

## Docker

```bash
# 构建镜像
docker build -t fns-cli .

# 运行
docker run --rm -it \
  -v $(pwd)/vault:/app/vault \
  -e FNS_API=http://server:9000 \
  -e FNS_TOKEN=your-token \
  -e FNS_VAULT="My Vault" \
  fns-cli run
```

或使用项目自带的 `docker-compose.yml` 进行完整部署。

## License

MIT
