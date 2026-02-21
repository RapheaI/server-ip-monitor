# 🌸 椿卷ฅ的IP监控通知系统

## 🚀 简介

这是一个简洁高效的服务器IP变更监控系统，当服务器公网IP发生变化时，自动通过Telegram发送通知。

## ✨ 特性

- ✅ **简洁高效** - 单文件实现完整功能
- ✅ **多IP接口** - 支持多个IP查询服务，确保可靠性
- ✅ **Systemd定时器** - 每5分钟自动检查
- ✅ **Telegram通知** - 专业的Markdown格式消息
- ✅ **原子操作** - 安全的文件写入机制
- ✅ **错误处理** - 完善的错误处理和超时控制

## 📦 快速安装

### 一键安装
```bash
# 使用椿卷ฅ的标准语法
bash <(curl -s https://raw.githubusercontent.com/RapheaI/server-ip-monitor/main/ip-notifier-installer.sh)
```

### 手动安装
```bash
# 1. 下载脚本
curl -s -o ip-notifier-installer.sh https://raw.githubusercontent.com/RapheaI/server-ip-monitor/main/ip-notifier-installer.sh

# 2. 运行安装
chmod +x ip-notifier-installer.sh
sudo ./ip-notifier-installer.sh
```

## 🔧 安装过程

安装脚本会：
1. 🔐 **检查权限** - 确保root权限运行
2. 📝 **交互配置** - 输入Telegram Bot Token和Chat ID
3. 📁 **创建脚本** - 生成监控脚本到 `/usr/local/bin/ip_notifier.sh`
4. ⚙️ **配置服务** - 创建Systemd服务和定时器
5. 🚀 **启动监控** - 启用并启动定时任务

## 📱 通知格式

当IP变更时，你会收到：
```
⚠️ *服务器 IP 变更提醒*
主机: your-server
旧 IP: `192.168.1.1`
新 IP: `192.168.1.2`
时间: 2026-02-21 08:45:23
```

## 🛠️ 管理命令

### 查看服务状态
```bash
# 查看定时器状态
systemctl status ip-check.timer

# 查看服务日志
journalctl -u ip-check.service

# 手动运行检查
/usr/local/bin/ip_notifier.sh
```

### 停止监控
```bash
# 停止定时器
systemctl stop ip-check.timer

# 禁用定时器
systemctl disable ip-check.timer
```

### 重启监控
```bash
# 重启定时器
systemctl restart ip-check.timer
```

## 📁 文件结构

```
/usr/local/bin/ip_notifier.sh     # 主监控脚本
/etc/systemd/system/ip-check.service  # Systemd服务
/etc/systemd/system/ip-check.timer    # Systemd定时器
/var/local/last_known_ip.txt          # IP历史记录
```

## 🔍 技术细节

### IP查询服务
脚本使用多个IP查询服务确保可靠性：
- `https://api.ipify.org`
- `https://ifconfig.me/ip`  
- `https://ipinfo.io/ip`

### 检查频率
- **启动延迟**: 系统启动后1分钟开始检查
- **检查间隔**: 每5分钟检查一次
- **超时设置**: 每个IP查询10秒超时

### 安全特性
- 🔒 **原子写入** - 使用临时文件避免数据损坏
- ⏱️ **超时控制** - 防止网络问题导致的阻塞
- 🛡️ **错误处理** - 优雅处理各种异常情况

## 🐛 故障排除

### 常见问题

#### 1. 没有收到通知
```bash
# 检查服务状态
systemctl status ip-check.timer

# 手动运行测试
/usr/local/bin/ip_notifier.sh

# 查看IP文件
cat /var/local/last_known_ip.txt
```

#### 2. Telegram配置错误
```bash
# 检查配置是否正确
cat /usr/local/bin/ip_notifier.sh | grep -E "TOKEN|CHAT_ID"
```

#### 3. 网络连接问题
```bash
# 测试网络连接
curl -s https://api.ipify.org
```

## 📄 许可证

MIT License - 椿卷ฅ 版权所有

---

**🌸 椿卷ฅ的简洁高效IP监控系统**