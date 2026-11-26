#!/bin/bash
# 每日流水线：安全检查 → 测试（无条件）→ 有新 commit 则推送 → 打包。⚠ 只由负责人执行。
# 工作区不干净时：照常检查和测试，跳过推送和打包，非零退出提示先 commit。
source "$(dirname "$0")/env.sh"
cd "$ROOT" || exit 1
set -euo pipefail

echo "=========================================="
echo "$PROJECT Daily Pipeline - $(date '+%F %T')"
echo "=========================================="

DIRTY=0
if [ -n "$(git status --short)" ]; then
    DIRTY=1; echo "[WARN] 有未提交变更（本次只检查和测试）："; git status --short
fi

bash "$ROOT/opt/linux/check.sh"
if [ -n "$TEST_CMD" ]; then echo "=== 测试 ==="; bash -c "$TEST_CMD"; else echo "[WARN] 未设置 TEST_CMD"; fi

if [ $DIRTY -eq 1 ]; then
    echo "检查与测试通过，但工作区有未提交变更，已跳过推送和打包。请先 commit。"; exit 1
fi

FIRST=${PUSH_REMOTES%% *}
if git rev-parse -q --verify "$FIRST/$PUSH_BRANCH" >/dev/null; then
    git fetch -q "$FIRST" || true
    UNPUSHED=$(git rev-list --count "$FIRST/$PUSH_BRANCH"..HEAD)
else
    UNPUSHED=$(git rev-list --count HEAD)
fi
if [ "$UNPUSHED" -eq 0 ]; then
    echo "没有新 commit，跳过推送"
else
    echo "发现 $UNPUSHED 个未推送 commit"
    SKIP_TESTS=1 bash "$ROOT/opt/linux/push.sh"
fi

bash "$ROOT/opt/linux/pack.sh"
echo "=== 最近 3 个 commit ==="; git log --pretty=format:'%h %s' -3; echo
echo "Pipeline 完成"
