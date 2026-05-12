# SVG 流程图设计参考

> 从 SKILL.md 按需引用。当 Mermaid 无法满足布局需求时，用 SVG + CSS 绘制流程图。

## 基本结构

节点用 CSS `position:absolute` 的圆角 `<div>`，SVG 层画箭头。关键点：
- 容器 `div` 设 `position:relative`，SVG 和节点都是 `position:absolute`
- SVG `viewBox` 的数值单位要和 CSS `width/height` 的 pt 值一致
- 箭头用 `<marker>` 定义头部，`<line>` 画直线，`<path>` 画曲线

## 关键注意事项

- SVG `viewBox` 的数值单位要和 CSS `width/height` 的 pt 值一致
- 如果 SVG 内容被裁掉，**同时**检查容器 div、SVG 元素、viewBox 三者的尺寸是否匹配
- 循环箭头用贝塞尔曲线 `C` 或二次贝塞尔 `Q`
- 不要全部节点都用红色——只在关键转折点用红色高亮，其余用灰/白
- 曲线上的标注文字要和曲线本身拉开距离，否则会重叠
- 两条曲线上下排列时，下方曲线和文字要预留足够空间（增大容器高度）

## 箭头类型速查

| 类型 | 语法 | 场景 |
|------|------|------|
| 直线箭头 | `<line>` + `marker-end` | 线性流程 |
| 曲线箭头 | `<path d="M... C...">` | 循环、回退、非线性关系 |
| 虚线箭头 | `stroke-dasharray="5 3"` | 可选路径、弱关联 |
| 红色强调箭头 | `stroke="#C8102E"` | 关键转折、高亮路径 |
