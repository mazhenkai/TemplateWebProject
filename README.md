# <项目名>

> 一句话说明项目是做什么的。

**第一次接手项目，先读 [`doc/doc/项目阅读说明.md`](doc/doc/项目阅读说明.md)，再读 [`doc/README.md`](doc/README.md)。** 项目级规范全部在 `doc/doc/`，各目录的规范在各自的 `README.md`。

---

## 快速开始

```bash
# 1. 准备配置（真实配置不入库，从模板复制后填写）
cp config/app.env.example config/app.env

# 2. 准备运行环境（解释器路径、依赖安装方式见开发环境说明）
#    doc/doc/开发环境说明.md

# 3. 启动开发环境（收工时 stop）
bash opt/linux/dev_daily.sh start
```

## 技术栈

| 层 | 技术 |
|---|---|
| 前端 | <如 Next.js + TypeScript> |
| 后端 | <如 Go + Gin / Python + FastAPI> |
| 数据库 | <如 PostgreSQL，dev / prd 双 schema> |
| 反代 | <如 Nginx> |

## 环境与端口

两套环境完全隔离：开发环境随便写，生产环境只放正式数据。

| 环境 | 前端端口 | 后端端口 | 数据库 schema | 环境标识 | 访问地址 |
|---|---|---|---|---|---|
| 开发 | <dev 前端> | <dev 后端> | `dev` | `APP_ENV=dev` | <dev 域名> |
| 生产 | <prd 前端> | <prd 后端> | `prd` | `APP_ENV=prd` | <prd 域名> |

> **凭据不入文档。** 账号、口令、密钥只放 `config/app.env`（不入库），通过安全渠道传递。

## 目录导航

| 目录 | 用途 | 是否 commit |
|---|---|---|
| `backend/` | 后端服务本体 | ✅ |
| `backend/migrations/` | 数据库迁移 SQL，按编号顺序执行 | ✅ |
| `frontend/` | 前端应用本体 | ✅ |
| `config/` | 配置唯一事实源：`app.env` 真实配置、`app.env.example` 模板 | ⚠️ 只提交 `*.example` |
| `tests/` | 单元测试与集成测试 | ✅ |
| `verify/` | 一次性验证脚本：数据库、外部 API 通不通 | ✅ |
| `opt/` | 运维脚本：启动重启、部署、检查、打包、推送 | ✅（密钥除外） |
| `doc/doc/` | 项目级规范 + 架构决策记录（ADR） | ✅ |
| `doc/plan/` | 开发计划（承诺） | ✅ |
| `doc/log/` | 开发日志（记录），一天一篇 | ✅ |
| `doc/todo/` | 已确认但暂缓的事项（待办池） | ✅ |
| `data/` | 本地散装数据：原始数据、样本、导出结果 | ❌ |
| `log/` | 运行期日志 | ❌ |

## 核心约束（读代码前必看）

按项目实际情况增删，每条都要能说出"违反了会怎样"。

1. **配置不硬编码**。凭据、端口、库名一律从 `config/app.env` 读。
2. **数据只允许 prd → dev 单向同步**，开发数据严禁进入生产库。
3. **测试只打 dev 环境**，禁止指向生产后端或生产 schema。
4. **AI 助手只做到 commit，push 由项目负责人本人执行**。见 [`推送与协作规范`](doc/doc/推送与协作规范.md)。
5. **规范与代码冲突时以 README / 规范为准**，改代码；规范过时就更新规范。

## 常用命令

| 命令 | 作用 |
|---|---|
| `bash opt/linux/dev_daily.sh start\|stop\|restart\|status\|log` | 开发环境开关、状态、日志检查 |
| `bash opt/linux/check.sh` | 提交 / 推送前的安全检查（`--history` 扫全部历史） |
| `bash opt/linux/pack.sh` | 打包已提交代码到 `dist/` |
| `bash opt/linux/push.sh` | 检查 → 测试 → 推送各远程（仅负责人） |
| `bash opt/linux/daily_pipeline.sh` | 每日：检查 → 测试 → 推送 → 打包（仅负责人） |
| `bash opt/linux/deploy.sh` | 发布到生产（按项目编写，仅负责人） |

脚本说明见 [`opt/README.md`](opt/README.md)。

## 文档索引

| 文档 | 管什么 |
|---|---|
| [`doc/README.md`](doc/README.md) | 文档体系：plan / log / todo / doc 分工与命名 |
| [`doc/doc/项目阅读说明.md`](doc/doc/项目阅读说明.md) | 接手项目的阅读顺序、调用链、修改前检查 |
| [`doc/doc/开发环境说明.md`](doc/doc/开发环境说明.md) | 本机环境、解释器、端口、配置位置 |
| [`doc/doc/提交规范.md`](doc/doc/提交规范.md) | commit 格式与拆分 |
| [`doc/doc/推送与协作规范.md`](doc/doc/推送与协作规范.md) | 谁能 push、AI 助手能做什么 |
| [`doc/doc/建表规范.md`](doc/doc/建表规范.md) | schema、表前缀、字段、迁移 |
| [`doc/doc/测试规范.md`](doc/doc/测试规范.md) | 测试分层、测试数据与清理 |
| [`doc/doc/部署规范.md`](doc/doc/部署规范.md) | dev → prd 发布流程与禁止操作 |
