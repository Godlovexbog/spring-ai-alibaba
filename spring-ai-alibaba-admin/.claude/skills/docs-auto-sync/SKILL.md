---
name: docs-auto-sync
description: >
  代码变更后自动同步 docs/ 下的技术文档资产（架构图、依赖图、接口清单、数据模型、ER 图）。
  检测 git diff 中 pom.xml / Entity / Controller / application.yml 的变更，增量更新受影响文档。
---

# docs-auto-sync — 技术文档自动同步

## 触发时机

- 用户说 "sync docs"、"更新文档"、"同步文档资产"
- 完成一轮代码变更后，用户要求刷新文档
- 作为 entity-crud-generator 的后置步骤自动触发

## 检查清单

- [ ] `git diff --name-only` 确定变更范围
- [ ] 变更涉及 pom.xml → 重建 external-deps.svg
- [ ] 变更涉及 Entity 或 DDL → 重建 data-model.md + data-model-er.svg
- [ ] 变更涉及 Controller → 重建 api-list.md
- [ ] 变更涉及模块结构 → 重建 architecture.svg + module-deps.svg
- [ ] 变更涉及 application.yml / docker-compose → 重建 external-deps.svg
- [ ] `api-model-alignment-check` 验证接口和数据模型一致性
- [ ] 输出变更摘要：更新了哪些文件，哪些资产未受影响

## 核心规则

### 1. 增量更新，不做全量重建

第一步先用 `git diff --name-only HEAD~1` 或对比当前工作区，**只重建受影响的文档**。如果无法确定影响范围（如初次运行），则全量扫描。

### 2. 变更→资产映射表

| 变更文件模式 | 影响的文档资产 |
|-------------|---------------|
| `**/pom.xml` | `external-deps.svg`（依赖图） |
| `**/entity/*.java` | `data-model.md` + `data-model-er.svg` |
| `**/sql/*.sql` | `data-model.md`（对照 DDL） |
| `**/controller/*.java` | `api-list.md`（接口清单） |
| `**/application*.yml` | `external-deps.svg`（中间件配置变更） |
| `**/docker-compose*.yaml` | `external-deps.svg`（中间件配置变更） |
| 新增/删除模块 | `architecture.svg` + `module-deps.svg` |

### 3. 文档生成标准

每类文档的生成方式参考 `human/` 目录下的对应提示词模板：

| 文档 | 参考提示词 | 关键注意事项 |
|------|-----------|-------------|
| `architecture.svg` | `1-全景图/1-架构图.txt` | 四层分层（前端/后端/中间件/数据），核心模块写职责，周边基础设施方框概括 |
| `module-deps.svg` | `1-全景图/2-模块依赖图.txt` | 只画项目自己的模块，外部库不画，循环依赖标红 |
| `external-deps.svg` | `1-全景图/3-外部依赖图.txt` | 三类分色：Java 依赖（蓝）、中间件（黄）、外部API（绿），砍掉 transitives |
| `api-list.md` | `2-接口与数据模型/1-REST 接口清单txt` | 按 Controller 分组，标注 HTTP 方法和路径 |
| `data-model.md` | `2-接口与数据模型/2-数据模型.txt` | Entity + DTO + DDL 三边对照，标 PK/FK/枚举 |
| `data-model-er.svg` | `2-接口与数据模型/2-数据模型.txt` | ER 表形状，颜色分域 |

### 4. 输出格式

生成完成后，打印变更摘要：

```
📐 docs-auto-sync 变更摘要
━━━━━━━━━━━━━━━━━━━━━━━━
检测到变更：3 个 Entity、2 个 Controller

✅ 已更新：
  - docs/data-model.md（新增 DocumentChunk 实体字段）
  - docs/data-model-er.svg（重新生成）
  - docs/api-list.md（新增 2 个接口）
⏭️ 未受影响：
  - docs/architecture.svg
  - docs/module-deps.svg
  - docs/external-deps.svg
```

### 5. 完成后必做

- [ ] 调用 `api-model-alignment-check` 验证一致性
- [ ] 清理中间 .drawio 文件（只保留 .svg）
- [ ] 更新 CLAUDE.md 的文档索引（如果新增了资产文件）

## allowed-tools

- `Bash: git diff / find / grep / ls` — 检测变更范围
- `Read` — 读取源代码文件（Entity/Controller/pom.xml/yml）
- `Write / Edit` — 写入/更新 docs/*.md 和 docs/*.drawio
- `Bash: /Applications/draw.io.app/Contents/MacOS/draw.io` — 导出 SVG
- `TaskCreate / TaskUpdate` — 跟踪多资产生成进度
