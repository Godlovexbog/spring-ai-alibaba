---
paths:
  - "**/entity/**/*Entity.java"
  - "**/entity/**/*DO.java"
---

# Entity 层规范

## 完整示例

```java
@Data
@TableName("application")
public class AppEntity {
    @TableId(value = "id", type = IdType.AUTO)
    private Long id;

    @TableField("app_id")
    private String appId;

    @TableField("workspace_id")
    private String workspaceId;

    private String name;
    private String description;
    private AppType type;            // 枚举，MyBatis-Plus 默认存 name()
    private CommonStatus status;

    @TableField("gmt_create")
    private Date gmtCreate;

    @TableField("gmt_modified")
    private Date gmtModified;

    private String creator;
    private String modifier;

    @TableField(exist = false)       // 非数据库字段
    private AppVersionEntity latestVersion;
}
```

## 规则

| 规则 | 说明 |
|------|------|
| 类注解 | `@Data` + `@TableName("table_name")`，表名用 snake_case |
| 主键 | `@TableId(value = "id", type = IdType.AUTO)` 自增 Long；业务 ID 另存为独立字段（如 `appId`） |
| 字段映射 | 仅当列名 ≠ 字段名时才加 `@TableField("column_name")` |
| 审计字段 | 每个表必须包含 `gmtCreate` / `gmtModified` / `creator` / `modifier` |
| 非持久化 | 用 `@TableField(exist = false)` |
| 逻辑删除 | **不用** `@TableLogic`，通过 `status = DELETED` + 查询时 `.ne(Entity::getStatus, DELETED)` 实现 |
| 枚举 | 字段类型直接用枚举类，MyBatis-Plus 默认存 `name()` 字符串 |
| 序列化 | 如需跨模块传输，实现 `Serializable` |

## 禁止事项

- ❌ 用 UUID / 雪花算法做主键（统一用自增 Long + IdType.AUTO）
- ❌ 使用 MyBatis-Plus 自动填充审计字段（`@TableField(fill = ...)`，项目未开启）
- ❌ 在 Entity 中写业务逻辑