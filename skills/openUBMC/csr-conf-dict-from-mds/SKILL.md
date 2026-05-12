---
name: csr-conf-dict-from-mds
description: 根据 OpenUBMC 组件 MDS 的 model.json 类模型定义，生成或更新 CSR 配置字典说明文档（含文档信息、变更历史、类概览、属性定义详表）；版式由本 skill 内 templates 与 examples 提供，不依赖外部 docs 文件抄格式；详表仅收录 usage 含 CSR 的项；以类名为唯一标识，已存在对应文档时只更新、不重复建文件或重复类章节。输出路径由用户指定；未指定时在组件仓库上层目录中查找 docs 仓库并写入 csr_conf_dict/object。Use when user asks to "根据model.json生成CSR配置字典文档", "生成csr_conf_dict object说明", "从MDS模型写配置指导", "更新类配置字典文档". Do NOT use for unrelated API 文档或不含 model.json 的仓库说明。
compatibility: 需要可读取的组件 `mds/model.json`；格式完全由本 skill 内 `templates/` 与 `examples/` 提供，不依赖外部 docs 文件
metadata:
  author: OpenUBMC Team
  version: 1.0.0
  tags: [openubmc, csr, mds, model-json, documentation, csr_conf_dict]
---

# CSR 配置字典文档（从 MDS model.json 生成）

## 描述范围（强制）

CRITICAL: **属性定义详表**及文档正文对属性的说明，**仅覆盖** `model.json` 中满足以下条件的属性：

- 该属性对应的模型对象上存在 `usage` 字段，且 **`usage` 数组包含字符串 `"CSR"`**（例如 `"usage": ["CSR"]` 或 `"usage": ["CSR", "ReadOnly"]` 等）。

以下情况**不写入**属性详表（可在类概览用脚注说明「未列出非 CSR usage 属性」）：

- 无 `usage` 字段，或 `usage` 中不含 `"CSR"`；
- 仅出现在接口展示类、且无 CSR 标记的属性。

## 唯一标识与已有文档（强制）

CRITICAL: 避免对**同一对象**重复建文件或在同一文档内重复建「类」章节。

1. **类名 = 逻辑对象唯一标识**  
   - 与 `model.json` 中该类的**顶层键名**完全一致（如 `Entity`、`ThresholdSensor`）。同一轮生成任务中，每个类名**只处理一次**，不得为同一类名输出两份内容。

2. **单类单文件（默认）**  
   - 目标文件路径固定为：`{输出目录}/{ClassName}.md`（文件名与类名一致，如 `CPU.md`、`ThresholdSensor.md`）。  
   - 写入前检查该路径是否**已存在**：  
     - **已存在**：进入**更新**流程——在同一文件内刷新文档信息与该类属性表，合并变更历史；**禁止**再创建 `ClassName(2).md`、`_v2.md`、`-copy.md` 等同义副本。  
     - **不存在**：创建新文件。

3. **多类合并为单文档（用户显式指定主文件名时）**  
   - 以用户指定的 **Markdown 主文件名**（如 `Sensor.md`）作为该**文档文件**的唯一标识；同一仓库、同一路径下不得再生成第二个并列文件描述同一组约定。  
   - 文档内每个类仍以 **类名** 区分章节（如 `## Entity 类 - 必选属性`）。更新某一类时，应对该类已有章节做**原地替换**；**禁止**在文末再追加一套同名 `## …{ClassName}…` 或重复整表。

4. **与既有文档冲突时**  
   - 若输出目录已有文件但命名与 `{ClassName}.md` 约定不一致、用户却认定是同一类：暂停自动拆分，请用户确认应以**标准 `{ClassName}.md`** 为准合并，还是保留特殊命名；**不得**在未确认时复制出第二份「同一类」说明。

## Instructions

### Step 0: 向用户确认输入（必做）

生成或更新前必须明确：

1. **目标组件**：用户给出的组件名（用于 SIG 映射，小写，与 `component-sig-mapping.json` 的键一致，如 `sensor`、`chassis`）。
2. **model.json 位置**：默认 `mds/model.json`（相对**组件仓库根目录**）。若不在默认路径，由用户给出相对或绝对路径（技能正文不出现固定盘符路径）。
3. **文档范围**：
   - 生成**单个类**对应的 `{ClassName}.md`，或
   - 像 Sensor 范例一样**一个 Markdown 内包含多个子类章节**（由用户指定主文件名与包含哪些顶层类）。
4. **维护人 / 责任人**：文档表格中需要展示的名称；用户未提供时用 `待补充` 占位。
5. **变更说明**：本次是「新增」还是「修订」，以及一句话变更摘要（用于变更历史表）。

若用户未说明 3，则默认：**每个 `model.json` 顶层对象键名**对应一个 CSR 对象类名，为每个类生成独立文件 `{ClassName}.md`（文件名与类名一致，与 `csr_conf_dict/object/` 下现有命名一致，如 `CPU.md`）。**生成前按上文「唯一标识与已有文档」检查文件是否已存在**：已存在则只更新该文件。若多个类需合并为单文档，必须由用户明确主文件名与章节结构，且合并文档内按类名去重章节。

### Step 1: 解析 `model.json`

1. 读取 JSON，先做语法校验（无效 JSON 则先报错，不生成文档）。
2. 顶层键一般为**资源类名**（如 `ThresholdSensor`、`Entity`）。对每个待生成文档的类：
   - 读取该类对象下的 `path`、`privilege`（如有）、`properties`。
   - 从以下来源收集**候选属性**，再按上文「描述范围」**过滤**：仅保留 `usage` 含 `"CSR"` 的项。
     - 该类顶层的 `properties`（每个子键为属性名，值为属性定义对象）；
     - 该类 `interfaces` 下各接口的 `properties`（若有），同样逐属性检查 `usage`。
   - 若同一属性名在顶层 `properties` 与 `interfaces.*.properties` 中重复出现，**合并为一行**：优先采用信息更完整的定义（含 `baseType` / `description` / `default` 较多者）；必要时在「描述」列用短句注明合并来源。
   - 纳入详表的属性常见字段：`baseType`、`type`、`usage`、`default`、`description`、`readOnly`、`writeOnly`、`enum`、`minimum`、`maximum` 等——以实际 JSON 为准。
3. **必选 / 可选**：若模型无显式 `required` 列表，则按以下约定生成表格分组（并在文档「类概览」或脚注中说明依据）：
   - 存在 `default` 且语义为可缺省 → 归入**可选属性**（与现有 Sensor/CPU 文档习惯一致时，可在描述中说明「有默认值」）。
   - 无 `default` 且为 CSR 关键字段 → 归入**必选属性**；不确定时标为可选并在「变更历史」或脚注注明「需业务确认」。

### Step 2: 输出内容结构（与模板对齐）

生成 Markdown 时**必须包含**以下四块（文档信息、变更历史、类概览、属性详表）；顺序、emoji、`---` 分隔线与扩展章节取舍以 `templates/STRUCTURE.md` 为准，全功能参考见 `examples/complete_example.md`。

1. **YAML Frontmatter**（与范例一致）  
   - `title`: `CSR配置字典之{ClassName}类`  
   - `date`: 当前日期 `YYYY/M/D`

2. **`# 📋 文档信息`**  
   表格列：`文档标题`、`版本`、`创建日期`、`最后更新`、`维护状态`  
   - 新建：`版本` v1.0，`创建日期`与`最后更新`为当天。  
   - 更新：保留原「创建日期」；**递增版本**（小改动 v1.x+1，结构大改 v2.0）；`最后更新`为当天。

3. **`# 📋 变更历史记录`**  
   子标题 `## 文档变更记录`，表格列：`版本`、`发布日期`、`变更类型`、`变更内容`、`影响范围`、`维护人员`  
   - **更新**时：完整保留历史行，在表**顶部**追加新行（最新在上或在下与仓库现有文件保持一致；若读到已有文件，与文件内顺序一致）。

4. **`# 🎯 类概览`**  
   二级标题用 `{ClassOverviewH2}`（见 `document_head.md`）：单类多为 `## Time 类`；多类合并可为 `## Sensor 类系统`。属性详表对每个子类重复 `section_attributes_block.md`。  
   表格列：  
   `类名称`、`功能描述`、`所属SIG组`、`所属组件`、`责任人`、`最后更新`、`状态`  
   - **所属SIG组**（强制）：**仅**允许填写 `component-sig-mapping.json` 的 `component_to_sig[组件名]` 或 `default_sig`（默认 `unknown`）；组件名为用户输入（小写）。**禁止**从现网其它 Markdown 照抄该列（无论旧文档写 `system`、`sensor` 等何种称呼）。映射表无键时在类概览脚注提示「请扩展 component-sig-mapping.json」。  
   - **所属组件**：填用户输入的组件名或产品习惯名称。  
   - **功能描述**：综合 `path`、类名、`description` 字段归纳（无则写「见属性详表」）。

5. **`# 📊 属性定义详表`**  
   仅包含 **Step 1 中已过滤的 CSR usage 属性**。  
   按「必选属性」「可选属性」分节，小节标题形如 `## {InnerClassName} 类 - 必选属性`（见 `section_attributes_block.md`）。  
   每个表格列固定为（与现有 object 文档一致）：  

   `属性名`、`类型`、`默认值`、`取值范围`、`动态关联`、`描述`、`使用场景`、`举例`、`来源`、`分类`  

   填充规则：  
   - **类型**：`baseType` 或 `type`。  
   - **默认值**：`default` 字段；无则填 `无` 或 `-`。  
   - **取值范围**：`enum`、`minimum`/`maximum`、或来自 `description` 的规范引用。  
   - **动态关联**：若 `description` 或默认值体现 `<=/`、`#/`、`expr` 等，摘到本列；否则 `-`。  
   - **描述**：优先用模型中 `description`；可补充换行与规范引用。  
   - **使用场景**：简短 CSR 配置场景句（本表仅 CSR 属性，与 CSR 字典用途一致）。  
   - **举例**：合理字面量或占位 `"..."`。  
   - **来源**：详表内均为 CSR 属性，填 `CSR` 或 `CSR配置`；若模型或业务另有「硬件提供」「smbios上报」等来源且用户已确认，可按用户说明填写。  
   - **分类**：**硬件** / **软件** / **混合**——依据 `description`、`baseType`、是否明显绑定 Scanner/Accessor 等语义归纳；写入「分类标准」时遵循 `templates/fragment_linkage_classification.md` 中硬件/软件两小节的写法；不确定时标 **软件**，并在脚注或变更说明中注明「分类待确认」。

### Step 3: 使用标准模板（强制）

CRITICAL: **必须**使用本 skill 内 `templates/` 与 `examples/` 拼装文档，**不要**打开 docs 仓库中的 object `*.md` 来抄版式。公共结构归纳见 `templates/STRUCTURE.md`。

`{SKILL_DIR}` 表示本 skill 目录（含 `SKILL.md`、`templates/`）。只读相对路径，**不得**把本机绝对路径写入生成的对外文档。

#### 模板文件一览

```
templates/
├── STRUCTURE.md                       # object 文档公共结构说明（给人/Agent 读）
├── document_head.md                   # YAML + 文档信息 → 变更历史 → 类概览 → # 📊 属性定义详表 + {AttributeBlocks}
├── section_attributes_block.md        # 单类必选/可选表（多类则重复拼接）
├── fragment_linkage_classification.md # 可选：动态关联 + 分类标准
└── fragment_suffix_examples_guide.md  # 配置示例 + 使用指南 + {PerformanceSectionOptional} + {RelatedDocSectionOptional}
examples/
└── complete_example.md                # 全功能排版参考（≈ Sensor 系拼装结果）
```

#### 拼装顺序（与 Sensor / CPU / Time 等现网顺序一致）

1. **`document_head.md`**：替换 `title`、`date`（与现网一致可用 `YYYY/M/D` 或模板中的 `{YYYY}/{MM}/{DD}`）、`{ClassOverviewH2}`（单类常用 `{ClassName} 类`，多类合并主文档可用 `{主类名} 类系统`）、`{ClassNameDisplay}` 等；`{AttributeBlocks}` 由下一步产生。  
2. **`{AttributeBlocks}`**：对每个待写类，复制 `section_attributes_block.md`，`{InnerClassName}` 为 `model.json` 顶层键名；属性表 **10 列** 表头与分隔行以 `section_attributes_block.md` 及 `STRUCTURE.md` 第 6 节常量为准，属性名列用反引号。  
3. **（可选）`fragment_linkage_classification.md`**：当 CSR 详表中出现 `<=/`、`#/`、`expr`、`${` 等动态语义，或用户明确要求时拼接；否则**整文件跳过**，直接进入下一步。  
4. **`fragment_suffix_examples_guide.md`**：填充 `{ConfigExampleBlocks}`、`{GuideSteps}`、`{GuideNotes}`、`{TroubleshootingBullets}`；`{PerformanceSectionOptional}` 有实质内容时填入完整 `## 性能建议` 小节，**无则置空**（该小节**整节删除**，禁止保留空标题或写「无」）。`{RelatedDocSectionOptional}`：**有**外链时替换为 `---`、换行、`# 📚 相关文档`、换行、列表；**无则置空**（不要保留空标题）。

#### SIG 与其它约定

- **所属 SIG**：类概览表格中的 **所属SIG组** 与映射表**完全一致**（见 Step 2）；无匹配用 `default_sig`。  
- 视觉与 emoji：以 `STRUCTURE.md` 第 3 节与 `examples/complete_example.md` 为准。  
- 占位：示例 JSON、分类示例列表不足时用短占位，**禁止**杜撰大段与模型无关的配置。

#### 禁止与允许（相对外部文档）

- **禁止**：为对齐版式读取 docs 或其它路径的参考 Markdown 并复制结构/段落。  
- **禁止**：擅自改 `templates/` 内属性表 **10 列** 列名与顺序（改版式应先改模板文件）。  
- **禁止**：在对外文档中写入本 skill 或本机绝对路径。  
- **允许**：读取**本次输出路径上已存在的目标文件**以合并变更历史、按类名替换章节。

#### 可选章节与占位（摘要）

- 无动态关联材料 → 不拼接 `fragment_linkage_classification.md`。  
- 无相关链接 → `{RelatedDocSectionOptional}` 置空（不单独拼接相关文档片段）。  
- `{ConfigExampleBlocks}` / `{HardwareExamples}` 不足 → 简短说明即可，禁止长篇编造。  
- **极简文档**：允许省略 `fragment_linkage_classification.md`（无动态关联与分类标准）；已在前文约定。

### Step 4: 输出路径解析（路径无关）

1. **用户已指定输出路径**  
   - 若为**文件路径**：向该文件写入（更新则读旧文件合并变更历史）；多类合并时遵守「唯一标识与已有文档」中的章节去重规则。  
   - 若为**目录路径**：目标文件为 `{目录}/{ClassName}.md`。**若该文件已存在，只更新、不新建其它路径的重复文件**（`ClassName` 与 `model.json` 顶层键一致）。

2. **用户未指定** — 自动查找 **docs 仓库**  
   - 令 `R` = 组件仓库根目录（含 `mds/model.json` 的目录的上一级，或由用户说明）。  
   - 自 `R` 起向**上级目录**逐级遍历（`R`、`parent(R)`、`parent(parent(R))`、…直到文件系统根或合理深度如 6 层）：  
     - 若存在 `docs/docs/zh/development/specifications/csr_conf_dict/object/`，且该路径可读，则输出目录即为该 `object` 目录。  
   - 常见布局：与组件仓并列的 **sibling** 目录名为 `docs`，其内部含 `docs/zh/...`（即仓库内第一层 `docs` 为站点内容根）。  
   - **若未找到**：停止生成，列出已探测的相对路径说明，请用户显式给出输出目录或 docs 仓库位置。

### Step 5: 写入与自检

- 写入前再次确认 JSON 未破坏、Markdown 表格列数一致。  
- 更新已有文件时：不得删除历史变更记录行。  
- 再次确认：输出目录中**不存在**与本次 `ClassName` 重复的第二份文件，且合并文档内**无重复类章节**。

## Examples

### 示例：用户指定组件与类名

- 组件：`sensor`  
- 模型：`mds/model.json`  
- 输出：未指定 → 按 Step 4 找到并列 `docs` 仓库后写入 `.../csr_conf_dict/object/ThresholdSensor.md`（若用户要求只生成某一类）。

### 示例：合并多类到单文件

- 用户声明：单文件 `Sensor.md`，包含 `Entity`、`ThresholdSensor`、`DiscreteSensor` 三节属性表。  
- 则只生成/更新该一个文件：类概览可合并描述；属性详表对每个子类各复制一节 `section_attributes_block.md`，`{InnerClassName}` 分别替换为 `Entity`、`ThresholdSensor`、`DiscreteSensor`（参见 `examples/complete_example.md` 的多类排版）。

## Troubleshooting

### 找不到 docs 仓库

请用户给出 docs 仓库根路径或输出目录；或确认并列目录名是否为 `docs`、内部是否包含 `docs/zh/development/specifications/csr_conf_dict/object`。

### SIG 显示 unknown

在 `component-sig-mapping.json` 的 `component_to_sig` 中增加 `组件名 -> sig` 条目后重新生成类概览表。

### model.json 与已发布文档字段不一致

以 `model.json` 为准更新属性表；在变更历史中写明「与模型同步」；若文档中有模型已删除的字段，在变更说明中标注「移除已废弃属性」并删除对应表行。

### 已出现重复文件或重复类章节

原因：未按类名唯一标识检查，或对合并文档追加了同名章节。

处理：保留**一份**以 `{ClassName}.md` 或用户指定主文件名为准的文档；删除或合并重复文件/重复 `## …类` 块后，按本 skill 规则重新导出一次。

## Related Skills

- `mdb-interface-dev` — MDB/MDS 接口与模型定义  
- `lua-component` — 微组件开发与建模上下文  

## References

- **版式与章节结构**：以 `templates/STRUCTURE.md` 为结构说明，以 `templates/*.md` 拼装规则与 `examples/complete_example.md` 为唯一格式依据。  
- **产品/协议说明**：仅在用户明确提供 URL 或片段时引用，不主动爬取外部站点。

