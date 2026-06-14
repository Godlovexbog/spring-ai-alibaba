---
paths:
  - "**/model/**/*Request.java"
  - "**/model/**/*Response.java"
  - "**/dto/**/*.java"
  - "**/*Query.java"
  - "**/*DTO.java"
---

# DTO 层规范（Request / Response / Query）

## 命名规范

| 角色 | 命名格式 | 示例 | 所在模块 |
|------|---------|------|---------|
| 请求体 | `XxxRequest` | `DatasetCreateRequest`、`AppQuery` | `server-start` / `server-runtime` |
| 响应体 | `XxxResponse` | `TokenResponse`、`ModelConfigResponse` | `server-start` / `server-runtime` |
| 传输对象 | `XxxDTO` | `OverviewStatsDTO` | 各模块 |
| 分页查询 | `XxxQuery` | `AppQuery`、`ServicesQueryRequest` | `server-start` |

## 注解规范

```java
// ✅ 正确示例
@Data
public class DatasetCreateRequest implements Serializable {
    @NotNull
    private String name;

    @NotBlank(message = "数据集名称不能为空")
    @Size(max = 100, message = "数据集名称不能超过100个字符")
    private String displayName;

    @JsonProperty("columns_config")   // 出参 JSON 字段 snake_case
    private List<DatasetColumn> columnsConfig;
}
```

| 规则 | 说明 |
|------|------|
| `@Data` | 所有 DTO 必须加 |
| `implements Serializable` | 所有 DTO 必须加 |
| `@JsonProperty("snake_case")` | Java 用 camelCase → JSON 输出 snake_case |
| `jakarta.validation` | 校验注解统一用 Jakarta 包（`@NotNull`、`@NotBlank`、`@Size`、`@Pattern`），**禁止** 用 `javax.validation` |
| 校验 message | 必须写中文提示，方便前端展示 |
| `@Builder` | 仅需 Builder 模式的 Response 加（如 `TokenResponse`），Request 不加 |
| 文档 | 每个字段加 `/** */` JavaDoc，**不用** `@Schema` |

## 禁止事项

- ❌ Request 中使用 `@Builder`（与 JSON 反序列化冲突）
- ❌ 字段用 `javax.validation` 包
- ❌ 校验注解不加 `message`