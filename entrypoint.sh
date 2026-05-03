#!/bin/bash
set -e

# =============================================
# FastNodeSync CLI Docker Entry Point
# =============================================
# 支持从环境变量生成 config.yaml 并启动同步

CONFIG_FILE="/app/config.yaml"

# 如果 config.yaml 不存在（未挂载），则从环境变量生成
if [ ! -f "$CONFIG_FILE" ]; then
    echo "[ENTRY] 未检测到 config.yaml，开始从环境变量生成..."

    # 必须有 FNS_API 和 FNS_TOKEN
    if [ -z "$FNS_API" ] || [ -z "$FNS_TOKEN" ]; then
        echo "[ERROR] 缺少必需的环境变量：FNS_API 和 FNS_TOKEN 必须设置"
        echo "示例：docker run -e FNS_API=https://your-server.zeabur.app -e FNS_TOKEN=your_token -e FNS_VAULT=defaultVault -v /path/to/vault:/app/vault ..."
        exit 1
    fi

    # ============ 服务端 ============
    VAULT_NAME="${FNS_VAULT:-defaultVault}"

    # ============ 同步行为 ============
    WATCH_PATH="${FNS_WATCH_PATH:-/app/vault}"
    SYNC_NOTES="${FNS_SYNC_NOTES:-true}"
    SYNC_FILES="${FNS_SYNC_FILES:-true}"
    SYNC_CONFIG="${FNS_SYNC_CONFIG:-true}"

    # exclude_patterns：逗号分隔，转为 YAML 列表格式
    if [ -n "$FNS_EXCLUDE_PATTERNS" ]; then
        EXCLUDE_PATTERNS=$(echo "$FNS_EXCLUDE_PATTERNS" | awk -F',' '{for(i=1;i<=NF;i++) printf "    - \"%s\"\n", $i}' | sed 's/"/\\"/g')
    else
        EXCLUDE_PATTERNS="    - \".git/**\"
    - \".trash/**\"
    - \"*.tmp\"
    - \".fns_state.json\""
    fi

    FILE_CHUNK_SIZE="${FNS_FILE_CHUNK_SIZE:-524288}"

    # ============ 客户端重连机制 ============
    RECONNECT_MAX_RETRIES="${FNS_RECONNECT_MAX_RETRIES:-15}"
    RECONNECT_BASE_DELAY="${FNS_RECONNECT_BASE_DELAY:-3}"
    HEARTBEAT_INTERVAL="${FNS_HEARTBEAT_INTERVAL:-30}"

    # ============ 日志 ============
    LOG_LEVEL="${FNS_LOG_LEVEL:-INFO}"
    LOG_FILE="${FNS_LOG_FILE:-}"

    cat > "$CONFIG_FILE" << EOF
server:
  api: "$FNS_API"
  token: "$FNS_TOKEN"
  vault: "$VAULT_NAME"

sync:
  watch_path: "$WATCH_PATH"
  sync_notes: $SYNC_NOTES
  sync_files: $SYNC_FILES
  sync_config: $SYNC_CONFIG
  exclude_patterns:
$EXCLUDE_PATTERNS
  file_chunk_size: $FILE_CHUNK_SIZE

client:
  reconnect_max_retries: $RECONNECT_MAX_RETRIES
  reconnect_base_delay: $RECONNECT_BASE_DELAY
  heartbeat_interval: $HEARTBEAT_INTERVAL

logging:
  level: "$LOG_LEVEL"
  file: "$LOG_FILE"
EOF
    echo "[ENTRY] config.yaml 生成完成："
    cat "$CONFIG_FILE"
fi

echo "[ENTRY] 启动 FastNodeSync CLI..."
exec python -m fns_cli.main run -c "$CONFIG_FILE"