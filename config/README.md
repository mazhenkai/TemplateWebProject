# config/

配置的唯一事实源。前端、后端、脚本都从这里读配置，代码内不硬编码凭据、端口、库名、域名。

## 放什么

| 文件 | 内容 | 是否 commit |
|---|---|---|
| `app.env` | 真实配置（含口令、Key、端口） | ❌ 已 gitignore |
| `app.env.example` | 模板：字段与 `app.env` 一致，值留空或写占位符 | ✅ |
| `*.example` | 其他配置的模板（如 `datasources.json.example`） | ✅ |
| `README.md` | 本文件 | ✅ |

`.gitignore` 默认忽略本目录下除 `README.md` 和 `*.example` 外的全部文件，新增的配置文件默认不会被提交。

## 硬性约束

1. **真实凭据只出现在 `app.env`**。代码、文档、日志、commit 信息、`*.example` 里都不能有。
2. **配置里引用密钥时只写变量名**，不写值：
   ```yaml
   api_key_env: XXX_API_KEY   # ✅ 只写环境变量名
   api_key: sk-xxxxxxxx       # ❌
   ```
3. **新增配置项时同步改 `app.env.example`**，并在 example 里写一行注释说明用途。
4. **环境靠 `APP_ENV` 区分**（`dev` / `prd`），不要为每个环境复制一份代码分支。
5. **误提交了密钥**：先去对应平台吊销并轮换，再清理仓库。git 历史里的东西删不干净，只删文件不算处理完。

## 前端读取配置

前端框架只会把带特定前缀的变量打进浏览器包（Next.js 是 `NEXT_PUBLIC_`，Vite 是 `VITE_`）。

- **带前缀 = 公开**。前缀变量里只能放公开信息（接口地址、站点名），绝不能放密钥。
- 前端需要的配置也写在 `app.env`，由框架配置文件指定读取位置，不在 `frontend/` 下另建 `.env`。
