# 提交 / 推送前的安全检查。任一项失败则非零退出。AI 助手可执行。与 ..\linux\check.sh 一致。
#
# 用法（项目根目录）：
#   powershell -NoProfile -ExecutionPolicy Bypass -File .\opt\windows\check.ps1
#   powershell -NoProfile -ExecutionPolicy Bypass -File .\opt\windows\check.ps1 -History   额外扫描全部历史
param([switch]$History)
. "$PSScriptRoot\env.ps1"
Set-Location $Root

$script:Fail = 0
function Ok([string]$m) { Write-Host "[ OK ] $m" }
function Bad([string]$m, $detail) {
    Write-Host "[FAIL] $m" -ForegroundColor Red
    $detail | ForEach-Object { Write-Host "    $_" }
    $script:Fail = 1
}

Write-Host "=== 安全检查：$Root ==="

# 1. 不应被跟踪的文件
$files = git ls-files
$bad = $files | Where-Object {
    ($_ -match '^config/[^/]+$' -and $_ -notmatch '^config/(README\.md|.*\.example)$') -or
    ($_ -match '(^|/)\.env(\..*)?$' -and $_ -notmatch '\.env\.example$') -or
    ($_ -match '(\.pem|\.key|_rsa|_rsa\.pub)$') -or
    ($_ -match '^(data|log)/' -and $_ -notmatch '^(data|log)/README\.md$')
}
if ($bad) { Bad '不应跟踪的文件（git rm --cached 后检查 .gitignore）' $bad } else { Ok '不应跟踪的文件' }

# 2 / 3. 内容扫描
function Scan([string]$What, [string]$Re) {
    $out = @(git grep -n -I -E $Re -- . ':!opt/linux/check.sh' ':!opt/windows/check.ps1' 2>$null)
    if ($History) {
        $revs = git rev-list --all
        $out += @(git grep -n -I -E $Re $revs -- . ':!opt/linux/check.sh' ':!opt/windows/check.ps1' 2>$null)
        $out += @(git log --all --format='%h 提交说明: %B' | Select-String -Pattern $Re | ForEach-Object { $_.Line })
    }
    $out = $out | Where-Object { $_ } | Sort-Object -Unique
    if ($out) { Bad $What $out } else { Ok $What }
}
Scan '密钥特征' 'sk-[A-Za-z0-9_-]{20,}|BEGIN [A-Z ]*PRIVATE KEY|AKIA[0-9A-Z]{16}|ghp_[A-Za-z0-9]{30,}'
$extra = Get-Cfg 'CHECK_EXTRA_PATTERNS'
if ($extra) { Scan '额外敏感词' $extra }

# 4. .sh 在仓库中必须是 LF（看索引里的换行，不受本机 autocrlf 影响）
$crlf = git ls-files --eol -- '*.sh' | Where-Object { $_ -match '^i/crlf' } | ForEach-Object { ($_ -split '\s+')[-1] }
if ($crlf) { Bad '.sh 含 CRLF' $crlf } else { Ok '.sh 换行符' }

if (git status --short) { Write-Host '[INFO] 工作区有未提交变更' }
Write-Host "[INFO] 提交作者：$((git log --format='%an <%ae>' | Sort-Object -Unique) -join ' ')"

if ($script:Fail -eq 0) { Write-Host '检查通过' }
else { Write-Host '检查未通过。已推送过的密钥必须先去平台吊销轮换，删文件不算处理完。' -ForegroundColor Red }
exit $script:Fail
