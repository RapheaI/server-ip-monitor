# 🚀 服务器IP变更监控系统

一个功能完整的服务器IP变更监控和Telegram推送系统，具有企业级的进程守护和自动恢复能力。

## 🌟 特性

### 🛡️ 多层保护架构
- **进程守护** - 自动监控和重启
- **Systemd服务** - 原生系统服务集成
- **看门狗定时器** - 定时健康检查和恢复
- **自动恢复** - 故障时无需人工干预

### 📱 智能通知
- **Telegram推送** - IP变更即时通知
- **系统告警** - 服务异常自动告警
- **测试消息** - 配置验证功能
- **Markdown格式** - 美观的消息展示

### 🔧 专业功能
- **多重IP查询** - 多个可靠的IP查询服务
- **历史追踪** - 完整的IP变更历史记录
- **详细日志** - 完整的运行和调试日志
- **一键部署** - 简单的安装和配置

## 🚀 快速开始

### 🌸 椿卷ฅ推荐的最佳语法
```bash
# 🎯 所有脚本都使用这个语法！
bash <(curl -s https://raw.githubusercontent.com/RapheaI/server-ip-monitor/main/ip-monitor-universal.sh)
```

### 其他脚本语法
```bash
# 卸载脚本
bash <(curl -s https://raw.githubusercontent.com/RapheaI/server-ip-monitor/main/ip-monitor-uninstall.sh)

# ARM兼容性检查
bash <(curl -s https://raw.githubusercontent.com/RapheaI/server-ip-monitor/main/arm-compatibility-check.sh)

# 交互式安装
bash <(curl -s https://raw.githubusercontent.com/RapheaI/server-ip-monitor/main/ip-monitor-interactive.sh)
```

### 2. 配置Telegram机器人
按照 [Telegram机器人创建指南](./telegram-bot-guide.md) 配置Bot Token和Chat ID。

### 3. 编辑配置
```bash
# 编辑脚本配置
vim ip-monitor-with-guard.sh
# 修改 TELEGRAM_BOT_TOKEN 和 TELEGRAM_CHAT_ID
```

### 4. 测试配置
```bash
./ip-monitor-with-guard.sh --test
```

### 5. 安装服务
```bash
./ip-monitor-with-guard.sh --install
systemctl daemon-reload
systemctl enable --now ip-monitor-guard.service
systemctl enable --now ip-monitor-watchdog.timer
```

## 📁 文件说明

### 核心脚本
- `ip-monitor-universal.sh` - **通用版**（推荐）支持 bash <(curl) 语法
- `ip-monitor-interactive.sh` - 交互式安装脚本
- `ip-monitor-with-guard.sh` - 增强版包含完整进程守护
- `ip-monitor-bot.sh` - 基础版IP监控脚本
- `ip-monitor-setup.sh` - 快速设置指南脚本

### 文档
- `telegram-bot-guide.md` - Telegram机器人创建指南
- `process-guard-config.md` - 进程守护配置说明

## ⚙️ 配置说明

### 主要配置变量
```bash
TELEGRAM_BOT_TOKEN=""      # 你的Telegram Bot Token
TELEGRAM_CHAT_ID=""         # 你的Telegram Chat ID
IP_CHECK_INTERVAL=300       # IP检查间隔(秒)
MAX_RESTART_ATTEMPTS=5      # 最大重启尝试次数
RESTART_DELAY=30            # 重启延迟(秒)
```

### 服务组件
- `ip-monitor-guard.service` - 主守护进程服务
- `ip-monitor-watchdog.service` - 看门狗检查服务
- `ip-monitor-watchdog.timer` - 定时检查定时器

## 📊 使用命令

### 状态检查
```bash
./ip-monitor-with-guard.sh --status
systemctl status ip-monitor-guard.service
```

### 服务管理
```bash
# 重启服务
systemctl restart ip-monitor-guard.service

# 停止服务
systemctl stop ip-monitor-guard.service

# 查看日志
tail -f /var/log/ip-monitor.log
tail -f /var/log/ip-monitor-guard.log
```

### 手动操作
```bash
# 单次IP检查
./ip-monitor-with-guard.sh --check

# 看门狗检查
./ip-monitor-with-guard.sh --watchdog-check

# 测试Telegram消息
./ip-monitor-with-guard.sh --test
```

## 🛡️ 进程守护架构

### 三层保护
1. **进程守护层** - 60秒健康检查，自动重启
2. **系统服务层** - systemd原生守护，重启策略
3. **看门狗层** - 5分钟定时检查，服务恢复

### 健康检查
- 进程存在性验证
- 健康时间戳检查（5分钟阈值）
- 文件完整性检查
- 功能测试验证

## 📱 Telegram消息示例

### IP变更通知
```
🚨 *服务器IP变更通知*

*服务器*: `AIshy`
*原IP*: `192.168.1.100`
*新IP*: `203.0.113.50`
*时间*: 2026-02-21 06:45:23

💡 请及时更新相关配置
```

### 系统告警
```
🚨 *IP监控守护进程告警*

监控进程已连续重启 5 次，守护进程停止。请检查系统状态。
```

## 🔧 故障排除

### 常见问题

**Q: Telegram消息发送失败**
- 检查Bot Token和Chat ID格式
- 确认机器人有发送消息权限
- 验证网络连接

**Q: IP获取失败**
- 检查网络连接
- 尝试手动访问IP查询服务
- 查看详细日志定位问题

**Q: 服务无法启动**
- 检查文件权限
- 查看systemd日志: `journalctl -u ip-monitor-guard.service`
- 验证依赖服务状态

### 日志文件
- `/var/log/ip-monitor.log` - 主运行日志
- `/var/log/ip-monitor-guard.log` - 守护进程日志
- `/var/lib/ip-monitor/ip-history.txt` - IP变更历史

## 📄 许可证

MIT License

## 🤝 贡献

欢迎提交Issue和Pull Request！

---

**开发者为椿卷ฅ定制，具有企业级的可靠性和易用性！** 🎉