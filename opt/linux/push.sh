#!/bin/bash
# 推送到各远程。⚠ 只由负责人执行，AI 助手不执行。
# 流程：工作区干净 → check.sh → 测试（SKIP_TESTS=1 跳过，调用方已跑过时用）→ 逐个远程推送
#
# 在 config/app.env 设置：
#   PUSH_REMOTES="github gitee"   远程名，未配置的远程自动跳过
#   PUSH_BRANCH=main
#   PUSH_KEY_<远程名>=~/.ssh/id_xxx   如 PUSH_KEY_github=~/.ssh/id_github（不设则用默认 ssh 配置）
#   TEST_CMD="..."                 测试命令
source "$(dirname "$0")/env.sh"
cd "$ROOT" || exit 1
set -euo pipefail

if [ -n "$(git status --short)" ]; then
    echo "工作区有未提交变更，取消推送："; git status --short; exit 1
fi

bash "$ROOT/opt/linux/check.sh"

if [ "${SKIP_TESTS:-}" = 1 ]; then
    echo "=== 跳过测试（调用方已执行）==="
elif [ -n "$TEST_CMD" ]; then
    echo "=== 测试 ==="; bash -c "$TEST_CMD"
else
    echo "[WARN] 未设置 TEST_CMD，未运行测试"
fi

for remote in $PUSH_REMOTES; do
    if ! git remote get-url "$remote" >/dev/null 2>&1; then
        echo "[SKIP] 未配置远程 $remote"; continue
    fi
    key_var="PUSH_KEY_$remote"; key=${!key_var:-}
    echo "=== 推送 $remote ($PUSH_BRANCH) ==="
    if [ -n "$key" ]; then
        GIT_SSH_COMMAND="ssh -i $key -o IdentitiesOnly=yes -o StrictHostKeyChecking=accept-new" \
            git push "$remote" "$PUSH_BRANCH"
    else
        git push "$remote" "$PUSH_BRANCH"
    fi
done
echo "推送完成"
