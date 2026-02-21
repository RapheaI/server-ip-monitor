#!/bin/bash

# 服务器IP变更监控和Telegram推送脚本
# 椿卷ฅ专用 - 自动检测IP变化并推送通知

# 配置区域 - 请根据实际情况修改
TELEGRAM_BOT_TOKEN=""  # 你的Telegram Bot Token
TELEGRAM_CHAT_ID=""     # 你的Telegram Chat ID
IP_CHECK_INTERVAL=300   # 检查间隔(秒)，默认5分钟
LOG_FILE="/var/log/ip-monitor.log"
IP_HISTORY_FILE="/var/lib/ip-monitor/ip-history.txt"

# 创建必要的目录
mkdir -p /var/lib/ip-monitor
mkdir -p /var/log

# 获取当前公网IP
get_current_ip() {
    # 尝试多个IP查询服务，提高可靠性
    local ip=""
    
    # 方法1: ipify.org
    ip=$(curl -s -m 10 "https://api.ipify.org" 2>/dev/null)
    if [ -n "$ip" ] && [[ "$ip" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "$ip"
        return 0
    fi
    
    # 方法2: icanhazip.com
    ip=$(curl -s -m 10 "https://icanhazip.com" 2>/dev/null)
    if [ -n "$ip" ] && [[ "$ip" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "$ip"
        return 0
    fi
    
    # 方法3: ident.me
    ip=$(curl -s -m 10 "https://ident.me" 2>/dev/null)
    if [ -n "$ip" ] && [[ "$ip" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "$ip"
        return 0
    fi
    
    # 如果都失败，记录错误
    log_message "ERROR" "无法获取公网IP"
    echo ""
    return 1
}

# 发送Telegram消息
send_telegram_message() {
    local message="$1"
    
    if [ -z "$TELEGRAM_BOT_TOKEN" ] || [ -z "$TELEGRAM_CHAT_ID" ]; then
        log_message "WARNING" "Telegram配置未设置，跳过消息发送"
        return 1
    fi
    
    # URL编码消息内容
    local encoded_message=$(echo "$message" | sed 's/ /%20/g; s/\n/%0A/g')
    
    # 发送消息
    local response=$(curl -s -X POST \
        "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
        -d "chat_id=${TELEGRAM_CHAT_ID}" \
        -d "text=${encoded_message}" \
        -d "parse_mode=Markdown")
    
    if echo "$response" | grep -q '"ok":true'; then
        log_message "INFO" "Telegram消息发送成功"
        return 0
    else
        log_message "ERROR" "Telegram消息发送失败: $response"
        return 1
    fi
}

# 记录日志
log_message() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    echo "[$timestamp] [$level] $message" | tee -a "$LOG_FILE"
}

# 获取上次记录的IP
get_previous_ip() {
    if [ -f "$IP_HISTORY_FILE" ]; then
        tail -n 1 "$IP_HISTORY_FILE" | cut -d'|' -f2
    else
        echo ""
    fi
}

# 保存当前IP到历史记录
save_current_ip() {
    local ip="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    echo "${timestamp}|${ip}" >> "$IP_HISTORY_FILE"
}

# 检查IP变化
check_ip_change() {
    local current_ip=$(get_current_ip)
    local previous_ip=$(get_previous_ip)
    
    if [ -z "$current_ip" ]; then
        log_message "ERROR" "无法获取当前IP，跳过检查"
        return 1
    fi
    
    if [ -z "$previous_ip" ]; then
        # 第一次运行，记录IP但不发送通知
        log_message "INFO" "首次运行，记录IP: $current_ip"
        save_current_ip "$current_ip"
        return 0
    fi
    
    if [ "$current_ip" != "$previous_ip" ]; then
        # IP发生变化
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
        
        # 构建Telegram消息
        local message="🚨 服务器IP变更通知\n\n服务器: $hostname\n架构: $(uname -m)\n原IP: $clean_previous_ip\n新IP: $clean_current_ip\n时间: $timestamp\n\n💡 请及时更新相关配置"
        
        # 发送Telegram通知
        if send_telegram_message "$message"; then
            save_current_ip "$current_ip"
            log_message "INFO" "IP变更通知已发送"
        else
            log_message "ERROR" "IP变更通知发送失败"
        fi
    else
        log_message "DEBUG" "IP未变化: $current_ip"
    fi
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
    echo "=== 🔍 IP监控状态 ==="
    echo "当前IP: $(get_simple_ip)"
    echo "上次IP: $(get_previous_ip)"
    echo "日志文件: $LOG_FILE"
    echo "历史记录: $IP_HISTORY_FILE"
    echo "检查间隔: ${IP_CHECK_INTERVAL}秒"
    
    if [ -f "$LOG_FILE" ]; then
        echo ""
        echo "最近日志:"
        tail -n 5 "$LOG_FILE"
    fi
}

# 安装为系统服务
install_service() {
    echo "=== 🔧 安装系统服务 ==="
    
    # 创建systemd服务文件
    cat > /etc/systemd/system/ip-monitor.service << EOF
[Unit]
Description=IP Change Monitor Service
After=network.target

[Service]
Type=simple
User=root
ExecStart=/bin/bash $(realpath "$0") --daemon
Restart=always
RestartSec=60

[Install]
WantedBy=multi-user.target
EOF
    
    # 创建定时任务（备用方案）
    cat > /etc/cron.d/ip-monitor << EOF
*/5 * * * * root $(realpath "$0") --check
EOF
    
    echo "✅ 服务文件已创建"
    echo ""
    echo "📋 下一步操作:"
    echo "1. 编辑脚本配置 TELEGRAM_BOT_TOKEN 和 TELEGRAM_CHAT_ID"
    echo "2. 运行: systemctl daemon-reload"
    echo "3. 运行: systemctl enable ip-monitor.service"
    echo "4. 运行: systemctl start ip-monitor.service"
}

# 守护进程模式
daemon_mode() {
    log_message "INFO" "IP监控守护进程启动"
    
    while true; do
        check_ip_change
        sleep "$IP_CHECK_INTERVAL"
    done
}

# 主程序
case "${1:-}" in
    "--check")
        check_ip_change
        ;;
    "--daemon")
        daemon_mode
        ;;
    "--status")
        show_status
        ;;
    "--install")
        install_service
        ;;
    "--test")
        echo "=== 🧪 测试模式 ==="
        echo "当前IP: $(get_current_ip)"
        echo "Telegram测试消息..."
        send_telegram_message "🧪 *IP监控测试消息*\n\n这是一个测试消息，用于验证Telegram机器人配置。\n*时间*: $(date '+%Y-%m-%d %H:%M:%S')"
        ;;
    "--help"|"")
        echo "=== 🚀 IP变更监控脚本 ==="
        echo ""
        echo "用法: $0 [选项]"
        echo ""
        echo "选项:"
        echo "  --check     执行一次IP检查"
        echo "  --daemon    以守护进程模式运行"
        echo "  --status    显示当前状态"
        echo "  --install   安装为系统服务"
        echo "  --test      测试Telegram消息"
        echo "  --help      显示此帮助"
        echo ""
        echo "📋 配置说明:"
        echo "  请编辑脚本开头的配置变量:"
        echo "  - TELEGRAM_BOT_TOKEN: 你的Telegram Bot Token"
        echo "  - TELEGRAM_CHAT_ID: 你的Telegram Chat ID"
        echo "  - IP_CHECK_INTERVAL: 检查间隔(秒)"
        ;;
    *)
        echo "未知选项: $1"
        echo "使用 '$0 --help' 查看帮助"
        exit 1
        ;;
esac