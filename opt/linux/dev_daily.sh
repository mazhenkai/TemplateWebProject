#!/bin/bash
# 开发环境开关。开发服务器长时间运行会占大量内存，开工 start、收工 stop。AI 助手可执行。
#
# 用法：
#   bash opt/linux/dev_daily.sh start     开工：检查并按天归档日志 → 启动前后端
#   bash opt/linux/dev_daily.sh stop      收工：关闭前后端
#   bash opt/linux/dev_daily.sh restart   重启
#   bash opt/linux/dev_daily.sh status    运行状态与内存
#   bash opt/linux/dev_daily.sh log       只检查日志
#
# 需要在 config/app.env 设置：
#   FRONTEND_PORT  BACKEND_PORT
#   FRONTEND_DEV_CMD   如 "npm run dev -- -p $FRONTEND_PORT -H 127.0.0.1"
#   BACKEND_DEV_CMD    如 "go run ./cmd/api" 或 "python -m uvicorn app.main:app --port $BACKEND_PORT"
# 命令分别在 frontend/、backend/ 目录下执行；某一端不需要就留空。
source "$(dirname "$0")/env.sh"

FE_LOG=$LOG_DIR/frontend_dev.log
BE_LOG=$LOG_DIR/backend_dev.log
ARCHIVE=$LOG_DIR/archive
KEEP_DAYS=${KEEP_DAYS:-14}
TODAY=$(date +%y%m%d)
ERR_RE='⨯|Error|ERROR|panic|Traceback|\| 5[0-9]{2} \|'
mkdir -p "$LOG_DIR"

rss_mb() { [ -n "$1" ] && ps -o rss= -p "$1" 2>/dev/null | awk '{printf "%d", $1/1024}'; }

check_one_log() {  # $1=日志 $2=名称 $3=rotate
    local log=$1 day errs
    echo "--- $2: $log"
    [ -f "$log" ] || { echo "    不存在，启动时新建"; return; }
    # 按首行启动标记判断日志属于哪天（mtime 不可靠）
    day=$(head -1 "$log" | grep -oP '^===== 20\K[0-9]{2}-[0-9]{2}-[0-9]{2}' | tr -d '-')
    [ -z "$day" ] && day=$(date -r "$log" +%y%m%d)
    echo "    大小 $(du -h "$log" | cut -f1)，最后写入 $(date -r "$log" '+%F %T')"
    errs=$(grep -aEc "$ERR_RE" "$log")
    if [ "$errs" -gt 0 ]; then
        echo "    ⚠ $errs 行错误，最近 5 条："
        grep -aE "$ERR_RE" "$log" | tail -5 | cut -c1-200 | sed 's/^/      /'
    else
        echo "    ✓ 无错误"
    fi
    if [ "$day" != "$TODAY" ] && [ "${3:-}" = rotate ]; then
        mkdir -p "$ARCHIVE/$day"
        mv "$log" "$ARCHIVE/$day/" && gzip -f "$ARCHIVE/$day/$(basename "$log")"
        echo "    → 已归档到 $ARCHIVE/$day/"
    fi
}

check_logs() {
    echo "=== 日志检查 ==="
    check_one_log "$FE_LOG" 前端 "${1:-}"
    check_one_log "$BE_LOG" 后端 "${1:-}"
    # 只清理压缩归档；删除阈值由 KEEP_DAYS 控制
    [ -d "$ARCHIVE" ] && find "$ARCHIVE" -name '*.gz' -mtime +"$KEEP_DAYS" -delete
}

stop_one() {  # $1=端口 $2=名称
    local pid; pid=$(port_pid "$1")
    [ -z "$pid" ] && { echo "$2 :$1 未运行"; return; }
    echo "停止 $2 :$1 pid=$pid"
    pkill -P "$pid" 2>/dev/null; kill "$pid" 2>/dev/null
    for _ in $(seq 10); do [ -z "$(port_pid "$1")" ] && return; sleep 1; done
    pid=$(port_pid "$1"); [ -n "$pid" ] && { echo "强制结束 $pid"; kill -9 "$pid"; }
}

start_one() {  # $1=目录 $2=命令 $3=日志 $4=名称
    [ -z "$2" ] && { echo "$4 未配置启动命令，跳过"; return; }
    echo "===== $(date '+%F %T') start =====" >> "$3"
    (cd "$ROOT/$1" && setsid nohup bash -c "$2" >> "$3" 2>&1 < /dev/null &)
    echo "已启动 $4，日志 $3"
}

status_dev() {
    echo "=== 开发环境状态 ==="
    local p pid
    for p in "前端:${FRONTEND_PORT:-}" "后端:${BACKEND_PORT:-}"; do
        [ -z "${p#*:}" ] && continue
        pid=$(port_pid "${p#*:}")
        if [ -n "$pid" ]; then echo "${p%%:*} :${p#*:} 运行中 pid=$pid 内存 $(rss_mb "$pid")MB"
        else echo "${p%%:*} :${p#*:} 未运行"; fi
    done
    free -h | awk '/Mem:/{print "系统内存：总 "$2"，已用 "$3"，可用 "$7}'
}

stop_dev() {
    echo "=== 关闭开发环境 ==="
    [ -n "${FRONTEND_PORT:-}" ] && stop_one "$FRONTEND_PORT" 前端
    [ -n "${BACKEND_PORT:-}" ] && stop_one "$BACKEND_PORT" 后端
}

start_dev() {
    check_logs rotate
    echo; echo "=== 启动开发环境 ==="
    stop_dev
    start_one frontend "${FRONTEND_DEV_CMD:-}" "$FE_LOG" 前端
    start_one backend  "${BACKEND_DEV_CMD:-}"  "$BE_LOG" 后端
    echo -n "等待端口就绪"
    for _ in $(seq 30); do
        { [ -z "${FRONTEND_DEV_CMD:-}" ] || [ -n "$(port_pid "$FRONTEND_PORT")" ]; } &&
        { [ -z "${BACKEND_DEV_CMD:-}" ]  || [ -n "$(port_pid "$BACKEND_PORT")" ]; } && break
        echo -n "."; sleep 1
    done
    echo; status_dev
    echo "收工记得：bash opt/linux/dev_daily.sh stop"
}

case "${1:-}" in
    start)   start_dev ;;
    stop)    stop_dev ;;
    restart) start_dev ;;
    status)  status_dev ;;
    log)     check_logs ;;
    *) echo "用法：$0 {start|stop|restart|status|log}"; exit 1 ;;
esac
