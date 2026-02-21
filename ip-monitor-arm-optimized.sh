#!/bin/bash

# 服务器IP变更监控脚本 - ARM优化版
# 专门优化ARM架构兼容性和性能

# 配置区域
TELEGRAM_BOT_TOKEN=""  # 你的Telegram Bot Token
TELEGRAM_CHAT_ID=""     # 你的Telegram Chat ID
IP_CHECK_INTERVAL=300   # 检查间隔(秒)

# ARM优化配置
MAX_RESTART_ATTEMPTS=3  # ARM设备重启次数减少
RESTART_DELAY=60        # ARM设备重启延迟增加
HEALTH_CHECK_INTERVAL=120 # ARM设备健康检查间隔增加

# ARM特定路径（适应不同发行版）
if [ -d "/var/run" ]; then
    RUN_DIR="/var/run"
else
    RUN_DIR="/run"
fi

if [ -d "/var/log" ]; then
    LOG_DIR="/var/log"
else
    LOG_DIR="/tmp"
fi

# 文件路径
LOG_FILE="$LOG_DIR/ip-monitor.log"
IP_HISTORY_FILE="/var/lib/ip-monitor/ip-history.txt"
PID_FILE="$RUN_DIR/ip-monitor.pid"
HEALTH_FILE="$RUN_DIR/ip-monitor.health"
GUARD_LOG="$LOG_DIR/ip-monitor-guard.log"

# ARM架构检测
get_architecture() {
    local arch=$(uname -m 2>/dev/null || echo "unknown")
    case "$arch" in
        "aarch64"|"arm64")
            echo "arm64"
            ;;
        "armv7l"|"armv8l")
            echo "arm32"
            ;;
        "x86_64")
            echo "x64"
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

# ARM优化：创建必要的目录
create_directories() {
    local arch=$(get_architecture)
    
    mkdir -p /var/lib/ip-monitor
    mkdir -p "$LOG_DIR"
    mkdir -p "$RUN_DIR"
    
    # ARM设备可能权限不同，确保目录可写
    if [ "$arch" = "arm32" ] || [ "$arch" = "arm64" ]; then
        chmod 755 /var/lib/ip-monitor 2>/dev/null || true
        chmod 755 "$LOG_DIR" 2>/dev/null || true
    fi
}

# 日志函数
log_message() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local arch=$(get_architecture)
    
    echo "[$timestamp] [$level] [$arch] $message" | tee -a "$LOG_FILE"
    
    if [ "$level" = "ERROR" ] || [ "$level" = "WARNING" ]; then
        echo "[$timestamp] [GUARD] [$arch] $message" >> "$GUARD_LOG"
    fi
}

# ARM优化：获取当前公网IP
get_current_ip() {
    local ip=""
    local arch=$(get_architecture)
    
    # ARM优化：根据架构选择最佳服务
    local services=()
    
    case "$arch" in
        "arm32")
            # ARM32设备：使用响应最快的服务
            services=("https://ident.me" "https://icanhazip.com" "https://api.ipify.org")
            ;;
        "arm64")
            # ARM64设备：使用可靠性最高的服务
            services=("https://api.ipify.org" "https://icanhazip.com" "https://ident.me")
            ;;
        *)
            # 其他架构：使用默认顺序
            services=("https://api.ipify.org" "https://icanhazip.com" "https://ident.me")
            ;;
    esac
    
    for service in "${services[@]}"; do
        # ARM优化：增加超时时间，适应可能较慢的网络
        ip=$(curl -s -m 15 "$service" 2>/dev/null)
        if [ -n "$ip" ] && [[ "$ip" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
            log_message "DEBUG" "IP查询成功: $service"
            echo "$ip"
            return 0
        fi
    done
    
    log_message "ERROR" "所有IP查询服务都失败"
    echo ""
    return 1
}

# 发送Telegram消息
send_telegram_message() {
    local message="$1"
    local arch=$(get_architecture)
    
    if [ -z "$TELEGRAM_BOT_TOKEN" ] || [ -z "$TELEGRAM_CHAT_ID" ]; then
        log_message "WARNING" "Telegram配置未设置"
        return 1
    fi
    
    local encoded_message=$(echo "$message" | sed 's/ /%20/g; s/\n/%0A/g')
    
    # ARM优化：增加超时时间
    local response=$(curl -s -m 30 -X POST \
        "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
        -d "chat_id=${TELEGRAM_CHAT_ID}" \
        -d "text=${encoded_message}" \
        -d "parse_mode=Markdown")
    
    if echo "$response" | grep -q '"ok":true'; then
        log_message "INFO" "Telegram消息发送成功"
        return 0
    else
        log_message "ERROR" "Telegram消息发送失败"
        return 1
    fi
}

# ARM优化：健康检查
health_check() {
    local arch=$(get_architecture)
    
    # 更新健康时间戳
    date +%s > "$HEALTH_FILE"
    
    # 检查PID文件
    if [ ! -f "$PID_FILE" ]; then
        log_message "WARNING" "PID文件不存在"
        return 1
    fi
    
    local pid=$(cat "$PID_FILE" 2>/dev/null)
    if [ -z "$pid" ] || ! kill -0 "$pid" 2>/dev/null; then
        log_message "ERROR" "进程不存在或已停止 (PID: $pid)"
        return 1
    fi
    
    # ARM优化：增加健康检查超时时间
    local current_time=$(date +%s)
    local health_time=$(cat "$HEALTH_FILE" 2>/dev/null || echo 0)
    local time_diff=$((current_time - health_time))
    
    local timeout_threshold=600  # ARM设备：10分钟超时
    if [ "$time_diff" -gt "$timeout_threshold" ]; then
        log_message "ERROR" "健康检查超时 (${time_diff}秒无更新)"
        return 1
    fi
    
    return 0
}

# ARM优化：守护进程模式
daemon_guard() {
    local restart_count=0
    local arch=$(get_architecture)
    
    log_message "INFO" "ARM守护进程启动 (架构: $arch)"
    
    # ARM优化：初始化目录
    create_directories
    
    while [ "$restart_count" -lt "$MAX_RESTART_ATTEMPTS" ]; do
        log_message "INFO" "启动监控进程 (架构: $arch, 尝试: $((restart_count + 1))/$MAX_RESTART_ATTEMPTS)"
        
        # 启动监控进程
        start_monitor_process
        local monitor_pid=$!
        
        # 保存PID
        echo "$monitor_pid" > "$PID_FILE"
        
        log_message "INFO" "监控进程启动成功 (PID: $monitor_pid, 架构: $arch)"
        
        # 健康检查循环
        while true; do
            sleep "$HEALTH_CHECK_INTERVAL"
            
            if ! health_check; then
                log_message "WARNING" "健康检查失败，重启监控进程"
                kill_monitor_process
                break
            fi
            
            # 检查重启计数
            if [ "$restart_count" -ge "$MAX_RESTART_ATTEMPTS" ]; then
                log_message "ERROR" "达到最大重启次数，停止守护"
                send_telegram_message "🚨 *IP监控守护进程告警*\n\n监控进程已连续重启 ${MAX_RESTART_ATTEMPTS} 次，守护进程停止。\n*架构*: $arch\n请检查系统状态。"
                exit 1
            fi
        done
        
        restart_count=$((restart_count + 1))
        log_message "INFO" "等待 ${RESTART_DELAY} 秒后重启"
        sleep "$RESTART_DELAY"
    done
}

# 启动监控进程
start_monitor_process() {
    (
        # 子进程：实际的IP监控逻辑
        trap 'cleanup_monitor' EXIT
        
        local arch=$(get_architecture)
        log_message "INFO" "IP监控进程启动 (架构: $arch)"
        
        while true; do
            # 执行IP检查
            check_ip_change
            
            # 更新健康时间戳
            date +%s > "$HEALTH_FILE"
            
            sleep "$IP_CHECK_INTERVAL"
        done
    ) &
}

# 清理监控进程
cleanup_monitor() {
    local arch=$(get_architecture)
    log_message "INFO" "IP监控进程退出 (架构: $arch)"
    rm -f "$PID_FILE" "$HEALTH_FILE"
}

# 停止监控进程
kill_monitor_process() {
    if [ -f "$PID_FILE" ]; then
        local pid=$(cat "$PID_FILE")
        if kill -0 "$pid" 2>/dev/null; then
            log_message "INFO" "停止监控进程 (PID: $pid)"
            kill "$pid" 2>/dev/null
            sleep 3  # ARM优化：增加等待时间
            if kill -0 "$pid" 2>/dev/null; then
                log_message "WARNING" "强制停止监控进程"
                kill -9 "$pid" 2>/dev/null
            fi
        fi
        rm -f "$PID_FILE" "$HEALTH_FILE"
    fi
}

# IP检查逻辑
check_ip_change() {
    local current_ip=$(get_current_ip)
    local previous_ip=$(get_previous_ip)
    local arch=$(get_architecture)
    
    if [ -z "$current_ip" ]; then
        log_message "ERROR" "无法获取当前IP"
        return 1
    fi
    
    if [ -z "$previous_ip" ]; then
        log_message "INFO" "首次运行，记录IP: $current_ip"
        save_current_ip "$current_ip"
        return 0
    fi
    
    if [ "$current_ip" != "$previous_ip" ]; then
        local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
        local hostname=$(hostname)
        
        log_message "INFO" "检测到IP变更: $previous_ip -> $current_ip"
        
        # 清理IP地址，确保只包含纯IP
        local clean_previous_ip=$(echo "$previous_ip" | grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' | head -1)
        local clean_current_ip=$(echo "$current_ip" | grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' | head -1)
        
        # 如果清理失败，使用原始值
        if [ -z "$clean_previous_ip" ]; then
            clean_previous_ip="$previous_ip"
        fi
        if [ -z "$clean_current_ip" ]; then
            clean_current_ip="$current_ip"
        fi
        
        local message="🚨 服务器IP变更通知 服务器: $hostname 架构: $arch 原IP: $clean_previous_ip 新IP: $clean_current_ip 时间: $timestamp 💡 请及时更新相关配置"
        
        if send_telegram_message "$message"; then
            save_current_ip "$current_ip"
            log_message "INFO" "IP变更通知已发送"
        fi
    else
        log_message "DEBUG" "IP未变化: $current_ip"
    fi
}

# 获取上次记录的IP
get_previous_ip() {
    if [ -f "$IP_HISTORY_FILE" ]; then
        local last_line=$(tail -n 1 "$IP_HISTORY_FILE")
        # 确保正确提取IP地址（第二列）
        echo "$last_line" | cut -d'|' -f2
    else
        echo ""
    fi
}

# 保存当前IP
save_current_ip() {
    local ip="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local arch=$(get_architecture)
    echo "${timestamp}|${ip}|${arch}" >> "$IP_HISTORY_FILE"
}

# 简单的IP获取（用于状态显示，不输出日志）
get_simple_ip() {
    local ip=""
    local services=("https://api.ipify.org" "https://icanhazip.com" "https://ident.me")
    
    for service in "${services[@]}"; do
        ip=$(curl -s -m 5 "$service" 2>/dev/null)
        if [ -n "$ip" ] && [[ "$ip" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
            echo "$ip"
            return 0
        fi
    done
    echo "获取失败"
    return 1
}

# 显示状态
show_status() {
    local arch=$(get_architecture)
    echo "=== 🔍 IP监控状态 (架构: $arch) ==="
    echo "当前IP: $(get_simple_ip)"
    echo "上次IP: $(get_previous_ip)"
    echo "检查间隔: ${IP_CHECK_INTERVAL}秒"
    echo ""
    echo "📁 文件状态:"
    echo "  日志文件: $LOG_FILE"
    echo "  历史记录: $IP_HISTORY_FILE"
    echo "  守护日志: $GUARD_LOG"
    echo "  PID文件: $PID_FILE"
    echo "  健康文件: $HEALTH_FILE"
    echo ""
    
    if [ -f "$PID_FILE" ]; then
        local pid=$(cat "$PID_FILE" 2>/dev/null)
        if kill -0 "$pid" 2>/dev/null; then
            echo "✅ 监控进程运行中 (PID: $pid)"
        else
            echo "❌ 监控进程已停止"
        fi
    else
        echo "❌ 监控进程未运行"
    fi
    
    echo ""
    echo "📋 最近日志:"
    tail -n 5 "$LOG_FILE" 2>/dev/null || echo "  无日志"
}

# ARM优化：安装系统服务
install_service() {
    local arch=$(get_architecture)
    echo "=== 🔧 安装ARM优化系统服务 (架构: $arch) ==="
    
    # 创建ARM优化的systemd服务
    cat > /etc/systemd/system/ip-monitor-arm.service << EOF
[Unit]
Description=IP Change Monitor ARM Service
After=network.target
Wants=network.target

[Service]
Type=forking
User=root
ExecStart=/bin/bash $(realpath "$0") --start-guard
ExecStop=/bin/bash $(realpath "$0") --stop
ExecReload=/bin/bash $(realpath "$0") --restart
Restart=always
RestartSec=20
StartLimitInterval=600
StartLimitBurst=3

# ARM优化：资源限制
MemoryLimit=100M
CPUQuota=50%

[Install]
WantedBy=multi-user.target
EOF
    
    echo "✅ ARM优化服务文件已创建"
    echo ""
    echo "🚀 启动命令:"
    echo "  systemctl daemon-reload"
    echo "  systemctl enable ip-monitor-arm.service"
    echo "  systemctl start ip-monitor-arm.service"
}

# 主程序
case "${1:-}" in
    "--start-guard")
        daemon_guard
        ;;
    "--stop")
        kill_monitor_process
        ;;
    "--restart")
        kill_monitor_process
        sleep 2
        start_monitor_process
        ;;
    "--status")
        show_status
        ;;
    "--install")
        install_service
        ;;
    "--test")
        local arch=$(get_architecture)
        # 确保架构信息不为空
        if [ -z "$arch" ] || [ "$arch" = "unknown" ]; then
            arch="检测失败"
        fi
        echo "🧪 ARM测试Telegram消息 (架构: $arch)..."
        send_telegram_message "🧪 *IP监控ARM版测试*\n\nARM架构兼容性测试成功！\n*架构*: $arch\n*时间*: $(date '+%Y-%m-%d %H:%M:%S')"
        ;;
    "--arch")
        get_architecture
        ;;
    "--help"|"")
        echo "=== 🚀 IP监控ARM优化版 ==="
        echo ""
        echo "特性:"
        echo "  ✅ 完整的ARM架构兼容性"
        echo "  ✅ ARM特定的性能优化"
        echo "  ✅ 适应ARM设备的资源限制"
        echo "  ✅ 详细的架构信息记录"
        echo ""
        echo "用法: $0 [选项]"
        echo ""
        echo "选项:"
        echo "  --start-guard    启动守护进程"
        echo "  --stop           停止监控进程"
        echo "  --restart        重启监控进程"
        echo "  --status         显示状态"
        echo "  --install        安装系统服务"
        echo "  --test           测试功能"
        echo "  --arch           显示系统架构"
        ;;
    *)
        echo "未知选项: $1"
        exit 1
        ;;
esac