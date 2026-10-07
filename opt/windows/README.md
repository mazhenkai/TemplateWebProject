# opt/windows/

Windows 平台的运维脚本（启动/重启/停止前后端，PowerShell）。

用法示例（项目根目录执行）：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\opt\windows\restart.ps1
```

脚本尽量与 `../linux/` 下同名脚本作用一致。详细用法见 `Docs/runbook/`。
