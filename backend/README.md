# Backend/

后端服务代码。技术栈不限（Python/FastAPI、Node、Java 等均可），按所选框架惯例组织。

约定：

- 只放后端服务本体，脚本、一次性工具不放这里（见 `Verify/`、`opt/`）。
- 服务启动/重启脚本统一放 `opt/windows/`、`opt/linux/`，不放本目录。
- 配置不硬编码，统一从 `Config/app.env` 读取（入库的只能是 `app.env.example` 模板）。
- 依赖清单入库（如 `requirements.txt`、`package.json`、`pom.xml`）。
