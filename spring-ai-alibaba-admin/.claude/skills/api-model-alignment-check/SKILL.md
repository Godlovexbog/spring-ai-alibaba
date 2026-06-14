---
name: api-model-alignment-check
description: >
  对照 docs/api-list.md 和 docs/data-model.md，检查接口引用的资源实体在数据模型中是否都有定义。
  列出不一致项并给出修复建议。可作为 docs-auto-sync 的后置验证步骤。
---

# api-model-alignment-check — 接口清单 ↔ 数据模型对齐检查

## 触发时机

- 用户说 "check alignment"、"校对接口和数据模型"、"对齐检查"
- 作为 docs-auto-sync 的后置步骤自动触发
- 每次修改 Controller 或 Entity 后运行

## 检查清单

- [ ] 解析 api-list.md → 提取所有资源实体名
- [ ] 解析 data-model.md → 提取所有实体名 + 字段清单 + 枚举列表
- [ ] 交叉对照：API 引用 vs 数据模型定义
- [ ] 深查字段级：接口入参/出参字段是否在数据模型中有对应
- [ ] 枚举检查：API 路径/DTO 中的枚举是否在数据模型枚举表中
- [ ] 生成不一致报告
- [ ] 可选自动修复（枚举遗漏等明确问题）
- [ ] 输出结论：一致 ✅ 或 不一致 ⚠️ + 表格

## 核心规则

### 1. 从 api-list.md 提取实体

扫描策略：

```
接口路径模式           →  提取的实体名
/console/v1/accounts   →  account
/console/v1/workspaces →  workspace
/console/v1/apps       →  application
/console/v1/providers  →  provider
/console/v1/knowledge-bases → knowledge_base
/console/v1/knowledge-bases/{kbId}/documents → document
/console/v1/documents/{docId}/chunks → document_chunk
/console/v1/plugins    →  plugin
/console/v1/tools      →  tool
/console/v1/mcp-servers → mcp_server
/console/v1/agent-schemas → agent_schema
/console/v1/component-servers → application_component
/console/v1/api-keys   →  api_key
/api/prompt            →  prompt
/api/dataset           →  dataset
/api/evaluator         →  evaluator
/api/experiment        →  experiment
/api/observability     →  （无实体，跳过）
/api/model             →  model_config
```

### 2. 从 data-model.md 提取实体

扫描 `### N. entity_name` 模式，提取：
- 实体名（标题中的英文名）
- 字段列表（表格行）
- 枚举信息（`枚举` 标记的字段 + 枚举表章节）

### 3. 对照规则

| 检查维度 | 方法 | 判定标准 |
|----------|------|----------|
| **实体存在性** | API 提取的实体名 ∈ data-model 实体名集合？ | 不在 → 缺失实体 ⚠️ |
| **字段完备性** | API 入参字段 ∈ data-model 实体字段集合？ | 不在 → 缺失字段 ⚠️ |
| **枚举完备性** | API 路径/DTO 引用的枚举值 ∈ 枚举汇总表？ | 不在 → 缺失枚举 ⚠️ |
| **类型一致性** | API 出参字段类型 = data-model 字段类型？ | 不一致 → 类型不匹配 ⚠️ |

### 4. 已知例外（白名单）

以下实体是合法的"无 MySQL 表"实体，不要报告为缺失：

| 实体 | 存储方式 | 说明 |
|------|----------|------|
| `document_chunk` | Elasticsearch | DTO 在 runtime/domain/knowledgebase/DocumentChunk.java |
| `chat_session` | 内存 ConcurrentHashMap | DTO 在 admin/dto/ChatSession.java，30min 过期 |
| `files` | 阿里云 OSS | 无持久化实体，FileController 直接操作 OSS |
| `system` | 无实体 | SystemController 只提供 health/global-config |
| `observability` | OTel 外部 | 从 LoongCollector/Elasticsearch 读取 Trace 数据 |

### 5. 输出格式

```
🔍 API ↔ Data Model 对齐检查报告
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
扫描: api-list.md (170+ 接口) ↔ data-model.md (28 表)

✅ 一致 (24/27):
  account, workspace, application, application_version,
  agent_schema, knowledge_base, document, plugin, tool,
  mcp_server, provider, model, api_key, application_component,
  reference, dataset, dataset_version, dataset_item,
  evaluator, evaluator_version, evaluator_template,
  experiment, experiment_result, prompt, prompt_version,
  prompt_build_template, model_config

⚠️ 不一致 (3):
  1. document_chunk — API 有完整 CRUD，data-model.md 中缺失
     → 存储: Elasticsearch（非 MySQL），DTO 已存在
     → 修复: 在 data-model.md 补充为 "7b. DocumentChunk（ES 存储）"

  2. chat_session — API 有 GET/DELETE，data-model.md 中缺失
     → 存储: ConcurrentHashMap（内存），30min 过期
     → 修复: 在 data-model.md 补充为 "28. ChatSession（内存存储）"

  3. ChunkType 枚举 — document_chunk 的分块策略枚举未记录
     → 定义: runtime/enums/ChunkType.java (LENGTH/PAGE/TITLE/REGEX)
     → 修复: 在枚举汇总表中追加

⏭️ 跳过 (4 个白名单): files, system, observability, auth
```

### 6. 自动修复模式

当用户明确说 "fix" 或 "自动修复" 时：
- 对缺失的枚举：追加到 data-model.md 枚举汇总表
- 对缺失的实体：询问用户确认後，追加到 data-model.md 对应章节
- 对类型不匹配：报告但不自动修改（需人工判断）

### 7. 完成后必做

- [ ] 报告保存到 `docs/alignment-report.md`（如果用户要求）
- [ ] 如果有自动修复，更新 `docs/data-model.md`
- [ ] 如果 data-model.md 被修改，建议运行 `docs-auto-sync`

## allowed-tools

- `Read` — 读取 api-list.md 和 data-model.md
- `Bash: grep / sed` — 提取实体名和模式
- `Edit` — 自动修复 data-model.md（需用户确认）
- `Write` — 写入对齐报告（可选）
