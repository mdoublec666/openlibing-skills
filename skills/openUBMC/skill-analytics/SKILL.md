---
name: skill-analytics
description: 采集当前会话中 OpenUBMC Skills 的使用情况并生成结构化报告。Use when user asks to "上报 skill 使用情况", "skill report", "skill 反馈", "使用报告". Do NOT use for 普通开发任务或非 Skill 相关的问题。
compatibility: Requires bash, jq (optional)
metadata:
  author: OpenUBMC Team
  version: 1.0.0
  tags: [analytics, telemetry, feedback, skills, openubmc]
---

# OpenUBMC Skill Analytics

## Instructions

### Step 1: 执行采集脚本

运行当前 skills 目录下的 `skill-analytics/skill-report.sh` 脚本。脚本会自动：

1. 检测当前使用的 AI 工具（OpenCode / Cursor / Claude Code）
2. 扫描已安装的 Skills 列表
3. 定位并分析当前会话日志，提取 Skill 触发记录、工具调用统计、成功/失败信号
4. 生成脱敏后的 JSON 报告（不含任何用户输入内容）

```bash
bash <SKILLS_DIR>/skill-analytics/skill-report.sh
```

其中 `<SKILLS_DIR>` 是当前 AI 工具的 skills 安装目录。

### Step 2: 展示报告摘要

将脚本输出的 JSON 以简洁可读的表格展示给用户，包括：

- 已安装的 Skills 及安装时长
- 当前会话中触发的 Skills
- 工具调用统计
- 任务结果（成功/失败）
- 错误摘要（如有）

### Step 3: 确认上报

**必须**询问用户是否同意上报。只有用户明确同意后，才执行上报：

```bash
curl -s -X POST "TELEMETRY_SERVER_URL/api/reports" \
  -H "Content-Type: application/json" \
  -d @/tmp/skill-report-latest.json
```

如果用户拒绝，告知报告已保存在 `/tmp/skill-report-latest.json`，用户可以自行查看或删除。

### Key Rules

- CRITICAL: 未经用户确认，禁止执行任何上报操作
- CRITICAL: 脚本仅分析当前会话日志，禁止扫描历史会话
- CRITICAL: 报告中不包含任何用户输入内容、代码片段或文件路径
- 报告仅包含结构化统计数据：Skill 名称、触发次数、工具调用计数、成功/失败状态

## Examples

### 示例：用户完成调试任务后上报

用户使用 debugging skill 排查了一个服务启动问题，然后输入 `/skill-report`：

1. 执行脚本，输出：

```
本次会话 Skill 使用报告：
  触发的 Skill: debugging
  工具调用: bash(5) read(8) grep(3) write(1)
  结果: 成功
  错误: 无
```

2. 询问："是否上报此报告？(Y/n)"
3. 用户确认 → 执行 curl 上报 → 完成

## Troubleshooting

### 脚本报错 "jq not found"

原因：系统未安装 jq。脚本会自动 fallback 到纯 grep/awk 模式，功能不受影响。

### 找不到当前会话日志

原因：AI 工具的日志路径可能与预期不同。脚本会输出警告并仅生成静态信息报告（已安装 Skills 列表）。

### curl 上报失败

原因：网络问题或服务端不可达。报告已保存在 `/tmp/skill-report-latest.json`，用户可稍后重试。
