# opt/windows/

Windows 平台运维脚本（PowerShell 5.1+）。脚本清单与权限见上级 [`opt/README.md`](../README.md)，与 `../linux/` 下同名脚本作用一致。

```powershell
# 在项目根目录执行
powershell -NoProfile -ExecutionPolicy Bypass -File .\opt\windows\dev_daily.ps1 start
```

## 已提供的脚本

| 脚本 | 说明 |
|---|---|
| `env.ps1` | 推导项目根、解析 `config\app.env`（支持 `$VAR` 展开）、提供 `Get-Cfg` / `Get-PortPid` / `Invoke-Native` |
| `check.ps1` | 同 `check.sh`；`-History` 扫全部历史 |
| `pack.ps1` | 同 `pack.sh`；`-Keep N` 控制保留个数 |
| `dev_daily.ps1` | `start\|stop\|restart\|status\|log`，启动命令用 `cmd /c` 执行，停止用 `taskkill /T` 结束进程树 |
| `push.ps1` | 同 `push.sh`，**仅负责人执行**；`-SkipTests` 跳过测试 |
| `daily_pipeline.ps1` | 同 `daily_pipeline.sh`，**仅负责人执行** |

`sync_tables` 操作的是服务器上的数据库，只提供 Linux 版。

## 编写约定

- **文件存为 UTF-8 with BOM**。Windows PowerShell 5.1 读无 BOM 文件按系统 ANSI 编码，中文会乱码甚至语法错误。
- 换行为 CRLF（`.gitattributes` 已约束 `*.ps1 eol=crlf`）。
- 开头 dot-source 公共变量：`. "$PSScriptRoot\env.ps1"`（其中已设 `$ErrorActionPreference = 'Stop'`）。
- `$ErrorActionPreference` 管不到外部命令（git、npm），用 `Invoke-Native { ... } '说明'` 检查退出码。
