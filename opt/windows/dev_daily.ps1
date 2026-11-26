# 开发环境开关。开工 start、收工 stop。AI 助手可执行。与 ..\linux\dev_daily.sh 一致。
#
# 用法（项目根目录）：
#   powershell -NoProfile -ExecutionPolicy Bypass -File .\opt\windows\dev_daily.ps1 start|stop|restart|status|log
#
# 需要在 config\app.env 设置 FRONTEND_PORT / BACKEND_PORT / FRONTEND_DEV_CMD / BACKEND_DEV_CMD，
# 命令分别在 frontend\、backend\ 目录下用 cmd /c 执行；某一端不需要就留空。
param([Parameter(Position = 0)][ValidateSet('start', 'stop', 'restart', 'status', 'log')][string]$Action = 'status')
. "$PSScriptRoot\env.ps1"

$FePort = Get-Cfg 'FRONTEND_PORT'; $BePort = Get-Cfg 'BACKEND_PORT'
$FeCmd  = Get-Cfg 'FRONTEND_DEV_CMD'; $BeCmd = Get-Cfg 'BACKEND_DEV_CMD'
$FeLog  = Join-Path $LogDir 'frontend_dev.log'
$BeLog  = Join-Path $LogDir 'backend_dev.log'
$Archive = Join-Path $LogDir 'archive'
$KeepDays = [int](Get-Cfg 'KEEP_DAYS' '14')
$Today  = Get-Date -Format 'yyMMdd'
$ErrRe  = '⨯|Error|ERROR|panic|Traceback|\| 5[0-9]{2} \|'
New-Item -ItemType Directory -Force -Path $LogDir | Out-Null

function Check-OneLog([string]$Log, [string]$Name, [switch]$Rotate) {
    Write-Host "--- ${Name}: $Log"
    if (-not (Test-Path $Log)) { Write-Host '    不存在，启动时新建'; return }
    $first = Get-Content $Log -TotalCount 1 -Encoding UTF8
    $day = if ($first -match '^===== 20(\d{2})-(\d{2})-(\d{2})') { $Matches[1] + $Matches[2] + $Matches[3] }
           else { (Get-Item $Log).LastWriteTime.ToString('yyMMdd') }
    $item = Get-Item $Log
    Write-Host ("    大小 {0:N0} KB，最后写入 {1}" -f ($item.Length / 1KB), $item.LastWriteTime)
    $errs = @(Select-String -Path $Log -Pattern $ErrRe -Encoding UTF8)
    if ($errs.Count -gt 0) {
        Write-Host "    ⚠ $($errs.Count) 行错误，最近 5 条："
        $errs | Select-Object -Last 5 | ForEach-Object { $l = $_.Line; Write-Host "      $($l.Substring(0, [Math]::Min(200, $l.Length)))" }
    } else { Write-Host '    ✓ 无错误' }
    if ($Rotate -and $day -ne $Today) {
        $dst = Join-Path $Archive $day
        New-Item -ItemType Directory -Force -Path $dst | Out-Null
        Compress-Archive -Path $Log -DestinationPath (Join-Path $dst ((Split-Path $Log -Leaf) + '.zip')) -Force
        Remove-Item $Log
        Write-Host "    → 已归档到 $dst"
    }
}

function Check-Logs([switch]$Rotate) {
    Write-Host '=== 日志检查 ==='
    Check-OneLog $FeLog '前端' -Rotate:$Rotate
    Check-OneLog $BeLog '后端' -Rotate:$Rotate
    if (Test-Path $Archive) {
        Get-ChildItem $Archive -Recurse -Filter '*.zip' |
            Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-$KeepDays) } | Remove-Item -Force
    }
}

function Stop-One([string]$Port, [string]$Name) {
    if (-not $Port) { return }
    $p = Get-PortPid $Port
    if (-not $p) { Write-Host "$Name :$Port 未运行"; return }
    Write-Host "停止 $Name :$Port pid=$p"
    taskkill /PID $p /T /F | Out-Null
}

function Start-One([string]$Dir, [string]$Cmd, [string]$Log, [string]$Name) {
    if (-not $Cmd) { Write-Host "$Name 未配置启动命令，跳过"; return }
    Add-Content -Path $Log -Value "===== $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') start =====" -Encoding UTF8
    Start-Process -FilePath 'cmd.exe' -ArgumentList '/c', "$Cmd >> `"$Log`" 2>&1" `
        -WorkingDirectory (Join-Path $Root $Dir) -WindowStyle Hidden | Out-Null
    Write-Host "已启动 $Name，日志 $Log"
}

function Show-Status {
    Write-Host '=== 开发环境状态 ==='
    foreach ($s in @(@('前端', $FePort), @('后端', $BePort))) {
        if (-not $s[1]) { continue }
        $p = Get-PortPid $s[1]
        if ($p) {
            $mb = [int]((Get-Process -Id $p).WorkingSet64 / 1MB)
            Write-Host "$($s[0]) :$($s[1]) 运行中 pid=$p 内存 ${mb}MB"
        } else { Write-Host "$($s[0]) :$($s[1]) 未运行" }
    }
}

function Stop-Dev { Write-Host '=== 关闭开发环境 ==='; Stop-One $FePort '前端'; Stop-One $BePort '后端' }

function Start-Dev {
    Check-Logs -Rotate
    Write-Host ''; Write-Host '=== 启动开发环境 ==='
    Stop-Dev
    Start-One 'frontend' $FeCmd $FeLog '前端'
    Start-One 'backend'  $BeCmd $BeLog '后端'
    Write-Host -NoNewline '等待端口就绪'
    for ($i = 0; $i -lt 30; $i++) {
        $feOk = (-not $FeCmd) -or (Get-PortPid $FePort)
        $beOk = (-not $BeCmd) -or (Get-PortPid $BePort)
        if ($feOk -and $beOk) { break }
        Write-Host -NoNewline '.'; Start-Sleep 1
    }
    Write-Host ''; Show-Status
    Write-Host '收工记得：dev_daily.ps1 stop'
}

switch ($Action) {
    'start'   { Start-Dev }
    'stop'    { Stop-Dev }
    'restart' { Start-Dev }
    'status'  { Show-Status }
    'log'     { Check-Logs }
}
