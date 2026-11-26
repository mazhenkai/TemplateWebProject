# 每日流水线：安全检查 → 测试（无条件）→ 有新 commit 则推送 → 打包。⚠ 只由负责人执行。
# 工作区不干净时：照常检查和测试，跳过推送和打包，非零退出提示先 commit。与 ..\linux\daily_pipeline.sh 一致。
. "$PSScriptRoot\env.ps1"
Set-Location $Root

Write-Host '=========================================='
Write-Host "$Project Daily Pipeline - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Host '=========================================='

$dirty = git status --short
if ($dirty) { Write-Warning '有未提交变更（本次只检查和测试）：'; $dirty }

& "$PSScriptRoot\check.ps1"
if ($LASTEXITCODE -ne 0) { exit 1 }
Invoke-Tests

if ($dirty) { Write-Host '检查与测试通过，但工作区有未提交变更，已跳过推送和打包。请先 commit。'; exit 1 }

$first = $PushRemotes[0]
git rev-parse -q --verify "$first/$PushBranch" 2>$null | Out-Null
if ($LASTEXITCODE -eq 0) {
    git fetch -q $first 2>$null
    $unpushed = [int](git rev-list --count "$first/$PushBranch..HEAD")
} else {
    $unpushed = [int](git rev-list --count HEAD)
}
if ($unpushed -eq 0) {
    Write-Host '没有新 commit，跳过推送'
} else {
    Write-Host "发现 $unpushed 个未推送 commit"
    & "$PSScriptRoot\push.ps1" -SkipTests
    if ($LASTEXITCODE -ne 0) { exit 1 }
}

& "$PSScriptRoot\pack.ps1"
Write-Host '=== 最近 3 个 commit ==='
git log --pretty=format:'%h %s' -3; Write-Host ''
Write-Host 'Pipeline 完成'
