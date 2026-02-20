# 🗑️ IP监控完全卸载指南

## 🌸 椿卷ฅ的IP监控卸载说明

### 📋 卸载脚本功能

#### **完全清理的内容：**
- 🔴 **系统服务** - 停止并禁用所有IP监控服务
- 🔴 **监控脚本** - 删除所有版本的监控脚本
- 🔴 **日志文件** - 清理所有监控日志
- 🔴 **数据文件** - 删除历史记录和状态文件
- 🔴 **运行进程** - 终止所有残留进程

### 🚀 使用方法

#### **方法1: 交互式卸载（推荐）**
```bash
# 🌸 下载并运行卸载脚本
curl -s https://raw.githubusercontent.com/RapheaI/server-ip-monitor/main/ip-monitor-uninstall.sh | bash
```

#### **方法2: 下载后运行**
```bash
# 下载卸载脚本
curl -O https://raw.githubusercontent.com/RapheaI/server-ip-monitor/main/ip-monitor-uninstall.sh

# 运行卸载
chmod +x ip-monitor-uninstall.sh
./ip-monitor-uninstall.sh
```

#### **方法3: 强制卸载**
```bash
# 不询问确认，直接卸载
curl -s https://raw.githubusercontent.com/RapheaI/server-ip-monitor/main/ip-monitor-uninstall.sh | bash -s -- --force
```

### 🔧 卸载流程

#### **6个卸载步骤：**
1. **📋 确认卸载** - 显示将要删除的内容并确认
2. **🛑 停止服务** - 停止并禁用所有IP监控服务
3. **🗂️ 删除服务文件** - 清理systemd服务配置
4. **📜 删除脚本文件** - 删除所有监控脚本
5. **🗄️ 清理数据** - 删除日志、历史记录和状态文件
6. **🔪 终止进程** - 清理所有残留进程

### 💡 使用场景

#### **重新安装前清理**
```bash
# 先完全卸载旧版本
curl -s https://raw.githubusercontent.com/RapheaI/server-ip-monitor/main/ip-monitor-uninstall.sh | bash

# 然后安装新版本
bash <(curl -s https://raw.githubusercontent.com/RapheaI/server-ip-monitor/main/ip-monitor-universal.sh)
```

#### **解决安装问题**
```bash
# 如果安装失败或服务无法启动，先卸载
curl -s https://raw.githubusercontent.com/RapheaI/server-ip-monitor/main/ip-monitor-uninstall.sh | bash --force

# 然后重新安装
bash <(curl -s https://raw.githubusercontent.com/RapheaI/server-ip-monitor/main/ip-monitor-universal.sh)
```

#### **多服务器管理**
```bash
# 在多台服务器上批量卸载
ssh user@server1 "curl -s https://raw.githubusercontent.com/RapheaI/server-ip-monitor/main/ip-monitor-uninstall.sh | bash"
ssh user@server2 "curl -s https://raw.githubusercontent.com/RapheaI/server-ip-monitor/main/ip-monitor-uninstall.sh | bash"
```

### 🛡️ 安全保障

#### **卸载前的检查**
- ✅ **服务检测** - 自动检测所有安装的服务
- ✅ **脚本检测** - 查找所有版本的监控脚本
- ✅ **进程检测** - 检查运行中的监控进程
- ✅ **数据检测** - 识别日志和数据文件

#### **安全措施**
- 🔒 **用户确认** - 重要操作前要求确认
- 🔒 **备份提醒** - 提示重要数据备份
- 🔒 **逐步执行** - 分步骤执行，可随时中止
- 🔒 **详细日志** - 显示每个操作的结果

### 📊 卸载验证

#### **验证卸载结果**
```bash
# 检查是否还有服务
systemctl list-unit-files | grep ip-monitor

# 检查是否还有脚本
ls -la /usr/local/bin/ip-monitor-*.sh 2>/dev/null || echo "无脚本文件"

# 检查是否还有进程
pgrep -f ip-monitor && echo "有残留进程" || echo "无残留进程"

# 检查是否还有数据文件
ls -la /var/log/ip-monitor* 2>/dev/null || echo "无日志文件"
ls -la /var/lib/ip-monitor/ 2>/dev/null || echo "无数据目录"
```

#### **手动清理（如果卸载脚本失败）**
```bash
# 手动停止服务
sudo systemctl stop ip-monitor-arm.service ip-monitor-guard.service ip-monitor.service 2>/dev/null || true

# 手动禁用服务
sudo systemctl disable ip-monitor-arm.service ip-monitor-guard.service ip-monitor.service 2>/dev/null || true

# 手动删除服务文件
sudo rm -f /etc/systemd/system/ip-monitor*.service

# 手动删除脚本
sudo rm -f /usr/local/bin/ip-monitor-*.sh

# 手动清理数据
sudo rm -rf /var/log/ip-monitor* /var/lib/ip-monitor /var/run/ip-monitor*

# 手动终止进程
sudo pkill -f ip-monitor 2>/dev/null || true
```

### 🔄 重新安装

#### **卸载后重新安装**
```bash
# 完全卸载
curl -s https://raw.githubusercontent.com/RapheaI/server-ip-monitor/main/ip-monitor-uninstall.sh | bash

# 重新安装
bash <(curl -s https://raw.githubusercontent.com/RapheaI/server-ip-monitor/main/ip-monitor-universal.sh)
```

#### **验证新安装**
```bash
# 检查服务状态
sudo systemctl status ip-monitor-arm.service

# 测试功能
/usr/local/bin/ip-monitor-arm-optimized.sh --test

# 查看状态
/usr/local/bin/ip-monitor-arm-optimized.sh --status
```

---

**椿卷ฅ，现在你拥有了完整的卸载解决方案！** 🎉

**无论是重新安装、解决安装问题，还是完全移除IP监控系统，都可以使用这个卸载脚本！** 🚀

**推荐的使用流程：**
1. **遇到问题** → 运行卸载脚本清理
2. **重新开始** → 使用交互式安装脚本
3. **验证功能** → 测试通知和监控功能

**需要卸载时，只需要运行：**
```bash
curl -s https://raw.githubusercontent.com/RapheaI/server-ip-monitor/main/ip-monitor-uninstall.sh | bash
```

**一切都会自动清理干净！** 🌸