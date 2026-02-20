#!/bin/bash

# 🌸 IP监控系统诊断脚本
# 找出原IP显示为arm64的问题根源

echo "=== 🔍 IP监控系统诊断 ==="
echo ""

# 1. 检查历史记录文件
echo "📋 1. 检查历史记录文件:"
if [ -f "/var/lib/ip-monitor/ip-history.txt" ]; then
    echo "历史记录文件内容:"
    cat /var/lib/ip-monitor/ip-history.txt
    echo ""
    echo "最后一行内容:"
    tail -n 1 /var/lib/ip-monitor/ip-history.txt
    echo ""
    echo "提取的IP地址:"
    tail -n 1 /var/lib/ip-monitor/ip-history.txt | cut -d'|' -f2
else
    echo "❌ 历史记录文件不存在"
fi

echo ""

# 2. 检查当前IP获取
echo "📋 2. 检查当前IP获取:"
current_ip=$(curl -s https://api.ipify.org 2>/dev/null || echo "获取失败")
echo "当前IP: $current_ip"

echo ""

# 3. 检查脚本配置
echo "📋 3. 检查脚本配置:"
if [ -f "/usr/local/bin/ip-monitor-arm-optimized.sh" ]; then
    echo "✅ ARM优化脚本存在"
    
    # 检查get_previous_ip函数
    echo "检查get_previous_ip函数:"
    grep -A 5 "get_previous_ip" /usr/local/bin/ip-monitor-arm-optimized.sh
else
    echo "❌ ARM优化脚本不存在"
fi

echo ""

# 4. 检查服务状态
echo "📋 4. 检查服务状态:"
systemctl status ip-monitor-arm.service 2>/dev/null | head -5 || echo "服务未运行"

echo ""

# 5. 修复建议
echo "📋 5. 修复建议:"
echo "如果历史记录中保存了'arm64'，请执行:"
echo "  sudo echo \"\$(date '+%Y-%m-%d %H:%M:%S')|113.10.249.106|arm64\" > /var/lib/ip-monitor/ip-history.txt"
echo ""
echo "或者完全重新安装:"
echo "  bash <(curl -s https://raw.githubusercontent.com/RapheaI/server-ip-monitor/main/ip-monitor-uninstall.sh)"
echo "  bash <(curl -s https://raw.githubusercontent.com/RapheaI/server-ip-monitor/main/ip-monitor-universal.sh)"

echo "=== 🔍 诊断完成 ==="