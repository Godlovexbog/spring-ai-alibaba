# Spring AI Alibaba Admin — REST 接口清单

> 扫描范围：32 个 Controller，约 170+ 个接口端点
> 
> 前缀 `/console/v1` = Admin 管理后台，`/api` = 评估实验模块，`/api/v1` = 对外 OpenAPI

## 1. 认证与账户

| 方法 | 路径 | 说明 |
|------|------|------|
| POST | `/console/v1/auth/login` | 用户登录认证 |
| POST | `/console/v1/auth/refresh-token` | 刷新访问令牌 |
| POST | `/console/v1/auth/logout` | 用户登出 |
| GET | `/oauth2/login/github` | GitHub OAuth 登录 |
| GET | `/oauth2/callback/github` | GitHub OAuth 回调 |
| POST | `/console/v1/accounts/` | 创建账号 |
| PUT | `/console/v1/accounts/{accountId}` | 更新账号 |
| DELETE | `/console/v1/accounts/{accountId}` | 删除账号 |
| GET | `/console/v1/accounts/{accountId}` | 获取账号详情 |
| GET | `/console/v1/accounts/` | 分页查询账号列表 |
| PUT | `/console/v1/accounts/change-password` | 修改密码 |
| GET | `/console/v1/accounts/profile` | 获取当前用户信息 |

## 2. 工作空间

| 方法 | 路径 | 说明 |
|------|------|------|
| POST | `/console/v1/workspaces/` | 创建工作空间 |
| PUT | `/console/v1/workspaces/{workspaceId}` | 更新工作空间 |
| DELETE | `/console/v1/workspaces/{workspaceId}` | 删除工作空间 |
| GET | `/console/v1/workspaces/{workspaceId}` | 获取工作空间详情 |
| GET | `/console/v1/workspaces/` | 分页查询工作空间列表 |

## 3. 应用管理

| 方法 | 路径 | 说明 |
|------|------|------|
| POST | `/console/v1/apps/` | 创建应用 |
| PUT | `/console/v1/apps/{appId}` | 更新应用 |
| DELETE | `/console/v1/apps/{appId}` | 删除应用 |
| GET | `/console/v1/apps/{appId}` | 获取应用详情 |
| GET | `/console/v1/apps/` | 分页查询应用列表 |
| POST | `/console/v1/apps/{appId}/publish` | 发布应用 |
| GET | `/console/v1/apps/{appId}/versions` | 分页查询应用版本 |
| GET | `/console/v1/apps/{appId}/versions/{version}` | 获取指定版本详情 |
| POST | `/console/v1/apps/{appId}/copy` | 复制应用 |
| POST | `/console/v1/apps/chat/completions` | 聊天补全（流式/同步） |

## 4. 工作流调试与执行

| 方法 | 路径 | 说明 |
|------|------|------|
| POST | `/console/v1/apps/workflow/debug/run-task` | 调试模式执行工作流 |
| POST | `/console/v1/apps/workflow/debug/get-task-process` | 获取调试任务状态 |
| POST | `/console/v1/apps/workflow/debug/init` | 初始化调试参数 |
| POST | `/console/v1/apps/workflow/debug/resume-task` | 恢复暂停的调试任务 |
| POST | `/console/v1/apps/workflow/debug/part-graph/run-task` | 部分图调试执行 |
| POST | `/console/v1/apps/workflow/debug/part-graph/stop-task` | 停止部分图调试 |
| POST | `/console/v1/apps/workflow/{appId}/run_stream` | 流式执行工作流（SSE） |

## 5. 对外 OpenAPI（Chat / Workflow）

| 方法 | 路径 | 说明 |
|------|------|------|
| POST | `/api/v1/apps/chat/completions` | 聊天补全（对外接口） |
| POST | `/api/v1/apps/workflow/completions` | 工作流补全（对外接口） |
| POST | `/api/v1/apps/workflow/async-completions` | 异步执行工作流 |
| POST | `/api/v1/apps/workflow/stop-completions` | 停止工作流执行 |
| POST | `/api/v1/apps/workflow/async-results` | 获取异步执行结果 |

## 6. 模型与提供商

| 方法 | 路径 | 说明 |
|------|------|------|
| POST | `/console/v1/providers/` | 添加模型供应商 |
| PUT | `/console/v1/providers/{provider}` | 更新供应商 |
| DELETE | `/console/v1/providers/{provider}` | 删除供应商 |
| GET | `/console/v1/providers/` | 查询供应商列表 |
| GET | `/console/v1/providers/{provider}` | 获取供应商详情 |
| POST | `/console/v1/providers/{provider}/models` | 添加模型 |
| PUT | `/console/v1/providers/{provider}/models/{modelId}` | 更新模型 |
| DELETE | `/console/v1/providers/{provider}/models/{modelId}` | 删除模型 |
| GET | `/console/v1/providers/{provider}/models` | 查询供应商模型 |
| GET | `/console/v1/providers/{provider}/models/{modelId}` | 获取模型详情 |
| GET | `/console/v1/providers/{provider}/models/{modelId}/parameter_rules` | 模型参数规则 |
| GET | `/console/v1/providers/protocols` | 支持的协议列表 |
| GET | `/console/v1/models/{modelType}/selector` | 模型选择器列表 |
| GET | `/console/v1/models/enabled` | 已启用的模型列表 |

## 7. 知识库

| 方法 | 路径 | 说明 |
|------|------|------|
| POST | `/console/v1/knowledge-bases/` | 创建知识库 |
| PUT | `/console/v1/knowledge-bases/{kbId}` | 更新知识库 |
| DELETE | `/console/v1/knowledge-bases/{kbId}` | 删除知识库 |
| GET | `/console/v1/knowledge-bases/{kbId}` | 获取知识库详情 |
| GET | `/console/v1/knowledge-bases/` | 分页查询知识库 |
| POST | `/console/v1/knowledge-bases/query-by-codes` | 批量查询知识库 |
| POST | `/console/v1/knowledge-bases/retrieve` | 检索知识库文档块 |

## 8. 文档管理

| 方法 | 路径 | 说明 |
|------|------|------|
| POST | `/console/v1/knowledge-bases/{kbId}/documents` | 创建文档 |
| PUT | `/console/v1/knowledge-bases/{kbId}/documents/{docId}` | 更新文档 |
| DELETE | `/console/v1/knowledge-bases/{kbId}/documents/{docId}` | 删除文档 |
| DELETE | `/console/v1/knowledge-bases/{kbId}/documents/batch-delete` | 批量删除文档 |
| GET | `/console/v1/knowledge-bases/{kbId}/documents/{docId}` | 获取文档详情 |
| GET | `/console/v1/knowledge-bases/{kbId}/documents` | 分页查询文档 |
| PUT | `/console/v1/knowledge-bases/{kbId}/documents/{docId}/re-index` | 重新索引文档 |

## 9. 文档块管理

| 方法 | 路径 | 说明 |
|------|------|------|
| POST | `/console/v1/documents/{docId}/chunks` | 创建文档块 |
| PUT | `/console/v1/documents/{docId}/chunks/{chunkId}` | 更新文档块 |
| DELETE | `/console/v1/documents/{docId}/chunks/{chunkId}` | 删除文档块 |
| DELETE | `/console/v1/documents/{docId}/chunks/batch-delete` | 批量删除文档块 |
| GET | `/console/v1/documents/{docId}/chunks` | 分页查询文档块 |
| POST | `/console/v1/documents/{docId}/chunks/preview` | 预览文档块 |
| PUT | `/console/v1/documents/{docId}/chunks/update-status` | 批量更新启用状态 |

## 10. 插件与工具

| 方法 | 路径 | 说明 |
|------|------|------|
| POST | `/console/v1/plugins` | 创建插件 |
| PUT | `/console/v1/plugins/{pluginId}` | 更新插件 |
| DELETE | `/console/v1/plugins/{pluginId}` | 删除插件 |
| GET | `/console/v1/plugins/{pluginId}` | 获取插件详情 |
| GET | `/console/v1/plugins` | 分页查询插件 |
| POST | `/console/v1/plugins/{pluginId}/tools` | 为插件创建工具 |
| PUT | `/console/v1/plugins/{pluginId}/tools/{toolId}` | 更新工具 |
| DELETE | `/console/v1/plugins/{pluginId}/tools/{toolId}` | 删除工具 |
| GET | `/console/v1/plugins/{pluginId}/tools/{toolId}` | 获取工具详情 |
| GET | `/console/v1/plugins/{pluginId}/tools` | 分页查询工具 |
| POST | `/console/v1/tools/{toolId}/enable` | 启用工具 |
| POST | `/console/v1/tools/{toolId}/disable` | 禁用工具 |
| POST | `/console/v1/plugins/{pluginId}/tools/{toolId}/test` | 测试工具 |
| POST | `/console/v1/plugins/{pluginId}/tools/{toolId}/publish` | 发布工具 |
| POST | `/console/v1/tools/query-by-ids` | 批量查询工具 |

## 11. MCP 服务器

| 方法 | 路径 | 说明 |
|------|------|------|
| POST | `/console/v1/mcp-servers/` | 创建 MCP 服务器 |
| PUT | `/console/v1/mcp-servers/` | 更新 MCP 服务器 |
| DELETE | `/console/v1/mcp-servers/{serverCode}` | 删除 MCP 服务器 |
| GET | `/console/v1/mcp-servers/{serverCode}` | 获取 MCP 服务器详情 |
| GET | `/console/v1/mcp-servers/` | 分页查询 MCP 服务器 |
| POST | `/console/v1/mcp-servers/query-by-codes` | 批量查询 MCP 服务器 |
| POST | `/console/v1/mcp-servers/debug-tools` | 调试 MCP 工具 |

## 12. Agent Schema

| 方法 | 路径 | 说明 |
|------|------|------|
| POST | `/console/v1/agent-schemas/` | 创建 Agent Schema |
| PUT | `/console/v1/agent-schemas/{id}` | 更新 Agent Schema |
| DELETE | `/console/v1/agent-schemas/{id}` | 删除 Agent Schema |
| GET | `/console/v1/agent-schemas/{id}` | 获取 Agent Schema 详情 |
| GET | `/console/v1/agent-schemas/` | 获取工作空间所有 Schema |
| GET | `/console/v1/agent-schemas/page` | 分页查询 Agent Schema |
| GET | `/console/v1/agent-schemas/search` | 按名称搜索 Schema |
| PATCH | `/console/v1/agent-schemas/{id}/enabled` | 启用/禁用 Schema |

## 13. 应用组件

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/console/v1/component-servers/` | 分页查询组件 |
| GET | `/console/v1/component-servers/app-publishable` | 可发布为组件的应用 |
| POST | `/console/v1/component-servers/` | 发布新组件 |
| PUT | `/console/v1/component-servers/{code}` | 更新组件 |
| DELETE | `/console/v1/component-servers/{code}` | 删除组件 |
| GET | `/console/v1/component-servers/{code}/detail-by-code` | 按编码获取组件详情 |
| GET | `/console/v1/component-servers/{appId}/detail-by-appid` | 按应用ID获取组件详情 |
| GET | `/console/v1/component-servers/{code}/query-refer` | 查询引用链 |
| GET | `/console/v1/component-servers/{appId}/query-config` | 查询组件配置 |
| POST | `/console/v1/component-servers/query-by-codes` | 批量查询组件 |
| GET | `/console/v1/component-servers/{code}/query-schema` | 获取组件 Schema |
| POST | `/console/v1/component-servers/schema-by-codes` | 批量获取 Schema |

## 14. API 密钥

| 方法 | 路径 | 说明 |
|------|------|------|
| POST | `/console/v1/api-keys/` | 创建 API 密钥 |
| PUT | `/console/v1/api-keys/{id}` | 更新 API 密钥 |
| DELETE | `/console/v1/api-keys/{id}` | 删除 API 密钥 |
| GET | `/console/v1/api-keys/{id}` | 获取 API 密钥详情 |
| GET | `/console/v1/api-keys/` | 分页查询 API 密钥 |

## 15. 文件管理

| 方法 | 路径 | 说明 |
|------|------|------|
| POST | `/console/v1/files/upload` | 上传多个文件 |
| GET | `/console/v1/files/download` | 下载文件 |
| POST | `/console/v1/files/upload-policies` | 获取 OSS 上传策略 |
| GET | `/console/v1/files/get-preview-url` | 获取文件预览 URL |

## 16. 系统

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/console/v1/system/global-config` | 获取系统全局配置 |
| GET | `/console/v1/system/health` | 健康检查 |

## 17. Prompt 工程

| 方法 | 路径 | 说明 |
|------|------|------|
| POST | `/api/prompt` | 创建 Prompt |
| GET | `/api/prompt` | 获取 Prompt 详情 |
| GET | `/api/prompts` | 分页查询 Prompt |
| PUT | `/api/prompt` | 更新 Prompt |
| DELETE | `/api/prompt` | 删除 Prompt |
| POST | `/api/prompt/version` | 创建 Prompt 版本 |
| GET | `/api/prompt/version` | 获取版本详情 |
| GET | `/api/prompt/versions` | 分页查询版本 |
| GET | `/api/prompt/template` | 获取 Prompt 模板 |
| GET | `/api/prompt/templates` | 分页查询模板 |
| POST | `/api/prompt/run` | 运行 Prompt 调试 |
| GET | `/api/prompt/session` | 获取会话信息 |
| DELETE | `/api/prompt/session` | 删除会话 |

## 18. 测评集 (Dataset)

| 方法 | 路径 | 说明 |
|------|------|------|
| POST | `/api/dataset/dataset` | 创建测评集 |
| POST | `/api/dataset/datasetVersion` | 创建测评集版本 |
| GET | `/api/dataset/datasets` | 分页查询测评集 |
| GET | `/api/dataset/dataset` | 获取测评集详情 |
| PUT | `/api/dataset/dataset` | 更新测评集 |
| DELETE | `/api/dataset/dataset` | 删除测评集 |
| POST | `/api/dataset/dataItem` | 创建数据项 |
| GET | `/api/dataset/dataItems` | 分页查询数据项 |
| GET | `/api/dataset/dataItem` | 获取数据项详情 |
| PUT | `/api/dataset/dataItem` | 更新数据项 |
| DELETE | `/api/dataset/dataItem` | 删除数据项 |
| GET | `/api/dataset/datasetVersions` | 分页查询版本 |
| PUT | `/api/dataset/datasetVersion` | 更新版本 |
| GET | `/api/dataset/experiments` | 关联实验列表 |
| POST | `/api/dataset/dataItemFromTrace` | 从 Trace 创建数据项 |

## 19. 评估器 (Evaluator)

| 方法 | 路径 | 说明 |
|------|------|------|
| POST | `/api/evaluator/evaluator` | 创建评估器 |
| POST | `/api/evaluator/evaluatorVersion` | 创建评估器版本 |
| GET | `/api/evaluator/evaluators` | 分页查询评估器 |
| GET | `/api/evaluator/evaluator` | 获取评估器详情 |
| GET | `/api/evaluator/evaluatorVersions` | 分页查询版本 |
| PUT | `/api/evaluator/evaluator` | 更新评估器 |
| DELETE | `/api/evaluator/evaluator` | 删除评估器 |
| POST | `/api/evaluator/debug` | 调试评估器 |
| GET | `/api/evaluator/templates` | 分页查询评估模板 |
| GET | `/api/evaluator/template` | 获取模板详情 |
| GET | `/api/evaluator/experiments` | 关联实验列表 |

## 20. 实验 (Experiment)

| 方法 | 路径 | 说明 |
|------|------|------|
| POST | `/api/experiment` | 创建实验 |
| GET | `/api/experiments` | 分页查询实验 |
| GET | `/api/experiment` | 获取实验详情 |
| GET | `/api/experiment/results` | 获取实验概览结果 |
| GET | `/api/experiment/result` | 获取实验详细结果 |
| PUT | `/api/experiment/stop` | 停止实验 |
| DELETE | `/api/experiment` | 删除实验 |
| PUT | `/api/experiment/restart` | 重启实验 |

## 21. 可观测性

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/api/observability/traces` | Trace 列表 |
| GET | `/api/observability/traces/{traceId}` | Trace 详情 |
| GET | `/api/observability/services` | 服务列表 |
| GET | `/api/observability/overview` | 可观测性概览 |

## 22. 模型配置（评估模块）

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/api/model/supported` | 支持的模型提供商 |
| GET | `/api/models` | 分页查询模型配置 |
| GET | `/api/model` | 获取模型配置详情 |
| GET | `/api/models/enabled` | 已启用的模型配置 |

## 23. Studio 图形化 API

| 方法 | 路径 | 说明 |
|------|------|------|
| (REST) | `/graph-studio/api/app/**` | 图形化 Studio 应用管理 |
| (REST) | `/graph-studio/api/dsl/**` | 图形化 Studio DSL 管理 |
| (REST) | `/graph-studio/api/run/**` | 图形化 Studio 运行器 |

---

## 接口分组统计

| 分组 | 数量 | 前缀 |
|------|------|------|
| 认证与账户 | 12 | `/console/v1/auth`, `/console/v1/accounts`, `/oauth2` |
| 工作空间 | 5 | `/console/v1/workspaces` |
| 应用管理 | 9 | `/console/v1/apps` |
| 工作流调试 | 7 | `/console/v1/apps/workflow` |
| 对外 OpenAPI | 5 | `/api/v1/apps` |
| 模型与提供商 | 14 | `/console/v1/providers`, `/console/v1/models` |
| 知识库 | 7 | `/console/v1/knowledge-bases` |
| 文档管理 | 7 | `/console/v1/knowledge-bases/{kbId}/documents` |
| 文档块管理 | 7 | `/console/v1/documents/{docId}/chunks` |
| 插件与工具 | 15 | `/console/v1/plugins`, `/console/v1/tools` |
| MCP 服务器 | 7 | `/console/v1/mcp-servers` |
| Agent Schema | 8 | `/console/v1/agent-schemas` |
| 应用组件 | 12 | `/console/v1/component-servers` |
| API 密钥 | 5 | `/console/v1/api-keys` |
| 文件管理 | 4 | `/console/v1/files` |
| 系统 | 2 | `/console/v1/system` |
| Prompt 工程 | 13 | `/api/prompt` |
| 测评集 | 15 | `/api/dataset` |
| 评估器 | 11 | `/api/evaluator` |
| 实验 | 8 | `/api/experiment` |
| 可观测性 | 4 | `/api/observability` |
| 模型配置 | 4 | `/api/model` |
| Studio 图形化 | 3 组 | `/graph-studio/api/**` |
| **合计** | **~170+** | |
