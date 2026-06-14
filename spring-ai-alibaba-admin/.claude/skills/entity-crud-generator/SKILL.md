---
name: entity-crud-generator
description: >
  参数化输入表定义（表名/字段/枚举/模块），生成 MyBatis Plus Entity + DTO（Request/Response）
  + Controller（CRUD 全套） + DDL（CREATE TABLE）。遵循项目约定。
---

# entity-crud-generator — 数据库实体全栈代码生成

## 触发时机

- 用户说 "新建一张表"、"添加实体"、"generate entity"
- 用户提供表名 + 字段列表 + 枚举
- 作为 docs-auto-sync 的前置步骤触发

## 输入参数

用户需要提供以下信息（缺少则询问）：

| 参数 | 必填 | 示例 | 说明 |
|------|------|------|------|
| `tableName` | ✅ | `user_profile` | 数据库表名（snake_case） |
| `entityName` | ✅ | `UserProfile` | Entity 类名（PascalCase） |
| `module` | ✅ | `builder` | `builder`（/console/v1/）或 `evaluation`（/api/） |
| `fields` | ✅ | 见下方 | 字段列表 |
| `enums` | ❌ | 见下方 | 关联的枚举定义 |

### 字段格式

```
字段名:类型:约束:说明
例：
username:VARCHAR(100):NOT NULL:用户名
status:INT:DEFAULT 1:状态
workspace_id:VARCHAR:FK→workspace:所属工作空间
```

### 枚举格式

```
枚举类名:字段名:值列表
例：
UserStatus:status:0=DELETED, 1=NORMAL, 2=DISABLED
```

## 检查清单

- [ ] 确认模块包路径（builder: `admin/builder/` vs evaluation: `admin/`）
- [ ] 确认 API 前缀（builder: `/console/v1/` vs evaluation: `/api/`）
- [ ] 生成 Entity 类
- [ ] 生成 DTO（CreateRequest + UpdateRequest + Response）
- [ ] 生成 Controller（CRUD 8 个标准接口）
- [ ] 生成 DDL（CREATE TABLE）
- [ ] 追加到 docs/data-model.md
- [ ] 输出所有生成文件路径

## 核心规则

### 1. Entity 生成规则

```java
// 文件路径：server-core/src/main/java/.../entity/{EntityName}Entity.java
@Data
@TableName("{table_name}")
public class {EntityName}Entity {

    @TableId(value = "id", type = IdType.AUTO)
    private Long id;  // 主键永远是 id BIGINT AUTO_INCREMENT

    // 对于 FK 字段：
    @TableField("{fk_column}")
    private String {fkField};  // FK→{referencedTable}

    // 对于业务唯一ID字段：
    @TableField("{id_column}")
    private String {idField};  // 业务ID

    // 对于枚举字段：
    private {EnumType} {field};  // 枚举值说明

    // 审计字段（Builder 模块）：
    @TableField("gmt_create")
    private Date gmtCreate;
    @TableField("gmt_modified")
    private Date gmtModified;
    private String creator;
    private String modifier;

    // 审计字段（Evaluation 模块，JPA）：
    private LocalDateTime createTime;
    private LocalDateTime updateTime;
}
```

### 2. DTO 生成规则

**CreateRequest：** 只包含必填字段 + 业务字段，不含 id 和审计字段。
**UpdateRequest：** 包含 id + 所有可更新字段。
**Response：** 包含所有字段（含 id 和审计字段）。

文件路径：`server-runtime/src/main/java/.../domain/{domain}/`

### 3. Controller 生成规则

```java
@RestController
@RequestMapping("{prefix}/{resource}")  // builder: /console/v1/{resources}
@RequiredArgsConstructor               // evaluation: /api/{resource}
public class {EntityName}Controller {

    // 标准 CRUD：
    @PostMapping("/")          // 创建
    @PutMapping("/{id}")       // 更新
    @DeleteMapping("/{id}")    // 删除
    @GetMapping("/{id}")       // 获取详情
    @GetMapping("/")           // 分页查询
}
```

### 4. DDL 生成规则

```sql
CREATE TABLE IF NOT EXISTS {table_name} (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    {field} {type} {constraints},
    ...
    -- FK：CONSTRAINT fk_{table}_{ref} FOREIGN KEY({col}) REFERENCES {ref_table}({ref_col}) ON DELETE CASCADE
    -- UNIQUE：UNIQUE KEY uk_{table}_{col}({col})
    -- INDEX：KEY idx_{table}_{col}({col})
    -- 审计字段（Builder）：
    gmt_create DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    gmt_modified DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    -- 或（Evaluation）：
    create_time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    update_time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
```

### 5. 自动注入规则

以下字段**永远自动添加**，用户不需要在输入参数中显式提供：

| 自动注入 | 条件 | 字段 |
|----------|------|------|
| 主键 | 永远 | `id BIGINT AUTO_INCREMENT PK` |
| 审计字段 | Builder 模块 | `gmt_create`, `gmt_modified`, `creator`, `modifier` |
| 审计字段 | Evaluation 模块 | `create_time`, `update_time` |
| 逻辑删除 | Evaluation 模块（dataset/evaluator/model_config） | `deleted TINYINT DEFAULT 0` |
| 业务ID | 如果实体需要对外暴露 | `{entity}_id VARCHAR` |

### 6. 完成后必做

- [ ] 更新 `docs/data-model.md`（追加新实体章节）
- [ ] 调用 `docs-auto-sync` 同步受影响的文档资产
- [ ] 告知用户实体在 Controller/DTO/Entity/DDL 的文件路径

## allowed-tools

- `Read` — 读取现有 Entity 作为模板参考、读取 data-model.md
- `Write` — 写入 Entity.java / DTO.java / Controller.java / DDL.sql
- `Edit` — 向 data-model.md 追加新实体章节
- `Bash: find` — 确定模块包路径
- `Skill: docs-auto-sync` — 触发生成的文档同步
