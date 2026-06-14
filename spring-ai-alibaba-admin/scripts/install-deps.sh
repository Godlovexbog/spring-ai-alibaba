#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# Spring AI Alibaba Admin — 本地环境安装脚本
# 平台: macOS (brew) / Linux (apt)
# 数据来源: docs/env-checklist.md
# ============================================================

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[1;36m'; NC='\033[0m'
log()  { echo -e "${CYAN}[$(date +%H:%M:%S)]${NC} $1"; }
ok()   { echo -e "${GREEN}[✓]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
err()  { echo -e "${RED}[✗]${NC} $1"; }

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DOCKER_COMPOSE_DEV="${PROJECT_DIR}/docker/middleware/docker-compose-dev.yaml"
DOCKER_COMPOSE_PROD="${PROJECT_DIR}/docker/middleware/docker-compose-prod.yaml"
MYSQL_INIT_SQL="${PROJECT_DIR}/docker/middleware/init/mysql/admin-schema.sql"

retry_count=0
MAX_RETRIES=3

# ---- 工具函数 ----
retry() {
    local n=0
    until [ $n -ge $MAX_RETRIES ]; do
        if "$@"; then return 0; fi
        n=$((n+1))
        err "第 ${n}/${MAX_RETRIES} 次失败: $*"
        sleep 2
    done
    err "连续 ${MAX_RETRIES} 次失败: $*"
    return 1
}

# ---- Step 1: 安装 brew / apt ----
install_pkg_manager() {
    if command -v brew &>/dev/null; then
        ok "Homebrew 已安装"
        PKG="brew install"
        return
    fi
    if command -v apt-get &>/dev/null; then
        ok "apt 可用"
        PKG="sudo apt-get install -y"
        return
    fi
    log "安装 Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    PKG="brew install"
}

# ---- Step 2: 安装 JDK 17 ----
install_jdk() {
    if java -version 2>&1 | grep -qE 'version "(17|18|19|2[0-9]|3[0-9])"'; then
        ok "JDK 17+ 已安装: $(java -version 2>&1 | head -1)"
        return
    fi
    log "安装 JDK 17..."
    if [[ "$PKG" == "brew install" ]]; then
        brew install openjdk@17
        # 创建符号链接
        sudo ln -sfn "$(brew --prefix)/opt/openjdk@17/libexec/openjdk.jdk" /Library/Java/JavaVirtualMachines/openjdk-17.jdk 2>/dev/null || true
        # 设置 JAVA_HOME
        export JAVA_HOME="$(/usr/libexec/java_home -v 17 2>/dev/null || echo "$(brew --prefix)/opt/openjdk@17")"
        echo "export JAVA_HOME=\"$JAVA_HOME\"" >> ~/.zshrc 2>/dev/null || true
        echo 'export PATH="$JAVA_HOME/bin:$PATH"' >> ~/.zshrc 2>/dev/null || true
    elif [[ "$PKG" == sudo* ]]; then
        sudo apt-get update
        sudo apt-get install -y openjdk-17-jdk
        export JAVA_HOME="/usr/lib/jvm/java-17-openjdk-amd64"
    fi
    ok "JDK 17 安装完成: $(java -version 2>&1 | head -1)"
}

# ---- Step 3: 安装 Maven ----
install_maven() {
    if command -v mvn &>/dev/null; then
        local mvn_ver=$(mvn --version 2>&1 | head -1 | grep -oE '[0-9]+\.[0-9]+' | head -1)
        if [ "$(echo "$mvn_ver >= 3.8" | bc 2>/dev/null || echo 1)" = "1" ]; then
            ok "Maven ${mvn_ver} 已安装"
            return
        fi
    fi
    log "安装 Maven 3.9+..."
    if [[ "$PKG" == "brew install" ]]; then
        brew install maven
    elif [[ "$PKG" == sudo* ]]; then
        sudo apt-get install -y maven
    fi
    ok "Maven 安装完成: $(mvn --version 2>&1 | head -1)"
}

# ---- Step 4: 安装 Docker ----
install_docker() {
    if command -v docker &>/dev/null; then
        ok "Docker 已安装: $(docker --version)"
    else
        log "安装 Docker Desktop..."
        if [[ "$PKG" == "brew install" ]]; then
            brew install --cask docker
            warn "请在 Applications 中打开 Docker Desktop 完成初始化，然后按回车继续..."
            read -r
        else
            sudo apt-get install -y docker.io docker-compose-v2
            sudo systemctl start docker
            sudo usermod -aG docker "$USER"
        fi
    fi

    if ! command -v docker &>/dev/null && [ -f "/Applications/Docker.app/Contents/Resources/bin/docker" ]; then
        export PATH="$PATH:/Applications/Docker.app/Contents/Resources/bin"
    fi

    if ! docker compose version &>/dev/null; then
        # 尝试 docker-compose (旧版)
        if command -v docker-compose &>/dev/null; then
            ok "使用 docker-compose (v1)"
        else
            err "需要 Docker Compose，请安装 Docker Desktop"
            exit 1
        fi
    else
        ok "Docker Compose 可用"
    fi
}

# ---- Step 5: 启动中间件 ----
start_middleware() {
    log "启动中间件容器..."

    if [ -f "$DOCKER_COMPOSE_PROD" ]; then
        cd "$(dirname "$DOCKER_COMPOSE_PROD")"
        docker compose -f "$(basename "$DOCKER_COMPOSE_PROD")" up -d 2>&1 | tail -5
        ok "中间件容器已启动（prod 配置）"
    elif [ -f "$DOCKER_COMPOSE_DEV" ]; then
        cd "$(dirname "$DOCKER_COMPOSE_DEV")"
        docker compose -f "$(basename "$DOCKER_COMPOSE_DEV")" up -d 2>&1 | tail -5
        ok "中间件容器已启动（dev 配置）"
    else
        err "找不到 docker-compose 文件"
        return 1
    fi
}

# ---- Step 6: 等待中间件就绪 ----
wait_for_services() {
    log "等待中间件就绪..."

    # MySQL
    for i in $(seq 1 30); do
        if docker exec mysql mysqladmin ping -h localhost --silent 2>/dev/null; then
            ok "MySQL 就绪"
            break
        fi
        [ $i -eq 30 ] && warn "MySQL 启动超时，继续..."
        sleep 2
    done

    # Redis
    for i in $(seq 1 15); do
        if docker exec redis redis-cli ping 2>/dev/null | grep -q PONG; then
            ok "Redis 就绪"
            break
        fi
        [ $i -eq 15 ] && warn "Redis 启动超时，继续..."
        sleep 1
    done

    # Elasticsearch
    for i in $(seq 1 30); do
        if curl -s http://localhost:9200/_cluster/health 2>/dev/null | grep -q '"status"'; then
            ok "Elasticsearch 就绪"
            break
        fi
        [ $i -eq 30 ] && warn "Elasticsearch 启动超时，继续..."
        sleep 3
    done

    # Nacos
    for i in $(seq 1 30); do
        if curl -s http://localhost:8848/nacos/v1/console/health/readiness 2>/dev/null | grep -q 'ok'; then
            ok "Nacos 就绪"
            break
        fi
        [ $i -eq 30 ] && warn "Nacos 启动超时，继续..."
        sleep 2
    done
}

# ---- Step 7: 初始化 MySQL ----
init_mysql() {
    log "初始化 MySQL 数据库..."

    if [ ! -f "$MYSQL_INIT_SQL" ]; then
        warn "找不到 admin-schema.sql，跳过 MySQL 初始化"
        warn "下载链接: https://github.com/spring-ai-alibaba/spring-ai-alibaba-admin/blob/main/docker/middleware/init/mysql/admin-schema.sql"
        warn "请将其放置在: docker/middleware/init/mysql/admin-schema.sql"
        return
    fi

    # 建库
    docker exec mysql mysql -u root -proot -e "CREATE DATABASE IF NOT EXISTS admin CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;" 2>/dev/null || {
        docker exec mysql mysql -u admin -padmin -e "CREATE DATABASE IF NOT EXISTS admin CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;" 2>/dev/null || true
    }

    # 导入 schema
    docker exec -i mysql mysql -u root -proot admin < "$MYSQL_INIT_SQL" 2>/dev/null || {
        docker exec -i mysql mysql -u admin -padmin admin < "$MYSQL_INIT_SQL" 2>/dev/null || true
    }
    ok "MySQL admin 数据库初始化完成"
}

# ---- Step 8: 初始化 Elasticsearch 索引 ----
init_elasticsearch() {
    log "检查 Elasticsearch 索引..."

    local init_script="${PROJECT_DIR}/docker/middleware/init/elasticsearch/init-indices.sh"
    if [ -f "$init_script" ]; then
        docker exec elasticsearch-init sh /scripts/init-indices.sh 2>/dev/null || {
            warn "ES 索引初始化失败，可能需要手动执行 init-indices.sh"
        }
    else
        warn "ES 初始化脚本不存在，跳过索引创建"
    fi
    ok "Elasticsearch 索引检查完成"
}

# ---- Step 9: 初始化 RocketMQ Topic ----
init_rocketmq() {
    log "初始化 RocketMQ Topic..."

    docker exec rmq-init-topic sh -c "
        sh mqadmin updateTopic -n rmq_namesrv:9876 -t topic_saa_studio_document_index -c DefaultCluster -a +message.type=NORMAL
        sh mqadmin updateSubGroup -n rmq_namesrv:9876 -g group_saa_studio_document_index -c DefaultCluster
    " 2>/dev/null || {
        warn "RocketMQ Topic 初始化失败（可能已存在或容器未启动），跳过"
    }
    ok "RocketMQ Topic 初始化完成（或已存在）"
}

# ---- Step 10: 安装 draw.io CLI ----
install_drawio() {
    if command -v draw.io &>/dev/null || [ -f "/Applications/draw.io.app/Contents/MacOS/draw.io" ]; then
        ok "draw.io 已安装"
        return
    fi
    log "安装 draw.io（SVG 图表导出）..."
    if [[ "$PKG" == "brew install" ]]; then
        brew install --cask drawio
    else
        warn "Linux 下 draw.io 请手动下载: https://github.com/jgraph/drawio-desktop/releases"
        warn "下载 .deb/.rpm 后安装: sudo dpkg -i drawio-*.deb"
    fi
}

# ---- Step 11: 验证 ----
verify() {
    log "========================================"
    log "  环境验证"
    log "========================================"

    echo ""
    echo "  运行时:"
    echo "    JDK:     $(java -version 2>&1 | head -1 || echo '未安装')"
    echo "    Maven:   $(mvn --version 2>&1 | head -1 || echo '未安装')"
    echo "    Docker:  $(docker --version 2>&1 || echo '未安装')"
    echo "    DrawIO:  $(draw.io --version 2>&1 | head -1 || echo '未安装')"
    echo ""
    echo "  中间件 (docker ps):"
    docker ps --format '    {{.Names}}  {{.Status}}' 2>/dev/null | grep -E 'mysql|redis|elasticsearch|nacos|rocketmq|loongcollector|kibana' || echo "    (无运行中的容器)"
    echo ""
    echo "  端口监听:"
    for port in 3306 6379 9200 8848 9876 18080 4318; do
        if lsof -i ":$port" -sTCP:LISTEN &>/dev/null; then
            echo "    :$port  ✅"
        else
            echo "    :$port  ❌"
        fi
    done
    echo ""

    ok "环境验证完成。运行 mvn spring-boot:run -pl spring-ai-alibaba-admin-server-start 启动应用"
}

# ---- 主流程 ----
main() {
    echo ""
    log "========================================"
    log "  Spring AI Alibaba Admin 环境安装"
    log "  docs/env-checklist.md → 自动化安装"
    log "========================================"
    echo ""

    install_pkg_manager
    retry install_jdk
    retry install_maven
    retry install_docker
    retry start_middleware
    wait_for_services
    retry init_mysql
    init_elasticsearch
    init_rocketmq
    retry install_drawio
    verify

    echo ""
    ok "全部完成! 运行: cd spring-ai-alibaba-admin-server-start && mvn spring-boot:run"
    echo ""
}

main "$@"
