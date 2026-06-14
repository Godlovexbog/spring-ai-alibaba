# 核心链路测试覆盖情况

> 对照 `docs/critical-paths.md` 的 8 条核心链路，扫描项目全部测试文件。

## 总览

| # | 链路 | 测试覆盖 | 现有测试 | 缺口 |
|---|------|----------|----------|------|
| 1 | Prompt 版本发布 | ❌ 没有 | 0 | Controller / Service / Mapper 全无 |
| 2 | 应用创建与发布 | ❌ 没有 | 0 | Controller / Service 全无 |
| 3 | 文档上传与索引 | ⚠️ 部分 | `TextDocumentReaderTest`、`TextSplitterTest`、`KnowledgeBaseIndexPipelineTest` | 缺：Controller 层 + RocketMQ Consumer + ES 写入集成 |
| 4 | 工具发布与测试 | ❌ 没有 | 0 | Controller / Service / 外部 HTTP 调用 全无 |
| 5 | 实验执行 | ❌ 没有 | 0 | Controller / Service / 批量 LLM 调用 全无 |
| 6 | Agent Schema 启用/禁用 | ❌ 没有 | 0 | Controller / Service 全无 |
| 7 | 对外聊天补全 | ⚠️ 部分 | `ConversationChatMemoryTest` | 缺：ChatController 流式/同步 + SSE + Session 管理 |
| 8 | 知识库检索 | ⚠️ 部分 | `TextSplitterTest`、`DashscopeRerankerTest` | 缺：Controller 层 + ES 查询 + enabled 过滤 |

## 详细分析

### ❌ 完全没有测试（5 条）

| # | 链路 | 涉及模块 | 缺失的测试层级 |
|---|------|----------|---------------|
| 1 | **Prompt 版本发布** | `server-start` | ① PromptController 无测试 ② PromptVersionServiceImpl.create() 状态机无测试 ③ Nacos 同步逻辑无测试 ④ 无 `PromptControllerTest.java` |
| 2 | **应用创建与发布** | `server-start` | ① AppController CRUD 无测试 ② AppStatus 四状态机无测试 ③ 版本快照无测试 |
| 4 | **工具发布与测试** | `server-start` | ① ToolController 无测试 ② ToolExecutionRequest 外部 HTTP 调用无测试 ③ ToolStatus+ToolTestStatus 双状态机无测试 |
| 5 | **实验执行** | `server-start` | ① ExperimentController 无测试 ② ExperimentStatus 五状态机无测试 ③ 批量 LLM 无测试 |
| 6 | **Agent Schema** | `server-start` | ① AgentSchemaController 无测试 ② sub_agents JSON 解析无测试 ③ enabled↔status 联动无测试 |

### ⚠️ 部分覆盖（3 条）

| # | 链路 | 已有的 | 缺的 |
|---|------|--------|------|
| 3 | **文档上传与索引** | ✅ `TextDocumentReaderTest`（文档解析）<br>✅ `TextSplitterTest`（文本分块）<br>✅ `KnowledgeBaseIndexPipelineTest`（索引流水线）<br>✅ `DashscopeRerankerTest`（重排序） | ❌ `DocumentController` 文件上传<br>❌ RocketMQ Consumer 消费<br>❌ ES 批量写入<br>❌ indexStatus 状态更新<br>❌ batch-delete ES 清理 |
| 7 | **对外聊天补全** | ✅ `ConversationChatMemoryTest`（对话记忆） | ❌ `ChatController.chatCompletions()`（流式/同步两模式）<br>❌ SSE 连接管理<br>❌ ChatSession 内存管理<br>❌ Agent 构建链 |
| 8 | **知识库检索** | ✅ `TextSplitterTest`（文本处理）<br>✅ `DashscopeRerankerTest`（重排序） | ❌ `KnowledgeBaseController.retrieve()`<br>❌ ES query 构建<br>❌ enabled 过滤<br>❌ score 阈值<br>❌ 空结果处理 |

---

## 缺口汇总

### 模块维度

| 模块 | 测试文件数 | 覆盖的链路 | 完全缺失的链路 |
|------|-----------|------------|---------------|
| `server-core` | 8 | 链路3(部分)、7(部分)、8(部分) | — |
| `server-start` | **0** | — | 链路1、2、3(Controller)、4、5、6、7(Controller)、8(Controller) |

### 测试层级维度

| 层级 | 现状 | 缺口 |
|------|------|------|
| **单元测试（工具类）** | 8 个（crypto/rag/utils） | 工具类覆盖尚可 |
| **单元测试（Service）** | 0 个 | 全部 4 个 Service 层链路缺失 |
| **集成测试（Controller）** | 0 个 | 全部 8 个 Controller 端点缺失 |
| **集成测试（跨系统）** | 0 个 | RocketMQ / ES / Nacos 交互全无 |

---

## 优先补齐建议

| 优先级 | 链路 | 理由 |
|--------|------|------|
| 🔴 P0 | 链路1 **Prompt 版本发布** | 刚完成需求定稿+方案设计，马上要改造，无基线测试覆盖改造风险极大 |
| 🔴 P0 | 链路3 **文档上传与索引** | 已有组件级测试但缺少集成测试，异步跨系统链路最易出问题 |
| 🟡 P1 | 链路2 **应用创建与发布** | 最核心的 Builder 入口，状态机路径多条 |
| 🟡 P1 | 链路5 **实验执行** | 五状态机 + 批量 LLM + 多实体关联 |
| 🟢 P2 | 链路4、6、7、8 | 已有部分覆盖，可渐进补全 |
