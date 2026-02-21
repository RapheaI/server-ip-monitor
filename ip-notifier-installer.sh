#!/bin/bash

# 检查是否为 root 权限
if [ "$EUID" -ne 0 ]; then
    echo "请使用 root 权限运行此脚本（sudo su）。"
    exit 1
fi

echo "--- 🚀 服务器 IP 变更 TG 通知安装程序 ---"

# 1. 交互式获取配置
read -p "请输入你的 Telegram Bot Token: " TG_TOKEN
read -p "请输入你的 Telegram Chat ID: " TG_CHAT_ID

# 2. 创建脚本文件
cat << EOF > /usr/local/bin/ip_notifier.sh
#!/bin/bash
set -euo pipefail

TOKEN="$TG_TOKEN"
CHAT_ID="$TG_CHAT_ID"
IP_FILE="/var/local/last_known_ip.txt"

# 备选 IP 接口
API_LIST=(
    "https://api.ipify.org"
    "https://ifconfig.me/ip"
    "https://ipinfo.io/ip"
)

CURRENT_IP=""
for url in "\${API_LIST[@]}"; do
    CURRENT_IP=\$(curl -s --max-time 10 "\$url") || continue
    if [[ \$CURRENT_IP =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}\$ ]]; then
        break
    else
        CURRENT_IP=""
    fi
done

if [ -z "\$CURRENT_IP" ]; then
    exit 0;
fi

OLD_IP=""
if [ -f "\$IP_FILE" ]; then
    OLD_IP=\$(cat "\$IP_FILE");
fi

if [ "\$CURRENT_IP" != "\$OLD_IP" ]; then
    HOSTNAME=\$(hostname)
    MESSAGE="⚠️ *服务器 IP 变更提醒*%0A主机: \$HOSTNAME%0A旧 IP: \`\$OLD_IP\`%0A新 IP: \`\$CURRENT_IP\`%0A时间: \$(date '+%Y-%m-%d %H:%M:%S')"
    
    curl -s --max-time 10 -X POST "https://api.telegram.org/bot\$TOKEN/sendMessage" \
        -d "chat_id=\$CHAT_ID" \
        -d "parse_mode=Markdown" \
        -d "text=\$MESSAGE" > /dev/null
    
    echo "\$CURRENT_IP" > "\${IP_FILE}.tmp" && mv "\${IP_FILE}.tmp" "\$IP_FILE"
fi
EOF

# 3. 设置权限
chmod +x /usr/local/bin/ip_notifier.sh

# 4. 创建 Systemd Service
cat << EOF > /etc/systemd/system/ip-check.service
[Unit]
Description=Check Public IP and Notify TG
After=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/ip_notifier.sh
EOF

# 5. 创建 Systemd Timer (每5分钟检查一次)
cat << EOF > /etc/systemd/system/ip-check.timer
[Unit]
Description=Run IP Check every 5 minutes

[Timer]
OnBootSec=1min
OnUnitActiveSec=5min
Unit=ip-check.service

[Install]
WantedBy=timers.target
EOF

# 6. 启动定时器
systemctl daemon-reload
systemctl enable --now ip-check.timer

echo "----------------------------------------"
echo "✅ 安装完成！"
echo "📍 脚本位置: /usr/local/bin/ip_notifier.sh"
echo "⏱️ 运行状态: 已开启每 5 分钟自动检测"
echo "🔍 查看日志: journalctl -u ip-check.service"
echo "----------------------------------------"