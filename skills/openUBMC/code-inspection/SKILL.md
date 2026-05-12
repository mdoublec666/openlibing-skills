---
name: code-inspection
description: 通用代码排查技能，支持加载规则清单进行代码静态分析。支持规则编码、场景匹配（代码仓类型、开发语言）、数据筛选（文件名、关键词）、判定条件等维度，输出结构化排查报告。支持生成规则模板和样例规则。Use when user asks to "代码排查", "静态分析", "规则检查", "代码审查", "代码规范检查", "加载规则清单", "生成规则模板".
compatibility: Works with any codebase
metadata:
  author: OpenUBMC Team
  version: 1.1.0
  tags: [code-inspection, static-analysis, code-review, rule-based, linting]
---

# 通用代码排查

## Instructions

### Step 1: 加载或生成规则清单

代码排查的核心是基于规则清单进行扫描。规则清单定义了排查的规则、匹配条件和判定逻辑。

#### 生成规则模板

如果用户没有现成的规则清单，可帮助用户生成规则模板：

1. **询问需求**：了解用户想要检查的问题类型（安全、质量、性能等）
2. **生成模板**：基于用户需求，生成符合 `rules/rules.schema.json` 规范的规则清单
3. **保存文件**：将生成的规则清单保存到指定路径（如 `./rules/custom-rules.yaml`）

参考模板文件：`templates/rule-template.yaml`

#### 规则清单来源

支持以下四种方式指定规则清单，按优先级从高到低：

1. **对话中直接指定**：用户在对话中提供规则文件路径或 URL
   - 本地文件：`/path/to/rules.yaml` 或 `./rules/custom.yaml`
   - 远程 URL：`https://example.com/rules.yaml`

2. **命令行参数**：通过命令行参数 `--rules` 指定
   ```bash
   # 使用本地规则文件
   --rules /path/to/rules.yaml
   
   # 使用远程规则文件
   --rules https://example.com/rules.yaml
   
   # 使用多个规则文件（合并生效）
   --rules ./rules/security.yaml --rules ./rules/quality.yaml
   ```

#### 规则清单加载流程

```
1. 检查对话中是否指定规则文件 → 使用指定规则
2. 检查是否有 --rules 参数 → 使用参数指定规则
3. 检查项目根目录是否存在 .inspection.yaml → 使用配置文件规则
4. 未指定任何规则 → 提示用户提供规则文件路径或 URL
```

**多规则文件合并**：当指定多个规则文件时，按顺序合并所有规则，相同 id 的规则后者覆盖前者。

#### 规则清单格式

规则清单使用 YAML 格式，核心设计理念是**使用自然语言描述，让 AI 理解规则意图并智能执行**。

所有规则文件必须符合 `rules/rules.schema.json` 中定义的 JSON Schema 规范。

```yaml
name: rule-set-name
version: 1.0.0
description: 规则集描述

rules:
  - id: RULE-001
    name: 规则名称
    description: 规则的详细描述，说明要检查什么问题
    severity: error|warning|info
    sceneMatch: 用自然语言描述该规则适用的场景，如"适用于所有项目的源代码文件，但排除测试文件和第三方依赖"
    dataFilter: 用自然语言描述如何筛选可疑代码，如"搜索包含 password、token 等敏感关键词的代码"
    judgmentCondition: 用自然语言描述如何判定问题，如"如果发现将敏感信息直接赋值给变量，则判定为安全问题"
    messageTemplate: "在 {file}:{line} 发现问题：{code}"
    suggestion: 修复建议
```

#### 规则字段详解

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| id | string | 是 | 规则唯一标识，如 `RULE-001` |
| name | string | 是 | 规则名称，简洁明了 |
| description | string | 是 | 规则详细描述，说明要检查什么问题 |
| severity | string | 是 | 严重级别：error/warning/info |
| sceneMatch | string | 是 | 场景匹配的自然语言描述，说明该规则适用的场景 |
| dataFilter | string | 是 | 数据筛选的自然语言描述，说明如何定位可疑代码 |
| judgmentCondition | string | 是 | 判定条件的自然语言描述，说明如何确认问题 |
| examples | array | 是 | 问题案例列表，帮助 AI 更准确地识别问题 |
| exceptions | array | 否 | 例外场景列表，说明哪些情况不应判定为问题 |
| messageTemplate | string | 是 | 问题消息模板，支持变量：{file}、{line}、{code} |
| suggestion | string | 否 | 修复建议 |

#### 自然语言字段说明

**sceneMatch（场景匹配）**：用自然语言描述规则适用的场景，AI 会理解并智能匹配。例如：
- "适用于所有项目的源代码文件，但排除测试文件、配置文件和第三方依赖"
- "适用于 Lua、Python、JavaScript 等语言的业务代码"
- "适用于涉及数据库操作的后端代码"

**dataFilter（数据筛选）**：用自然语言描述如何筛选可疑代码，AI 会据此执行搜索。例如：
- "搜索包含 print、console.log 等调试打印函数的代码"
- "搜索包含 password、token、secret 等敏感关键词的赋值语句"
- "搜索函数定义，特别是没有注释说明的公开函数"

**judgmentCondition（判定条件）**：用自然语言描述如何判定问题，AI 会据此确认。例如：
- "如果代码中存在调试打印语句，且不在测试文件中，则判定为问题"
- "如果发现将敏感信息直接赋值给变量，且值是硬编码的字符串，则判定为安全问题"
- "如果函数体行数超过 50 行，则判定为过长函数"

#### examples 问题案例

**examples（问题案例）**：提供真实的问题代码示例，帮助 AI 更准确地识别问题。每个案例包含：
- code：问题代码片段
- problem：问题描述，说明这段代码存在什么问题
- language：代码语言（可选，默认 general）

例如：
```yaml
examples:
  - code: "print('Debug: user data =', user_data)"
    problem: 遗留的调试打印语句，可能泄露敏感信息且影响性能
    language: python
  - code: "console.log('Testing value:', result);"
    problem: 遗留的调试打印语句，应在生产环境移除
    language: javascript
```

#### exceptions 例外场景

**exceptions（例外场景）**：说明哪些情况不应判定为问题，避免误报。每个例外包含：
- scenario：例外场景描述
- reason：为什么这种情况不应判定为问题
- example：例外情况的代码示例（可选）

例如：
```yaml
exceptions:
  - scenario: 测试文件中的打印语句
    reason: 测试文件需要打印输出以验证测试结果，这是正常的测试行为
    example: "function test_user_login() { print('Test passed') }"
  - scenario: 日志框架的调试级别输出
    reason: 使用 log.debug() 等日志框架是规范的做法，可以控制输出级别
    example: "log.debug('Processing request', request_id)"
```

### Step 2: 执行排查流程

#### 2.1 理解规则意图

1. 读取规则清单，理解每个规则的：
   - sceneMatch：适用的场景描述
   - dataFilter：如何筛选可疑代码
   - judgmentCondition：如何判定问题
   - examples：参考问题案例，理解什么样的代码有问题
   - exceptions：理解例外场景，避免误报

2. 应用 AI 智能理解：
   - 根据场景描述确定扫描范围
   - 理解筛选条件并转化为搜索策略
   - 参照案例理解问题模式
   - 理解判定逻辑并执行验证
   - 检查例外场景，避免误报

#### 2.2 执行智能扫描

**重要**：排查过程必须使用大模型逐个分析疑似问题，不要编写脚本进行自动化排查。

基于自然语言描述执行智能扫描：

1. **场景匹配**：根据 sceneMatch 描述，AI 判断哪些文件需要扫描
2. **数据筛选**：根据 dataFilter 描述，AI 执行关键词搜索、模式匹配等
3. **问题判定**：根据 judgmentCondition 描述和 examples 案例，AI 分析代码上下文并判定问题
4. **例外检查**：根据 exceptions 描述，AI 确认问题是否属于例外场景

### Step 3: 生成排查报告

**重要**：报告仅包含已确认需要修复的问题。以下情况不应出现在报告中：
- 经过判断确认不是问题的代码
- 明确不需要修改的代码（如合理的示例代码、测试数据等）
- 属于例外场景的代码

排查完成后生成 Markdown 格式的报告，包含以下信息：

```markdown
# 代码排查报告

## 扫描概况

- **代码仓**: {repo_name}
- **扫描时间**: {scan_time}
- **扫描文件数**: {file_count}
- **发现问题数**: {issue_count}

## 问题列表

### ERROR 级别 ({error_count})

#### {rule_id}: {rule_name}

- **文件**: {file_path}
- **行号**: {line_number}
- **代码片段**: 
  ```
  {code_snippet}
  ```
- **问题描述**: {description}
- **修复建议**: {suggestion}

### WARNING 级别 ({warning_count})

...

### INFO 级别 ({info_count})

...

## 统计摘要

| 规则ID | 规则名称 | 问题数量 |
|--------|----------|----------|
| RULE-001 | 规则1 | 5 |
| RULE-002 | 规则2 | 3 |
```

### Step 4: 输出报告

报告固定输出到项目根目录下的 `inspection_report.md` 文件中。每次排查会覆盖该文件。

## 关键规则

- CRITICAL: 支持根据用户需求生成规则模板和样例规则
- CRITICAL: 生成规则时必须符合 `rules/rules.schema.json` 规范
- CRITICAL: 规则加载优先级：对话指定 > 命令行参数 > 项目配置文件 > 提示用户提供规则
- CRITICAL: 支持从本地文件路径加载规则，路径可以是绝对路径或相对路径
- CRITICAL: 支持从远程 URL 加载规则文件（HTTP/HTTPS）
- CRITICAL: 支持多个规则文件合并，相同 id 的规则后者覆盖前者
- CRITICAL: 项目配置文件 .inspection.yaml 放在项目根目录
- CRITICAL: 必须先加载规则清单，理解规则意图，再执行排查
- CRITICAL: 使用自然语言描述规则，AI 智能理解并执行
- CRITICAL: 排查过程必须使用大模型逐个分析疑似问题，不要编写脚本进行自动化排查
- CRITICAL: sceneMatch 决定扫描范围，dataFilter 定位疑点，judgmentCondition 确认问题
- CRITICAL: examples 提供问题案例，帮助 AI 更准确识别问题模式
- CRITICAL: exceptions 描述例外场景，避免误报
- CRITICAL: 报告仅包含已确认需要修复的问题，去除明确不需要修改代码、非问题的内容
- CRITICAL: 报告必须包含代码仓、文件、行号、问题描述、规则名等关键信息
- 支持增量扫描，只扫描变更的文件

## Examples

### 示例 1：生成规则模板

```bash
# 用户请求：帮我生成一个检查硬编码密码的规则
# 询问具体需求（检查哪些敏感信息、适用哪些文件类型等）
# 生成规则清单并保存到 ./rules/security.yaml
# 用户可基于生成的规则进行调整
```

### 示例 2：无规则文件时的排查流程

```bash
# 用户请求：请对 /path/to/repo 进行排查
# 提示用户提供规则文件路径或 URL
# 执行排查流程
# 生成报告
```

### 示例 3：使用自定义规则文件排查

```bash
# 用户提供规则清单路径：/path/to/rules.yaml
# 或在对话中说明：使用 /path/to/rules.yaml 规则文件进行排查
# 加载规则清单
# 执行排查
# 生成报告
```

### 示例 4：使用远程规则文件

```bash
# 用户提供 URL：https://example.com/security-rules.yaml
# 或在对话中说明：使用远程规则 https://example.com/security-rules.yaml
# 下载并加载规则
# 执行排查
# 生成报告
```

### 示例 5：使用项目配置文件

```bash
# 项目根目录存在 .inspection.yaml
# 自动加载配置文件中指定的规则
# 执行排查
# 生成报告
```

### 示例 6：合并多个规则文件

```bash
# 用户请求：使用 ./rules/security.yaml 和 ./rules/quality.yaml 进行排查
# 或命令行：--rules ./rules/security.yaml --rules ./rules/quality.yaml
# 合并规则清单
# 执行排查
# 生成报告
```

## Troubleshooting

### 规则清单加载失败

1. 检查 YAML 格式是否正确
2. 使用 JSON Schema 验证规则格式：`rules/rules.schema.json`
3. 检查必填字段是否完整：
   - 规则集必须包含：name、version、rules
   - 每个规则必须包含：id、name、description、severity、sceneMatch、dataFilter、judgmentCondition、examples、messageTemplate
4. 检查字段值是否符合规范：
   - id 格式必须为 `XXX-NNN`（如 SEC-001）
   - severity 必须为 error/warning/info
   - version 必须为语义化版本（如 1.0.0）
5. 检查自然语言描述是否清晰明确（建议长度 10-500 字符）
6. 检查文件路径或 URL 是否可访问
7. YAML 文件必须使用空格缩进（不使用 Tab）

### 外部规则文件加载失败

1. **本地文件路径问题**：
   - 检查文件路径是否正确（支持绝对路径和相对路径）
   - 确认文件扩展名为 `.yaml` 或 `.yml`
   - 检查文件是否有读取权限

2. **远程 URL 问题**：
   - 确认 URL 以 `http://` 或 `https://` 开头
   - 检查网络连接是否正常
   - 确认远程服务器返回正确的 Content-Type
   - 尝试在浏览器中直接访问 URL 验证

3. **项目配置文件问题**：
   - 确认 `.inspection.yaml` 文件在项目根目录
   - 检查配置文件中的 rules 列表格式是否正确
   - 验证配置文件中的路径是相对于项目根目录

4. **多规则文件合并问题**：
   - 检查是否有重复的规则 id（后者会覆盖前者）
   - 确认所有规则文件格式都正确
   - 验证合并后的规则集是否符合预期

### 排查结果为空

1. 检查 sceneMatch 的自然语言描述是否与代码仓匹配
2. 检查 dataFilter 的描述是否能够定位到可疑代码
3. 检查 judgmentCondition 的判定逻辑是否正确
4. 检查自然语言描述是否清晰、具体

### 排查速度慢

1. 优化 sceneMatch 描述，使 AI 更准确理解扫描范围
2. 使用更精确的 dataFilter 描述
3. 明确排除不需要扫描的文件类型或目录

## References

- 代码排查最佳实践: <https://example.com/code-inspection-best-practices>
- 规则编写指南: <https://example.com/rule-writing-guide>
