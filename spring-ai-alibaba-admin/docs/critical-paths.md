# 核心链路清单 — 最值得测的 8 条路径

> 依据：`docs/api-list.md` · `docs/data-model.md` · `CLAUDE.md`
>
> 筛选原则：**改造时最容易出问题**，不是覆盖面最广。宁少勿多，≤8 条。

## 总览

| # | 链路名 | 起点 | 关键风险 |
|---|--------|------|----------|
| 1 | Prompt 版本发布 | `POST /api/prompt/version` | pre→release 状态机 + Nacos 同步失败不回滚 |
| 2 | 应用创建与发布 | `POST /console/v1/apps/` | AppStatus 四状态机 + 版本快照 |
| 3 | 文档上传与索引 | `POST /console/v1/knowledge-bases/{kbId}/documents` | 异步 RocketMQ 索引 + ES 写入 + indexStatus 状态流 |
| 4 | 工具发布与测试 | `POST /console/v1/plugins/{id}/tools/{id}/publish` | ToolStatus 四状态机 + ToolTestStatus + POST test 同步调用 |
| 5 | 实验执行 | `POST /api/experiment` | ExperimentStatus 五状态机 + 多实体关联 + progress 更新 |
| 6 | Agent Schema 启用/禁用 | `PATCH /console/v1/agent-schemas/{id}/enabled` | sub_agents JSON 解析 + 类型约束 + enabled 字段反转 |
| 7 | 聊天补全 | `POST /api/v1/apps/chat/completions` | 流式/同步双模式 + SSE + session 管理 |
| 8 | 知识库检索 | `POST /console/v1/knowledge-bases/retrieve` | ES 查询 + score 排序 + chunk enabled 过滤 |

---

## 详细分析

### 链路 1：Prompt 版本发布

| 维度 | 内容 |
|------|------|
| **起点** | `POST /api/prompt/version`（创建新版本，status=release） |
| **关键节点** | ① `PromptController.createPromptVersion()` → ② `PromptVersionServiceImpl.create()` → ③ `promptVersionMapper.existsByPromptKeyAndVersion()` 状态冲突检查 → ④ 若 pre 覆盖则 `updateByPromptKeyAndVersion()`，若 release 新建则 `insert()` → ⑤ `publishPromptToNacos()` 调用 Nacos ConfigService.publishConfig() → ⑥ `promptService.updateLatestVersion()` |
| **终点** | 成功：`prompt_version` 表写入新记录 + `prompt` 表 latestVersion 更新 + Nacos 配置已发布（dataId=`prompt-{key}.json`） |
| **为什么容易出问题** | ① 状态机冲突（pre 覆盖、release 不可覆盖）逻辑分散在 Service 内 if-else 链，条件组合多 ② Nacos 同步异常被 catch 但不回滚 `@Transactional` ④ pre 版本也会更新 latestVersion（可能是 bug）③ `previousVersion` 只在 INSERT 新记录时自动填充，UPDATE 覆盖时不更新 |

### 链路 2：应用创建与发布

| 维度 | 内容 |
|------|------|
| **起点** | `POST /console/v1/apps/` → `POST /console/v1/apps/{appId}/publish` |
| **关键节点** | ① `AppController.create()` → ② `AppController.publish()` → ③ `application` 表 INSERT（status=DRAFT）→ ④ `application_version` 表 INSERT（快照 config） → ⑤ status 从 DRAFT → PUBLISHED → ⑥ 若再次编辑 → PUBLISHED_EDITING，发布 → 新版本号 + 回 PUBLISHED |
| **终点** | 成功：`application` status=PUBLISHED + `application_version` 表有新版本记录 |
| **为什么容易出问题** | ① AppStatus 四状态（DRAFT→PUBLISHED→PUBLISHED_EDITING→PUBLISHED→DELETED），状态转换路径两条 ② config 字段是复杂 JSON，版本快照时序列化/反序列化可能丢失字段 ③ `app_id` 和 `workspace_id` 双唯一约束 |

### 链路 3：文档上传与索引

| 维度 | 内容 |
|------|------|
| **起点** | `POST /console/v1/knowledge-bases/{kbId}/documents`（上传文档） |
| **关键节点** | ① `DocumentController` → ② 文件上传到 OSS/本地 → ③ `document` 表 INSERT（indexStatus=UPLOADED, status=NORMAL） → ④ RocketMQ Producer 发送索引消息（topic=`topic_saa_studio_document_index`）→ ⑤ Consumer 消费 → ⑥ 解析文档（Tika/PDF/Markdown Reader）→ ⑦ `DocumentChunkConverter` 写入 ES 索引 → ⑧ 更新 `document.indexStatus`：UPLOADED→PROCESSING→PROCESSED(或 FAILED) |
| **终点** | 成功：`document.index_status=PROCESSED` + ES 中有分块数据 + RocketMQ 消息已消费 |
| **为什么容易出问题** | ① 异步链路长（RocketMQ → Consumer → ES），中间任何一环失败 indexStatus 卡在 PROCESSING ② ES 索引名由 `indexConfig` 配置决定，配置错误时 Consumer 写入失败 ③ 批量删除文档时 `batch-delete` 需要同步清理 ES 索引，易遗漏 ④ `processConfig` 是 JSON 配置，解析错误时 Consumer 抛异常但不回滚 DB 写入 |

### 链路 4：工具发布与测试

| 维度 | 内容 |
|------|------|
| **起点** | `POST /console/v1/plugins/{pluginId}/tools/{toolId}/test` → `POST /.../publish` |
| **关键节点** | ① `ToolController` → ② `ToolExecutionRequest` 携带 tool 配置（apiSchema/config JSON） → ③ 实际 HTTP 调用外部 API → ④ 返回结果更新 `tool.testStatus`（NOT_TEST→PASSED/FAILED）→ ⑤ `publish`：`tool.status` DRAFT→PUBLISHED → ⑥ 若再次编辑 test，PUBLISHED_EDITING→PUBLISHED |
| **终点** | 成功：`tool.status=PUBLISHED` + `tool.test_status=PASSED` + `tool.enabled=true` |
| **为什么容易出问题** | ① 测试是同步 HTTP 调用外部服务（超时/网络错误处理）② 状态机 ToolStatus 四状态 + ToolTestStatus 三状态，两套状态独立但有关联（未测试不能发布？代码里是否强制校验未知）③ `apiSchema` JSON 格式变化时旧 tool 测试失败但不影响已发布状态 |

### 链路 5：实验执行

| 维度 | 内容 |
|------|------|
| **起点** | `POST /api/experiment`（创建实验，status=RUNNING） |
| **关键节点** | ① `ExperimentController` → ② `experiment` 表 INSERT（status=DRAFT→RUNNING）→ ③ 读取 `dataset_version` 获取数据项列表 → ④ 遍历数据项，对每条调用 LLM（通过 `evaluator_config` 中的 evaluatorVersionId 关联的评估器配置）→ ⑤ 写入 `experiment_result` 表（每项一条）→ ⑥ 更新 `experiment.progress` → ⑦ 全部完成后 status=COMPLETED |
| **终点** | 成功：`experiment.status=COMPLETED` + `experiment.progress=100` + `experiment_result` 表有 N 条记录（score 非 null） |
| **为什么容易出问题** | ① 五状态机（DRAFT→RUNNING→COMPLETED/FAILED/STOPPED），FAILED 时 progress 可能不是 100，前端展示逻辑依赖 status+progress 组合 ② 批量调用 LLM 时单条失败是否继续？③ `experiment_result.score` 是 DECIMAL(3,2)，评估器返回异常值时写入失败 |

### 链路 6：Agent Schema 启用/禁用

| 维度 | 内容 |
|------|------|
| **起点** | `PATCH /console/v1/agent-schemas/{id}/enabled` |
| **关键节点** | ① `AgentSchemaController` → ② 查询 `agent_schema` 记录 → ③ 反转 `enabled` 布尔值 → ④ UPDATE 写回 → ⑤ 如果 AgentType 是 ParallelAgent/SequentialAgent 且 `sub_agents` 字段非 null，子 agent 的启用状态是否联动？（代码中需确认）|
| **终点** | 成功：`agent_schema.enabled` 已反转 + `agent_schema.status` 可能联动（active↔inactive） |
| **为什么容易出问题** | ① `sub_agents` 是 TEXT 存 JSON，格式错误时 parse 失败但不影响启用/禁用主 agent ② AgentStatus 四状态（active/inactive/configuring/error），enabled 反转时 status 是否联动（active→inactive 等）代码逻辑易遗漏 ③ 通过 reference 表多态引用了该 agent 的 application_component 是否需要感知 agent 被禁用？ |

### 链路 7：对外聊天补全

| 维度 | 内容 |
|------|------|
| **起点** | `POST /api/v1/apps/chat/completions`（对外 OpenAPI） |
| **关键节点** | ① `ChatController.chatCompletions()` → ② 解析请求体（Streaming 模式 vs 同步模式）→ ③ 查询 app 配置（`application_version.config` JSON）→ ④ 构建 Agent 执行链（agent_schema→ReactAgent/ParallelAgent 等）→ ⑤ 调用 LLM（通过 provider/model 配置）→ ⑥ 流式模式：`Flux<ServerSentEvent>` → ⑦ 同步模式：`Result<ChatCompletionResponse>` |
| **终点** | 成功：流式返回 SSE 事件流（content+metrics）或同步返回完整 JSON |
| **为什么容易出问题** | ① 流式模式下 SSE 连接中断时的资源清理 ② config JSON 反序列化失败导致 Agent 构建异常 ③ `modelConfig` 中的 `baseUrl`/`apiKey` 为 null 时调用 LLM 失败 ④ ChatSession 是 ConcurrentHashMap 内存存储，重启后丢失 |

### 链路 8：知识库检索

| 维度 | 内容 |
|------|------|
| **起点** | `POST /console/v1/knowledge-bases/retrieve` |
| **关键节点** | ① `KnowledgeBaseController` → ② 解析 `searchConfig` JSON（topK、threshold 等）→ ③ 调用 ElasticsearchClient.search() → ④ `vectorStore.similaritySearch(query, topK)` → ⑤ 过滤 `document_chunk.enabled=true` → ⑥ 返回得分排序后的 chunks |
| **终点** | 成功：返回 Top-K 个相关 DocumentChunk，每个带 score |
| **为什么容易出问题** | ① `indexConfig` 配置与 ES 实际索引名不一致时 search 返回空 ② ES 连接超时时 Controller 返回什么（空列表 vs 500？）③ `document_chunk.enabled=false` 的 chunk 在 ES 中被过滤还是在返回后被过滤？两者性能差异大 ④ 检索时 `kb_id` 和 `workspace_id` 双重过滤是否正确应用 |

---

## 选这 8 条的原因

| 标准 | 覆盖 |
|------|------|
| **状态机复杂** | Prompt(pre/release)、App(DRAFT→PUBLISHED→EDITING)、Tool(DRAFT→PUBLISHED+TestStatus)、Experiment(DRAFT→RUNNING→COMPLETED/FAILED/STOPPED) — 4 条链路涉及多状态转换 |
| **跨系统交互** | Document(RocketMQ+ES)、Retrieve(ES query)、Chat(LLM+SSE+Session) — 3 条涉及 DB 外系统 |
| **配置敏感** | Agent(sub_agents JSON)、App(config JSON)、Experiment(evaluatorConfig JSON) — 3 条依赖 JSON 配置正确性 |
| **并发/异步** | Document(RocketMQ 异步)、Experiment(批量 LLM 调用) — 2 条有异步风险 |
| **对外接口** | Chat(/api/v1/apps 对外 OpenAPI) — 1 条直接面向外部用户 |
