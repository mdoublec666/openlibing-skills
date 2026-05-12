---
name: openubmc-debugging
description: 调试 openUBMC 的 Systemd、Skynet、MDB/D-Bus 和 ASAN 问题，用于服务启动失败、资源接口异常、协程或 task 异常、内存泄漏排查。Use when user asks to "服务启动失败", "MDB或D-Bus接口访问失败", "Skynet服务调试", "Lua协程或mc.tasks异常", "ASAN内存泄漏排查", "日志分析", "systemctl排查", "journalctl查日志". Do NOT use for OpenBMC naming conventions or generic Linux debugging without openUBMC context.
compatibility: Requires openUBMC 1.0.0+, systemd >= 245, dbus >= 1.12, skynet >= 1.0.0
metadata:
  author: OpenUBMC Team
  version: 1.3.0
  tags: [openubmc, debugging, systemd, skynet, dbus, mdb, asan, mc.tasks, journalctl, troubleshooting]
---

# OpenUBMC 系统调试

## Instructions

### Step 1: 收集信息

先收集证据，再下结论。区分"事实""推断""下一步验证"。

向用户收集以下信息：

- 服务名、unit 文件、`config.cfg`
- `systemctl` / `journalctl` 输出
- `src/service/main.lua` 或相关启动代码
- `<bus-name>`、`<object-path>`、相关 `mds/*.json`
- ASAN 的编译选项、环境变量、触发命令、日志路径

### Step 2: 定位问题类型

根据症状判断属于以下哪类问题：

- **Systemd 启动问题**：`ExecStart` 是否通过 `skynet + config.cfg` 拉起，依赖和资源限制是否合理
- **Skynet 问题**：是否正确拉起 `sd_bus`，是否包含目标组件，线程数是否合理
- **MDB / D-Bus 问题**：总线名、对象路径、接口和属性是否存在
- **ASAN 问题**：是否配置 `ASAN_OPTIONS` / `UBSAN_OPTIONS` / `LSAN_OPTIONS`，常驻进程是否支持退出检测

### Step 3: 按类型排查

#### Systemd 启动失败

1. 查看服务状态和日志：

```bash
systemctl status <service>
journalctl -u <service> -n 100
```

2. 检查 unit 文件和 `config.cfg`
3. 回查 `src/service/main.lua`

#### 组件未拉起

检查以下配置项：
- `config:set_start(...)` 和 `config:include_app(...)` 是否配置
- `MODULE_NAME`、`thread` 设置
- `src/service/main.lua` 入口逻辑

#### D-Bus / MDB 接口访问失败

1. 确认 `<bus-name>` 和 `<object-path>`
2. 执行：

```bash
source /etc/profile
busctl --user tree <bus-name>
busctl --user introspect <bus-name> <object-path>
```

3. 如果对象不存在，回查 `mds/*.json`、`bingo gen` 和组件初始化逻辑

#### Lua 协程 / task 异常

1. 确认是否使用了 `skynet.fork` 或 `mc.tasks`
2. `skynet.fork` 创建的是协程，不是线程；`skynet.sleep(100)` 是 1 秒
3. 检查是否有长阻塞、错误 sleep 单位、重复任务或未停止任务

#### ASAN 内存泄漏

1. 收集编译选项、环境变量、触发命令和日志路径
2. 确认是否按官方流程启用了退出检测
3. 常驻进程优先按文档触发检测，不先做静态猜测

### 关键规则

- CRITICAL: 严格区分 `openUBMC` 和 `OpenBMC`；禁止默认使用 `xyz.openbmc_project.*` 或 `/xyz/openbmc_project/*`
- CRITICAL: 禁止虚构 `openubmc-manager` 之类未见于官方资料的服务
- CRITICAL: 禁止把 generic Linux 调试技巧当成 openUBMC 官方工作流
- CRITICAL: 禁止在证据不足时断言"这是 openUBMC 的标准实现"
- 优先使用 openUBMC 官方文档出现过的真实示例，如 `bmc_core`、`bmc.kepler.my_app`、`/bmc/demo/MyMDSModel/1`、`sd_bus`
- ASAN 问题优先走官方流程，不先给泛化 `valgrind` 建议

## Examples

### 示例 1：服务启动失败排查

1. 要求提供服务名
2. 检查：

```bash
systemctl status <service>
journalctl -u <service> -n 100
```

3. 查看 unit 文件和 `config.cfg`
4. 回查 `src/service/main.lua`

### 示例 2：D-Bus / MDB 接口访问失败排查

1. 确认 `<bus-name>` 和 `<object-path>`
2. 执行：

```bash
source /etc/profile
busctl --user tree <bus-name>
busctl --user introspect <bus-name> <object-path>
```

3. 如果对象不存在，回查 `mds/*.json`、`bingo gen` 和组件初始化逻辑

### 示例 3：Lua 协程 / task 异常排查

1. 确认是否使用了 `skynet.fork` 或 `mc.tasks`
2. 检查是否误把协程当线程
3. 检查是否有长阻塞、错误 sleep 单位、重复任务或未停止任务

### 示例 4：ASAN 内存泄漏排查

1. 收集编译选项、环境变量、触发命令和日志路径
2. 确认是否按官方流程启用了退出检测
3. 常驻进程优先按文档触发检测，不先做静态猜测

## Troubleshooting

### systemctl status 显示 inactive (dead) 但无报错

原因：unit 文件的 `ExecStart` 路径或参数不正确，或 `config.cfg` 缺失。

解决方案：

1. 确认 unit 文件中 `ExecStart` 的路径和参数
2. 确认 `config.cfg` 文件存在且格式正确
3. 手动执行 `ExecStart` 命令查看输出

### busctl 显示 "No such name"

原因：服务未注册到 D-Bus，或总线名拼写错误。

解决方案：

1. 确认服务已成功启动：`systemctl status <service>`
2. 列出所有已注册的总线名：`busctl --user list`
3. 确认总线名拼写正确（注意大小写）

### skynet.sleep 时间不对

原因：`skynet.sleep(N)` 的单位是 1/100 秒，不是毫秒。`skynet.sleep(100)` = 1 秒。

解决方案：按 1/100 秒为单位换算。常见错误是误以为是毫秒单位。

### ASAN 日志中没有泄漏报告

原因：常驻进程未触发退出检测，或 `ASAN_OPTIONS` 未正确配置。

解决方案：

1. 确认 `ASAN_OPTIONS` 环境变量已设置
2. 常驻进程需按官方文档触发退出检测
3. 确认编译时启用了 `-fsanitize=address` 选项

## References

- 架构简介: <https://www.openubmc.cn/docs/zh/development/design_reference/architecture.html>
- 组件启动配置: <https://www.openubmc.cn/docs/zh/development/design_reference/key_feature/app_startup.html>
- Skynet 开发指南: <https://www.openubmc.cn/docs/zh/development/develop_guide/app_development/skynet_guide.html>
- 扩展对外接口: <https://www.openubmc.cn/docs/zh/development/quick_start/extend_bmc_api.html>
