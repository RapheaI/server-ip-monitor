# 🤖 Telegram机器人创建指南

## 📋 创建Telegram Bot

### 步骤1: 创建机器人
1. **打开Telegram**，搜索 `@BotFather`
2. **发送命令**: `/newbot`
3. **设置机器人名称** (显示名称)
4. **设置机器人用户名** (必须以bot结尾，如: `my_ip_monitor_bot`)
5. **复制Bot Token** (格式: `123456789:ABCdefGHIjklMNOpqrsTUVwxyz`)

### 步骤2: 获取Chat ID

#### 方法A: 个人聊天
1. **搜索你的机器人**并开始聊天
2. **发送任意消息**
3. **访问URL**: 
   ```
   https://api.telegram.org/bot<你的Token>/getUpdates
   ```
4. **在JSON中找到** `"chat":{"id":123456789}`

#### 方法B: 群组/频道
1. **将机器人添加到群组/频道**
2. **在群组中发送消息**
3. **使用同样的URL获取Chat ID**

## ⚙️ 配置脚本

### 编辑配置变量
在 `ip-monitor-bot.sh` 中修改:

```bash
TELEGRAM_BOT_TOKEN="123456789:ABCdefGHIjklMNOpqrsTUVwxyz"
TELEGRAM_CHAT_ID="123456789"
```

### 测试配置
```bash
./ip-monitor-bot.sh --test
```

## 🛠️ 高级配置

### 自定义检查间隔
```bash
IP_CHECK_INTERVAL=600  # 10分钟检查一次
```

### 自定义日志位置
```bash
LOG_FILE="/var/log/custom-ip-monitor.log"
IP_HISTORY_FILE="/opt/ip-monitor/history.txt"
```

## 🔧 故障排除

### 常见问题

**Q: 无法获取Chat ID**
- 确保已向机器人发送消息
- 检查Token是否正确
- 等待几秒后重试getUpdates

**Q: 消息发送失败**
- 检查Token和Chat ID格式
- 确认机器人有发送消息权限
- 检查网络连接

**Q: IP获取失败**
- 检查网络连接
- 尝试手动访问IP查询服务
- 考虑使用本地网络接口IP作为备选

## 📊 消息格式示例

### IP变更通知
```
🚨 *服务器IP变更通知*

*服务器*: `AIshy`
*原IP*: `192.168.1.100`
*新IP*: `203.0.113.50`
*时间*: 2026-02-21 06:45:23

💡 请及时更新相关配置
```

### 测试消息
```
🧪 *IP监控测试消息*

这是一个测试消息，用于验证Telegram机器人配置。
*时间*: 2026-02-21 06:45:23
```

## 🚀 自动化部署

### 一键安装
```bash
./ip-monitor-bot.sh --install
systemctl daemon-reload
systemctl enable ip-monitor.service
systemctl start ip-monitor.service
```

### 手动运行
```bash
# 单次检查
./ip-monitor-bot.sh --check

# 守护进程模式
./ip-monitor-bot.sh --daemon

# 查看状态
./ip-monitor-bot.sh --status
```

## 🔒 安全建议

- 🔐 **保护Bot Token** - 不要公开分享
- 📁 **安全存储** - 脚本文件设置适当权限
- 🔄 **定期检查** - 监控脚本运行状态
- 📋 **备份配置** - 保存Token和Chat ID到安全位置

---

**椿卷ฅ，按照这个指南即可快速设置IP监控机器人！** 🎉