#!/bin/bash

# 🌸 椿卷ฅ的IP监控交互式安装向导
# 一键完成所有配置和部署

set -e  # 遇到错误立即退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 打印彩色消息
print_color() {
    local color="$1"
    local message="$2"
    echo -e "${color}${message}${NC}"
}

# 打印标题
print_title() {
    echo ""
    print_color "$PURPLE" "=== $1 ==="
    echo ""
}

# 打印步骤
print_step() {
    print_color "$CYAN" "📋 步骤 $1: $2"
}

# 打印成功
print_success() {
    print_color "$GREEN" "✅ $1"
}

# 打印警告
print_warning() {
    print_color "$YELLOW" "⚠️ $1"
}

# 打印错误
print_error() {
    print_color "$RED" "❌ $1"
}

# 用户输入函数
user_input() {
    local prompt="$1"
    local default="$2"
    local var_name="$3"
    
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
    local prompt="$1"
    local default="$2"
    
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
    local arch=$(uname -m)
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

# 欢迎界面
show_welcome() {
    clear
    print_color "$PURPLE" "========================================"
    print_color "$PURPLE" "🌸 椿卷ฅ的IP监控交互式安装向导"
    print_color "$PURPLE" "========================================"
    echo ""
    print_color "$CYAN" "这个向导将帮助你："
    echo "  🛡️  配置Telegram机器人"
    echo "  🔧  安装IP监控服务"
    echo "  📱  测试消息推送"
    echo "  🚀  完成所有部署"
    echo ""
    print_color "$YELLOW" "请准备好你的Telegram Bot Token和Chat ID"
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
    local missing_deps=()
    
    for dep in "${deps[@]}"; do
        if command -v "$dep" >/dev/null 2>&1; then
            print_success "$dep - 可用"
        else
            print_error "$dep - 缺失"
            missing_deps+=("$dep")
        fi
    done
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        print_error "缺少必要的依赖: ${missing_deps[*]}"
        if user_confirm "是否尝试安装缺失的依赖？" "y"; then
            install_dependencies "${missing_deps[@]}"
        else
            print_error "无法继续安装"
            exit 1
        fi
    fi
    
    # 检查网络
    print_step "2" "检查网络连接"
    if ping -c 1 -W 3 api.telegram.org >/dev/null 2>&1; then
        print_success "网络连接正常"
    else
        print_warning "网络连接可能有问题，但继续安装"
    fi
}

# 安装依赖
install_dependencies() {
    local deps=("$@")
    
    if command -v apt >/dev/null 2>&1; then
        # Debian/Ubuntu
        print_step "*" "使用APT安装依赖"
        apt update
        apt install -y "${deps[@]}"
    elif command -v yum >/dev/null 2>&1; then
        # CentOS/RHEL
        print_step "*" "使用YUM安装依赖"
        yum install -y "${deps[@]}"
    elif command -v apk >/dev/null 2>&1; then
        # Alpine
        print_step "*" "使用APK安装依赖"
        apk add "${deps[@]}"
    else
        print_error "无法自动安装依赖，请手动安装: ${deps[*]}"
        exit 1
    fi
}

# Telegram配置
telegraｍ_config() {
    print_title "Telegram机器人配置"
    
    print_color "$YELLOW" "🤖 如果你还没有Telegram机器人，请："
    echo "  1. 在Telegram中搜索 @BotFather"
    echo "  2. 发送 /newbot 创建新机器人"
    echo "  3. 设置机器人名称和用户名"
    echo "  4. 复制得到的Bot Token"
    echo ""
    print_color "$YELLOW" "💬 获取Chat ID："
    echo "  1. 将机器人添加到你的聊天"
    echo "  2. 发送任意消息给机器人"
    echo "  3. 访问: https://api.telegram.org/bot<你的Token>/getUpdates"
    echo "  4. 在JSON中找到 chat.id 字段"
    echo ""
    
    while true; do
        user_input "请输入你的Telegram Bot Token" "" "TELEGRAM_BOT_TOKEN"
        
        if [ -n "$TELEGRAM_BOT_TOKEN" ]; then
            # 验证Token格式
            if [[ "$TELEGRAM_BOT_TOKEN" =~ ^[0-9]+:[a-zA-Z0-9_-]+$ ]]; then
                print_success "Token格式正确"
                break
            else
                print_error "Token格式不正确，请重新输入"
            fi
        else
            print_error "Token不能为空"
        fi
    done
    
    while true; do
        user_input "请输入你的Telegram Chat ID" "" "TELEGRAM_CHAT_ID"
        
        if [ -n "$TELEGRAM_CHAT_ID" ] && [[ "$TELEGRAM_CHAT_ID" =~ ^-?[0-9]+$ ]]; then
            print_success "Chat ID格式正确"
            break
        else
            print_error "Chat ID必须是数字，请重新输入"
        fi
    done
}

# 测试Telegram配置
test_telegram() {
    print_title "测试Telegram配置"
    
    print_step "1" "发送测试消息"
    
    local arch=$(detect_architecture)
    local hostname=$(hostname)
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    local message="🧪 *IP监控测试消息*\n\n"
    message+="交互式安装向导测试成功！\n"
    message+="*服务器*: \`$hostname\`\n"
    message+="*架构*: $arch\n"
    message+="*时间*: $timestamp\n"
    message+="\n🎉 配置验证完成！"
    
    # URL编码消息
    local encoded_message=$(echo "$message" | sed 's/ /%20/g; s/\n/%0A/g')
    
    # 发送测试消息
    local response=$(curl -s -X POST \
        "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
        -d "chat_id=${TELEGRAM_CHAT_ID}" \
        -d "text=${encoded_message}" \
        -d "parse_mode=Markdown")
    
    if echo "$response" | grep -q '"ok":true'; then
        print_success "测试消息发送成功！请检查Telegram"
        return 0
    else
        print_error "测试消息发送失败"
        echo "响应: $response"
        return 1
    fi
}

# 选择脚本版本
select_version() {
    print_title "选择监控脚本版本"
    
    local arch=$(detect_architecture)
    
    echo "请选择适合你系统的版本："
    echo ""
    echo "  1. 🏗️ ARM优化版 (推荐用于ARM设备)"
    echo "     适用于: 树莓派、ARM服务器等"
    echo ""
    echo "  2. 🛡️ 增强版 (推荐用于x86服务器)"
    echo "     适用于: 云服务器、VPS等"
    echo ""
    echo "  3. 🔧 基础版 (轻量级)"
    echo "     适用于: 资源有限的设备"
    echo ""
    
    while true; do
        user_input "请选择版本 [1-3]" "1" "VERSION_CHOICE"
        
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
                print_error "无效选择，请输入 1-3"
                ;;
        esac
    done
}

# 下载和配置脚本
download_and_config() {
    print_title "下载和配置监控脚本"
    
    print_step "1" "下载监控脚本"
    if curl -s -o "$SCRIPT_NAME" "$SCRIPT_URL"; then
        print_success "脚本下载成功"
        chmod +x "$SCRIPT_NAME"
    else
        print_error "脚本下载失败"
        exit 1
    fi
    
    print_step "2" "配置Telegram参数"
    # 更新脚本中的配置
    sed -i "s/TELEGRAM_BOT_TOKEN=\"\"/TELEGRAM_BOT_TOKEN=\"$TELEGRAM_BOT_TOKEN\"/" "$SCRIPT_NAME"
    sed -i "s/TELEGRAM_CHAT_ID=\"\"/TELEGRAM_CHAT_ID=\"$TELEGRAM_CHAT_ID\"/" "$SCRIPT_NAME"
    
    print_success "Telegram配置已更新"
    
    print_step "3" "测试配置后的脚本"
    if ./"$SCRIPT_NAME" --test; then
        print_success "脚本测试成功"
    else
        print_warning "脚本测试有警告，但继续安装"
    fi
}

# 安装系统服务
install_system_service() {
    print_title "安装系统服务"
    
    print_step "1" "安装监控服务"
    if ./"$SCRIPT_NAME" --install; then
        print_success "服务安装成功"
    else
        print_error "服务安装失败"
        exit 1
    fi
    
    print_step "2" "重新加载系统服务"
    if systemctl daemon-reload; then
        print_success "服务重载成功"
    else
        print_error "服务重载失败"
        exit 1
    fi
    
    print_step "3" "启用开机自启"
    if systemctl enable "$SERVICE_NAME"; then
        print_success "开机自启已启用"
    else
        print_error "开机自启启用失败"
        exit 1
    fi
    
    print_step "4" "启动监控服务"
    if systemctl start "$SERVICE_NAME"; then
        print_success "监控服务已启动"
    else
        print_error "监控服务启动失败"
        exit 1
    fi
}

# 验证安装
verify_installation() {
    print_title "验证安装结果"
    
    print_step "1" "检查服务状态"
    if systemctl is-active "$SERVICE_NAME" >/dev/null 2>&1; then
        print_success "监控服务运行中"
    else
        print_error "监控服务未运行"
        systemctl status "$SERVICE_NAME"
    fi
    
    print_step "2" "检查脚本状态"
    if ./"$SCRIPT_NAME" --status; then
        print_success "脚本状态检查完成"
    else
        print_warning "脚本状态检查有警告"
    fi
    
    print_step "3" "发送最终测试消息"
    local hostname=$(hostname)
    local arch=$(detect_architecture)
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    local message="🎉 *IP监控系统安装完成*\n\n"
    message+="交互式安装向导已完成所有配置！\n"
    message+="*服务器*: \`$hostname\`\n"
    message+="*架构*: $arch\n"
    message+="*服务*: $SERVICE_NAME\n"
    message+="*时间*: $timestamp\n"
    message+="\n🛡️ IP监控系统现已正式运行！"
    
    local encoded_message=$(echo "$message" | sed 's/ /%20/g; s/\n/%0A/g')
    
    local response=$(curl -s -X POST \
        "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
        -d "chat_id=${TELEGRAM_CHAT_ID}" \
        -d "text=${encoded_message}" \
        -d "parse_mode=Markdown")
    
    if echo "$response" | grep -q '"ok":true'; then
        print_success "最终测试消息发送成功"
    else
        print_warning "最终测试消息发送失败"
    fi
}

# 显示完成信息
show_completion() {
    print_title "🎉 安装完成！"
    
    print_color "$GREEN" "✅ IP监控系统已成功安装并运行"
    echo ""
    print_color "$CYAN" "📋 安装摘要："
    echo "  🤖 Telegram Bot: 已配置"
    echo "  🛡️  监控服务: $SERVICE_NAME"
    echo "  📱 消息推送: 已测试"
    echo "  🔧 系统架构: $(detect_architecture)"
    echo ""
    print_color "$YELLOW" "🚀 下一步操作："
    echo "  1. 等待IP变更通知（如果有变化）"
    echo "  2. 查看服务状态: systemctl status $SERVICE_NAME"
    echo "  3. 查看监控日志: tail -f /var/log/ip-monitor.log"
    echo "  4. 测试手动检查: ./$SCRIPT_NAME --check"
    echo ""
    print_color "$PURPLE" "💡 使用命令："
    echo "  systemctl status $SERVICE_NAME    # 查看服务状态"
    echo "  systemctl restart $SERVICE_NAME   # 重启服务"
    echo "  ./$SCRIPT_NAME --status          # 查看监控状态"
    echo "  ./$SCRIPT_NAME --test           # 测试消息推送"
    echo ""
    print_color "$GREEN" "🌸 感谢使用椿卷ฅ的IP监控系统！"
}

# 主安装流程
main() {
    show_welcome
    system_check
    telegraｍ_config
    
    if ! test_telegram; then
        if user_confirm "Telegram测试失败，是否继续安装？" "n"; then
            print_warning "继续安装，但Telegram功能可能不正常"
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

# 运行主程序
main "$@"