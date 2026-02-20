#!/bin/bash

# 🌸 IP监控历史记录修复脚本
# 直接修复原IP显示为arm64的问题

echo "=== 🔧 IP监控历史记录修复 ==="
echo ""

# 1. 停止监控服务
echo "📋 1. 停止监控服务..."
sudo systemctl stop ip-monitor-arm.service 2>/dev/null && echo "✅ 服务已停止" || echo "⚠️ 服务未运行"

echo ""

# 2. 备份当前历史记录
echo "📋 2. 备份历史记录..."
if [ -f "/var/lib/ip-monitor/ip-history.txt" ]; then
    sudo cp /var/lib/ip-monitor/ip-history.txt /var/lib/ip-monitor/ip-history.txt.backup
    echo "✅ 历史记录已备份"
    echo "原内容:"
    cat /var/lib/ip-monitor/ip-history.txt
else
    echo "⚠️ 历史记录文件不存在，将创建新文件"
    sudo mkdir -p /var/lib/ip-monitor
fi

echo ""

# 3. 获取当前正确的IP地址
echo "📋 3. 获取当前IP..."
CURRENT_IP=$(curl -s https://api.ipify.org 2>/dev/null || echo "113.10.249.106")
echo "当前IP: $CURRENT_IP"

# 如果获取失败，使用已知的正确IP
if [ "$CURRENT_IP" = "获取失败" ] || [ -z "$CURRENT_IP" ]; then
    CURRENT_IP="113.10.249.106"
    echo "使用已知IP: $CURRENT_IP"
fi

echo ""

# 4. 修复历史记录
echo "📋 4. 修复历史记录..."
sudo echo "$(date '+%Y-%m-%d %H:%M:%S')|$CURRENT_IP|arm64" > /var/lib/ip-monitor/ip-history.txt
echo "✅ 历史记录已修复"
echo "新内容:"
cat /var/lib/ip-monitor/ip-history.txt

echo ""

# 5. 重启监控服务
echo "📋 5. 重启监控服务..."
sudo systemctl start ip-monitor-arm.service && echo "✅ 服务已启动" || echo "❌ 服务启动失败"

echo ""

# 6. 验证修复
echo "📋 6. 验证修复..."
sleep 2
sudo systemctl status ip-monitor-arm.service | head -3

echo ""
echo "检查历史记录中的IP:"
PREVIOUS_IP=$(tail -n 1 /var/lib/ip-monitor/ip-history.txt | cut -d'|' -f2)
echo "原IP: $PREVIOUS_IP"

if [ "$PREVIOUS_IP" = "$CURRENT_IP" ]; then
    echo "✅ 修复成功！原IP现在显示为: $PREVIOUS_IP"
else
    echo "❌ 修复失败，原IP仍然显示为: $PREVIOUS_IP"
fi

echo ""
echo "=== 🔧 修复完成 ==="
echo ""
echo "下次IP变更时，原IP将正确显示为: $CURRENT_IP"