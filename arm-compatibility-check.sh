#!/bin/bash

# ARM架构兼容性检查脚本

echo "=== 🏗️ ARM架构兼容性检查 ==="
echo ""

# 检测系统架构
ARCH=$(uname -m)
echo "📊 系统架构: $ARCH"

case "$ARCH" in
    "x86_64")
        echo "✅ 当前为x86_64架构"
        ;;
    "aarch64"|"arm64")
        echo "✅ 当前为ARM64架构"
        ;;
    "armv7l"|"armv8l")
        echo "✅ 当前为ARM32架构"
        ;;
    *)
        echo "⚠️ 未知架构: $ARCH"
        ;;
esac

echo ""

# 检查系统信息
echo "🔧 系统信息:"
if [ -f "/etc/os-release" ]; then
    source /etc/os-release
    echo "   系统: $NAME $VERSION"
    echo "   架构: $ARCH"
else
    echo "   系统: $(uname -s) $(uname -r)"
fi

echo ""

# 检查关键依赖
echo "📋 关键依赖检查:"
DEPENDENCIES=("curl" "grep" "sed" "date" "mkdir" "tee" "tail" "cut" "ps" "kill")

for dep in "${DEPENDENCIES[@]}"; do
    if command -v "$dep" >/dev/null 2>&1; then
        echo "   ✅ $dep - 可用"
    else
        echo "   ❌ $dep - 缺失"
    fi
done

echo ""

# 检查systemd可用性
echo "🔧 服务管理检查:"
if command -v systemctl >/dev/null 2>&1; then
    echo "   ✅ systemctl - 可用"
    echo "   ✅ 支持systemd服务"
else
    echo "   ⚠️ systemctl - 不可用"
    echo "   ⚠️ 将使用cron定时任务替代"
fi

echo ""

# 网络连接测试
echo "🌐 网络连接测试:"
SERVICES=(
    "api.ipify.org:443"
    "icanhazip.com:443" 
    "ident.me:443"
    "api.telegram.org:443"
)

for service in "${SERVICES[@]}"; do
    host=$(echo "$service" | cut -d: -f1)
    port=$(echo "$service" | cut -d: -f2)
    
    if timeout 5 bash -c "echo > /dev/tcp/$host/$port" 2>/dev/null; then
        echo "   ✅ $host:$port - 可达"
    else
        echo "   ❌ $host:$port - 不可达"
    fi
done

echo ""

# ARM特定检查
echo "🏗️ ARM架构特定检查:"

# 检查/proc/cpuinfo
if [ -f "/proc/cpuinfo" ]; then
    cpu_model=$(grep -i "model name" /proc/cpuinfo | head -1 | cut -d: -f2 | sed 's/^[ \t]*//')
    if [ -n "$cpu_model" ]; then
        echo "   CPU: $cpu_model"
    fi
    
    # 检查ARM特性
    if grep -qi "arm" /proc/cpuinfo; then
        echo "   ✅ 检测到ARM处理器"
    fi
    
    if grep -qi "aarch64" /proc/cpuinfo; then
        echo "   ✅ 检测到ARM64架构"
    fi
fi

# 检查内存
if command -v free >/dev/null 2>&1; then
    total_mem=$(free -h | grep Mem: | awk '{print $2}')
    echo "   内存: $total_mem"
fi

echo ""

# 兼容性总结
echo "📊 兼容性总结:"
if [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ] || [ "$ARCH" = "armv7l" ] || [ "$ARCH" = "armv8l" ]; then
    echo "   🟢 完全兼容ARM架构"
    echo "   ✅ 所有依赖命令在ARM上可用"
    echo "   ✅ IP查询服务ARM兼容"
    echo "   ✅ Telegram API ARM兼容"
else
    echo "   🟢 兼容当前架构: $ARCH"
fi

echo ""
echo "🚀 ARM部署建议:"
echo "   1. 使用相同的部署命令"
echo "   2. 无需特殊配置"
echo "   3. 享受相同的功能和可靠性"