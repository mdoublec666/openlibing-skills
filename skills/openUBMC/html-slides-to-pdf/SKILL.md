---
name: html-slides-to-pdf
description: 使用 HTML-first 工作流制作演示幻灯片并导出为 PDF。每页一个 HTML 文件，共享 common.css，通过预览页迭代调整，用户确认后再用 Puppeteer + pdf-lib 合并导出。适用于用户要求制作华为风/汇报风幻灯片并导出 PDF，或要求将已有 HTML slides 转成 PDF 时。
---

# HTML Slides to PDF

## 何时使用

- 用户要制作中文汇报/演示幻灯片，最终交付 PDF
- 用户已有一组 HTML slide 文件，要合并导出成一个 PDF
- 用户说"转 PDF"、"导出 PDF"、"生成 PDF"
- 不需要 PPTX 格式，PDF 即可满足需求（如邮件分发、在线预览、打印）

## 与 PPTX 工作流的区别

| 维度 | HTML → PDF（本 skill） | HTML → PPTX（ppt-workflow） |
|---|---|---|
| 输出格式 | PDF（不可编辑，适合分发） | PPTX（可编辑，适合演讲） |
| 排版精度 | 像素级还原，所见即所得 | 受 html2pptx 转换限制，部分样式丢失 |
| 依赖 | Puppeteer + pdf-lib | pptxgenjs + Playwright + Sharp |
| SVG/CSS 支持 | 完整支持 | 部分支持，复杂 SVG 可能异常 |
| 适合场景 | 框图多、SVG 流程图多、精确排版 | 需要后续编辑、加动画、演讲用 |

**经验法则**：如果页面中有 SVG 手画的流程图、架构堆叠图或复杂 CSS 布局，优先走 PDF 路线。

## 文件结构

```
project/
├── slides/
│   ├── common.css          # 共享样式
│   ├── slide01.html        # 每页一个文件
│   ├── slide02.html
│   └── ...
├── icons/                  # 图标资源（可选）
│   └── *.png
├── preview.html            # 预览页（iframe 嵌入所有 slide）
├── export-pdf.js           # PDF 导出脚本
└── Output.pdf              # 输出文件
```

## 制作流程

### 1. 建立基础结构

创建 `slides/common.css` 定义全局样式。默认尺寸 16:9：

```css
body {
  width: 720pt; height: 405pt; margin: 0; padding: 0;
  background: #ffffff;
  font-family: Arial, Helvetica, sans-serif;
  display: flex; flex-direction: column;
  overflow: hidden;
}
```

### 2. 逐页编写 HTML

每页是独立的完整 HTML 文件，引用 `common.css`：

```html
<!DOCTYPE html><html><head>
  <meta charset="UTF-8">
  <link rel="stylesheet" href="common.css">
</head><body>
  <!-- 页面内容 -->
</body></html>
```

### 3. 创建预览页

用 iframe 嵌入所有 slide，方便在浏览器中滚动预览：

```html
<div class="slide-frame">
  <span class="slide-label">01 封面</span>
  <iframe src="slides/slide01.html"></iframe>
</div>
```

预览页设置：
- 每个 iframe 容器 `width: 960px; aspect-ratio: 16/9`
- 灰色背景 `#e8e8e8`，白色 slide 容器带阴影
- 页码标签用 `position: absolute; top: -22px`

### 4. 迭代调整

在浏览器中打开预览页，逐页检查和调整。**关键注意事项：**

- 每次修改 slide HTML 后，刷新预览页即可看到效果
- 页码格式统一为 `XX / 总页数`，增删页后必须全部更新
- 如果 SVG 内容被裁掉，检查 SVG 的 `viewBox` 和容器 `height` 是否一致
- 如果文字被遮挡，增大容器高度或调整元素位置

#### 预览确认门（重要）

**完成所有 slide 的初稿后，必须先展示预览给用户确认，不要立即导出 PDF。**

流程：
1. 完成所有 HTML slide 编写和预览页创建
2. 在浏览器中打开预览页，截图或展示给用户
3. 明确告知用户："初稿已完成，请在预览页中检查布局和内容。如有需要调整的地方请告诉我，确认没问题后我会导出 PDF。"
4. 等待用户反馈——用户确认无误后再进入导出环节
5. 如果有图片占位块，在确认环节一并提醒用户是否需要提供图片（参见 `ppt-internal-reporting` 的图片资源规范）

**禁止行为**：
- ❌ 不等用户确认就自动导出 PDF
- ❌ 每次修改一个 slide 就重新生成整个 PDF
- ❌ 把导出 PDF 作为制作流程的默认最后一步

**正确做法**：
- ✅ 初稿 → 预览展示 → 用户确认 → 仅在确认后导出一次 PDF
- ✅ 修改单个 slide 后只更新该页，重新展示预览，不自动重新导出
- ✅ 用户主动说"导出 PDF"或"生成 PDF"时才执行导出

### 5. 导出 PDF

> **前置条件**：仅在用户确认预览无误，或用户主动要求导出时才执行本步骤。

#### 依赖安装

```bash
npm install puppeteer pdf-lib --save-dev
```

#### 导出脚本

```javascript
const puppeteer = require('puppeteer');
const { PDFDocument } = require('pdf-lib');
const path = require('path');
const fs = require('fs');

const SLIDES_DIR = path.join(__dirname, 'slides');
const TOTAL_SLIDES = 9;  // 按实际页数修改
const SLIDE_WIDTH = 960;
const SLIDE_HEIGHT = 540;

(async () => {
  const browser = await puppeteer.launch({ headless: true });
  const page = await browser.newPage();
  await page.setViewport({ width: SLIDE_WIDTH, height: SLIDE_HEIGHT });

  const merged = await PDFDocument.create();

  for (let i = 1; i <= TOTAL_SLIDES; i++) {
    const num = String(i).padStart(2, '0');
    const htmlPath = path.join(SLIDES_DIR, `slide${num}.html`);
    console.log(`Rendering slide ${num}...`);

    await page.goto(`file://${htmlPath}`, {
      waitUntil: 'networkidle0',
      timeout: 15000
    });
    await new Promise(r => setTimeout(r, 1500));

    const pdfBytes = await page.pdf({
      width: `${SLIDE_WIDTH}px`,
      height: `${SLIDE_HEIGHT}px`,
      printBackground: true,
      margin: { top: 0, right: 0, bottom: 0, left: 0 },
    });

    const doc = await PDFDocument.load(pdfBytes);
    const [pg] = await merged.copyPages(doc, [0]);
    merged.addPage(pg);
  }

  await browser.close();

  const outputPath = path.join(__dirname, 'Output.pdf');
  fs.writeFileSync(outputPath, await merged.save());
  console.log(`Done! → ${outputPath}`);
})();
```

#### 执行

```bash
node export-pdf.js
```

### 6. 关键参数说明

| 参数 | 说明 | 默认值 |
|---|---|---|
| `SLIDE_WIDTH` | 渲染视口宽度（px） | 960 |
| `SLIDE_HEIGHT` | 渲染视口高度（px） | 540 |
| `waitUntil` | 页面加载策略 | `networkidle0` |
| `setTimeout` | 额外等待时间（ms），确保字体/图片加载 | 1500 |
| `printBackground` | 是否渲染背景色 | `true` |

如果 slide 使用了 CDN 资源（如 Mermaid、Google Fonts），可能需要增大 `setTimeout` 到 3000-5000ms。

## SVG 流程图技巧

当需要在 slide 中画流程图时，推荐用 SVG + CSS 绝对定位而非 Mermaid：

### 基本结构

```html
<div style="position:relative;width:680pt;height:260pt;">
  <!-- SVG 箭头层 -->
  <svg viewBox="0 0 680 260"
       style="position:absolute;top:0;left:0;width:680pt;height:260pt;">
    <defs>
      <marker id="arrow" viewBox="0 0 10 10" refX="9" refY="5"
              markerWidth="6" markerHeight="6" orient="auto">
        <path d="M0 1L9 5L0 9z" fill="#595757"/>
      </marker>
    </defs>
    <!-- 直线箭头 -->
    <line x1="100" y1="30" x2="180" y2="30"
          stroke="#595757" stroke-width="1.5" marker-end="url(#arrow)"/>
    <!-- 曲线循环箭头 -->
    <path d="M 400 35 C 400 8 200 8 200 35"
          stroke="#C8102E" stroke-width="1.5" fill="none"
          marker-end="url(#arrow-red)"/>
    <!-- 虚线 -->
    <line ... stroke-dasharray="5 3"/>
  </svg>

  <!-- 节点（CSS 绝对定位） -->
  <div style="position:absolute;left:10pt;top:15pt;width:88pt;height:26pt;
              background:#f5f5f5;border:1.5pt solid #B5B5B5;border-radius:4pt;
              display:flex;align-items:center;justify-content:center;">
    <p style="font-size:9pt;font-weight:800;">节点名称</p>
  </div>
</div>
```

### 注意事项

- SVG `viewBox` 的数值单位要和 CSS `width/height` 的 pt 值一致
- 如果 SVG 内容被裁掉，**同时**检查容器 div、SVG 元素、viewBox 三者的尺寸是否匹配
- 循环箭头用贝塞尔曲线 `C` 或二次贝塞尔 `Q`
- 不要所有节点都用红色——只在关键转折点用红色高亮
- 曲线上的标注文字要和曲线本身拉开距离，否则会重叠
- 两条曲线上下排列时，下方曲线和文字要预留足够空间（增大容器高度）

## 常见问题

| 问题 | 原因 | 解决方式 |
|---|---|---|
| PDF 中文字被裁掉 | SVG viewBox 高度不够 | 增大 viewBox 和容器高度，保持一致 |
| PDF 空白或样式丢失 | `file://` 路径错误 | 检查 `htmlPath` 是否为绝对路径 |
| 图标/图片未显示 | `networkidle0` 超时前未加载完 | 增大 `setTimeout` 等待时间 |
| Mermaid 图太小 | `useMaxWidth: true` 压缩了 SVG | 改用 SVG 手画，或设 `useMaxWidth: false` + JS 后处理 viewBox |
| 页码没更新 | 增删页后忘记同步 | 全局搜索 `/ XX` 替换为新总页数 |
| PDF 页面尺寸不对 | Puppeteer pdf() 的 width/height 和 viewport 不匹配 | 保持两者一致（960×540） |

## 与风格 skill 的关系

- 页面风格和内容规范：按 `ppt-internal-reporting` 或对应的风格 skill 执行
- 本 skill 只负责：文件结构、预览机制、导出流程和 SVG 流程图技巧
