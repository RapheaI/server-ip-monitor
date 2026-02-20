# 🛡️ 进程守护配置说明

## 📋 守护架构

### 多层保护设计

#### 第一层: 进程守护 (Process Guard)
- **功能**: 监控主进程状态
- **重启策略**: 最大5次重启尝试
- **检测间隔**: 60秒健康检查
- **恢复延迟**: 30秒重启延迟

#### 第二层: 系统服务 (Systemd Service)
- **功能**: systemd原生守护
- **重启策略**: Restart=always
- **检测**: systemd进程监控
- **限制**: StartLimitInterval=300, StartLimitBurst=5

#### 第三层: 看门狗定时器 (Watchdog Timer)
- **功能**: 定时健康检查
- **间隔**: 每5分钟检查一次
- **动作**: 检测失败时重启服务
- **通知**: 发送Telegram告警

## ⚙️ 配置参数

### 守护进程配置
```bash
MAX_RESTART_ATTEMPTS=5    # 最大重启次数
RESTART_DELAY=30          # 重启延迟(秒)
HEALTH_CHECK_INTERVAL=60  # 健康检查间隔(秒)
```

### 文件监控
```bash
PID_FILE="/var/run/ip-monitor.pid"      # 进程ID文件
HEALTH_FILE="/var/run/ip-monitor.health" # 健康时间戳
GUARD_LOG="/var/log/ip-monitor-guard.log" # 守护日志
```

## 🔧 健康检查机制

### 检查项目
1. **进程存在性** - 检查PID是否有效
2. **健康时间戳** - 5分钟内是否有更新
3. **文件完整性** - 必要的文件是否存在
4. **功能测试** - 实际执行IP检查

### 恢复策略
- ✅ **优雅重启** - 先正常停止，再启动
- ⚠️ **强制停止** - 优雅重启失败后强制停止
- 🔄 **延迟重启** - 避免频繁重启循环
- 🚨 **告警通知** - 达到重启上限时发送告警

## 🚀 服务组件

### 主守护服务
```ini
[Service]
Type=forking
ExecStart=/path/script --start-guard
ExecStop=/path/script --stop
ExecReload=/path/script --restart
Restart=always
RestartSec=10
```

### 看门狗服务
```ini
[Service]
Type=oneshot
ExecStart=/path/script --watchdog-check
```

### 定时器
```ini
[Timer]
OnCalendar=*:0/5  # 每5分钟
Persistent=true
```

## 📊 监控指标

### 运行状态
- 🟢 **进程状态** - 运行/停止/重启中
- 📈 **运行时长** - 持续运行时间
- 🔄 **重启次数** - 历史重启统计
- ⚠️ **异常次数** - 健康检查失败次数

### 性能指标
- ⏱️ **响应时间** - IP检查耗时
- 📡 **网络状态** - IP查询成功率
- 💬 **消息发送** - Telegram发送成功率
- 💾 **资源使用** - 内存和CPU占用

## 🔒 安全特性

### 进程隔离
- 🔐 **独立PID** - 每个进程独立标识
- 📁 **文件锁定** - 防止多实例冲突
- 🧹 **资源清理** - 退出时清理临时文件
- 🔄 **状态同步** - 多进程状态同步

### 错误处理
- 🛡️ **优雅降级** - 单点故障不影响整体
- 📋 **错误隔离** - 局部错误不传播
- 🔄 **自动恢复** - 故障后自动重启
- 📢 **及时告警** - 重大故障立即通知

## 🎯 部署策略

### 生产环境
```bash
# 安装服务
./ip-monitor-with-guard.sh --install

# 启动服务
systemctl daemon-reload
systemctl enable --now ip-monitor-guard.service
systemctl enable --now ip-monitor-watchdog.timer

# 验证状态
./ip-monitor-with-guard.sh --status
systemctl status ip-monitor-guard.service
```

### 监控和维护
```bash
# 查看日志
tail -f /var/log/ip-monitor.log
tail -f /var/log/ip-monitor-guard.log

# 服务管理
systemctl restart ip-monitor-guard.service
systemctl status ip-monitor-watchdog.timer

# 手动检查
./ip-monitor-with-guard.sh --watchdog-check
```

## 💡 最佳实践

### 配置优化
1. **调整间隔** - 根据网络状况调整检查间隔
2. **资源限制** - 设置适当的内存和CPU限制
3. **日志轮转** - 配置logrotate防止日志过大
4. **备份配置** - 定期备份重要配置文件

### 故障排查
1. **检查日志** - 首先查看守护进程日志
2. **验证配置** - 确认Telegram配置正确
3. **测试网络** - 验证IP查询服务可达性
4. **检查权限** - 确认文件权限和用户权限

---

**椿卷ฅ，这个进程守护系统提供了企业级的可靠性保障！** 🏆