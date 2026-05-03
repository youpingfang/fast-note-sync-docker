FROM python:3.10-slim

WORKDIR /app

# 安装依赖
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 复制 CLI 代码
COPY fns_cli/ ./fns_cli/

# 复制 entrypoint 脚本
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# 创建 vault 目录（可被 volume 覆盖）
RUN mkdir -p /app/vault

# 容器启动入口
ENTRYPOINT ["/entrypoint.sh"]