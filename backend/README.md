# backend/

后端服务本体。技术栈不限，内部结构按框架惯例组织。复制模板后把下面的「目录职责」「分层依赖」改成实际内容。

## 放什么 / 不放什么

- ✅ 服务代码、依赖清单（`go.mod` / `requirements.txt` / `package.json`）、迁移 SQL（`migrations/`）
- ❌ 启动、重启、部署脚本 → `opt/`
- ❌ 一次性验证脚本 → `verify/`
- ❌ 测试数据、导出文件 → `data/`
- ❌ 真实配置 → `config/app.env`

## 目录职责（示例，按实际改）

| 路径 | 职责 |
|---|---|
| `cmd/` 或 `main.py` | 程序入口 |
| `handler/` / `api/` | 接收请求、参数校验、返回响应 |
| `service/` | 业务逻辑 |
| `repository/` / `dao/` | 数据库访问，**唯一写 SQL 的地方** |
| `model/` | 表结构映射 |
| `dto/` / `schema/` | 接口入参出参 |
| `middleware/` | 鉴权、日志、限流 |
| `migrations/` | 表结构变更 SQL，见 `migrations/README.md` |

## 硬性约束

1. **分层依赖单向**：`handler → service → repository`，禁止反向调用，禁止 handler 直接访问数据库。
2. **对外请求只走一个出口**。调用第三方 API 集中在一个 client 模块，便于统一超时、重试、日志脱敏。
3. **配置从 `config/app.env` 读**，启动时缺少必填项直接报错退出，不要静默使用默认值。
4. **日志脱敏**：`Authorization`、口令、token 一律写成 `***`。
5. **环境由 `APP_ENV` 决定**，代码里不出现写死的 `dev` / `prd` 判断分支之外的环境特殊逻辑。
6. **接口文档随代码生成**（如 Swagger），不手写易过期的接口清单。

## 命名

- 文件、目录：小写 + 下划线（Go / Python）或按框架惯例。
- 与规划文档对应的模块，在文件头注释里写清楚对应的 `doc/plan/` 文档名。
