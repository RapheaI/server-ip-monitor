#!/bin/bash

# 服务器IP变更监控脚本 - 增强版
# 包含完整的进程守护和自动恢复功能

# 配置区域
TELEGRAM_BOT_TOKEN=""  # 你的Telegram Bot Token
TELEGRAM_CHAT_ID=""     # 你的Telegram Chat ID
IP_CHECK_INTERVAL=300   # 检查间隔(秒)

# 守护进程配置
MAX_RESTART_ATTEMPTS=5  # 最大重启尝试次数
RESTART_DELAY=30        # 重启延迟(秒)
HEALTH_CHECK_INTERVAL=60 # 健康检查间隔(秒)

# 文件路径
LOG_FILE="/var/log/ip-monitor.log"
IP_HISTORY_FILE="/var/lib/ip-monitor/ip-history.txt"
PID_FILE="/var/run/ip-monitor.pid"
HEALTH_FILE="/var/run/ip-monitor.health"
GUARD_LOG="/var/log/ip-monitor-guard.log"

# 创建必要的目录
mkdir -p /var/lib/ip-monitor
mkdir -p /var/log
mkdir -p /var/run

# 日志函数
log_message() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local log_entry="[$timestamp] [$level] $message"
    
    echo "$log_entry" | tee -a "$LOG_FILE"
    
    # 同时记录到守护进程日志
    if [ "$level" = "ERROR" ] || [ "$level" = "WARNING" ]; then
        echo "$log_entry" >> "$GUARD_LOG"
    fi
}

# 守护进程日志
guard_log() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [GUARD] $message" >> "$GUARD_LOG"
}

# 获取当前公网IP
get_current_ip() {
    local ip=""
    
    # 尝试多个IP查询服务
    local services=("https://api.ipify.org" "https://icanhazip.com" "https://ident.me")
    
    for service in "${services[@]}"; do
        ip=$(curl -s -m 10 "$service" 2>/dev/null)
        if [ -n "$ip" ] && [[ "$ip" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
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
    
    if [ -z "$TELEGRAM_BOT_TOKEN" ] || [ -z "$TELEGRAM_CHAT_ID" ]; then
        log_message "WARNING" "Telegram配置未设置"
        return 1
    fi
    
    local encoded_message=$(echo "$message" | sed 's/ /%20/g; s/\n/%0A/g')
    
    local response=$(curl -s -X POST \
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

# 健康检查
health_check() {
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
    
    # 检查健康时间戳
    local current_time=$(date +%s)
    local health_time=$(cat "$HEALTH_FILE" 2>/dev/null || echo 0)
    local time_diff=$((current_time - health_time))
    
    if [ "$time_diff" -gt 300 ]; then  # 5分钟无更新
        log_message "ERROR" "健康检查超时 (${time_diff}秒无更新)"
        return 1
    fi
    
    return 0
}

# 守护进程模式
daemon_guard() {
    local restart_count=0
    
    guard_log "守护进程启动"
    
    while [ "$restart_count" -lt "$MAX_RESTART_ATTEMPTS" ]; do
        guard_log "启动监控进程 (尝试: $((restart_count + 1))/$MAX_RESTART_ATTEMPTS)"
        
        # 启动监控进程
        start_monitor_process
        local monitor_pid=$!
        
        # 保存PID
        echo "$monitor_pid" > "$PID_FILE"
        
        guard_log "监控进程启动成功 (PID: $monitor_pid)"
        
        # 健康检查循环
        while true; do
            sleep "$HEALTH_CHECK_INTERVAL"
            
            if ! health_check; then
                guard_log "健康检查失败，重启监控进程"
                kill_monitor_process
                break
            fi
            
            # 检查重启计数
            if [ "$restart_count" -ge "$MAX_RESTART_ATTEMPTS" ]; then
                guard_log "达到最大重启次数，停止守护"
                send_telegram_message "🚨 *IP监控守护进程告警*\n\n监控进程已连续重启 ${MAX_RESTART_ATTEMPTS} 次，守护进程停止。请检查系统状态。"
                exit 1
            fi
        done
        
        restart_count=$((restart_count + 1))
        guard_log "等待 ${RESTART_DELAY} 秒后重启"
        sleep "$RESTART_DELAY"
    done
}

# 启动监控进程
start_monitor_process() {
    (
        # 子进程：实际的IP监控逻辑
        trap 'cleanup_monitor' EXIT
        
        log_message "INFO" "IP监控进程启动"
        
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
    log_message "INFO" "IP监控进程退出"
    rm -f "$PID_FILE" "$HEALTH_FILE"
}

# 停止监控进程
kill_monitor_process() {
    if [ -f "$PID_FILE" ]; then
        local pid=$(cat "$PID_FILE")
        if kill -0 "$pid" 2>/dev/null; then
            guard_log "停止监控进程 (PID: $pid)"
            kill "$pid" 2>/dev/null
            sleep 2
            if kill -0 "$pid" 2>/dev/null; then
                guard_log "强制停止监控进程"
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
        
        local message="🚨 *服务器IP变更通知*\n\n"
        message+="*服务器*: \`$hostname\`\n"
        message+="*原IP*: \`$previous_ip\`\n"
        message+="*新IP*: \`$current_ip\`\n"
        message+="*时间*: $timestamp\n"
        message+="\n💡 请及时更新相关配置"
        
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
        tail -n 1 "$IP_HISTORY_FILE" | cut -d'|' -f2
    else
        echo ""
    fi
}

# 保存当前IP
save_current_ip() {
    local ip="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "${timestamp}|${ip}" >> "$IP_HISTORY_FILE"
}

# 显示状态
show_status() {
    echo "=== 🔍 IP监控状态 ==="
    echo "当前IP: $(get_current_ip)"
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
    echo ""
    echo "🛡️ 守护日志:"
    tail -n 5 "$GUARD_LOG" 2>/dev/null || echo "  无守护日志"
}

# 安装系统服务
install_service() {
    echo "=== 🔧 安装系统服务 ==="
    
    # 创建增强版systemd服务
    cat > /etc/systemd/system/ip-monitor-guard.service << EOF
[Unit]
Description=IP Change Monitor Guard Service
After=network.target
Wants=network.target

[Service]
Type=forking
User=root
ExecStart=/bin/bash $(realpath "$0") --start-guard
ExecStop=/bin/bash $(realpath "$0") --stop
ExecReload=/bin/bash $(realpath "$0") --restart
Restart=always
RestartSec=10
StartLimitInterval=300
StartLimitBurst=5

[Install]
WantedBy=multi-user.target
EOF
    
    # 创建看门狗服务
    cat > /etc/systemd/system/ip-monitor-watchdog.service << EOF
[Unit]
Description=IP Monitor Watchdog
After=ip-monitor-guard.service
Requires=ip-monitor-guard.service

[Service]
Type=oneshot
User=root
ExecStart=/bin/bash $(realpath "$0") --watchdog-check
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF
    
    # 创建定时器
    cat > /etc/systemd/system/ip-monitor-watchdog.timer << EOF
[Unit]
Description=IP Monitor Watchdog Timer
Requires=ip-monitor-watchdog.service

[Timer]
OnCalendar=*:0/5  # 每5分钟执行一次
Persistent=true

[Install]
WantedBy=timers.target
EOF
    
    echo "✅ 增强版服务文件已创建"
    echo ""
    echo "📋 服务组件:"
    echo "  - ip-monitor-guard.service: 主守护进程"
    echo "  - ip-monitor-watchdog.service: 看门狗检查"
    echo "  - ip-monitor-watchdog.timer: 定时检查"
    echo ""
    echo "🚀 启动命令:"
    echo "  systemctl daemon-reload"
    echo "  systemctl enable ip-monitor-guard.service"
    echo "  systemctl enable ip-monitor-watchdog.timer"
    echo "  systemctl start ip-monitor-guard.service"
    echo "  systemctl start ip-monitor-watchdog.timer"
}

# 看门狗检查
watchdog_check() {
    if ! health_check; then
        guard_log "看门狗检查失败，重启服务"
        systemctl restart ip-monitor-guard.service
        send_telegram_message "🔄 *IP监控服务重启*\n\n看门狗检测到服务异常，已自动重启。"
    fi
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
    "--watchdog-check")
        watchdog_check
        ;;
    "--status")
        show_status
        ;;
    "--install")
        install_service
        ;;
    "--test")
        echo "🧪 测试Telegram消息..."
        send_telegram_message "🧪 *IP监控增强版测试*\n\n进程守护功能测试成功！\n*时间*: $(date '+%Y-%m-%d %H:%M:%S')"
        ;;
    "--help"|"")
        echo "=== 🚀 IP监控增强版 ==="
        echo ""
        echo "特性:"
        echo "  ✅ 完整的进程守护"
        echo "  ✅ 自动健康检查"
        echo "  ✅ 看门狗监控"
        echo "  ✅ 自动恢复机制"
        echo "  ✅ 多重保护层级"
        echo ""
        echo "用法: $0 [选项]"
        echo ""
        echo "选项:"
        echo "  --start-guard    启动守护进程"
        echo "  --stop           停止监控进程"
        echo "  --restart        重启监控进程"
        echo "  --watchdog-check 看门狗检查"
        echo "  --status         显示状态"
        echo "  --install        安装系统服务"
        echo "  --test           测试功能"
        ;;
    *)
        echo "未知选项: $1"
        exit 1
        ;;
esac