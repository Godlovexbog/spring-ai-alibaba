#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# deps-start.sh — 一键启动所有依赖中间件
# 支持: docker compose / brew services / 手动 jar
# 每个服务就绪后才返回
# ============================================================

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[1;36m'; NC='\033[0m'
log() { echo -e "${CYAN}[start]${NC} $1"; }
ok()  { echo -e "${GREEN}[ready]${NC} $1"; }

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
COMPOSE_DIR="${PROJECT_DIR}/docker/middleware"
WAIT_TIMEOUT=60

# ---- 服务定义 ----
# name:port:check_url:depends_on
SERVICES_DOCKER=(
    "MySQL:3306:docker exec mysql mysqladmin ping -h localhost --silent:"
    "Redis:6379:docker exec redis redis-cli ping PONG:MySQL"
    "Elasticsearch:9200:curl -s http://localhost:9200/_cluster/health | grep -q '\"status\"':"
    "Nacos:8848:curl -s http://localhost:8848/nacos/v1/console/health/readiness | grep -q 'ok':"
    "RocketMQ NameSrv:9876:docker exec rmq_namesrv sh -c 'ps aux | grep mqnamesrv | grep -v grep' >/dev/null 2>&1:"
    "RocketMQ Broker:10911:docker exec rmq_broker sh -c 'ps aux | grep mqbroker | grep -v grep' >/dev/null 2>&1:RocketMQ NameSrv"
    "RocketMQ Proxy:18080:docker exec rmq_proxy sh -c 'ps aux | grep mqproxy | grep -v grep' >/dev/null 2>&1:RocketMQ Broker"
    "LoongCollector:4318:curl -s http://localhost:4318/ >/dev/null 2>&1:Elasticsearch"
    "Kibana:5601:curl -s http://localhost:5601/api/status >/dev/null 2>&1:Elasticsearch"
)

# ---- 启动 Docker Compose 中间件 ----
start_docker_compose() {
    if [ ! -f "${COMPOSE_DIR}/docker-compose-prod.yaml" ]; then
        log "未找到 docker-compose-prod.yaml，跳过 Docker Compose 启动"
        return
    fi

    log "启动 Docker Compose 中间件..."
    cd "$COMPOSE_DIR"
    docker compose -f docker-compose-prod.yaml up -d 2>&1 | tail -3
}

# ---- 等待服务就绪 ----
wait_for_service() {
    local name="$1"
    local port="$2"
    local check="$3"
    local depends="$4"

    # 如果依赖的服务未启动，跳过
    if [ -n "$depends" ]; then
        local dep_port=$(echo "${SERVICES_DOCKER[@]}" | tr ' ' '\n' | grep "^${depends}:" | cut -d: -f1 || true)
    fi

    log "等待 $name 就绪..."
    local waited=0
    while [ $waited -lt $WAIT_TIMEOUT ]; do
        if eval "$check" 2>/dev/null; then
            ok "$name (:$port)"
            return 0
        fi
        sleep 2
        waited=$((waited + 2))
        [ $((waited % 10)) -eq 0 ] && echo -n "."
    done
    echo ""
    echo -e "${YELLOW}[warn]${NC} $name 在 ${WAIT_TIMEOUT}s 内未就绪，继续..."
    return 1
}

# ---- 启动 Brew 管理的服务 ----
start_brew_services() {
    local svc=$1
    if brew services list 2>/dev/null | grep -q "^${svc}\s.*started"; then
        ok "$svc (brew) 已在运行"
        return
    fi
    log "启动 $svc (brew services)"
    brew services start "$svc" 2>/dev/null || {
        echo -e "${YELLOW}[warn]${NC} brew services start $svc 失败，请手动启动"
    }
}

# ---- 主流程 ----
main() {
    echo ""
    log "=============================="
    log "  启动所有依赖中间件"
    log "=============================="

    # 1. Docker Compose 中间件
    start_docker_compose

    # 2. 等待每个 Docker 服务就绪
    echo ""
    for svc_def in "${SERVICES_DOCKER[@]}"; do
        IFS=':' read -r name port check depends <<< "$svc_def"
        wait_for_service "$name" "$port" "$check" "$depends" || true
    done

    # 3. Brew 服务（如果不用 Docker 版本）
    echo ""
    log "所有服务启动完毕，最终端口状态:"
    for svc_def in "${SERVICES_DOCKER[@]}"; do
        IFS=':' read -r name port check depends <<< "$svc_def"
        if lsof -i ":$port" -sTCP:LISTEN &>/dev/null; then
            ok ":$port $name ✅"
        else
            echo -e "  :$port $name ❌"
        fi
    done

    echo ""
    ok "依赖启动完成"
}

main "$@"
