#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# deps-stop.sh — 一键停止所有依赖中间件
# 支持: docker compose / brew services / 手动进程 kill
# ============================================================

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[1;36m'; NC='\033[0m'
log() { echo -e "${CYAN}[stop]${NC} $1"; }
ok()  { echo -e "${GREEN}[done]${NC} $1"; }
warn(){ echo -e "${YELLOW}[warn]${NC} $1"; }

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
COMPOSE_DIR="${PROJECT_DIR}/docker/middleware"

# ---- 停止 Docker Compose 中间件 ----
stop_docker_compose() {
    if [ ! -f "${COMPOSE_DIR}/docker-compose-prod.yaml" ]; then
        log "未找到 docker-compose-prod.yaml"
        return
    fi

    log "停止 Docker Compose 中间件..."
    cd "$COMPOSE_DIR"
    docker compose -f docker-compose-prod.yaml down --remove-orphans 2>&1 | tail -5 || {
        docker-compose -f docker-compose-prod.yaml down --remove-orphans 2>&1 | tail -5 || true
    }
    ok "Docker Compose 已停止"
}

# ---- 停止 Brew 管理的服务 ----
stop_brew_services() {
    local svc=$1
    if brew services list 2>/dev/null | grep -q "^${svc}\s.*started"; then
        log "停止 $svc (brew)"
        brew services stop "$svc" 2>/dev/null || warn "停止 $svc 失败"
    else
        ok "$svc 未在运行"
    fi
}

# ---- 停止手动 jar 进程 ----
stop_jar_process() {
    local pattern="$1"
    local name="$2"
    local pid=$(pgrep -f "$pattern" 2>/dev/null || true)
    if [ -n "$pid" ]; then
        log "停止 $name (pid: $pid)"
        kill "$pid" 2>/dev/null || true
        sleep 1
        kill -9 "$pid" 2>/dev/null || true
        ok "$name 已停止"
    else
        ok "$name 未在运行"
    fi
}

# ---- 释放端口 ----
release_port() {
    local port=$1
    local pid=$(lsof -ti ":$port" -sTCP:LISTEN 2>/dev/null || true)
    if [ -n "$pid" ]; then
        log "释放端口 :$port (pid: $pid)"
        kill "$pid" 2>/dev/null || true
        sleep 1
        kill -9 "$pid" 2>/dev/null || true
    fi
}

# ---- 主流程 ----
main() {
    echo ""
    log "=============================="
    log "  停止所有依赖中间件"
    log "=============================="

    # 1. Docker Compose 全停
    stop_docker_compose

    # 2. Brew 服务（如果单独装了）
    for svc in mysql redis elasticsearch kibana; do
        stop_brew_services "$svc" || true
    done

    # 3. 手动 jar 进程
    stop_jar_process "nacos-server" "Nacos Server" || true
    stop_jar_process "rocketmq" "RocketMQ" || true

    # 4. 兜底：释放仍然占用的端口
    echo ""
    log "检查残留端口..."
    for port in 3306 6379 9200 8848 9876 10911 18080 4318 5601; do
        release_port "$port" 2>/dev/null || true
    done

    echo ""
    ok "所有依赖已停止"
}

main "$@"
