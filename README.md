# 项目目录模板

按第一、二层目录组织。各目录职责如下，复制本目录后按需改名、删剪。

## 目录说明

```
ProjectTemplate/
├── Backend/          后端服务（技术栈不限，内部结构按所选框架惯例自行细分）
├── Config/           配置唯一事实源（app.env 真实配置，gitignore；app.env.example 模板入库）
├── Data/             本地数据文件（不进 git 的散装数据）
├── Docs/             全部文档
│   ├── archive/      废弃/过期文档存档
│   ├── complete/     已完成规划的归档（从 plan/ 移入）
│   ├── log/          开发日志（按日期命名）
│   ├── plan/         进行中的规划文档
│   ├── runbook/      运行手册（启动/重启/运维命令）
│   └── readme.md     项目说明（账号、命令清单等）
├── Frontend/         前端（技术栈不限，内部结构按所选框架惯例自行细分）
├── Verify/           独立验证脚本（数据库连通、外部 API 通路等，一次性工具）
└── opt/              运维脚本
    ├── linux/        Linux 下服务启动/重启脚本
    └── windows/      Windows 下服务启动/重启脚本（restart.ps1 / start_frontend.ps1 ...）
```

## 配套约定

- **配置解耦**：代码内不硬编码凭据/端口/库名，统一从 `Config/app.env` 读取；仓库只入库 `app.env.example` 模板。
- **文档命名**：带时间戳前缀，如 `2610071347产品规划.md`（时间戳 + 标题）。
- **规划生命周期**：`Docs/plan/`（进行中）→ 完成后移入 `Docs/complete/`。
- **Verify/ 与 opt/**：`Verify/` 放"验证通路是否通"的一次性脚本；`opt/` 放"日常运维反复用"的脚本，两者不混放。
- **跨平台**：`opt/` 按 `linux/`、`windows/` 分目录，脚本同名便于记忆。
- **空目录不入库**：git 不跟踪空目录，本模板也不放 `.gitkeep`；克隆后按各目录 README 的说明自行创建子目录。
