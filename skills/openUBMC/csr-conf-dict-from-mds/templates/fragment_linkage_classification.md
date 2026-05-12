<!-- 可选片段：当 CSR 属性中存在 <=/、#/、expr、${ 等动态关联语义时，本片段接在「属性定义详表」之后、「配置示例」之前；否则整文件不拼接。 -->

# 🔗 动态关联机制

## 语法规范

{LinkageSyntaxIntro}

```{LinkageCodeFence}
{LinkageCodeExample}
```

{LinkageExtraH2Blocks}

## 关联说明

{LinkageBullets}

---

# 📂 分类标准

## 硬件属性

- **定义**：与硬件特性和物理参数直接相关的属性
- **特点**：通常与 IPMI / PCIe / NCSI 等协议或硬件扫描路径对应
- **示例**：{HardwareExamples}

---

## 软件属性

- **定义**：用于逻辑控制和软件管理的参数
- **特点**：由 CSR 或组件逻辑维护的配置与状态
- **示例**：{SoftwareExamples}

---
