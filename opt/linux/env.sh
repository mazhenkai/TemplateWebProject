#!/bin/bash
# 公共变量：被 opt/linux/ 下其他脚本 source，不单独执行。
# 路径全部相对项目根推导；端口、启动命令等从 config/app.env 读取。

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
PROJECT=${PROJECT:-$(basename "$ROOT")}
CONFIG=$ROOT/config/app.env
DIST=$ROOT/dist
LOG_DIR=$ROOT/log

if [ -f "$CONFIG" ]; then
    set -a
    # shellcheck disable=SC1090
    source "$CONFIG"
    set +a
else
    echo "[WARN] 缺少 $CONFIG，请先 cp config/app.env.example config/app.env" >&2
fi

# 远程与密钥（push.sh 用），可在 app.env 覆盖
PUSH_REMOTES=${PUSH_REMOTES:-"github gitee"}
PUSH_BRANCH=${PUSH_BRANCH:-main}

# 测试入口（push.sh / daily_pipeline.sh 用），在 app.env 里按技术栈填写
TEST_CMD=${TEST_CMD:-}

# 端口 → pid
port_pid() { ss -tlnp "sport = :$1" 2>/dev/null | grep -oP 'pid=\K[0-9]+' | head -1; }

# 加载 conda 环境（Python 项目用，PY_ENV 在 app.env 设置）
activate_py() {
    # shellcheck disable=SC1090,SC1091
    [ -n "${PY_ENV:-}" ] && source "${CONDA_BASE:-$HOME/miniconda3}/bin/activate" "$PY_ENV"
}
