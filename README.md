# Fast-note-sync-docker

命令行客户端，通过 WebSocket 将 Obsidian 笔记库和配置文件同步到远程服务器。

> **背景** —— 本项目是为 [fast-note-sync-service](https://github.com/haierkeys/fast-note-sync-service) 打造的容器化客户端。原有服务面向 macOS 设计，Fast-note-sync-docker 通过 Docker 将相同的同步能力带入 Linux，让 Linux 用户也能将 Obsidian 笔记库与 FastNodeSync 服务器同步。参考的 Go 语言实现的跨平台客户端：[FastNodeSync-CLI](https://github.com/Go1c/FastNodeSync-CLI)。
>
> 请部署好[fast-note-sync-service](https://github.com/haierkeys/fast-note-sync-service) 这个项目后，再来看这个进行 服务器中的docker 部署。

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

| 客户端 → 服务器动作                                                         | 说明         |
| ------------------------------------------------------------------- | ---------- |
| `NoteSync` / `NoteModify` / `NoteDelete` / `NoteRename`             | 笔记 CRUD 操作 |
| `FileSync` / `FileUploadCheck` / `FileDelete` / `FileChunkDownload` | 文件同步操作     |
| `FolderSync` / `FolderModify` / `FolderDelete` / `FolderRename`     | 文件夹操作      |
| `SettingSync` / `SettingModify` / `SettingDelete`                   | 配置同步       |
| 服务器 → 客户端动作 | 说明 |
|---|---|
| `NoteSyncModify` / `NoteSyncDelete` / `NoteSyncRename` | 远程笔记变更事件 |
| `FileSyncUpdate` / `FileSyncDelete` / `FileSyncRename` | 远程文件变更事件 |
| `NoteSyncNeedPush` | 服务器请求客户端推送笔记 |
| `FileUpload` | 服务器请求客户端上传文件 |
| `NoteSyncEnd` / `FileSyncEnd` | 同步结束标记 |

## 快速开始

```yaml
services:
  fns-cli:
    image: youpingfang/fns-cli:latest
    container_name: fns-cli
    build:
      context: .
      dockerfile: Dockerfile
    environment:
      FNS_API: http://ip:9000
      FNS_TOKEN: xxxxx
      FNS_VAULT: Obsidian Vault
      FNS_WATCH_PATH: /app/vault
      FNS_SYNC_NOTES: "true"
      FNS_SYNC_FILES: "true"
      FNS_SYNC_CONFIG: "false"
      FNS_EXCLUDE_PATTERNS: .git/**,.trash/**,*.tmp,.fns_state.json
      FNS_FILE_CHUNK_SIZE: "524288"
      FNS_RECONNECT_MAX_RETRIES: "15"
      FNS_RECONNECT_BASE_DELAY: "3"
      FNS_HEARTBEAT_INTERVAL: "30"
      FNS_LOG_LEVEL: INFO
      FNS_LOG_FILE: ""
    volumes:
      - ${PWD}/vault:/app/vault:rw
    restart: unless-stopped
networks: {}
```

```env
填入你的服务器信息：

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

## 环境变量说明

| 变量                          | 默认值           | 说明                 |
| --------------------------- | ------------- | ------------------ |
| `FNS_API`                   | —             | FastNodeSync 服务器地址 |
| `FNS_TOKEN`                 | —             | JWT 认证 Token       |
| `FNS_VAULT`                 | —             | 服务器上的库名称           |
| `FNS_WATCH_PATH`            | `/app/vault`  | 本地 vault 挂载路径      |
| `FNS_SYNC_NOTES`            | `true`        | 启用笔记同步             |
| `FNS_SYNC_FILES`            | `true`        | 启用文件同步             |
| `FNS_SYNC_CONFIG`           | `false`       | 启用配置同步             |
| `FNS_EXCLUDE_PATTERNS`      | `.git/**,...` | 逗号分隔的排除规则          |
| `FNS_FILE_CHUNK_SIZE`       | `524288`      | 文件分块大小（字节）         |
| `FNS_RECONNECT_MAX_RETRIES` | `15`          | 最大重连次数             |
| `FNS_RECONNECT_BASE_DELAY`  | `3`           | 重连基础延迟（秒）          |
| `FNS_HEARTBEAT_INTERVAL`    | `30`          | 心跳间隔（秒）            |
| `FNS_LOG_LEVEL`             | `INFO`        | 日志级别               |
| `FNS_LOG_FILE`              | `""`          | 日志文件路径（空为 stdout）  |

### 2. 配置环境变量

```bash
mkdir -p vault
```

### 也可以手动克隆仓库，构建并运行

```bash
git clone https://github.com/youpingfang/fast-note-sync-docker.git
cd fast-note-sync-docker
```

```bash
docker-compose up -d
```

查看日志：

```bash
docker-compose logs -f
```

## License

MIT
