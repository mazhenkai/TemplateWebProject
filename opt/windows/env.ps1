# 公共变量：被 opt\windows\ 下其他脚本 dot-source（. "$PSScriptRoot\env.ps1"），不单独执行。
# 路径全部相对项目根推导；端口、启动命令等从 config\app.env 读取。
$ErrorActionPreference = 'Stop'

$Root    = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$Project = if ($env:PROJECT) { $env:PROJECT } else { Split-Path $Root -Leaf }
$Config  = Join-Path $Root 'config\app.env'
$Dist    = Join-Path $Root 'dist'
$LogDir  = Join-Path $Root 'log'

# 读取 app.env：KEY=VALUE，# 开头为注释；双引号或无引号的值会展开 $VAR / ${VAR}，单引号不展开
$Cfg = @{}
function Expand-CfgValue([string]$v) {
    [regex]::Replace($v, '\$\{?([A-Za-z_][A-Za-z0-9_]*)\}?', {
        param($m)
        $n = $m.Groups[1].Value
        if ($Cfg.ContainsKey($n)) { $Cfg[$n] } else { [Environment]::GetEnvironmentVariable($n) }
    })
}
if (Test-Path $Config) {
    foreach ($line in Get-Content $Config -Encoding UTF8) {
        if ($line -match '^\s*(#|$)') { continue }
        if ($line -notmatch '^\s*([A-Za-z_][A-Za-z0-9_]*)=(.*)$') { continue }
        $k = $Matches[1]; $v = $Matches[2].Trim()
        if ($v -match "^'(.*)'$")      { $v = $Matches[1] }
        elseif ($v -match '^"(.*)"$') { $v = Expand-CfgValue $Matches[1] }
        else                          { $v = Expand-CfgValue $v }
        $Cfg[$k] = $v
        [Environment]::SetEnvironmentVariable($k, $v, 'Process')
    }
} else {
    Write-Warning "缺少 $Config，请先 copy config\app.env.example config\app.env"
}

function Get-Cfg([string]$Name, [string]$Default = '') {
    if ($Cfg.ContainsKey($Name) -and $Cfg[$Name] -ne '') { $Cfg[$Name] } else { $Default }
}

$PushRemotes = (Get-Cfg 'PUSH_REMOTES' 'github gitee') -split '\s+' | Where-Object { $_ }
$PushBranch  = Get-Cfg 'PUSH_BRANCH' 'main'
$TestCmd     = Get-Cfg 'TEST_CMD'

# 执行外部命令，非零退出码时抛错（$ErrorActionPreference 管不到外部命令）
function Invoke-Native([scriptblock]$Block, [string]$What) {
    & $Block
    if ($LASTEXITCODE -ne 0) { throw "$What 失败（退出码 $LASTEXITCODE）" }
}

# 端口 → pid
function Get-PortPid([int]$Port) {
    Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue |
        Select-Object -First 1 -ExpandProperty OwningProcess
}

# 运行测试命令（TEST_CMD 为空时只警告）
function Invoke-Tests {
    if (-not $TestCmd) { Write-Warning '未设置 TEST_CMD，未运行测试'; return }
    Write-Host '=== 测试 ==='
    Push-Location $Root
    try { Invoke-Native { cmd /c $TestCmd } '测试' } finally { Pop-Location }
}
