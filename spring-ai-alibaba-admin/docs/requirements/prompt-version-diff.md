# 需求定稿：Prompt 版本对比

> **一句话**：为团队多人协作场景提供 Prompt 版本演进追溯能力——通过两版本 diff 快速定位"谁、什么时候、改了什么"。
>
> 需求来源：`human/7-需求/1-六维草稿` → 三判断定稿
>
> 分析依据：`docs/api-list.md` · `docs/data-model.md` · `CLAUDE.md` · `PromptVersionServiceImpl.java` · `PromptVersionDO.java` · `PromptController.java`

---

## 1. 业务目标

**为团队多人协作场景提供 Prompt 版本演进追溯能力——当线上效果变化时，能快速定位"谁、什么时候、改了什么"，并辅助版本合并决策。**

> ⚠️ 上一稿偏"单工程师 review 自己的修改"。对照三个实际场景（线上效果回溯、多人协作合并、发布前审查），其中两个是团队场景。因此 diff 接口不仅要返回内容差异，还必须附带**元信息**：两个版本的创建时间、创建人、状态（pre/release），让团队协作有据可查。

---

## 2. 用户场景

### 典型场景

> 小王在调试 Prompt 时，把 v3 的 template 从 "你是一个客服助手" 改成了 v5 的 "你是一个专业客服助手，请用中文回答"，但 v5 在预发环境效果反而差了。他想看看 v3 和 v5 到底改了什么——除了 template 那句文案，variables 里是不是也少了一个 `{user_name}` 变量？modelConfig 里的 `temperature` 是不是从 0.7 被不小心改成了 1.0？

### 当前痛点

| 痛点 | 说明 |
|------|------|
| **无 diff 接口** | 当前 `PromptVersionController` 只有 `GET /api/prompt/version`（获取单个详情），没有两个版本的对比端点。用户只能肉眼对比两个版本详情。 |
| **template 是 LONGTEXT** | Prompt 模板可能很长（数百行），肉眼逐行对比易遗漏 |
| **variables/modelConfig 是 JSON** | JSON 字符串嵌套复杂时肉眼对比几乎不可能 |
| **previousVersion 仅单向链** | `PromptVersionDO.previousVersion` 只记录了上一版本号，没有内容比较能力 |
| **全量快照无增量** | 每个版本独立存储完整 template（非差异存储），对比只能靠运行时计算 |

---

## 3. 接口契约

### 3.1 基本设计

对齐项目现有风格：

| 约定项 | 采用值 | 来源 |
|--------|--------|------|
| API 前缀 | `/api` | `PromptController` 已有 `@RequestMapping("/api")` |
| 请求方式 | GET | diff 是读操作，无副作用 |
| 响应格式 | `Result<DiffResponse>` | 现有非流式接口统一用 `com.alibaba.cloud.ai.studio.runtime.domain.Result<T>` |
| 分页 | 不涉及 | diff 是单次对比 |
| 错误处理 | `StudioException` | 项目统一异常类型 |

### 3.2 端点定义

```
GET /api/prompt/version/diff?promptKey={promptKey}&versionA={versionA}&versionB={versionB}
```

### 3.3 入参

| 参数 | 类型 | 必填 | 约束 | 说明 |
|------|------|------|------|------|
| `promptKey` | String | ✅ | `@NotEmpty` | Prompt Key，如 `customer_service_prompt` |
| `versionA` | String | ✅ | `@Pattern(regexp = "^[a-zA-Z0-9._-]+$")` | 基准版本号（旧版本） |
| `versionB` | String | ✅ | `@Pattern(regexp = "^[a-zA-Z0-9._-]+$")` | 对比版本号（新版本） |

> version 约束对齐 `PromptVersionDO.version` 字段的 JSR303 校验规则。

### 3.4 返回结构

```json
{
  "promptKey": "customer_service_prompt",
  "versionA": {
    "version": "v3",
    "status": "release",
    "creator": "zhangsan",
    "createdAt": "2026-05-01T10:00:00",
    "versionDesc": "增加了多语言支持"
  },
  "versionB": {
    "version": "v5",
    "status": "pre",
    "creator": "lisi",
    "createdAt": "2026-06-10T14:30:00",
    "versionDesc": "调整了语气参数"
  },
  "diff": {
    "template": {
      "type": "text_diff",
      "hasChanges": true,
      "addedLines": 2,
      "removedLines": 1,
      "changedLines": 0,
      "segments": [
        { "type": "unchanged", "content": "你是一个客服助手" },
        { "type": "added", "content": "，请用中文回答" },
        { "type": "removed", "content": "。" },
        { "type": "added", "content": "。如果用户不满意，请转人工。" }
      ]
    },
    "variables": {
      "type": "json_diff",
      "hasChanges": true,
      "addedKeys": ["user_level"],
      "removedKeys": ["user_name"],
      "changedKeys": []
    },
    "modelConfig": {
      "type": "json_diff",
      "hasChanges": false,
      "addedKeys": [],
      "removedKeys": [],
      "changedKeys": []
    }
  },
  "summary": "template: +2 -1行; variables: +1键(user_level), -1键(user_name); modelConfig: 无变更"
}
```

> ⚠️ 返回结构从扁平改为嵌套 `versionA` / `versionB` 对象。原因是业务目标调整为团队协作追溯后，需要携带每个版本的**创建时间、创建人、状态、版本描述**等元信息，方便定位"谁、什么时候、在什么状态下改了什么"。

### 3.5 错误码

| 错误码 | HTTP 状态 | 条件 | 对应 StudioException |
|--------|----------|------|---------------------|
| `PROMPT_KEY_NOT_FOUND` | 404 | promptKey 不存在 | `StudioException.NOT_FOUND` |
| `PROMPT_VERSION_NOT_FOUND` | 404 | versionA 或 versionB 不存在 | `StudioException.NOT_FOUND` |
| `PROMPT_SAME_VERSION` | 400 | versionA == versionB | `StudioException.INVALID_PARAM` |

### 3.6 数据来源

| 返回字段 | 数据来源 | SQL |
|----------|----------|-----|
| `promptKey` | 入参 | — |
| `statusA / statusB` | `prompt_version.status` | `SELECT status FROM prompt_version WHERE prompt_key = ? AND version = ?` |
| `createdAtA / createdAtB` | `prompt_version.create_time` | 同上 |
| `template diff` | 两次查询取 template，运行时计算 | `SELECT template FROM prompt_version WHERE prompt_key = ? AND version IN (?, ?)` |
| `variables diff` | 两次查询取 variables，运行时代入 | 同上 |
| `modelConfig diff` | 两次查询取 model_config，运行时代入 | 同上 |

> 当前无缓存层，每次 diff 需要 2 次 DB 查询。`template` 是 LONGTEXT，大模板需注意内存。

---

## 4. 边界场景清单

### 4.1 已决策的边界场景

| # | 场景 | 决策 | 预期行为 |
|---|------|------|----------|
| 1 | **versionA 和 versionB 相同** | 基于代码推断 | 返回 `PROMPT_SAME_VERSION` 错误 |
| 2 | **versionA 是 release，versionB 是 pre** | 基于代码推断 | 正常 diff，各目标注状态 |
| 3 | **versionA 不存在（已物理删除）** | 基于代码推断 | 返回 `PROMPT_VERSION_NOT_FOUND` |
| 4 | **两个版本 template 完全一致，仅 variables 不同** | 基于代码推断 | template.hasChanges=false，variables 列差异 |
| 5 | **template 为 null（数据库 NULL）** | ✅ **已决策**: 视同空字符串 | NULL 与 "" diff 结果为空；NULL 与 "xxx" diff 结果为新增全部内容 |
| 6 | **template 超长（100KB+ LONGTEXT 大模板）** | ✅ **已决策**: 不做大小限制 | 直接全量 diff，不加 `PROMPT_DIFF_TOO_LARGE` 错误码 |
| 7 | **软删除的 Prompt（Prompt 主表 deleted=true 但 prompt_version 未级联删除）** | ✅ **已决策**: 允许查 diff | 软删除的 Prompt 下的版本仍然可查 diff，方便团队回溯已下线的 Prompt 的历史变更 |
| 8 | **versionA 比 versionB 晚创建（用户传入顺序颠倒）** | 基于代码推断 | 严格按 versionA=基准、versionB=对比。不自动按时间排序 |
| 9 | **并发场景：diff 查询期间版本被删除** | 基于代码推断 | 第二次查询不到则提示版本不存在 |
| 10 | **MySQL 默认大小写不敏感（utf8mb4_general_ci），version "v1" = "V1"** | ✅ **已决策**: 不在应用层 toLowerCase | version 大小写比较依赖 DB 层的 collation。查询参数原样传入 SQL，不额外做大小写处理 |
| 11 | **modelConfig 格式不兼容（旧版本 schema 不同导致 JSON parse 失败）** | 基于代码推断 | modelConfig.hasChanges=true 但 diff 为空，summary 注明"格式不兼容" |
| 12 | **variables JSON 嵌套对象** | 基于代码推断 | 仅做一层深度对比（根级 key），嵌套对象整值替换标记 |

### 4.2 性能边界决策

| # | 决策 | 说明 |
|---|------|------|
| 🔒 | **不加缓存层** | diff 每次实时计算，不引入 Redis/本地缓存。当前 prompt_version 表数据量预估 < 10 万条，2 次索引查询性能足够。后续如有性能问题再考虑缓存 |
| 🔒 | **不限制单次 diff 版本跨度** | v1 vs v100 和 v99 vs v100 开销相同（都只查 2 条记录），无需限制

---

## 5. 老项目约束

> 来源：`CLAUDE.md` 第 6 节（禁区）、第 7 节（历史包袱）。当前两节均为空模板，暂无硬性约束。以下为基于现有代码模式推断的约束。

| # | 约束 | CLAUDE.md 来源 |
|---|------|----------------|
| 1 | **API 前缀必须为 `/api`** | CLAUDE.md §4："评估实验 `/api/`"。Prompt 模块属于评估实验域 |
| 2 | **返回格式必须使用 `Result<T>`** | 扫描确认：`PromptController` 所有非流式接口均用 `Result<T>` 包裹 |
| 3 | **version 字段格式必须符合 `@Pattern(regexp = "^[a-zA-Z0-9._-]+$")`** | 来自 `PromptVersionDO.version` 的已有校验 |
| 4 | **异常必须使用 `StudioException`** | 扫描确认：`PromptVersionServiceImpl` 统一用 `StudioException.CONFLICT` / `NOT_FOUND` / `INVALID_PARAM` |
| 5 | **不修改 prompt 和 prompt_version 表结构** | CLAUDE.md §6（禁区）虽为空，但新增功能应尽量不修改已有表。diff 是纯读操作，不涉及表变更 |
| 6 | **不修改 prompt_version.status 状态机** | 现有 pre→release 状态机逻辑已有复杂度（pre 覆盖更新、release 不可变）。diff 接口不触碰状态变更 |
| 7 | **不引入新的持久化存储** | diff 结果实时计算，不入库。避免增加`prompt_version_diff`等新表 |
| 8 | **分页风格对齐 `PageResult<T>`** | 如果后续版本列表要加 diff 入口，分页参数对齐 `pageNo/pageSize` |

---

## 6. 不在这次范围里的事

### 6.1 ❌ 砍掉（9 条）

| # | 候选 | 砍掉理由 |
|---|------|----------|
| 1 | **后端生成 unified diff 格式化输出** | 前端自行渲染。后端只返回逐行/逐键差异数据（segments 数组），不做 `+/-` 格式化 |
| 2 | **跨 promptKey 对比** | 场景极小（用户不会在"客服Prompt"和"翻译Prompt"之间做对比） |
| 3 | **N 版本并行对比（3+ side-by-side）** | 前端复杂度高。需要时多次调用两两对比即可 |
| 4 | **diff 结果缓存** | 已决策不加缓存，每次实时计算（见 §4.2） |
| 5 | **基于 diff 的版本回滚** | 涉及状态机修改，属于禁区范畴 |
| 6 | **语义级 diff（调用 LLM 分析 prompt 语义差异）** | 成本和延迟不可控，LLM 输出不稳定 |
| 7 | **Nacos 同步 diff（本地版本 vs Nacos 已发布版本）** | Nacos 仅同步 release 版本的 template + variables（不含 modelConfig），对比维度不完整 |
| 8 | **versionDescription 的逐字 diff** | `versionDesc` 是人工填写的自由文本摘要（如"调整了语气参数"），不是结构化字段。只做透传展示，不参与 diff 计算。版本描述的变化本身不是工程师关注的核心差异 |
| 9 | **权限控制** | 本期不做接口级权限校验。diff 是纯读操作，不修改任何数据。权限控制依赖现有的 Controller 层认证机制即可 |

### 6.2 📋 留到下期（2 条）

| # | 候选 | 下期理由 |
|---|------|----------|
| 1 | **diff 结果导出（支持 JSON / Markdown / PDF）** | 团队 review 需要离线分享 diff 结果。但核心 diff 能力先做完，导出是增强 |
| 2 | **一键对比上一版本（快捷参数 `?versionB=latest` 或单独端点）** | 最高频场景是"和上一版比"。本次先支持显式传 versionA+B，下期加便捷接口 |

---

## 📎 附录：涉及文件

| 文件 | 角色 |
|------|------|
| `PromptController.java` | 新增 diff 端点 |
| `PromptVersionDO.java` | 数据源，两个版本独立查询 |
| `PromptVersionServiceImpl.java` | 新增 `diffVersions()` 方法 |
| `docs/api-list.md` §17 | 接口清单更新（新增 1 条） |
| `docs/data-model.md` §25 | 无需修改（不涉及表结构变更） |
