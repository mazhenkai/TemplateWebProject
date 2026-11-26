# 推送到各远程。⚠ 只由负责人执行，AI 助手不执行。与 ..\linux\push.sh 一致。
# 流程：工作区干净 → check.ps1 → 测试（-SkipTests 跳过，调用方已跑过时用）→ 逐个远程推送
# 变量见 config\app.env.example：PUSH_REMOTES / PUSH_BRANCH / PUSH_KEY_<远程名> / TEST_CMD
param([switch]$SkipTests)
. "$PSScriptRoot\env.ps1"
Set-Location $Root

$dirty = git status --short
if ($dirty) { Write-Host '工作区有未提交变更，取消推送：'; $dirty; exit 1 }

& "$PSScriptRoot\check.ps1"
if ($LASTEXITCODE -ne 0) { exit 1 }

if ($SkipTests) { Write-Host '=== 跳过测试（调用方已执行）===' } else { Invoke-Tests }

foreach ($remote in $PushRemotes) {
    git remote get-url $remote 2>$null | Out-Null
    if ($LASTEXITCODE -ne 0) { Write-Host "[SKIP] 未配置远程 $remote"; continue }
    $key = Get-Cfg "PUSH_KEY_$remote"
    Write-Host "=== 推送 $remote ($PushBranch) ==="
    if ($key) {
        $env:GIT_SSH_COMMAND = "ssh -i `"$key`" -o IdentitiesOnly=yes -o StrictHostKeyChecking=accept-new"
    } else {
        Remove-Item Env:GIT_SSH_COMMAND -ErrorAction SilentlyContinue
    }
    Invoke-Native { git push $remote $PushBranch } "推送 $remote"
}
Write-Host '推送完成'
