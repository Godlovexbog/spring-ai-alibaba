---
path: "**/service/**/*Service*.java"
---

# Service 层规范

## 接口定义

放在 `server-core` 的 `.../service/` 包下：

```java
public interface AppService {
    String createApp(Application application);
    void updateApp(Application application);
    Application getApp(String appId);
    PagingList<Application> listApps(AppQuery query);
}
```

## 实现类

放在 `.../service/impl/` 包下：

```java
@Service
public class AppServiceImpl
        extends ServiceImpl<AppMapper, AppEntity>   // 继承 MyBatis-Plus ServiceImpl
        implements AppService {

    @Override
    @Transactional(rollbackFor = Exception.class)   // 写操作必须加
    public String createApp(Application application) {
        try {
            // 校验
            if (StringUtils.isBlank(application.getName())) {
                throw new BizException(ErrorCode.MISSING_PARAMS.toError("name"));
            }
            // 持久化
            AppEntity entity = convertToEntity(application);
            entity.setGmtCreate(new Date());
            this.save(entity);
            return entity.getAppId();
        } catch (BizException e) {
            throw e;                                // BizException 直接透传
        } catch (Exception e) {
            throw new BizException(ErrorCode.CREATE_APP_ERROR.toError(), e);
        }
    }
}
```

## 规则

| 规则 | 说明 |
|------|------|
| 继承 | **数据持久化类** ServiceImpl 必须 `extends ServiceImpl<Mapper, Entity>` 获得内置 CRUD；**编排类** ServiceImpl（如 AgentService）直接 `implements` 接口 |
| 事务 | **写操作**方法加 `@Transactional(rollbackFor = Exception.class)`；读操作不加 |
| 异常 | `try { ... } catch (BizException e) { throw e; } catch (Exception e) { throw new BizException(...) }` |
| 日志 | 操作入口用 `LogUtils.monitor()` 记链路；异常用 `log.error("xxx", e)` |
| 审计 | `gmtCreate` / `creator` 在插入时手动赋值；`gmtModified` / `modifier` 在更新时手动赋值 |
| 输入 | 接收 DTO / domain 对象，**不** 直接接收 Entity |
| 输出 | 返回 DTO / domain 对象，**不** 直接返回 Entity（转换逻辑可放 private 方法或工具类） |

## 禁止事项

- ❌ 写操作不加 `@Transactional`
- ❌ 吞异常不抛（`catch (Exception e) { log.error(...); return null; }`）
- ❌ 直接暴露 Entity 给 Controller