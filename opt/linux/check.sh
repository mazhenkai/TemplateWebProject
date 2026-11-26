#!/bin/bash
# 提交 / 推送前的安全检查。任一项失败则非零退出。AI 助手可执行。
#
# 用法：
#   bash opt/linux/check.sh            检查当前已跟踪文件（工作区 + 暂存区）
#   bash opt/linux/check.sh --history  额外扫描全部提交历史（开源 / 首次推送到公开仓库前用）
#
# 检查项：
#   1. 不应被跟踪的文件：真实配置、.env、私钥、data/ 与 log/ 下的数据
#   2. 已跟踪文件里的密钥特征
#   3. 额外敏感词：在 app.env 里设 CHECK_EXTRA_PATTERNS（正则，| 分隔），如本机路径、IP、内部域名
#   4. .sh 文件不得含 CRLF
source "$(dirname "$0")/env.sh"
cd "$ROOT" || exit 1

FAIL=0
ok()   { echo "[ OK ] $1"; }
fail() { echo "[FAIL] $1"; [ -n "$2" ] && echo "$2" | sed 's/^/    /'; FAIL=1; }

echo "=== 安全检查：$ROOT ==="

# 1. 不应被跟踪的文件
BAD=$(git ls-files | grep -E '^config/[^/]+$' | grep -v -E '^config/(README\.md|.*\.example)$';
      git ls-files | grep -E '(^|/)\.env(\..*)?$' | grep -v '\.env\.example$';
      git ls-files | grep -E '(\.pem|\.key|_rsa|_rsa\.pub)$';
      git ls-files | grep -E '^(data|log)/' | grep -v -E '^(data|log)/README\.md$')
[ -z "$BAD" ] && ok "不应跟踪的文件" || fail "不应跟踪的文件（git rm --cached 后检查 .gitignore）" "$BAD"

# 2 / 3. 内容扫描
SECRET_RE='sk-[A-Za-z0-9_-]{20,}|BEGIN [A-Z ]*PRIVATE KEY|AKIA[0-9A-Z]{16}|ghp_[A-Za-z0-9]{30,}'
scan() {  # $1=说明 $2=正则
    local out
    out=$(git grep -n -I -E "$2" -- . ':!opt/linux/check.sh' 2>/dev/null)
    if [ "$HISTORY" = 1 ]; then
        out+=$'\n'$(git grep -n -I -E "$2" $(git rev-list --all) -- . ':!opt/linux/check.sh' 2>/dev/null)
        out+=$'\n'$(git log --all --format='%h 提交说明: %B' | grep -E "$2")
    fi
    out=$(echo "$out" | sed '/^$/d' | sort -u)
    [ -z "$out" ] && ok "$1" || fail "$1" "$out"
}
HISTORY=0; [ "$1" = "--history" ] && HISTORY=1
scan "密钥特征" "$SECRET_RE"
[ -n "${CHECK_EXTRA_PATTERNS:-}" ] && scan "额外敏感词" "$CHECK_EXTRA_PATTERNS"

# 4. CRLF
CRLF=$(git ls-files '*.sh' | xargs -r grep -l $'\r' 2>/dev/null)
[ -z "$CRLF" ] && ok ".sh 换行符" || fail ".sh 含 CRLF（sed -i 's/\r\$//' <文件>）" "$CRLF"

# 提示：未提交变更
[ -n "$(git status --short)" ] && echo "[INFO] 工作区有未提交变更"
echo "[INFO] 提交作者：$(git log --format='%an <%ae>' 2>/dev/null | sort -u | paste -sd' ')"

if [ $FAIL -eq 0 ]; then
    echo "检查通过"
else
    echo "检查未通过。已推送过的密钥必须先去平台吊销轮换，删文件不算处理完。"
fi
exit $FAIL
