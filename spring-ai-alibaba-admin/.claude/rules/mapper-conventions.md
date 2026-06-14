---
path: "**/mapper/**/*Mapper.java"
---

# Mapper 层规范

## 完整示例

```java
public interface AppMapper extends BaseMapper<AppEntity> {
}
```

## 规则

| 规则 | 说明 |
|------|------|
| 继承 | `extends BaseMapper<Entity>`，无需额外方法 |
| 复杂查询 | 在 ServiceImpl 中用 `LambdaQueryWrapper` / `LambdaUpdateWrapper` / `Page` 完成 |
| XML | **不使用** MyBatis XML 映射文件 |

## 查询范式（在 ServiceImpl 中使用）

```java
// 分页查询
Page<AppEntity> page = new Page<>(query.getCurrent(), query.getSize());
LambdaQueryWrapper<AppEntity> qw = new LambdaQueryWrapper<>();
qw.eq(AppEntity::getWorkspaceId, context.getWorkspaceId())
  .ne(AppEntity::getStatus, CommonStatus.DELETED.getStatus())
  .like(StringUtils.isNotBlank(query.getName()), AppEntity::getName, query.getName())
  .orderByDesc(AppEntity::getId);
IPage<AppEntity> result = this.page(page, qw);
```

## 禁止事项

- ❌ Mapper 中写自定义 SQL 方法（非必要不写，优先用 LambdaQueryWrapper）
- ❌ 在 Mapper 接口中写 `@Select` / `@Update` 注解
- ❌ 创建 MyBatis XML 文件