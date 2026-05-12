# Code Inspection Skill

通用代码排查技能，支持基于规则清单的代码静态分析。

**重要**：本技能使用大模型逐个分析疑似问题，不编写脚本进行自动化排查。这是 AI 驱动的智能分析过程，能够理解代码上下文并做出准确判断。

## 功能特性

- ✅ AI 驱动：使用大模型逐个分析疑似问题，理解代码上下文，准确判断
- ✅ 规则清单驱动：支持 YAML 格式的自定义规则清单
- ✅ 规则模板生成：支持根据需求生成规则模板和样例
- ✅ 多种规则来源：支持本地文件、远程 URL、项目配置文件
- ✅ 规则合并：支持多个规则文件合并，灵活组合检查规则
- ✅ 多维度匹配：场景匹配（代码仓类型、开发语言）、数据筛选（文件名、关键词）、判定条件
- ✅ 灵活配置：支持 include/exclude 模式、正则表达式、关键词搜索
- ✅ 结构化报告：自动生成 Markdown 格式的排查报告

## 目录结构

```
code-inspection/
├── SKILL.md                    # 技能文档
├── skill.json                  # 技能元数据
├── rules/                      # 规则清单目录
│   └── rules.schema.json      # JSON Schema 规范
└── templates/                  # 模板目录
    ├── report-template.md      # 报告模板
    ├── config-template.yaml    # 配置文件模板
    └── rule-template.yaml      # 规则模板
```

## 使用方法

### 1. 生成规则模板

```bash
# 根据需求生成规则清单
帮我生成一个检查硬编码密码的规则

# 生成规则后可保存到本地文件
# ./rules/security.yaml
```

### 2. 使用规则文件

```bash
# 提供规则文件路径
请使用 /path/to/rules.yaml 对 /path/to/repo 进行排查
```

### 3. 使用自定义规则文件

```bash
# 用户提供规则清单路径（支持 .yaml 和 .json 格式）
请使用 /path/to/my-rules.yaml 对 /path/to/repo 进行排查

# 或使用 JSON 格式
请使用 /path/to/my-rules.json 对 /path/to/repo 进行排查
```

### 4. 使用远程规则文件

```bash
# 从远程 URL 加载规则
请使用 https://example.com/rules.yaml 对 /path/to/repo 进行排查
```

### 5. 使用项目配置文件

在项目根目录创建 `.inspection.yaml` 配置文件：

```yaml
# 规则文件列表（支持本地路径和远程 URL）
rules:
  - ./rules/custom-rules.yaml
  - https://example.com/shared-rules.yaml

# 排除特定规则
excludeRules:
  - EX-001

# 输出配置
output:
  format: markdown
  path: ./inspection_report.md
```

然后执行排查，将自动加载配置文件中指定的规则。

### 6. 合并多个规则文件

```bash
# 同时使用多个规则文件
请使用 ./rules/security.yaml 和 ./rules/quality.yaml 对 /path/to/repo 进行排查

# 或在配置文件中指定多个规则文件
rules:
  - ./rules/security.yaml
  - ./rules/quality.yaml
```

### 规则加载优先级

按以下优先级加载规则文件（高优先级优先）：

1. **对话中直接指定**：用户在对话中提供规则文件路径或 URL
2. **命令行参数**：`--rules` 参数指定的规则文件
3. **项目配置文件**：`.inspection.yaml` 中配置的规则
4. **未指定任何规则**：提示用户提供规则文件

## 规则清单格式

规则清单使用 YAML 格式，核心设计理念是**使用自然语言描述，让 AI 理解规则意图并智能执行**。

所有规则文件必须符合 `rules/rules.schema.json` 中定义的 JSON Schema 规范。

```yaml
name: my-rules
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

## 规则字段说明

| 字段 | 必填 | 说明 |
|------|------|------|
| id | 是 | 规则唯一标识，格式：XXX-NNN（如 SEC-001） |
| name | 是 | 规则名称 |
| description | 是 | 规则详细描述，说明要检查什么问题 |
| severity | 是 | 严重级别：error/warning/info |
| sceneMatch | 是 | 场景匹配的自然语言描述 |
| dataFilter | 是 | 数据筛选的自然语言描述 |
| judgmentCondition | 是 | 判定条件的自然语言描述 |
| examples | 是 | 问题案例列表，帮助 AI 更准确识别问题 |
| exceptions | 否 | 例外场景列表，避免误报 |
| messageTemplate | 是 | 问题消息模板，支持变量：{file}、{line}、{code} |
| suggestion | 否 | 修复建议 |

## 自然语言字段说明

### sceneMatch（场景匹配）

用自然语言描述规则适用的场景，AI 会理解并智能匹配。例如：

- "适用于所有项目的源代码文件，但排除测试文件、配置文件和第三方依赖"
- "适用于 Lua、Python、JavaScript 等语言的业务代码"
- "适用于涉及数据库操作的后端代码"

### dataFilter（数据筛选）

用自然语言描述如何筛选可疑代码，AI 会据此执行搜索。例如：

- "搜索包含 print、console.log 等调试打印函数的代码"
- "搜索包含 password、token、secret 等敏感关键词的赋值语句"
- "搜索函数定义，特别是没有注释说明的公开函数"

### judgmentCondition（判定条件）

用自然语言描述如何判定问题，AI 会据此确认。例如：

- "如果代码中存在调试打印语句，且不在测试文件中，则判定为问题"
- "如果发现将敏感信息直接赋值给变量，且值是硬编码的字符串，则判定为安全问题"
- "如果函数体行数超过 50 行，则判定为过长函数"

### examples（问题案例）

提供真实的问题代码示例，帮助 AI 更准确地识别问题。每个案例包含：

- **code**：问题代码片段
- **problem**：问题描述，说明这段代码存在什么问题
- **language**：代码语言（可选，默认 general）

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

### exceptions（例外场景）

说明哪些情况不应判定为问题，避免误报。每个例外包含：

- **scenario**：例外场景描述
- **reason**：为什么这种情况不应判定为问题
- **example**：例外情况的代码示例（可选）

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

## 排查报告示例

**重要**：报告仅包含已确认需要修复的问题。以下情况不应出现在报告中：
- 经过判断确认不是问题的代码
- 明确不需要修改的代码（如合理的示例代码、测试数据等）
- 属于例外场景的代码

```markdown
# 代码排查报告

## 扫描概况

- **代码仓**: my-repo
- **扫描时间**: 2026-04-27 16:30:00
- **扫描文件数**: 150
- **发现问题数**: 23

## 问题列表

### ERROR 级别 (5)

#### SEC-001: 硬编码密钥检查

- **文件**: src/config.lua
- **行号**: 42
- **代码片段**:
  ```
  local password = "admin123"
  ```
- **问题描述**: 发现硬编码的敏感信息
- **修复建议**: 使用环境变量或配置文件管理敏感信息
```

## 创建自定义规则

要创建自定义规则：

1. 创建 YAML 文件，使用自然语言描述规则
2. 验证规则格式是否符合 `rules/rules.schema.json` 规范
3. 重点编写五个核心字段：
   - sceneMatch：描述适用场景（长度 10-500 字符）
   - dataFilter：描述如何筛选可疑代码（长度 10-500 字符）
   - judgmentCondition：描述如何判定问题（长度 10-500 字符）
   - examples：提供问题案例，帮助 AI 识别问题模式（至少 1 个案例）
   - exceptions：描述例外场景，避免误报（可选但推荐）
4. 确保规则 ID 格式正确：`XXX-NNN`（如 SEC-001）
5. 确保 severity 为：error/warning/info
6. 将规则文件放在项目中或托管在远程服务器
7. 使用时指定规则文件路径或 URL

### 编写高质量的 examples 和 exceptions

**好的 examples 示例：**
```yaml
examples:
  - code: "password = 'admin123'"
    problem: 硬编码的密码容易被泄露，应使用环境变量
    language: python
  - code: "const API_KEY = 'sk-1234567890'"
    problem: API Key 直接写在代码中，可能被提交到代码仓库
    language: javascript
```

**不好的 examples 示例：**
```yaml
# 问题描述过于简单，不够具体
examples:
  - code: "password = '123'"
    problem: 有问题
```

**好的 exceptions 示例：**
```yaml
exceptions:
  - scenario: 从环境变量读取敏感信息
    reason: 通过环境变量或配置文件获取是安全的做法
    example: "password = os.getenv('DB_PASSWORD')"
  - scenario: 测试用例中的示例数据
    reason: 测试文件中的假数据用于演示，不是真实敏感信息
    example: "test_password = 'test123' # 仅用于测试"
```

**不好的 exceptions 示例：**
```yaml
# 缺少原因说明
exceptions:
  - scenario: 测试文件
    reason: 允许
```

## 最佳实践

1. **优先级排序**：优先处理 ERROR 级别的问题
2. **增量扫描**：只扫描变更的文件以提高效率
3. **规则调优**：根据项目特点调整规则的严格程度
4. **持续集成**：将代码排查集成到 CI/CD 流程中
5. **使用项目配置**：在项目根目录创建 `.inspection.yaml` 文件，统一团队规则配置
6. **规则共享**：将通用规则托管在远程服务器，团队共享同一套规则标准
7. **规则版本化**：使用语义化版本管理规则集，便于追踪规则变更
