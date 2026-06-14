---
path: "**/*Version*.java"
---

# 版本管理规范

所有支持多版本的对象统一使用 `(parent_id, version)` 联合唯一约束：

| 对象 | 主表 | 版本表 |
|------|------|--------|
| 应用 | `application` | `application_version` |
| Prompt | `prompt` | `prompt_version` |
| 测评集 | `dataset` | `dataset_version` |
| 评估器 | `evaluator` | `evaluator_version` |

## 设计约定

- 主表存储当前版本引用，版本表存储历史版本快照
- 版本号递增，历史版本不可变（只读）
- 查询时默认返回最新版本，历史版本按需回溯
