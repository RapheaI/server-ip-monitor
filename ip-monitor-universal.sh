#!/bin/bash

# 🌸 椿卷ฅ的IP监控通用安装脚本
# 兼容所有shell的一键安装

set -e

# 输出函数
print_step() { echo "📋 步骤 $1: $2"; }
print_success() { echo "✅ $1"; }
print_warning() { echo "⚠️ $1"; }
print_error() { echo "❌ $1"; }
print_title() { echo ""; echo "=== $1 ==="; echo ""; }

# 用户输入
user_input() {
    local prompt="$1" default="$2" var_name="$3"
    if [ -n "$default" ]; then
        read -p "$prompt [$default]: " input
        eval "$var_name=\${input:-$default}"
    else
        read -p "$prompt: " input
        eval "$var_name=\$input"
    fi
}

# 确认函数
user_confirm() {
    local prompt="$1" default="$2"
    if [ "$default" = "y" ]; then
        read -p "$prompt [Y/n]: " confirm
        confirm=${confirm:-y}
    else
        read -p "$prompt [y/N]: " confirm
        confirm=${confirm:-n}
    fi
    [[ "$confirm" =~ ^[Yy]$ ]]
}

# 系统架构检测
detect_architecture() {
    case "$(uname -m)" in
        "aarch64"|"arm64") echo "arm64" ;;
        "armv7l"|"armv8l") echo "arm32" ;;
        "x86_64") echo "x64" ;;
        *) echo "unknown" ;;
    esac
}

# 欢迎界面
show_welcome() {
    clear
    echo "========================================"
    echo "🌸 椿卷ฅ的IP监控通用安装脚本"
    echo "========================================"
    echo ""
    echo "这个脚本将帮助你："
    echo "  🛡️  配置Telegram机器人"
    echo "  🔧  安装IP监控服务"
    echo "  📱  测试消息推送"
    echo "  🚀  完成所有部署"
    echo ""
    echo "请准备好你的Telegram Bot Token和Chat ID"
    echo ""
    
    if ! user_confirm "是否继续安装？" "y"; then
        print_success "安装已取消"
        exit 0
    fi
}

# 系统检查
system_check() {
    print_title "系统环境检查"
    
    local arch=$(detect_architecture)
    print_step "1" "检测系统架构: $arch"
    
    # 检查依赖
    local deps=("curl" "grep" "sed" "systemctl")
    for dep in "${deps[@]}"; do
        if command -v "$dep" >/dev/null 2>&1; then
            print_success "$dep - 可用"
        else
            print_error "$dep - 缺失"
            exit 1
        fi
    done
    
    print_step "2" "检查网络连接"
    if ping -c 1 -W 3 api.telegram.org >/dev/null 2>&1; then
        print_success "网络连接正常"
    else
        print_warning "网络连接可能有问题"
    fi
}

# Telegram配置
telegraｍ_config() {
    print_title "Telegram机器人配置"
    
    echo "🤖 如果你还没有Telegram机器人："
    echo "  1. 在Telegram搜索 @BotFather"
    echo "  2. 发送 /newbot 创建机器人"
    echo "  3. 复制得到的Bot Token"
    echo ""
    echo "💬 获取Chat ID："
    echo "  1. 将机器人添加到聊天"
    echo "  2. 发送消息给机器人"
    echo "  3. 访问: https://api.telegram.org/bot<你的Token>/getUpdates"
    echo "  4. 在JSON中找到 chat.id"
    echo ""
    
    while true; do
        user_input "请输入Telegram Bot Token" "" "TELEGRAM_BOT_TOKEN"
        if [ -n "$TELEGRAM_BOT_TOKEN" ] && [[ "$TELEGRAM_BOT_TOKEN" =~ ^[0-9]+:[a-zA-Z0-9_-]+$ ]]; then
            print_success "Token格式正确"
            break
        else
            print_error "Token格式不正确"
        fi
    done
    
    while true; do
        user_input "请输入Telegram Chat ID" "" "TELEGRAM_CHAT_ID"
        if [ -n "$TELEGRAM_CHAT_ID" ] && [[ "$TELEGRAM_CHAT_ID" =~ ^-?[0-9]+$ ]]; then
            print_success "Chat ID格式正确"
            break
        else
            print_error "Chat ID必须是数字"
        fi
    done
}

# 测试Telegram
test_telegram() {
    print_title "测试Telegram配置"
    print_step "1" "发送测试消息"
    
    local message="🧪 IP监控测试消息\n\n测试成功！\n服务器: $(hostname)\n架构: $(detect_architecture)\n时间: $(date '+%Y-%m-%d %H:%M:%S')"
    local encoded_message=$(echo "$message" | sed 's/ /%20/g; s/\n/%0A/g')
    
    local response=$(curl -s -X POST \
        "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
        -d "chat_id=${TELEGRAM_CHAT_ID}" \
        -d "text=${encoded_message}" \
        -d "parse_mode=Markdown")
    
    if echo "$response" | grep -q '"ok":true'; then
        print_success "测试消息发送成功！"
        return 0
    else
        print_error "测试消息发送失败"
        return 1
    fi
}

# 选择版本
select_version() {
    print_title "选择监控脚本版本"
    
    echo "请选择版本："
    echo "  1. ARM优化版 (树莓派等)"
    echo "  2. 增强版 (x86服务器)"
    echo "  3. 基础版 (轻量级)"
    echo ""
    
    while true; do
        user_input "请选择 [1-3]" "1" "VERSION_CHOICE"
        case "$VERSION_CHOICE" in
            "1")
                SCRIPT_URL="https://raw.githubusercontent.com/RapheaI/server-ip-monitor/main/ip-monitor-arm-optimized.sh"
                SCRIPT_NAME="ip-monitor-arm-optimized.sh"
                SERVICE_NAME="ip-monitor-arm.service"
                print_success "选择: ARM优化版"
                break
                ;;
            "2")
                SCRIPT_URL="https://raw.githubusercontent.com/RapheaI/server-ip-monitor/main/ip-monitor-with-guard.sh"
                SCRIPT_NAME="ip-monitor-with-guard.sh"
                SERVICE_NAME="ip-monitor-guard.service"
                print_success "选择: 增强版"
                break
                ;;
            "3")
                SCRIPT_URL="https://raw.githubusercontent.com/RapheaI/server-ip-monitor/main/ip-monitor-bot.sh"
                SCRIPT_NAME="ip-monitor-bot.sh"
                SERVICE_NAME="ip-monitor.service"
                print_success "选择: 基础版"
                break
                ;;
            *)
                print_error "无效选择"
                ;;
        esac
    done
}

# 下载配置
download_and_config() {
    print_title "下载和配置"
    
    print_step "1" "下载监控脚本"
    if curl -s -o "$SCRIPT_NAME" "$SCRIPT_URL"; then
        print_success "下载成功"
        chmod +x "$SCRIPT_NAME"
    else
        print_error "下载失败"
        exit 1
    fi
    
    print_step "2" "配置Telegram参数"
    sed -i "s/TELEGRAM_BOT_TOKEN=\"\"/TELEGRAM_BOT_TOKEN=\"$TELEGRAM_BOT_TOKEN\"/" "$SCRIPT_NAME"
    sed -i "s/TELEGRAM_CHAT_ID=\"\"/TELEGRAM_CHAT_ID=\"$TELEGRAM_CHAT_ID\"/" "$SCRIPT_NAME"
    print_success "配置完成"
    
    print_step "3" "测试脚本"
    if ./"$SCRIPT_NAME" --test; then
        print_success "测试成功"
    else
        print_warning "测试有警告"
    fi
}

# 安装服务
install_system_service() {
    print_title "安装系统服务"
    
    print_step "1" "安装监控服务"
    ./"$SCRIPT_NAME" --install
    print_success "服务安装成功"
    
    print_step "2" "重载服务"
    systemctl daemon-reload
    print_success "服务重载成功"
    
    print_step "3" "启用自启"
    systemctl enable "$SERVICE_NAME"
    print_success "开机自启已启用"
    
    print_step "4" "启动服务"
    systemctl start "$SERVICE_NAME"
    print_success "监控服务已启动"
}

# 验证安装
verify_installation() {
    print_title "验证安装"
    
    print_step "1" "检查服务状态"
    if systemctl is-active "$SERVICE_NAME" >/dev/null 2>&1; then
        print_success "服务运行中"
    else
        print_error "服务未运行"
    fi
    
    print_step "2" "检查脚本状态"
    ./"$SCRIPT_NAME" --status
    print_success "状态检查完成"
}

# 完成界面
show_completion() {
    print_title "🎉 安装完成！"
    
    print_success "IP监控系统已成功安装"
    echo ""
    echo "📋 安装摘要："
    echo "  🤖 Telegram Bot: 已配置"
    echo "  🛡️  监控服务: $SERVICE_NAME"
    echo "  📱 消息推送: 已测试"
    echo "  🔧 系统架构: $(detect_architecture)"
    echo ""
    echo "🚀 使用命令："
    echo "  systemctl status $SERVICE_NAME"
    echo "  ./$SCRIPT_NAME --status"
    echo "  ./$SCRIPT_NAME --test"
    echo ""
    echo "🌸 感谢使用！"
}

# 帮助信息
show_help() {
    echo "=== 🌸 IP监控通用安装脚本 ==="
    echo ""
    echo "用法:"
    echo "  bash <(curl -s https://raw.githubusercontent.com/RapheaI/server-ip-monitor/main/ip-monitor-universal.sh)"
    echo "  或"
    echo "  curl -s https://raw.githubusercontent.com/RapheaI/server-ip-monitor/main/ip-monitor-universal.sh | bash"
    echo ""
    echo "选项:"
    echo "  无参数   开始交互式安装"
    echo "  --help   显示此帮助"
    echo ""
}

# 主流程
main() {
    show_welcome
    system_check
    telegraｍ_config
    
    if ! test_telegram; then
        if user_confirm "Telegram测试失败，继续安装？" "n"; then
            print_warning "继续安装"
        else
            print_error "安装中止"
            exit 1
        fi
    fi
    
    select_version
    download_and_config
    install_system_service
    verify_installation
    show_completion
}

# 运行
case "${1:-}" in
    "--help"|"-h") show_help ;;
    "") main "$@" ;;
    *) echo "未知选项: $1"; show_help; exit 1 ;;
esac