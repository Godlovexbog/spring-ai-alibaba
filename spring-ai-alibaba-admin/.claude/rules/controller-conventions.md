---
path: "**/controller/**/*Controller.java"
---

# Controller 层规范

## 完整示例

```java
@RestController
@Tag(name = "dataset")                              // Swagger 标签
@RequestMapping("/api/dataset")                     // 类级别路径前缀
public class DatasetController {

    @PostMapping("/dataset")
    public Result<Dataset> createDataSet(
            @Validated @RequestBody DatasetCreateRequest request) {
        // 业务逻辑委托给 Service
        Dataset dataset = datasetService.createDataset(request);
        return Result.success(dataset);
    }

    @GetMapping("/dataset")
    public Result<PagingList<Dataset>> listDataSets(
            @Validated DatasetQuery query) {
        PagingList<Dataset> result = datasetService.listDataSets(query);
        return Result.success(result);
    }
}
```

## 规则

| 规则 | 说明 |
|------|------|
| 类注解 | `@RestController` + `@Tag(name = "xxx")` + `@RequestMapping("/prefix")`，**禁止** 只用 `@Controller` |
| API 前缀 | Builder：`/console/v1/`，Evaluation：`/api/`，OpenAPI：`/api/v1/apps` |
| 方法命名 | `createXxx` / `updateXxx` / `deleteXxx` / `getXxx` / `listXxx`，特殊操作取动词（`publishApp`、`copyApp`）|
| 参数校验 | 优先用 `@Validated` + `jakarta.validation` 注解自动校验；复杂业务校验在 Service 中 `throw new BizException()` |
| 返回值 | 全部返回 `Result.success(data)`，**不** 直接返回裸对象 |
| HTTP 动词 | POST 创建/更新、GET 查询、PUT 全量更新、DELETE 删除 |
| JavaDoc | 每个 public 方法必须有 |

## 禁止事项

- ❌ Controller 中写业务逻辑（只做参数收集 + 调用 Service + 组装 Result）
- ❌ try-catch 包整个方法（异常交给 `@ControllerAdvice`）
- ❌ 返回裸类型（`String`、`List<T>`、`void`）