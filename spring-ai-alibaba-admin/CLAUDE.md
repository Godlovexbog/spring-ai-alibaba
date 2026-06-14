# CLAUDE.md — Spring AI Alibaba Admin

> AI 助手操作手册。精简版，详细内容通过链接指向 `docs/`。

## 1. 项目定位

Spring AI Alibaba Admin 是一个 **一站式的 AI Agent 可视化开发与运维平台**。提供 Agent 应用的可视化搭建、Prompt 工程、知识库 RAG、模型管理、MCP 工具集成、评估实验和可观测性等完整生命周期管理。

- 前端：React SPA
- 后端：Java 17 + Spring Boot 3.3.6 + MyBatis Plus 3.5.9
- 数据库：MySQL 8.0（主存储）+ Redis + Elasticsearch
- 部署：Docker / Kubernetes

## 2. 核心架构

分层架构（前端 → 后端 → 中间件 → 数据层），详见架构图：

> 🔗 [architecture.svg](docs/architecture.svg)

**内部模块依赖**（start → openapi → core → runtime，单向收敛，无循环）：

> 🔗 [module-deps.svg](docs/module-deps.svg)

**外部依赖**（Java 主干依赖 / 中间件 / 外部 API 三类）：

> 🔗 [external-deps.svg](docs/external-deps.svg)

## 3. 关键模块

| 模块 | 职责 |
|------|------|
| `server-start` | 启动入口，装配所有模块，加载配置 |
| `server-openapi` | REST API 网关层，`/api/v1/apps` 对外接口 |
| `server-core` | 核心业务：Agent / RAG / 工作流配置 / 文件管理 |
| `server-runtime` | 运行时抽象层，最底层基础模块 |

**业务功能域：**

| 域 | 说明 |
|----|------|
| 应用构建（Builder） | Agent 可视化搭建、工作流编排、组件市场 |
| 知识库 RAG | 文档上传 → 解析 → 分块 → ES 索引 → 检索 |
| 模型管理 | DashScope / OpenAI / DeepSeek / Ollama 多供应商 |
| 插件 & 工具 | 插件注册 + 工具 CRUD + 测试 + 发布 |
| MCP 集成 | Model Context Protocol 服务器注册与调试 |
| Prompt 工程 | Prompt 模板 / 版本管理 / 在线调试 |
| 评估实验 | 测评集 + 评估器 + 实验执行 + 结果分析 |
| 可观测性 | OpenTelemetry Trace 查看，服务概览 |

## 4. 关键约定

- **Java 17+**，Lombok 注解（`@Data`, `@Builder`, `@Slf4j`），SLF4J 日志
- **MyBatis Plus** 做 ORM，`@TableName` / `@TableId(type=IdType.AUTO)` 标注实体，枚举用 `@EnumValue` 存储
- **API 前缀**：管理后台 `/console/v1/`，评估实验 `/api/`，对外开放 `/api/v1/apps`
- **审计字段**：`gmt_create` / `gmt_modified` + `creator` / `modifier`（大部分表）
- **逻辑删除**：部分 Evaluation 模块表使用 `deleted` 字段（TINYINT, 0/1）
- **状态枚举**：实体状态统一用枚举类，数据库存 INT 或 VARCHAR 的 code 值
- **软删除**：大部分 Builder 表用 `CommonStatus.DELETED(0)` 标记，不物理删除
- **版本管理**：`application_version`、`prompt_version`、`dataset_version`、`evaluator_version` 均用 `(parent_id, version)` 联合唯一约束

### 代码规范

- 使用 Apache 2.0 许可证头
- `make lint` / `make licenses-check` 做代码检查
- Controller 统一用 `@RestController` + `@RequestMapping`

## 5. 怎么跑

### 前置条件

```bash
# JDK 17+, Maven 3.8+, Docker
java --version  # 确认 17+
docker compose version  # 确认可用
```

### 启动中间件

```bash
cd docker/middleware
docker compose -f docker-compose-prod.yaml up -d
# 启动 MySQL 8.0 + Redis 7.2 + ES 9.1 + Nacos + RocketMQ 5.3 + LoongCollector
```

### 配置 API Key

复制对应模板文件：
- `model-config-dashscope.yaml` → 阿里云百炼
- `model-config-openai.yaml` → OpenAI
- `model-config-deepseek.yaml` → DeepSeek

### 启动应用

```bash
cd spring-ai-alibaba-admin-server-start
# 设置环境变量：
export SPRING_DATASOURCE_URL=jdbc:mysql://localhost:3306/admin?...
export SPRING_DATASOURCE_USERNAME=admin
export SPRING_DATASOURCE_PASSWORD=admin
export SPRING_REDIS_HOST=localhost
export SPRING_REDIS_PORT=6379
export NACOS_SERVER_ADDR=localhost:8848

# 启动
mvn spring-boot:run
# 访问 http://localhost:8080
```

### Docker 部署

```bash
docker compose -f deploy/docker-compose/docker-compose-service.yaml up -d
```

## 6. 禁区

> （待补充：不可触碰的模块、不可修改的表结构、不可删除的 API 等）

## 7. 历史包袱

> （待补充：已知技术债、待重构代码、兼容性遗留问题等）

---

## 📎 文档索引

| 文档 | 路径 | 说明 |
|------|------|------|
| 架构全景图 | [architecture.svg](docs/architecture.svg) | 四层架构 + 数据库表名 |
| 模块依赖图 | [module-deps.svg](docs/module-deps.svg) | 内部模块依赖关系 |
| 外部依赖图 | [external-deps.svg](docs/external-deps.svg) | Java / 中间件 / 外部 API 三类 |
| REST 接口清单 | [api-list.md](docs/api-list.md) | ~170+ 接口端点完整列表 |
| 数据模型 | [data-model.md](docs/data-model.md) | 28 张表字段清单 + PK/FK/枚举 + 三边对照 |
| 数据模型 ER 图 | [data-model-er.svg](docs/data-model-er.svg) | Builder + Evaluation 域实体关系 |
