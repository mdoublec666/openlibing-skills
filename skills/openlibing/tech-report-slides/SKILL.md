---
name: tech-report-slides
description: "Creates polished, interactive, single-file HTML slide decks for technical project reporting. Use this skill whenever the user wants to present technical work — operator development, feature delivery, performance optimization, system design, experiment results, architecture decisions, or any engineering initiative. Works from any mix of inputs: design docs, code diffs, benchmark logs, test results, or just a verbal description. Follows a conversational workflow: collect materials → confirm outline & language → choose theme → generate demo preview → iterate to a full deck. Trigger on any of: 做个汇报, 生成演示, presentation, slide deck, slides, 汇报材料, 演示文稿, 做个展示, 汇报一下, PPT, report slides, 做个ppt, technical report, or whenever the user wants to communicate project results to an audience."
---

# 技术汇报幻灯片

从技术项目材料生成精美的自包含 `.html` 幻灯片。单个文件，浏览器直接打开——无需 PowerPoint、无外部依赖、无 CDN。

---

## 工作流程

### 第一步 · 收集与理解材料

接受任意组合的输入——先读完所有材料再提问：

| 输入类型 | 示例 |
|---------|------|
| **文档** | 设计文档、README、变更日志、需求文档、会议记录 |
| **代码** | Diff、PR 描述、实现文件、配置变更 |
| **数据** | 性能测试日志、指标表格、测试结果、耗时数据 |
| **口述** | 用户描述做了什么、改了什么、结果如何 |

读完后，**每次只问一个针对性问题**来补充缺口。优先确认：
1. 做了什么 / 改了什么 / 达成了什么？
2. 核心结果或产出是什么（尽量带数字）？
3. 受众是谁，他们最需要带走什么信息？
4. 幻灯片使用什么语言？（中文 / English / 混合）

### 第二步 · 提出幻灯片大纲

根据材料起草幻灯片结构，用清晰的编号列表展示：

```
1. 封面       — [项目名称]、[一句话副标题]、核心技术标签
2. 背景       — [问题或动机]
3. [内容页]   — [根据材料确定的描述]
...
N. 结论       — [核心指标 / 结论]、下一步
```

同时询问：
- 需要增加或删减的幻灯片？
- 需要重点呈现的具体数据、引用或证明？
- 需要回避的敏感内容？

**等待用户明确确认**后再继续。

### 第三步 · 选择主题

展示两个选项，请用户选择：

| # | 主题 | 风格特点 |
|---|------|---------|
| **1** | Dark · GitHub | 深色背景，蓝/绿/紫 accent——技术感、开发者向 |
| **2** | Light · 暖珊瑚 | 暖奶白背景，珊瑚色 accent——专业、温暖、干净 |

读取 `assets/themes.md` 获取所选主题的完整 CSS 变量。

### 第四步 · 生成 Demo 预览

构建 **3 张预览**：封面 + 背景/问题页 + 一张有代表性的内容页。

输出完整有效的 `.html` 文件，告知文件路径，请用户在浏览器中打开。

然后询问：*「整体观感是否合适？在生成完整版之前，布局、风格或内容有需要调整的吗？」*

**等待反馈**后再进行完整生成。

### 第五步 · 完整生成

生成完整幻灯片组。读取 `assets/components.md` 获取完整的 CSS + HTML 组件库。

**强制设计规则：**
- 每张幻灯片都要有存在的理由——宁可删减，不要用空洞内容凑数
- 数字结果 / 性能数据 → 条形图或统计组件，不要埋在正文段落里
- 3个以上并列概念 → 卡片网格或流程图，不要用原始列表堆砌
- 会让幻灯片拥挤的深层技术细节 → 侧边 detail 面板（点击触发）
- 迭代历程或发布记录 → 时间轴组件
- 结尾必须有结论页，明确写出 2-3 个最重要的结论和下一步

保存为 `presentation.html`（或用户指定的文件名），存放在当前工作目录。

### 第六步 · 迭代修改

询问：*「有需要调整的吗——措辞、某张幻灯片的布局、数据、顺序？」*

应用修改并保存，反复迭代直到用户满意。

---

## 幻灯片类型参考

各类型的 HTML/CSS 实现详见 `assets/components.md`。

| 幻灯片类型 | 适用场景 | 使用的核心组件 |
|-----------|---------|--------------|
| **封面** | 项目介绍 | Kicker 徽章、带 accent `<span>` 的 `h1`、标签 pill |
| **问题/背景** | 说明重要性、难点所在 | 2列网格：问题卡片 + 解法/假设卡片 |
| **架构** | 系统概览、核心组件 | 3列卡片，可点击 → 详情面板 |
| **工作流** | 分步流程、处理管线 | 流程步骤 + 箭头；卡点用 gate 样式标记 |
| **Playbook** | 方法论、阶段划分 | 2×2 阶段卡片网格，可点击 → 详情面板 |
| **时间轴** | 迭代历程、发布记录 | 带分类彩色圆点的 `tl-item` 行 |
| **性能** | 基准测试结果、优化前后对比 | 性能条形图 + 统计组件 |
| **证据** | 数据表格、日志、对比 | 数据表格 + 行内代码块 + App ID 链接 |
| **能力验证** | 已证明的内容、核心成果 | 2×2 图标卡片 + 底部 banner |
| **交付物** | 输出清单 | 带 `cell-ok` ✅ 列的状态表格 |
| **结论** | 总结 + 下一步 | 大号指标数字、斜体引用语、pill 标签 |

---

## 技术要求

- **单个 `.html` 文件** — 所有 CSS 和 JS 内联，无外部资源
- **导航** — 底部 pill 栏含圆点指示器、前/后按钮，键盘快捷键：`← →` / `空格` 翻页，`Esc` 关闭详情面板
- **详情面板** — 右侧遮罩层（宽 480px），带模糊背景，点击卡片/步骤滑入
- **幻灯片切换** — `opacity` 渐隐，`.4s ease`
- **字体栈** — `-apple-system, 'Segoe UI', 'PingFang SC', 'Microsoft YaHei', sans-serif`（兼容中文）
- **不捏造数据** — 数字缺失时使用 `[待补充]`，不要自行编造
- **不使用 CDN 或外部图片** — 如需图形可用内联 SVG；避免指向外部 URL 的 `<img>` 标签

---

## Light 主题适配规则（迭代经验总结）

### 核心认知：不是"颜色换换"

直接把 dark 主题的颜色改浅，会保留所有描边风格，结果是"浅色的 GitHub"，而不是真正的品牌风格。Light 主题需要在**卡片系统、装饰元素、背景纹理**三个维度上做根本性改变。

### 卡片系统

| 卡片类型 | 错误做法 | 正确做法 |
|---------|---------|---------|
| 普通卡片 | `border: 1px solid var(--border)` | `box-shadow` 浮起，无描边，`border-radius: 14–16px` |
| Accent 卡片 | 全框彩色描边 + tint 背景 | 白色背景 + **左侧 3px 色条** + 对应颜色柔和 shadow |
| Flow gate 步骤 | 全框变色 + tint 背景 | **顶部 3px 色条** + 对应 shadow，背景保持白色 |
| Timeline 卡片 | `border: 1px solid` | `box-shadow`，无描边 |

### 装饰元素

- **`.label::before`**：用圆点（6px circle）代替横线
- **Kicker**：实心填充 pill + 白字，纯色背景
- **Tags**：实心浅色填充，无描边
- **Pills / Timeline badge**：实心填充 + 白字，不用描边 tint
- **Banner**：左侧色条 + 主题主 accent 颜色调；不要用紫色描边

### 字体与排版

- 去掉 UI 元素的 `monospace`（性能条标签、stat 数值）；只有真正的代码/技术标识符才用等宽字体
- `h2` 建议 `font-weight: 700`（比 600 更有力量感）
- Light 主题 `p/li` 行高 ≥ 1.75

### 背景纹理（Light · 暖珊瑚 签名）

Light 主题必须有背景纹理，这是品牌感最直观的来源：

```css
/* Light · 暖珊瑚 — 暖色圆点阵列 */
background-image:
  radial-gradient(circle, rgba(26,24,23,.055) 1px, transparent 1px),  /* 28px 圆点 */
  radial-gradient(ellipse 90% 55% at 50% -5%, rgba(217,119,87,.1) 0%, transparent 65%);
background-size: 28px 28px, 100% 100%;
```

### 布局平衡

- **4 个并列 stat** 必须用 `display:grid; grid-template-columns:1fr 1fr` 的 2×2 布局，不要 `flex-direction:column` 竖排——后者会造成右列远高于左列
- 两列用 `align-items: center` 而不是 `start`，避免高度悬殊
- 综合汇总型 stat（如"综合 ratio"）用左侧绿色色条突出，放在 2×2 的第 4 格

### 导航栏

- Light 主题 nav：纯白背景（`rgba(255,255,255,.97)`），无描边，靠 `box-shadow` 浮起
