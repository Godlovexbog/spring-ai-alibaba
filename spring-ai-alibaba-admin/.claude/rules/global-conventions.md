---
---

# 全局约定

> **规则优先级**：本规范 > 个人习惯。所有新增/修改代码必须符合本节约定。如发现现有代码不符合规范，优先对齐本节约定。

| 类别 | 约定 |
|------|------|
| JDK | Java 17+，推荐使用 records、switch 表达式、text blocks |
| Lombok | `@Data`、`@Builder`、`@AllArgsConstructor`、`@NoArgsConstructor` |
| 日志 | SLF4J（`log.info/warn/error`），禁止 `System.out.println`。链路日志用 `LogUtils.monitor()` |
| 异常 | 统一用 `BizException(ErrorCode.XXX.toError(...))` 抛出业务异常，由全局 `@ControllerAdvice` 兜底转为 `Result.error()` |
| 返回值 | 所有 Controller 方法返回 `Result<T>`（定义在 `server-runtime`） |
| 许可证 | Apache 2.0 头，`make licenses-check` 验证 |
| 序列化 | 所有 DTO / domain 对象实现 `Serializable` |