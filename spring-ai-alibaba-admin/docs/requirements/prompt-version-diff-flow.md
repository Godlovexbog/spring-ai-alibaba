# Prompt 版本对比 — 改造流程图

> 基于 `docs/requirements/prompt-version-diff.md` 需求定稿 + `prompt-version-diff-impact.md` 改造点清单

## 一、完整调用链（sequenceDiagram）

```mermaid
sequenceDiagram
    actor User as 👤 用户
    participant UI as 🖥️ DiffModal.tsx
    participant API as 📡 prompt/index.ts
    participant Ctrl as 🎮 PromptController
    participant Svc as ⚙️ PromptVersionServiceImpl
    participant Calc as 🔧 DiffCalculator
    participant Mapper as 🗄️ PromptVersionMapper
    participant DB as 🗄️ prompt_version 表

    User->>UI: 在版本列表选 v3 和 v5，点"对比"
    UI->>API: getPromptVersionDiff({promptKey, versionA:"v3", versionB:"v5"})
    API->>Ctrl: GET /api/prompt/version/diff?promptKey=cs_prompt&versionA=v3&versionB=v5

    rect rgb(255,245,238)
        Note over Ctrl: 参数校验
        Ctrl->>Ctrl: @Validated: promptKey not blank<br/>versionA ≠ versionB
        alt 校验失败
            Ctrl-->>API: Result.error(INVALID_PARAM)
            API-->>UI: 400 错误提示
        end
    end

    Ctrl->>Svc: diffVersions(PromptVersionDiffRequest)

    rect rgb(240,255,240)
        Note over Svc,DB: 两次独立查询
        Svc->>Mapper: selectByPromptKeyAndVersion("cs_prompt", "v3")
        Mapper->>DB: SELECT * FROM prompt_version<br/>WHERE prompt_key='cs_prompt' AND version='v3'
        DB-->>Mapper: PromptVersionDO{tpl:"你是一个客服助手", ...}
        Mapper-->>Svc: versionA DO
        Svc->>Mapper: selectByPromptKeyAndVersion("cs_prompt", "v5")
        Mapper->>DB: SELECT * FROM prompt_version<br/>WHERE prompt_key='cs_prompt' AND version='v5'
        DB-->>Mapper: PromptVersionDO{tpl:"你是一个专业客服...", ...}
        Mapper-->>Svc: versionB DO
        alt versionA 或 versionB 为 null
            Svc-->>Ctrl: throw StudioException.NOT_FOUND
            Ctrl-->>API: Result.error(NOT_FOUND, 404)
        end
    end

    rect rgb(255,250,240)
        Note over Svc,Calc: 内容 diff 计算
        Svc->>Calc: textDiff(tplA, tplB)
        Calc-->>Svc: [{unchanged:"..."},{added:"..."}]
        Svc->>Calc: jsonDiff(varsA, varsB)
        Calc-->>Svc: {addedKeys:[], removedKeys:[], changedKeys:[]}
        Svc->>Calc: jsonDiff(modelA, modelB)
        Calc-->>Svc: {addedKeys:[], removedKeys:[], changedKeys:[]}
    end

    rect rgb(245,240,255)
        Note over Svc: 组装响应
        Svc->>Svc: PromptDiffResponse.builder()<br/>.versionA({version,status,creator,createdAt,desc})<br/>.versionB({...})<br/>.diff(template+variables+modelConfig)<br/>.summary("template:+2-1行; variables:无变更")<br/>.build()
    end

    Svc-->>Ctrl: PromptDiffResponse
    Ctrl-->>API: Result&lt;PromptDiffResponse&gt; (200)
    API-->>UI: JSON response
    UI-->>User: 🔍 渲染 diff 弹窗：<br/>绿色=新增行, 红色=删除行<br/>variables 键变更表格
```

## 二、数据流：入参 → 中间态 → 返回

```mermaid
flowchart LR
    subgraph 入参
        A1["promptKey='cs_prompt'"]
        A2["versionA='v3'"]
        A3["versionB='v5'"]
    end

    subgraph 中间态["中间态 (DO)"]
        B1["PromptVersionDO<br/>version=v3, status=release<br/>creator=zhangsan<br/>template='你是一个客服助手'<br/>variables='{\"name\":\"user\"}'<br/>modelConfig='{\"temp\":0.7}'"]
        B2["PromptVersionDO<br/>version=v5, status=pre<br/>creator=lisi<br/>template='你是一个专业客服...'<br/>variables='{\"name\":\"user\",\"level\":\"vip\"}'<br/>modelConfig='{\"temp\":0.7}'"]
    end

    subgraph Diff计算["DiffCalculator 计算"]
        C1["textDiff → 4 segments<br/>(1 unchanged, 1 removed, 2 added)"]
        C2["jsonDiff → 1 addedKey(level)<br/>jsonDiff → 0 changedKeys"]
        C3["jsonDiff → 无变更"]
    end

    subgraph 返回["PromptDiffResponse"]
        D1["versionA: {v3, release, zhangsan, 2026-05-01}<br/>versionB: {v5, pre, lisi, 2026-06-10}"]
        D2["diff.template: hasChanges=true, +2 -1<br/>diff.variables: hasChanges=true, +1键<br/>diff.modelConfig: hasChanges=false"]
        D3["summary: 'template: +2-1行; variables: +1键(level)'"]
    end

    A1 & A2 & A3 -->|"Mapper.selectByPromptKeyAndVersion ×2"| B1 & B2
    B1 & B2 -->|"DiffCalculator.textDiff / jsonDiff"| C1 & C2 & C3
    C1 & C2 & C3 -->|"组装元信息 + 生成 summary"| D1 & D2 & D3
```

## 三、表结构 —— 不改表

```
┌─────────────────────────────────────────────────────────────┐
│                    ⚠️ 本次改造不改表                          │
│                                                             │
│  prompt_version 表结构完全不变。diff 是纯读操作：              │
│  - 复用现有 selectByPromptKeyAndVersion() 查询               │
│  - 走现有 (prompt_key, version) 联合索引                     │
│  - 不新增列（不存 diff 结果）                                │
│  - 不新增表（如 prompt_version_diff）                        │
│  - 不修改索引                                               │
│                                                             │
│  prompt_version 现有结构（不变）：                             │
│  ┌─────────────────────────────────────────────────────┐    │
│  │ id           BIGINT PK AUTO_INCREMENT              │    │
│  │ version      VARCHAR(32)                           │    │
│  │ prompt_key   VARCHAR(255)  ── 联合索引 (prompt_key, │    │
│  │ version_desc VARCHAR(255)       version)            │    │
│  │ template     LONGTEXT                              │    │
│  │ variables    VARCHAR                               │    │
│  │ model_config VARCHAR                               │    │
│  │ status       VARCHAR(32)   pre | release           │    │
│  │ create_time  DATETIME(3)                           │    │
│  │ previous_version VARCHAR(32)                       │    │
│  └─────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────┘
```
