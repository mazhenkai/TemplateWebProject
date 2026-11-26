# opt/linux/

Linux 平台运维脚本（bash）。脚本清单与权限见上级 [`opt/README.md`](../README.md)。

```bash
# 在项目根目录执行
bash opt/linux/dev_daily.sh start
```

## 已提供的脚本

| 脚本 | 说明 |
|---|---|
| `env.sh` | 推导项目根、加载 `config/app.env`、提供 `port_pid` / `activate_py` |
| `check.sh` | 不应跟踪的文件、密钥特征、`CHECK_EXTRA_PATTERNS`、`.sh` 的 CRLF；`--history` 扫全部历史 |
| `pack.sh` | `git archive` 打包 HEAD 到 `dist/`，`KEEP=N` 控制保留个数 |
| `dev_daily.sh` | 读 `FRONTEND_DEV_CMD` / `BACKEND_DEV_CMD` 启停开发环境，日志写 `log/` 并按天归档 |
| `push.sh` | 读 `PUSH_REMOTES` / `PUSH_KEY_<远程>` / `TEST_CMD`，**仅负责人执行** |
| `daily_pipeline.sh` | 检查 → 测试 → 有新 commit 则推送 → 打包，**仅负责人执行** |
| `sync_tables.sh` | 读 `TB_WHITELIST`：`diff`（默认，只读）列出 prd 缺表与字段差异；`apply` 补建缺表，**仅负责人执行** |

需要的变量全部在 `config/app.env.example` 里有说明。`deploy.sh`（表结构步骤调用 `sync_tables.sh apply -y`）、`rerun_prd.sh`、`prd_to_dev.sh` 与技术栈和部署方式强相关，按项目编写，要求见上级 README。

- 文件必须是 LF 换行（`.gitattributes` 已约束 `*.sh eol=lf`）。
- 开头 `set -euo pipefail`，并 `source "$(dirname "$0")/env.sh"` 加载公共变量。
- 与 `../windows/` 下同名脚本作用一致。
