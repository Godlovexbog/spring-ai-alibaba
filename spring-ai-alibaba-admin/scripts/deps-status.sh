#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# deps-status.sh — 查看每个中间件的运行状态
# 打印运行状态 + 端口监听 + 健康检查结果
# ============================================================

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; CYAN='\033[1;36m'; NC='\033[0m'
BOLD='\033[1m'; NC2='\033[0m'

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
COMPOSE_DIR="${PROJECT_DIR}/docker/middleware"

# ---- 服务清单 ----
# name:port:type:check_cmd
SERVICES=(
    "MySQL:3306:docker:docker exec mysql mysqladmin ping -h localhost --silent"
    "Redis:6379:docker:docker exec redis redis-cli ping 2>/dev/null | grep -q PONG"
    "Elasticsearch:9200:docker:curl -s -o /dev/null -w '%{http_code}' http://localhost:9200/_cluster/health | grep -q 200"
    "Nacos:8848:docker:curl -s -o /dev/null -w '%{http_code}' http://localhost:8848/nacos/v1/console/health/readiness | grep -q 200"
    "RocketMQ NameSrv:9876:process:pgrep -f mqnamesrv &>/dev/null"
    "RocketMQ Broker:10911:process:pgrep -f mqbroker &>/dev/null"
    "RocketMQ Proxy:18080:docker:curl -s -o /dev/null -w '%{http_code}' http://localhost:18080/ | head -c 3 | grep -qv 000"
    "LoongCollector:4318:docker:curl -s -o /dev/null -w '%{http_code}' http://localhost:4318/ | grep -qv 000"
    "Kibana:5601:docker:curl -s -o /dev/null -w '%{http_code}' http://localhost:5601/api/status | grep -q 200"
)

# ---- 检查端口 ----
port_listening() {
    local port=$1
    if lsof -i ":$port" -sTCP:LISTEN &>/dev/null 2>&1; then
        echo "LISTEN ✅"
    else
        echo "CLOSED ❌"
    fi
}

# ---- 检查进程 ----
process_running() {
    local name=$1
    if docker ps --format '{{.Names}}' 2>/dev/null | grep -qi "$name" ; then
        echo "DOCKER 🐳"
    elif pgrep -f "$name" &>/dev/null 2>&1; then
        echo "PID $(pgrep -f "$name" | head -1)"
    elif brew services list 2>/dev/null | grep -q "^${name}\s.*started"; then
        echo "BREW 🍺"
    else
        echo "STOPPED ❌"
    fi
}

# ---- 健康检查 ----
health_check() {
    local check=$1
    if eval "$check" 2>/dev/null; then
        echo "HEALTHY ✅"
    else
        echo "UNHEALTHY ⚠️"
    fi
}

# ---- 主流程 ----
main() {
    echo ""
    echo -e "${BOLD}  Spring AI Alibaba Admin — 依赖中间件状态${NC2}"
    echo "  $(date '+%Y-%m-%d %H:%M:%S')"
    echo ""

    # Docker Compose 容器概览
    if docker compose version &>/dev/null && [ -f "${COMPOSE_DIR}/docker-compose-prod.yaml" ]; then
        cd "$COMPOSE_DIR"
        local containers=$(docker compose -f docker-compose-prod.yaml ps --format 'table {{.Name}}\t{{.Status}}' 2>/dev/null | tail -n +2 | wc -l | tr -d ' ')
        echo -e "  Docker Compose 容器: ${containers:-0} 个运行中"
        echo ""
    fi

    # 表头
    printf "  %-22s %-8s %-14s %-10s %-14s\n" "服务" "端口" "进程状态" "端口监听" "健康检查"
    printf "  %-22s %-8s %-14s %-10s %-14s\n" "──────────────────────" "───────" "────────────" "────────" "────────────"

    # 逐服务检查
    local ok_count=0 fail_count=0
    for svc_def in "${SERVICES[@]}"; do
        IFS=':' read -r name port type check <<< "$svc_def"

        local proc=$(process_running "${name%% *}" | tr '[:upper:]' '[:lower:]')
        local port_stat=$(port_listening "$port")

        # 确定整体状态
        if echo "$port_stat" | grep -q '✅'; then
            local health=$(health_check "$check")
            ok_count=$((ok_count + 1))
        else
            local health="—"
            fail_count=$((fail_count + 1))
        fi

        printf "  %-22s %-8s %-14s %-10s %-14s\n" "$name" ":$port" "$proc" "$port_stat" "$health"
    done

    echo ""
    echo -e "  汇总: ${GREEN}${ok_count} 正常${NC} / ${RED}${fail_count} 异常${NC}"
    echo ""

    # 额外: brew 管理状态
    if command -v brew &>/dev/null; then
        local brew_count=$(brew services list 2>/dev/null | grep -c "started" || echo "0")
        echo "  Brew services 运行中: ${brew_count}"
    fi
    echo ""
}

main "$@"
