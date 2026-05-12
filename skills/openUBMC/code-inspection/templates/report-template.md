# 代码排查报告

## 扫描概况

- **代码仓**: {{repo_name}}
- **扫描时间**: {{scan_time}}
- **扫描文件数**: {{file_count}}
- **发现问题数**: {{issue_count}}

## 问题统计

| 严重级别 | 数量 |
|----------|------|
| ERROR | {{error_count}} |
| WARNING | {{warning_count}} |
| INFO | {{info_count}} |

## 问题列表

### ERROR 级别 ({{error_count}})

{{#each error_issues}}
#### {{this.rule_id}}: {{this.rule_name}}

- **文件**: {{this.file_path}}
- **行号**: {{this.line_number}}
- **代码片段**:
  ```
  {{this.code_snippet}}
  ```
- **问题描述**: {{this.description}}
- **修复建议**: {{this.suggestion}}

{{/each}}

### WARNING 级别 ({{warning_count}})

{{#each warning_issues}}
#### {{this.rule_id}}: {{this.rule_name}}

- **文件**: {{this.file_path}}
- **行号**: {{this.line_number}}
- **代码片段**:
  ```
  {{this.code_snippet}}
  ```
- **问题描述**: {{this.description}}
- **修复建议**: {{this.suggestion}}

{{/each}}

### INFO 级别 ({{info_count}})

{{#each info_issues}}
#### {{this.rule_id}}: {{this.rule_name}}

- **文件**: {{this.file_path}}
- **行号**: {{this.line_number}}
- **问题描述**: {{this.description}}
- **建议**: {{this.suggestion}}

{{/each}}

## 规则统计

| 规则ID | 规则名称 | 严重级别 | 问题数量 |
|--------|----------|----------|----------|
{{#each rule_stats}}
| {{this.rule_id}} | {{this.rule_name}} | {{this.severity}} | {{this.count}} |
{{/each}}

## 扫描范围

- **包含文件模式**: {{include_patterns}}
- **排除文件模式**: {{exclude_patterns}}
- **使用的规则清单**: {{rules_file}}

## 说明

本报告由代码排查技能自动生成，用于识别代码中的潜在问题。请根据严重级别优先处理 ERROR 级别的问题。

---

*报告生成时间: {{scan_time}}*
