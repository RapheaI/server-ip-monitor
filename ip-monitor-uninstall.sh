#!/bin/bash

# 🌸 椿卷ฅ的IP监控完全卸载脚本
# 彻底清理所有IP监控系统组件

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 输出函数
print_step() { echo "📋 步骤 $1: $2"; }
print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️ $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }
print_info() { echo -e "${BLUE}💡 $1${NC}"; }

# 用户确认
confirm_uninstall() {
    echo ""
    echo "========================================"
    echo "🚨 IP监控系统完全卸载"
    echo "========================================"
    echo ""
    echo "这将删除以下内容："
    echo "  🔴 所有IP监控服务"
    echo "  🔴 系统服务文件"
    echo "  🔴 监控脚本文件"
    echo "  🔴 日志和历史记录"
    echo "  🔴 配置文件和数据"
    echo ""
    echo "此操作不可逆！"
    echo ""
    
    read -p "确认完全卸载？ [y/N]: " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        print_success "卸载已取消"
        exit 0
    fi
}

# 检测安装的服务
detect_services() {
    local services=()
    
    # 检测可能安装的服务
    if systemctl list-unit-files | grep -q "ip-monitor-arm.service"; then
        services+=("ip-monitor-arm.service")
    fi
    
    if systemctl list-unit-files | grep -q "ip-monitor-guard.service"; then
        services+=("ip-monitor-guard.service")
    fi
    
    if systemctl list-unit-files | grep -q "ip-monitor.service"; then
        services+=("ip-monitor.service")
    fi
    
    echo "${services[@]}"
}

# 检测安装的脚本
detect_scripts() {
    local scripts=()
    
    # 检测可能安装的脚本位置
    if [ -f "/usr/local/bin/ip-monitor-arm-optimized.sh" ]; then
        scripts+=("/usr/local/bin/ip-monitor-arm-optimized.sh")
    fi
    
    if [ -f "/usr/local/bin/ip-monitor-with-guard.sh" ]; then
        scripts+=("/usr/local/bin/ip-monitor-with-guard.sh")
    fi
    
    if [ -f "/usr/local/bin/ip-monitor-bot.sh" ]; then
        scripts+=("/usr/local/bin/ip-monitor-bot.sh")
    fi
    
    if [ -f "/usr/local/bin/ip-monitor-interactive.sh" ]; then
        scripts+=("/usr/local/bin/ip-monitor-interactive.sh")
    fi
    
    if [ -f "/usr/local/bin/ip-monitor-universal.sh" ]; then
        scripts+=("/usr/local/bin/ip-monitor-universal.sh")
    fi
    
    # 当前目录的脚本
    for script in ip-monitor-*.sh; do
        if [ -f "$script" ]; then
            scripts+=("$(pwd)/$script")
        fi
    done
    
    echo "${scripts[@]}"
}

# 停止并禁用服务
stop_services() {
    local services=($(detect_services))
    
    if [ ${#services[@]} -eq 0 ]; then
        print_info "未发现IP监控服务"
        return 0
    fi
    
    print_step "1" "停止和禁用服务"
    
    for service in "${services[@]}"; do
        print_info "处理服务: $service"
        
        # 停止服务
        if systemctl is-active "$service" >/dev/null 2>&1; then
            sudo systemctl stop "$service"
            print_success "已停止: $service"
        else
            print_info "服务未运行: $service"
        fi
        
        # 禁用服务
        if systemctl is-enabled "$service" >/dev/null 2>&1; then
            sudo systemctl disable "$service"
            print_success "已禁用: $service"
        else
            print_info "服务未启用: $service"
        fi
        
        # 重置失败状态
        sudo systemctl reset-failed "$service" 2>/dev/null || true
    done
    
    # 重新加载systemd
    sudo systemctl daemon-reload
    print_success "服务重载完成"
}

# 删除服务文件
remove_service_files() {
    local services=($(detect_services))
    
    print_step "2" "删除服务文件"
    
    for service in "${services[@]}"; do
        local service_file="/etc/systemd/system/$service"
        
        if [ -f "$service_file" ]; then
            sudo rm -f "$service_file"
            print_success "已删除: $service_file"
        else
            print_info "服务文件不存在: $service_file"
        fi
    done
    
    # 重新加载systemd
    sudo systemctl daemon-reload
    print_success "服务文件清理完成"
}

# 删除脚本文件
remove_script_files() {
    local scripts=($(detect_scripts))
    
    print_step "3" "删除脚本文件"
    
    if [ ${#scripts[@]} -eq 0 ]; then
        print_info "未发现IP监控脚本"
        return 0
    fi
    
    for script in "${scripts[@]}"; do
        if [ -f "$script" ]; then
            # 询问是否删除当前目录的脚本
            if [[ "$script" == "./"* ]] || [[ "$script" == "$(pwd)/"* ]]; then
                read -p "删除当前目录脚本 $script? [y/N]: " confirm
                if [[ "$confirm" =~ ^[Yy]$ ]]; then
                    rm -f "$script"
                    print_success "已删除: $script"
                else
                    print_info "保留: $script"
                fi
            else
                # 系统目录的脚本直接删除
                sudo rm -f "$script"
                print_success "已删除: $script"
            fi
        else
            print_info "脚本不存在: $script"
        fi
    done
}

# 删除数据和日志文件
remove_data_files() {
    print_step "4" "删除数据和日志文件"
    
    # 日志文件
    local log_files=(
        "/var/log/ip-monitor.log"
        "/var/log/ip-monitor-guard.log"
        "/var/log/ip-monitor-arm.log"
    )
    
    for log_file in "${log_files[@]}"; do
        if [ -f "$log_file" ]; then
            sudo rm -f "$log_file"
            print_success "已删除: $log_file"
        fi
    done
    
    # 数据文件
    local data_dirs=(
        "/var/lib/ip-monitor"
        "/var/run/ip-monitor"
    )
    
    for data_dir in "${data_dirs[@]}"; do
        if [ -d "$data_dir" ]; then
            sudo rm -rf "$data_dir"
            print_success "已删除: $data_dir"
        fi
    done
    
    # PID和状态文件
    local state_files=(
        "/var/run/ip-monitor.pid"
        "/var/run/ip-monitor.health"
        "/var/run/ip-monitor-arm.pid"
        "/var/run/ip-monitor-arm.health"
    )
    
    for state_file in "${state_files[@]}"; do
        if [ -f "$state_file" ]; then
            sudo rm -f "$state_file"
            print_success "已删除: $state_file"
        fi
    done
}

# 清理进程
cleanup_processes() {
    print_step "5" "清理残留进程"
    
    # 查找并终止IP监控相关进程
    local pids=$(pgrep -f "ip-monitor" 2>/dev/null || true)
    
    if [ -n "$pids" ]; then
        print_info "发现残留进程: $pids"
        
        # 先尝试正常终止
        for pid in $pids; do
            if kill -0 "$pid" 2>/dev/null; then
                kill "$pid" 2>/dev/null
                print_success "已终止进程: $pid"
            fi
        done
        
        # 等待2秒
        sleep 2
        
        # 检查是否还有进程存活
        local remaining_pids=$(pgrep -f "ip-monitor" 2>/dev/null || true)
        
        if [ -n "$remaining_pids" ]; then
            print_warning "强制终止残留进程"
            for pid in $remaining_pids; do
                if kill -0 "$pid" 2>/dev/null; then
                    kill -9 "$pid" 2>/dev/null
                    print_success "已强制终止: $pid"
                fi
            done
        fi
    else
        print_info "未发现残留进程"
    fi
}

# 验证卸载结果
verify_uninstall() {
    print_step "6" "验证卸载结果"
    
    local services=($(detect_services))
    local scripts=($(detect_scripts))
    
    if [ ${#services[@]} -eq 0 ] && [ ${#scripts[@]} -eq 0 ]; then
        print_success "✅ 卸载完成！所有IP监控组件已清理"
    else
        print_warning "⚠️ 部分组件可能未完全清理"
        
        if [ ${#services[@]} -gt 0 ]; then
            echo "残留服务: ${services[*]}"
        fi
        
        if [ ${#scripts[@]} -gt 0 ]; then
            echo "残留脚本: ${scripts[*]}"
        fi
        
        print_info "可以重新运行卸载脚本进行彻底清理"
    fi
    
    # 最终检查进程
    local remaining_pids=$(pgrep -f "ip-monitor" 2>/dev/null || true)
    if [ -n "$remaining_pids" ]; then
        print_warning "仍有进程运行: $remaining_pids"
    else
        print_success "✅ 无残留进程"
    fi
}

# 显示卸载摘要
show_summary() {
    echo ""
    echo "========================================"
    echo "🎉 IP监控系统卸载完成"
    echo "========================================"
    echo ""
    echo "已清理的内容："
    echo "  🔴 系统服务"
    echo "  🔴 监控脚本"
    echo "  🔴 日志文件"
    echo "  🔴 数据文件"
    echo "  🔴 运行进程"
    echo ""
    echo "如果需要重新安装，可以使用："
    echo "  bash <(curl -s https://raw.githubusercontent.com/RapheaI/server-ip-monitor/main/ip-monitor-universal.sh)"
    echo ""
    echo "🌸 感谢使用椿卷ฅ的IP监控系统！"
    echo ""
}

# 主卸载流程
main() {
    confirm_uninstall
    stop_services
    remove_service_files
    remove_script_files
    remove_data_files
    cleanup_processes
    verify_uninstall
    show_summary
}

# 帮助信息
show_help() {
    echo "=== 🌸 IP监控完全卸载脚本 ==="
    echo ""
    echo "用法:"
    echo "  $0                    # 开始交互式卸载"
    echo "  $0 --force           # 强制卸载（不询问确认）"
    echo "  $0 --help            # 显示此帮助"
    echo ""
    echo "功能:"
    echo "  🔴 停止并禁用所有IP监控服务"
    echo "  🔴 删除系统服务文件"
    echo "  🔴 删除监控脚本文件"
    echo "  🔴 清理日志和数据文件"
    echo "  🔴 终止残留进程"
    echo ""
    echo "注意: 此操作不可逆！"
    echo ""
}

# 运行主程序
case "${1:-}" in
    "--help"|"-h")
        show_help
        ;;
    "--force")
        # 强制模式（跳过确认）
        stop_services
        remove_service_files
        remove_script_files
        remove_data_files
        cleanup_processes
        verify_uninstall
        show_summary
        ;;
    "")
        main "$@"
        ;;
    *)
        echo "未知选项: $1"
        show_help
        exit 1
        ;;
esac