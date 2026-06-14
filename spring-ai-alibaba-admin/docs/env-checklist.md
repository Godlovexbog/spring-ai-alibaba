# Spring AI Alibaba Admin — 环境依赖盘点

> 数据来源：pom.xml · application*.yml · docker-compose*.yaml · README · docs/external-deps.svg

## 一、运行时环境

| 依赖 | 版本要求 | 默认端口 | 连接信息 | 初始化要求 |
|------|----------|----------|----------|------------|
| **JDK** | **17+** | — | `java --version` 确认 | 安装 OpenJDK 17 或 GraalVM 17 |
| **Maven** | **3.8+** | — | `mvn --version` 确认 | 配置 `settings.xml`（如需私服） |
| **Node.js** | LTS（前端） | 5173（Vite dev） | 前端在 `frontend/` 目录 | `npm install` |

---

## 二、中间件（Docker Compose 一键启动）

### 2.1 必选中间件

| 依赖 | 版本 | 默认端口 | 连接信息 | 初始化要求 |
|------|------|----------|----------|------------|
| **MySQL** | **8.0** | **3306** | `jdbc:mysql://{host}:3306/admin` | ① 创建数据库 `admin`（`CREATE DATABASE admin`）② 执行 `docker/middleware/init/mysql/admin-schema.sql` 建表 ③ 用户名/密码配置在 `SPRING_DATASOURCE_USERNAME/PASSWORD` |
| **Redis** | **7.x** | **6379** | `redis://{host}:6379` | ① 默认 database 0 ② 无需预建数据 ③ Redisson 客户端自动连接 |
| **Nacos** | **latest** | **8848**（HTTP）**9848**（gRPC） | `nacos.server-addr={host}:8848` | ① standalone 模式启动 ② 默认命名空间 public ③ 如用 A2A 需注册服务 |
| **Elasticsearch** | **9.x** | **9200**（REST）**9300**（内部） | `http://{host}:9200` | ① `discovery.type=single-node` ② 关闭安全：`xpack.security.enabled=false` ③ 执行 `docker/middleware/init/elasticsearch/init-indices.sh` 创建索引 |

### 2.2 可选中间件

| 依赖 | 版本 | 默认端口 | 连接信息 | 初始化要求 |
|------|------|----------|----------|------------|
| **RocketMQ** | **5.x** | **9876**（NameSrv）**10911**（Broker）**18080**（Proxy） | `rocketmq.endpoints={host}:18080` | ① 启动 NameSrv + Broker + Proxy ② 创建 Topic：`topic_saa_studio_document_index` ③ 创建 ConsumerGroup：`group_saa_studio_document_index` |
| **LoongCollector** | **3.x** | **4318**（OTLP HTTP） | `management.otlp.tracing.endpoint=http://{host}:4318/v1/traces` | ① 依赖 ES 先启动 ② 配置文件在 `docker/middleware/conf/loongcollector/` |
| **Kibana** | **9.x** | **5601** | `http://{host}:5601` | ① 依赖 ES 先启动 ② 用于开发环境 Trace 可视化 |

### 2.3 一键启动

```bash
# 启动全部中间件（MySQL + Redis + ES + Nacos + RocketMQ + LoongCollector + Kibana）
cd docker/middleware
docker compose -f docker-compose-prod.yaml up -d

# 仅启动开发环境（MySQL）
docker compose -f docker-compose-dev.yaml up -d
```

---

## 三、外部 API / 云服务

### 3.1 大模型 API（至少配置一个）

| 依赖 | 版本要求 | 接入方式 | 连接信息 | 初始化要求 |
|------|----------|----------|----------|------------|
| **DashScope**（阿里云百炼） | — | API Key | `https://dashscope.aliyuncs.com/compatible-mode` | ① 获取 API Key：https://bailian.console.aliyun.com ② 配置 `DASHSCOPE_API_KEY` 环境变量 ③ 参考 `model-config-dashscope.yaml` |
| **OpenAI** | — | API Key | `https://api.openai.com/v1` | ① 获取 API Key：https://platform.openai.com ② 配置 `OPENAI_API_KEY` 环境变量 ③ 参考 `model-config-openai.yaml` |
| **DeepSeek** | — | API Key | DeepSeek API 端点 | ① 获取 API Key ② 配置 `DEEPSEEK_API_KEY` 环境变量 ③ 参考 `model-config-deepseek.yaml` |
| **Ollama** | — | 本地服务 | `http://{host}:11434` | ① 安装 Ollama ② `ollama pull {model}` 拉取模型 ③ 无需 API Key |

### 3.2 阿里云服务（可选）

| 依赖 | 版本要求 | 接入方式 | 连接信息 | 初始化要求 |
|------|----------|----------|----------|------------|
| **Aliyun OSS** | — | AccessKey | SDK 自动连接 | ① 开通 OSS 服务 ② 创建 Bucket ③ 配置 AccessKey ID/Secret |
| **ARMS**（应用实时监控） | — | AccessKey | SDK 自动上报 | ① 开通 ARMS 服务 ② 引入 `spring-ai-alibaba-autoconfigure-arms-observation` |

---

## 四、应用配置环境变量清单

启动应用前需要设置的环境变量（通过 `application.yml` 中的 `${...}` 占位符提取）：

### 4.1 必设

```bash
# MySQL
export SPRING_DATASOURCE_URL=jdbc:mysql://localhost:3306/admin?useUnicode=true&characterEncoding=utf-8&useSSL=false&serverTimezone=Asia/Shanghai
export SPRING_DATASOURCE_USERNAME=admin
export SPRING_DATASOURCE_PASSWORD=admin

# Redis
export SPRING_REDIS_HOST=localhost
export SPRING_REDIS_PORT=6379
export SPRING_REDIS_DATABASE=0

# Nacos
export NACOS_SERVER_ADDR=localhost:8848
```

### 4.2 按需设置

```bash
# Elasticsearch（如果不用 RAG 可跳过）
export SPRING_ELASTICSEARCH_URIS=http://localhost:9200

# RocketMQ（如果不用异步文档索引可跳过）
export ROCKETMQ_ENDPOINTS=localhost:18080
export ROCKETMQ_DOCUMENT_INDEX_TOPIC=topic_saa_studio_document_index
export ROCKETMQ_DOCUMENT_INDEX_GROUP=group_saa_studio_document_index

# OpenTelemetry（如果不用链路追踪可跳过）
export MANAGEMENT_OTLP_TRACING_EXPORT_ENDPOINT=http://localhost:4318/v1/traces

# 大模型 API Key（至少设一个）
export DASHSCOPE_API_KEY=your-key
export OPENAI_API_KEY=your-key
export DEEPSEEK_API_KEY=your-key
```

---

## 五、端口占用速查

```
3306  MySQL
6379  Redis
8848  Nacos HTTP
9848  Nacos gRPC
9200  Elasticsearch REST
9300  Elasticsearch 内部
5601  Kibana
9876  RocketMQ NameSrv
10911 RocketMQ Broker
18080 RocketMQ Proxy
4318  LoongCollector OTLP
11434 Ollama（可选）
8080  应用端口（Spring Boot 默认）
5173  前端 Vite Dev Server
```

---

## 六、初始化检查清单

部署新环境时按顺序执行：

- [ ] JDK 17+ 已安装
- [ ] Maven 3.8+ 已安装
- [ ] Docker + Docker Compose 已安装
- [ ] 中间件已启动（`docker compose up -d`）
- [ ] `docker ps` 确认所有容器 healthy
- [ ] MySQL 数据库 `admin` 已创建
- [ ] MySQL schema 已导入（`admin-schema.sql`）
- [ ] Elasticsearch 索引已创建（`init-indices.sh`）
- [ ] RocketMQ Topic `topic_saa_studio_document_index` 已创建
- [ ] Nacos 可访问 `http://localhost:8848/nacos`
- [ ] 至少一个模型 API Key 已配置
- [ ] 环境变量已设置（见第四节）
- [ ] `mvn spring-boot:run` 启动成功
- [ ] `curl http://localhost:8080/console/v1/system/health` 返回 200
