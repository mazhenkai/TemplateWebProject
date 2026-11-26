# 打包已提交的代码到 dist\。用 git archive，被忽略和未提交的内容天然不会进包。AI 助手可执行。
#   powershell -NoProfile -ExecutionPolicy Bypass -File .\opt\windows\pack.ps1 [-Keep 5]
param([int]$Keep = 5)
. "$PSScriptRoot\env.ps1"
Set-Location $Root

$name = '{0}_{1}_{2}.zip' -f (Get-Date -Format 'yyMMdd_HHmm'), $Project, (git rev-parse --short HEAD)
New-Item -ItemType Directory -Force -Path $Dist | Out-Null
Invoke-Native { git archive --format=zip --prefix="$Project/" -o (Join-Path $Dist $name) HEAD } 'git archive'
Write-Host "打包完成：$(Join-Path $Dist $name)"
if (git status --short) { Write-Warning '工作区有未提交变更，未包含在包内' }

$all = Get-ChildItem $Dist -Filter "*_${Project}_*.zip" | Sort-Object LastWriteTime -Descending
$all | Select-Object -Skip $Keep | Remove-Item -Force
Write-Host "当前保留：$([Math]::Min($all.Count, $Keep)) 个"
