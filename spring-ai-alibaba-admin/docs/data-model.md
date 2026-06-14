# Spring AI Alibaba Admin — 核心数据模型

> 三边对照：Java Entity + 建表 DDL + DTO，扫描 28 个实体、2 个 SQL schema。
>
> ⚠️ **存储说明**：大部分实体为 MySQL 持久化表（MyBatis Plus），`DocumentChunk` 存储在 Elasticsearch 中，`ChatSession` 为内存存储（ConcurrentHashMap，30分钟过期，注释建议生产用 Redis）。

## 一、Builder 模块（应用构建）

### 1. account（账户）

| 字段 | 类型 | 约束 | 说明 |
|------|------|------|------|
| **id** | BIGINT | **PK** AUTO_INCREMENT | 主键 |
| account_id | VARCHAR | | 账户业务ID |
| username | VARCHAR | | 用户名 |
| email | VARCHAR | | 邮箱 |
| mobile | VARCHAR | | 手机号 |
| password | VARCHAR | | 密码（Argon2 哈希） |
| nickname | VARCHAR | | 昵称 |
| icon | VARCHAR | | 头像 URL |
| **status** | INT | `枚举` | AccountStatus: 0=DELETED, 1=NORMAL, 2=DISABLED |
| **type** | VARCHAR | `枚举` | AccountType: "admin", "user" |
| gmt_create / gmt_modified | DATETIME | | 审计时间 |
| gmt_last_login | DATETIME | | 最后登录时间 |
| creator / modifier | VARCHAR | | 审计人 |

### 2. workspace（工作空间）

| 字段 | 类型 | 约束 | 说明 |
|------|------|------|------|
| **id** | BIGINT | **PK** AUTO_INCREMENT | 主键 |
| workspace_id | VARCHAR | | 工作空间业务ID |
| **account_id** | VARCHAR | **FK → account** | 所属账户 |
| name | VARCHAR | | 空间名称 |
| description | VARCHAR | | 空间描述 |
| **status** | INT | `枚举` | CommonStatus: 0=DELETED, 1=NORMAL |
| config | TEXT | | 配置 (JSON) |
| gmt_create / gmt_modified | DATETIME | | 审计时间 |

### 3. application（应用）

| 字段 | 类型 | 约束 | 说明 |
|------|------|------|------|
| **id** | BIGINT | **PK** AUTO_INCREMENT | 主键 |
| app_id | VARCHAR | | 应用业务ID |
| **workspace_id** | VARCHAR | **FK → workspace** | 所属工作空间 |
| name | VARCHAR | | 应用名称 |
| description | TEXT | | 应用描述 |
| icon | VARCHAR | | 图标 |
| **type** | VARCHAR | `枚举` | AppType: "basic"\|"workflow" |
| **status** | INT | `枚举` | AppStatus: 0=DELETED, 1=DRAFT, 2=PUBLISHED, 3=PUBLISHED_EDITING |
| source | VARCHAR | | 来源 |
| gmt_create / gmt_modified | DATETIME | | 审计时间 |

### 4. application_version（应用版本）

| 字段 | 类型 | 约束 | 说明 |
|------|------|------|------|
| **id** | BIGINT | **PK** AUTO_INCREMENT | 主键 |
| **app_id** | VARCHAR | **FK → application** | 所属应用 |
| workspace_id | VARCHAR | FK → workspace | 冗余工作空间 |
| version | VARCHAR | UNIQUE(app_id, version) | 版本号 |
| **status** | INT | `枚举` | AppStatus |
| config | TEXT | | 版本配置 (JSON) |
| description | TEXT | | 版本说明 |
| gmt_create / gmt_modified | DATETIME | | 审计时间 |

### 5. agent_schema（Agent 定义）

| 字段 | 类型 | 约束 | 说明 |
|------|------|------|------|
| **id** | BIGINT | **PK** AUTO_INCREMENT | 主键 |
| agent_id | VARCHAR | UNIQUE | Agent 业务ID |
| **workspace_id** | VARCHAR | **FK → workspace** | 所属工作空间 |
| name | VARCHAR | | Agent 名称 |
| description | VARCHAR | | 描述 |
| **type** | VARCHAR | `枚举` | AgentType: ReactAgent\|ParallelAgent\|SequentialAgent\|LLMRoutingAgent\|LoopAgent |
| **status** | VARCHAR | `枚举` | AgentStatus: active\|inactive\|configuring\|error |
| instruction | TEXT | | 系统指令 |
| input_keys / output_key | VARCHAR | | 输入/输出键 |
| sub_agents | TEXT | | 子 Agent 配置 (JSON) |
| yaml_schema | TEXT | | YAML Schema |
| enabled | BOOLEAN | | 是否启用 |
| gmt_create / gmt_modified | DATETIME | | 审计时间 |

### 6. knowledge_base（知识库）

| 字段 | 类型 | 约束 | 说明 |
|------|------|------|------|
| **id** | BIGINT | **PK** AUTO_INCREMENT | 主键 |
| kb_id | VARCHAR | UNIQUE | 知识库业务ID |
| **workspace_id** | VARCHAR | **FK → workspace** | 所属工作空间 |
| name | VARCHAR | | 知识库名称 |
| description | TEXT | | 描述 |
| **type** | VARCHAR | `枚举` | KnowledgeBaseType: "unstructured"\|"structured" |
| **status** | INT | `枚举` | CommonStatus |
| process_config | TEXT | | 文档处理配置 (JSON) |
| index_config | TEXT | | 索引配置 (JSON) |
| search_config | TEXT | | 检索配置 (JSON) |
| total_docs | BIGINT | | 文档总数 |
| gmt_create / gmt_modified | DATETIME | | 审计时间 |

### 7. document（文档）

| 字段 | 类型 | 约束 | 说明 |
|------|------|------|------|
| **id** | BIGINT | **PK** AUTO_INCREMENT | 主键 |
| doc_id | VARCHAR | UNIQUE | 文档业务ID |
| **kb_id** | VARCHAR | **FK → knowledge_base** | 所属知识库 |
| workspace_id | VARCHAR | FK → workspace | 冗余工作空间 |
| name | VARCHAR | | 文档名 |
| **type** | VARCHAR | `枚举` | DocumentType: "file"\|"url"\|"oss" |
| **status** | INT | `枚举` | CommonStatus |
| **index_status** | INT | `枚举` | DocumentIndexStatus: 1=UPLOADED, 2=PROCESSING, 3=PROCESSED, 4=FAILED |
| format | VARCHAR | | 文档格式 (pdf/txt/md 等) |
| size | BIGINT | | 文件大小 (bytes) |
| metadata | TEXT | | 元数据 (JSON) |
| path / parsed_path | VARCHAR | | 原始路径 / 解析后路径 |
| process_config | TEXT | | 处理配置 (JSON) |
| enabled | BOOLEAN | | 是否启用 |
| error | TEXT | | 错误信息 |
| gmt_create / gmt_modified | DATETIME | | 审计时间 |

### 7b. DocumentChunk（文档块 — ES 存储 ⚠️ 非 MySQL）

> **存储引擎**：Elasticsearch，非 MySQL 表。由 `DocumentChunkConverter` 负责 ES 写入，`DocumentChunkController` 提供 CRUD 接口。
> 对应 API：`/documents/{docId}/chunks`（7 个接口：创建、更新、删除、批量删除、分页查询、预览、批量更新状态）

| 字段 | 类型 | 约束 | 说明 |
|------|------|------|------|
| **chunk_id** | String | **PK**（ES doc id） | 文档块唯一标识 |
| doc_id | String | FK → document | 所属文档 |
| doc_name | String | | 文档名称 |
| title | String | | 块标题 |
| text | String | | 块内容文本 |
| score | Double | | 相关性得分 |
| page_number | Integer | | 原文档页码 |
| enabled | Boolean | | 是否启用 |
| workspace_id | String | FK → workspace | 所属工作空间 |

> **关联枚举**：`ChunkType` — 分块策略：LENGTH（按字符长度）、PAGE（按页）、TITLE（按标题）、REGEX（正则）

### 8. plugin（插件）

| 字段 | 类型 | 约束 | 说明 |
|------|------|------|------|
| **id** | BIGINT | **PK** AUTO_INCREMENT | 主键 |
| plugin_id | VARCHAR | UNIQUE | 插件业务ID |
| **workspace_id** | VARCHAR | **FK → workspace** | 所属工作空间 |
| name | VARCHAR | | 插件名称 |
| description | VARCHAR | | 描述 |
| **type** | VARCHAR | `枚举` | PluginType: "official"\|"custom" |
| **status** | INT | `枚举` | PluginStatus: 0=DELETED, 1=NORMAL |
| config | TEXT | | 插件配置 (JSON) |
| source | VARCHAR | | 来源 |
| gmt_create / gmt_modified | DATETIME | | 审计时间 |

### 9. tool（工具）

| 字段 | 类型 | 约束 | 说明 |
|------|------|------|------|
| **id** | BIGINT | **PK** AUTO_INCREMENT | 主键 |
| tool_id | VARCHAR | UNIQUE | 工具业务ID |
| **plugin_id** | VARCHAR | **FK → plugin** | 所属插件 |
| workspace_id | VARCHAR | FK → workspace | 冗余工作空间 |
| name | VARCHAR | | 工具名称 |
| description | TEXT | | 描述 |
| **status** | INT | `枚举` | ToolStatus: 0=DELETED, 1=DRAFT, 2=PUBLISHED, 3=PUBLISHED_EDITING |
| **test_status** | INT | `枚举` | ToolTestStatus: 1=NOT_TEST, 2=PASSED, 3=FAILED |
| enabled | BOOLEAN | | 启用状态 |
| config | TEXT | | 工具配置 (JSON) |
| api_schema | TEXT | | API Schema (JSON) |
| gmt_create / gmt_modified | DATETIME | | 审计时间 |

### 10. mcp_server（MCP 服务器）

| 字段 | 类型 | 约束 | 说明 |
|------|------|------|------|
| **id** | BIGINT | **PK** AUTO_INCREMENT | 主键 |
| server_code | VARCHAR | UNIQUE | 服务器编码 |
| **workspace_id** | VARCHAR | **FK → workspace** | 所属工作空间 |
| account_id | VARCHAR | FK → account | 所属账户 |
| name | VARCHAR | | 服务器名称 |
| description | TEXT | | 描述 |
| type | VARCHAR | | 服务器类型 |
| deploy_env | VARCHAR | | 部署环境 |
| deploy_config | TEXT | | 部署配置 (JSON) |
| detail_config | TEXT | | 详细配置 (JSON) |
| host | VARCHAR | | 主机地址 |
| install_type | VARCHAR | | 安装类型 |
| source | VARCHAR | | 来源 |
| biz_type | VARCHAR | | 业务类型 |
| status | INT | | 状态 |
| gmt_create / gmt_modified | DATETIME | | 审计时间 |

### 11. provider（模型供应商）

| 字段 | 类型 | 约束 | 说明 |
|------|------|------|------|
| **id** | BIGINT | **PK** AUTO_INCREMENT | 主键 |
| provider | VARCHAR | UNIQUE | 供应商标识 (dashscope/openai/deepseek) |
| **workspace_id** | VARCHAR | **FK → workspace** | 所属工作空间 |
| name | VARCHAR | | 显示名称 |
| description | VARCHAR | | 描述 |
| icon | VARCHAR | | 图标 |
| protocol | VARCHAR | | 协议 (默认 "openai") |
| credential | TEXT | | 认证信息 (加密) |
| supported_model_types | VARCHAR | | 支持的模型类型 |
| enable | BOOLEAN | | 启用 |
| source | VARCHAR | | 来源 |
| gmt_create / gmt_modified | DATETIME | | 审计时间 |

### 12. model（模型）

| 字段 | 类型 | 约束 | 说明 |
|------|------|------|------|
| **id** | BIGINT | **PK** AUTO_INCREMENT | 主键 |
| model_id | VARCHAR | UNIQUE | 模型业务ID |
| **provider** | VARCHAR | **FK → provider** | 所属供应商 |
| workspace_id | VARCHAR | FK → workspace | 冗余工作空间 |
| name | VARCHAR | | 显示名称 |
| type | VARCHAR | | 模型类型 (chat/image/embedding) |
| mode | VARCHAR | | 模式 |
| tags | VARCHAR | | 标签 |
| icon | VARCHAR | | 图标 |
| enable | BOOLEAN | | 启用 |
| source | VARCHAR | | 来源 |
| gmt_create / gmt_modified | DATETIME | | 审计时间 |

### 13. api_key（API 密钥）

| 字段 | 类型 | 约束 | 说明 |
|------|------|------|------|
| **id** | BIGINT | **PK** AUTO_INCREMENT | 主键 |
| api_key | VARCHAR | UNIQUE | API Key 值 |
| account_id | VARCHAR | FK → account | 所属账户 |
| description | VARCHAR | | 描述 |
| **status** | INT | `枚举` | CommonStatus |
| gmt_create / gmt_modified | DATETIME | | 审计时间 |

### 14. application_component（应用组件）

| 字段 | 类型 | 约束 | 说明 |
|------|------|------|------|
| **id** | BIGINT | **PK** AUTO_INCREMENT | 主键 |
| code | VARCHAR | UNIQUE | 组件编码 |
| app_id | VARCHAR | FK → application | 源应用 |
| workspace_id | VARCHAR | FK → workspace | 所属工作空间 |
| name | VARCHAR | | 组件名称 |
| type | VARCHAR | | 组件类型 |
| description | VARCHAR | | 描述 |
| config | TEXT | | 组件配置 (JSON) |
| status | INT | | 状态 |
| need_update | INT | | 是否需要更新 |
| gmt_create / gmt_modified | DATETIME | | 审计时间 |

### 15. reference（多态引用）

| 字段 | 类型 | 约束 | 说明 |
|------|------|------|------|
| **id** | BIGINT | **PK** AUTO_INCREMENT | 主键 |
| main_code | VARCHAR | | 主体编码 |
| main_type | INT | | 主体类型 |
| refer_code | VARCHAR | | 被引用编码 |
| refer_type | INT | | 被引用类型 |
| workspace_id | VARCHAR | FK → workspace | 所属工作空间 |
| gmt_create / gmt_modified | DATETIME | | 审计时间 |

> reference 实现多态关联：App 引用 Agent、App 引用 KnowledgeBase 等，通过 main_type/refer_type 区分类型。

---

## 二、Evaluation 模块（评估实验）

### 16. dataset（测评集）

| 字段 | 类型 | 约束 | 说明 |
|------|------|------|------|
| **id** | BIGINT | **PK** AUTO_INCREMENT (起始 10000) | 主键 |
| name | VARCHAR(255) | NOT NULL | 测评集名称 |
| description | TEXT | | 描述 |
| columns_config | LONGTEXT | | 列配置 (JSON) |
| **deleted** | TINYINT | DEFAULT 0 | 逻辑删除: 0=未删除, 1=已删除 |
| create_time / update_time | DATETIME | | 审计时间 |

### 17. dataset_version（测评集版本）

| 字段 | 类型 | 约束 | 说明 |
|------|------|------|------|
| **id** | BIGINT | **PK** AUTO_INCREMENT | 主键 |
| **dataset_id** | BIGINT | **FK → dataset** CASCADE | 测评集ID |
| version | VARCHAR(32) | UNIQUE(dataset_id, version) | 版本号 |
| description | TEXT | | 版本描述 |
| data_count | INT | DEFAULT 0 | 数据量 |
| **status** | VARCHAR(32) | `枚举` DEFAULT 'DRAFT' | DRAFT / PUBLISHED / ARCHIVED |
| experiments | TEXT | | 实验集合 (JSON) |
| dataset_items | TEXT | | 数据项快照 (JSON) |
| create_time / update_time | DATETIME | | 审计时间 |

### 18. dataset_item（测评数据项）

| 字段 | 类型 | 约束 | 说明 |
|------|------|------|------|
| **id** | BIGINT | **PK** AUTO_INCREMENT | 主键 |
| **dataset_id** | BIGINT | **FK → dataset** CASCADE | 测评集ID |
| columns_config | LONGTEXT | | 列配置 (JSON) |
| data_content | LONGTEXT | NOT NULL | 数据内容 (JSON) |
| **deleted** | TINYINT | DEFAULT 0 | 逻辑删除（⚠️ DDL有，Java实体缺失） |
| create_time / update_time | DATETIME | | 审计时间 |

### 19. evaluator（评估器）

| 字段 | 类型 | 约束 | 说明 |
|------|------|------|------|
| **id** | BIGINT | **PK** AUTO_INCREMENT | 主键 |
| name | VARCHAR(255) | NOT NULL | 评估器名称 |
| description | TEXT | | 描述 |
| **deleted** | TINYINT | DEFAULT 0 | 逻辑删除 |
| create_time / update_time | DATETIME | | 审计时间 |

### 20. evaluator_version（评估器版本）

| 字段 | 类型 | 约束 | 说明 |
|------|------|------|------|
| **id** | BIGINT | **PK** AUTO_INCREMENT | 主键 |
| **evaluator_id** | BIGINT | **FK → evaluator** CASCADE | 评估器ID |
| version | VARCHAR(32) | UNIQUE(evaluator_id, version) | 版本号 |
| description | TEXT | | 版本描述 |
| model_config | TEXT | NOT NULL | 模型配置 (JSON) |
| prompt | LONGTEXT | | Prompt 配置 (JSON) |
| variables | LONGTEXT | | 变量参数 (JSON) |
| **status** | VARCHAR(32) | `枚举` | DRAFT / PUBLISHED / ARCHIVED |
| experiments | TEXT | | 实验集合 (JSON) |
| create_time / update_time | DATETIME | | 审计时间 |

### 21. evaluator_template（评估器模板）

| 字段 | 类型 | 约束 | 说明 |
|------|------|------|------|
| **id** | BIGINT | **PK** AUTO_INCREMENT | 主键 |
| evaluator_template_key | VARCHAR(255) | UNIQUE | 模板 Key |
| template_desc | VARCHAR(255) | INDEX | 模板描述 |
| template | LONGTEXT | | 模板内容 |
| variables | LONGTEXT | | 变量参数 (JSON) |
| model_config | LONGTEXT | | 推荐模型参数 |

### 22. experiment（实验）

| 字段 | 类型 | 约束 | 说明 |
|------|------|------|------|
| **id** | BIGINT | **PK** AUTO_INCREMENT | 主键 |
| name | VARCHAR(255) | NOT NULL | 实验名称 |
| description | TEXT | | 描述 |
| **dataset_id** | BIGINT | NOT NULL, INDEX | 测评集ID |
| **dataset_version_id** | BIGINT | NOT NULL, INDEX | 版本ID |
| dataset_version | VARCHAR(32) | NOT NULL | 版本号 (冗余) |
| evaluation_object_config | LONGTEXT | | 评测对象配置 (JSON) |
| evaluator_config | TEXT | NOT NULL | 评估器配置 (JSON) |
| **status** | VARCHAR(32) | `枚举` DEFAULT 'DRAFT', INDEX | ExperimentStatus: DRAFT\|RUNNING\|COMPLETED\|FAILED\|STOPPED |
| progress | INT | DEFAULT 0 | 进度 (0-100) |
| complete_time | DATETIME | | 完成时间 |
| create_time / update_time | DATETIME | INDEX(create_time) | 审计时间 |

### 23. experiment_result（实验结果）

| 字段 | 类型 | 约束 | 说明 |
|------|------|------|------|
| **id** | BIGINT | **PK** AUTO_INCREMENT | 主键 |
| **experiment_id** | BIGINT | NOT NULL, INDEX | 实验ID |
| **evaluator_version_id** | BIGINT | NOT NULL, INDEX | 评估器版本ID |
| input | LONGTEXT | NOT NULL | 输入内容 |
| actual_output | LONGTEXT | NOT NULL | 实际输出 |
| reference_output | LONGTEXT | | 参考输出 |
| score | DECIMAL(3,2) | | 评分 (0.00-1.00) |
| reason | TEXT | | 评分依据 |
| evaluation_time | DATETIME | | 评估时间 |
| create_time / update_time | DATETIME | INDEX(create_time) | 审计时间 |

### 24. prompt（Prompt 定义）

| 字段 | 类型 | 约束 | 说明 |
|------|------|------|------|
| **id** | BIGINT | **PK** AUTO_INCREMENT | 主键 |
| prompt_key | VARCHAR(255) | UNIQUE | Prompt Key |
| prompt_desc | VARCHAR(255) | | 描述 |
| latest_version | VARCHAR(32) | | 最新版本号 |
| tags | VARCHAR(255) | | 标签 (逗号分隔) |
| create_time / update_time | DATETIME(3) | INDEX(create_time) | 审计时间 |

### 25. prompt_version（Prompt 版本）

| 字段 | 类型 | 约束 | 说明 |
|------|------|------|------|
| **id** | BIGINT | **PK** AUTO_INCREMENT | 主键 |
| **prompt_key** | VARCHAR(255) | UNIQUE(prompt_key, version), INDEX | Prompt Key |
| version | VARCHAR(32) | | 版本号 |
| version_desc | VARCHAR(255) | | 版本描述 |
| template | LONGTEXT | | Prompt 模板内容 |
| variables | LONGTEXT | | 变量参数 (JSON) |
| model_config | LONGTEXT | | 调试模型参数 (JSON) |
| **status** | VARCHAR(32) | `枚举` DEFAULT 'pre', INDEX | pre(预发布) / release(正式) |
| previous_version | VARCHAR(32) | | 前置版本号 (对比用) |
| create_time / update_time | DATETIME(3) | INDEX(create_time) | 审计时间 |

### 26. prompt_build_template（Prompt 构建模板）

| 字段 | 类型 | 约束 | 说明 |
|------|------|------|------|
| **id** | BIGINT | **PK** AUTO_INCREMENT | 主键 |
| prompt_template_key | VARCHAR(255) | UNIQUE | 模板 Key |
| template_desc | VARCHAR(255) | | 模板描述 |
| tags | VARCHAR(255) | INDEX | 标签 |
| template | LONGTEXT | | 模板内容 |
| variables | LONGTEXT | | 变量参数 (JSON) |
| model_config | LONGTEXT | | 推荐模型参数 (JSON) |

### 27. model_config（模型配置）

| 字段 | 类型 | 约束 | 说明 |
|------|------|------|------|
| **id** | BIGINT | **PK** AUTO_INCREMENT | 主键 |
| name | VARCHAR(100) | UNIQUE, NOT NULL | 配置名称 |
| provider | VARCHAR(50) | NOT NULL, INDEX | 供应商 |
| model_name | VARCHAR(100) | NOT NULL | 模型标识 (gpt-4o 等) |
| base_url | VARCHAR(500) | NOT NULL | 服务地址 |
| api_key | VARCHAR(500) | NOT NULL | API 密钥 |
| default_parameters | JSON | | 默认参数 (JSON) |
| supported_parameters | JSON | | 支持的参数 (JSON) |
| **status** | TINYINT | `枚举` DEFAULT 1, INDEX | 1=启用, 0=禁用 |
| **deleted** | TINYINT | DEFAULT 0, INDEX | 逻辑删除（⚠️ DDL有，Java实体缺失） |
| create_time / update_time | DATETIME | INDEX(create_time) | 审计时间 |

### 28. ChatSession（会话 — 内存存储 ⚠️ 非 MySQL）

> **存储引擎**：内存 `ConcurrentHashMap`，30 分钟过期，定时清理（每 10 分钟）。代码注释建议生产环境使用 Redis。
> 对应 API：`/api/prompt/session`（GET 获取 / DELETE 删除）

| 字段 | 类型 | 约束 | 说明 |
|------|------|------|------|
| **session_id** | String | **PK**（UUID） | 会话唯一标识 |
| prompt_key | String | FK → prompt.prompt_key | 关联 Prompt |
| version | String | | Prompt 版本 |
| template | String | | Prompt 模板内容 |
| variables | String | | 变量配置 (JSON) |
| model_config | ModelConfigInfo | | 模型配置信息 |
| messages | List\<ChatMessage\> | | 会话消息历史 |
| mock_tools | List\<MockTool\> | | Mock 工具列表 |
| create_time | Long | | 创建时间戳 |
| last_update_time | Long | | 最后更新时间戳 |

> 注意：ChatSession 是纯 DTO，没有对应 MySQL 表、没有 Entity 注解、没有 DDL。

---

## 三、枚举值汇总

| 枚举类 | 字段 | 值 |
|--------|------|-----|
| **AccountStatus** | account.status | 0=DELETED, 1=NORMAL, 2=DISABLED |
| **AccountType** | account.type | "admin", "user" |
| **CommonStatus** | api_key / document / kb / workspace .status | 0=DELETED, 1=NORMAL |
| **AppStatus** | application / application_version .status | 0=DELETED, 1=DRAFT, 2=PUBLISHED, 3=PUBLISHED_EDITING |
| **AppType** | application.type | "basic", "workflow" |
| **AgentType** | agent_schema.type | ReactAgent, ParallelAgent, SequentialAgent, LLMRoutingAgent, LoopAgent |
| **AgentStatus** | agent_schema.status | active, inactive, configuring, error |
| **KnowledgeBaseType** | knowledge_base.type | "unstructured", "structured" |
| **DocumentType** | document.type | "file", "url", "oss" |
| **DocumentIndexStatus** | document.index_status | 1=UPLOADED, 2=PROCESSING, 3=PROCESSED, 4=FAILED |
| **PluginType** | plugin.type | "official", "custom" |
| **PluginStatus** | plugin.status | 0=DELETED, 1=NORMAL |
| **ToolStatus** | tool.status | 0=DELETED, 1=DRAFT, 2=PUBLISHED, 3=PUBLISHED_EDITING |
| **ToolTestStatus** | tool.test_status | 1=NOT_TEST, 2=PASSED, 3=FAILED |
| **ExperimentStatus** | experiment.status | DRAFT, RUNNING, COMPLETED, FAILED, STOPPED |
| **versionStatus** | dataset_version / evaluator_version .status | DRAFT, PUBLISHED (⚠️ DDL 含 ARCHIVED，Java 枚举缺失) |
| **prompt_version.status** | (无枚举类，硬编码) | "pre" (预发布), "release" (正式) |
| **ChunkType** | DocumentChunk 分块策略 | LENGTH, PAGE, TITLE, REGEX |

---

## 四、三边不一致问题

### 4.1 Entity ↔ DDL 不一致

| # | 问题 | 严重程度 |
|---|------|----------|
| 1 | `DatasetItemDO.java` 缺少 `deleted` 字段（DDL 有） | ⚠️ 中 |
| 2 | `ModelConfigDO.java` 缺少 `deleted` 字段（DDL 有） | ⚠️ 中 |
| 3 | `versionStatus` 枚举缺少 `ARCHIVED`（DDL 注释含此值） | 🔴 高 |
| 4 | `prompt_version.status` 无对应 Java 枚举类 | ⚠️ 中 |
| 5 | `AccountEntity.defaultWorkspaceId` 标注 `exist=false` 为非DB字段 | ✅ 设计如此 |
| 6 | `AppEntity.latestVersion/publishedVersion` 标注 `exist=false` | ✅ 设计如此 |

### 4.2 API 接口 ↔ 数据模型 对照结果（`api-list.md` ↔ `data-model.md`）

| # | 发现 | 说明 |
|---|------|------|
| 1 | ✅ 接口引用的所有 MySQL 实体在数据模型中均有定义 | account / workspace / application / agent_schema / knowledge_base / document / plugin / tool / mcp_server / provider / model / api_key / application_component / reference / dataset / evaluator / experiment / prompt / model_config |
| 2 | ⚠️ `DocumentChunk` 接口有完整 CRUD（7个），原 data-model.md 缺失 | 已补充：存储在 ES 中，非 MySQL，DTO 为 `DocumentChunk.java` |
| 3 | ⚠️ `ChatSession` 接口有 GET/DELETE，原 data-model.md 缺失 | 已补充：存储在内存 `ConcurrentHashMap` 中，非 MySQL 非 ES，30分钟过期 |
| 4 | ⚠️ `ChunkType` 枚举未记录 | 已补充：LENGTH / PAGE / TITLE / REGEX，定义在 `runtime/enums/ChunkType.java` |

---

## 五、ER 图

见 `docs/data-model-er.svg`。

> ER 图已包含 Builder 域（15个实体）和 Evaluation 域（12个实体）的核心 MySQL 表关系。
> ⚠️ `DocumentChunk`（ES 存储）和 `ChatSession`（内存存储）不在此 ER 图中，详见上文各实体说明。
