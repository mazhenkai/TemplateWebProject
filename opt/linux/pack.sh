#!/bin/bash
# 打包已提交的代码到 dist/。用 git archive，被忽略和未提交的内容天然不会进包。AI 助手可执行。
#   KEEP=5 bash opt/linux/pack.sh    保留最近 N 个包（默认 5）
source "$(dirname "$0")/env.sh"
cd "$ROOT" || exit 1
set -euo pipefail

KEEP=${KEEP:-5}
NAME="$(date +%y%m%d_%H%M)_${PROJECT}_$(git rev-parse --short HEAD).zip"
mkdir -p "$DIST"

git archive --format=zip --prefix="$PROJECT/" -o "$DIST/$NAME" HEAD
echo "打包完成：$DIST/$NAME"
[ -n "$(git status --short)" ] && echo "[WARN] 工作区有未提交变更，未包含在包内"

ls -t "$DIST"/*_"${PROJECT}"_*.zip 2>/dev/null | tail -n +$((KEEP + 1)) | xargs -r rm -f
echo "当前保留：$(ls "$DIST"/*_"${PROJECT}"_*.zip | wc -l) 个"
