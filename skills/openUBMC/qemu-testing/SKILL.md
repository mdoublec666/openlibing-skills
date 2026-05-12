---
name: openubmc-qemu-testing
description: 处理 openUBMC 的 QEMU 启动、冒烟验证和 skynet coredump 排查。Use when user asks to "Qemu怎么启动", "Qemu冒烟测试", "Qemu启动后Web不通", "skynet持续coredump", "SSH通但Web不通", "QEMU环境调试". Do NOT use for generic QEMU tutorials or OpenBMC QEMU workflows.
compatibility: Requires openUBMC 1.0.0+, qemu-system-arm >= 6.0.0
metadata:
  author: OpenUBMC Team
  version: 1.2.0
  tags: [openubmc, qemu, skynet, smoke-test, coredump, troubleshooting]
---

# OpenUBMC QEMU 仿真测试

## Instructions

### Step 1: 收集信息

先收集再分析，向用户索要以下信息：

- 实际启动脚本或配置文件
- 镜像路径和版本
- 主机 CPU / 内存和 QEMU 分配的 CPU / memory
- 登录方式、端口映射、串口日志
- 崩溃前后最后一段系统日志

CRITICAL: 禁止虚构 `bingo qemu start`、`bingo qemu stop` 一类命令。优先使用项目内实际启动脚本、配置文件和论坛经验。

### Step 2: 诊断问题类型

根据症状判断属于以下哪类：

- **启动失败**：脚本、镜像、资源配置是否匹配
- **SSH 通但 Web 不通**：端口映射、监听状态、相关服务日志
- **多个 skynet coredump**：并行检查资源压力和组件异常
- **冒烟测试**：系统启动稳定性、SSH / Web / IPMI 可达性、核心服务状态、关键错误日志

### Step 3: 按类型排查

#### QEMU 启动

1. 索要项目内实际启动脚本或配置文件
2. 确认镜像版本、CPU / memory、端口映射
3. 基于实际脚本解释启动方式，不自行发明命令

#### SSH 通但 Web 不通

1. 确认端口映射和监听状态
2. 查看 Web 相关服务是否成功拉起
3. 检查日志和网络配置

#### skynet 持续 coredump

如果日志类似：

```text
coredump:do_coredump ..., task skynet ... start
coredump:coredump_wait ..., task skynet ... star wait
```

优先做三件事：

1. 检查主机资源和 QEMU 分配资源是否紧张
2. 检查崩溃前最后一段系统日志
3. 判断是资源压力还是组件本身异常

#### 冒烟测试

至少确认：

- 系统能稳定启动
- SSH / Web / IPMI 是否可达
- 核心服务是否持续运行
- 是否存在连续重启或 coredump

### 关键规则

- CRITICAL: 严格区分 openUBMC 和 OpenBMC，禁止默认套用 OpenBMC 启动方式
- CRITICAL: 优先使用项目内实际启动脚本和配置文件，禁止自行发明命令
- CRITICAL: QEMU 报错时先判断是资源压力、网络映射、服务未拉起、skynet 崩溃，还是组件本身异常
- 禁止直接断言"就是资源不足"
- 禁止把论坛示例硬套到不同仓库或不同镜像版本
- 禁止在没有现场上下文时生成自造 E2E 脚本
- 禁止把 QEMU 启动问题直接等同于组件测试失败

## Examples

### 示例 1：QEMU 启动

1. 索要项目内实际启动脚本或配置文件
2. 确认镜像版本、CPU / memory、端口映射
3. 基于实际脚本解释启动方式，不自行发明命令

### 示例 2：SSH 可以，Web 不通

1. 确认端口映射和监听状态
2. 查看 Web 相关服务是否成功拉起
3. 检查日志和网络配置

### 示例 3：skynet 持续 coredump

如果日志类似：

```text
coredump:do_coredump ..., task skynet ... start
coredump:coredump_wait ..., task skynet ... star wait
```

1. 检查主机资源和 QEMU 分配资源是否紧张
2. 检查崩溃前最后一段系统日志
3. 判断是资源压力还是组件本身异常

### 示例 4：冒烟测试

至少确认：

- 系统能稳定启动
- SSH / Web / IPMI 是否可达
- 核心服务是否持续运行
- 是否存在连续重启或 coredump

## Troubleshooting

### QEMU 启动后立即退出

原因：镜像路径不正确、主机资源不足或启动脚本参数错误。

解决方案：

1. 确认镜像文件存在且路径正确
2. 检查主机 CPU / 内存是否足够
3. 查看串口日志中的错误信息
4. 对比启动脚本与论坛中已验证的配置

### SSH 连接成功但 Web 端口不通

原因：端口映射缺失、Web 服务未启动或网络配置异常。

解决方案：

1. 确认 QEMU 启动参数中的端口映射包含 Web 端口
2. SSH 进入后检查 Web 服务状态
3. 检查防火墙和网络接口配置

### skynet 连续 coredump 重启

原因：主机资源紧张导致 QEMU 内存不足，或某个组件异常。

解决方案：

1. 检查主机 CPU / 内存使用率
2. 增加 QEMU 分配的 memory
3. 查看 coredump 前最后一段 `journalctl` 日志
4. 如果是特定组件引起，单独禁用该组件后验证

### 冒烟测试部分服务不可达

原因：服务启动顺序问题或依赖服务未就绪。

解决方案：

1. 等待系统完全启动后再测试（通常需要 2-5 分钟）
2. 检查各服务状态：`systemctl status <service>`
3. 查看系统日志确认是否有启动异常

## References

- Qemu 使用指南论坛帖: <https://discuss.openubmc.cn/t/topic/636>
- Qemu 仿真应用之冒烟测试篇论坛帖: <https://discuss.openubmc.cn/t/topic/2155>
