# 🎯 统一脚本语法指南

## 🌸 椿卷ฅ推荐的标准化语法

### 📋 所有脚本的统一语法

#### **安装脚本**
```bash
# 🌸 椿卷ฅ推荐的最佳语法！
bash <(curl -s https://raw.githubusercontent.com/RapheaI/server-ip-monitor/main/ip-monitor-universal.sh)
```

#### **卸载脚本**
```bash
# 完全卸载
bash <(curl -s https://raw.githubusercontent.com/RapheaI/server-ip-monitor/main/ip-monitor-uninstall.sh)
```

#### **工具脚本**
```bash
# ARM兼容性检查
bash <(curl -s https://raw.githubusercontent.com/RapheaI/server-ip-monitor/main/arm-compatibility-check.sh)

# 交互式安装
bash <(curl -s https://raw.githubusercontent.com/RapheaI/server-ip-monitor/main/ip-monitor-interactive.sh)
```

### 💡 为什么统一使用 bash <(curl)

#### **技术优势**
- ✅ **直接执行** - 无需创建临时文件
- ✅ **更好错误处理** - 完整的错误信息显示
- ✅ **内存执行** - 脚本在内存中运行，更安全
- ✅ **快速响应** - 立即开始交互式操作

#### **用户体验**
- 🎯 **一致性** - 所有脚本使用相同语法
- 🔄 **易记忆** - 只需要记住一种语法格式
- 🛡️ **安全性** - 可以预览脚本内容
- 📱 **便捷性** - 一行命令完成所有操作

### 🚀 完整的使用命令列表

#### **核心功能**
```bash
# 🌸 安装IP监控系统
bash <(curl -s https://raw.githubusercontent.com/RapheaI/server-ip-monitor/main/ip-monitor-universal.sh)

# 🗑️ 完全卸载
bash <(curl -s https://raw.githubusercontent.com/RapheaI/server-ip-monitor/main/ip-monitor-uninstall.sh)
```

#### **工具和检查**
```bash
# 🏗️ ARM兼容性检查
bash <(curl -s https://raw.githubusercontent.com/RapheaI/server-ip-monitor/main/arm-compatibility-check.sh)

# 🔧 交互式安装
bash <(curl -s https://raw.githubusercontent.com/RapheaI/server-ip-monitor/main/ip-monitor-interactive.sh)

# 📱 快速设置
bash <(curl -s https://raw.githubusercontent.com/RapheaI/server-ip-monitor/main/ip-monitor-setup.sh)
```

#### **特定版本**
```bash
# 🏗️ ARM优化版
bash <(curl -s https://raw.githubusercontent.com/RapheaI/server-ip-monitor/main/ip-monitor-arm-optimized.sh)

# 🛡️ 增强版
bash <(curl -s https://raw.githubusercontent.com/RapheaI/server-ip-monitor/main/ip-monitor-with-guard.sh)

# 📱 基础版
bash <(curl -s https://raw.githubusercontent.com/RapheaI/server-ip-monitor/main/ip-monitor-bot.sh)
```

### 🔧 故障排除

#### **如果 bash <(curl) 不支持**
```bash
# 兼容语法（备用方案）
curl -s https://raw.githubusercontent.com/RapheaI/server-ip-monitor/main/ip-monitor-universal.sh | bash
```

#### **如果 curl 不存在**
```bash
# 先安装curl
# Ubuntu/Debian
sudo apt update && sudo apt install -y curl

# CentOS/RHEL
sudo yum install -y curl

# Alpine
sudo apk add curl
```

#### **网络连接问题**
```bash
# 测试GitHub连接
curl -I https://raw.githubusercontent.com/RapheaI/server-ip-monitor/main/ip-monitor-universal.sh

# 使用代理（如果需要）
curl -x http://proxy:port -s https://raw.githubusercontent.com/RapheaI/server-ip-monitor/main/ip-monitor-universal.sh | bash
```

### 🛡️ 安全最佳实践

#### **预览脚本内容**
```bash
# 运行前先查看脚本
curl -s https://raw.githubusercontent.com/RapheaI/server-ip-monitor/main/ip-monitor-universal.sh | head -20

# 或者使用less查看完整内容
curl -s https://raw.githubusercontent.com/RapheaI/server-ip-monitor/main/ip-monitor-universal.sh | less
```

#### **验证脚本来源**
```bash
# 检查URL是否正确
# 正确的格式：
https://raw.githubusercontent.com/RapheaI/server-ip-monitor/main/脚本名称.sh

# 注意：
# - 用户名: RapheaI (你的GitHub账号)
# - 仓库: server-ip-monitor (专用仓库)
# - 分支: main (主分支)
```

### 📊 使用场景

#### **生产环境部署**
```bash
# 在多台服务器上标准化部署
ssh user@server1 "bash <(curl -s https://raw.githubusercontent.com/RapheaI/server-ip-monitor/main/ip-monitor-universal.sh)"
ssh user@server2 "bash <(curl -s https://raw.githubusercontent.com/RapheaI/server-ip-monitor/main/ip-monitor-universal.sh)"
```

#### **自动化脚本集成**
```bash
#!/bin/bash
# 在自动化脚本中调用
echo "正在部署IP监控系统..."
bash <(curl -s https://raw.githubusercontent.com/RapheaI/server-ip-monitor/main/ip-monitor-universal.sh)
echo "部署完成！"
```

#### **容器环境**
```bash
# 在Dockerfile中使用
FROM ubuntu:20.04
RUN apt update && apt install -y curl
RUN bash <(curl -s https://raw.githubusercontent.com/RapheaI/server-ip-monitor/main/ip-monitor-universal.sh)
```

### 🌟 总结

#### **核心原则**
- 🎯 **统一语法** - 所有脚本使用 `bash <(curl ...)`
- 🔄 **一致性** - 相同的使用方式和体验
- 🛡️ **安全性** - 可预览和验证脚本内容
- 📱 **便捷性** - 一行命令完成操作

#### **标准格式**
```bash
bash <(curl -s https://raw.githubusercontent.com/RapheaI/server-ip-monitor/main/脚本名称.sh)
```

---

**椿卷ฅ，现在所有脚本都统一使用最佳语法了！** 🎉

**无论安装、卸载、还是使用工具，都只需要记住这一种语法格式！** 🚀

**核心命令：**
```bash
# 🌸 安装
bash <(curl -s https://raw.githubusercontent.com/RapheaI/server-ip-monitor/main/ip-monitor-universal.sh)

# 🗑️ 卸载  
bash <(curl -s https://raw.githubusercontent.com/RapheaI/server-ip-monitor/main/ip-monitor-uninstall.sh)

# 🛠️ 工具
bash <(curl -s https://raw.githubusercontent.com/RapheaI/server-ip-monitor/main/arm-compatibility-check.sh)
```

**标准化让一切变得更简单！** 🌸