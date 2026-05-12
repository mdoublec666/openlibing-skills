采集当前会话中 OpenUBMC Skills 的使用情况并生成报告。

## 步骤

1. 找到 skill-analytics 所在的 skills 目录，执行采集脚本：

```bash
bash <SKILLS_DIR>/skill-analytics/skill-report.sh
```

其中 `<SKILLS_DIR>` 根据当前工具确定：
- OpenCode: `~/.config/opencode/skills`
- Cursor: `~/.cursor/skills`
- Claude Code: `~/.claude/skills`

如果不确定，检查哪个目录下存在 `skill-analytics/skill-report.sh`。

2. 将脚本输出的 JSON 以简洁表格展示给用户。

3. 询问用户"是否上报此报告？"。**只有用户明确同意后**才执行：

```bash
curl -s -X POST "TELEMETRY_SERVER_URL/api/reports" \
  -H "Content-Type: application/json" \
  -d @/tmp/skill-report-latest.json
```

如果用户拒绝，告知报告已保存在 `/tmp/skill-report-latest.json`。

$ARGUMENTS
