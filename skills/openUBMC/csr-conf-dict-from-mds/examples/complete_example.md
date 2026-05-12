---
title: CSR配置字典之Sensor类
date: 2026/05/06
---

<!--
  拼装参考：document_head（含多段 section_attributes_block 展开为 {AttributeBlocks}）
  + fragment_linkage_classification（本例已含「动态关联」「分类标准」）
  + fragment_suffix_examples_guide（{PerformanceSectionOptional} 有则含「性能建议」，无则整节不出现；
    {RelatedDocSectionOptional} 本例为空；有外链时自带前置 --- 与 # 📚 相关文档）
-->

# 📋 文档信息

| 项目 | 内容 |
|------|------|
| **文档标题** | Sensor类配置字典 |
| **版本** | v1.0 |
| **创建日期** | 2026-01-27 |
| **最后更新** | 2026-05-06 |
| **维护状态** | ✅ 活跃维护 |

---

# 📋 变更历史记录

## 文档变更记录

| 版本 | 发布日期 | 变更类型 | 变更内容 | 影响范围 | 维护人员 |
|------|----------|----------|----------|----------|----------|
| v1.1 | 2026-05-06 | 修订 | 新增温度传感器配置示例 | 扩展章节 | 传感器管理组 |
| v1.0 | 2026-01-27 | 初始版本 | 创建Sensor类配置字典 | 全新文档 | 传感器管理组 |

---

# 🎯 类概览

## Sensor 类系统

| 属性 | 值 |
|------|----|
| **类名称** | `Sensor` (Entity + ThresholdSensor + DiscreteSensor) |
| **功能描述** | 传感器管理系统，包含实体管理(Entity)、门限传感器(ThresholdSensor)和离散传感器(DiscreteSensor)，提供完整的传感器配置和监控功能 |
| **所属SIG组** | bmc-core |
| **所属组件** | sensor |
| **责任人** | 传感器管理组 |
| **最后更新** | 2026-05-06 |
| **状态** | 🟢 正常运行 |

---

# 📊 属性定义详表

## Entity 类 - 必选属性

| 属性名 | 类型 | 默认值 | 取值范围 | 动态关联 | 描述 | 使用场景 | 举例 | 来源 | 分类 |
|--------|------|--------|----------|----------|------|----------|------|------|------|
| `Id` | U8 | - | U8 | - | 传感器对应的实体标识<br/>具体参照IPMI标准协议规范Table 43-, Entity ID Codes(P550) | 配置传感器实体 | `7` | CSR | 软件 |
| `Instance` | U8 | - | U8 | - | 传感器对应的实体实例标识，通常以0x60开始配置 | 配置传感器实体 | `96` | CSR | 软件 |
| `Name` | String | - | String | - | 实体名称 | 配置传感器实体 | `"MainBoard"` | CSR | 软件 |
| `Presence` | U8 | 1 | 默认1或者关联部件在位 | - | 实体在位状态 | 配置传感器实体 | `1` | CSR | 软件 |
| `PowerState` | Mixed | 1 | 默认1或者关联部件在位 | Scanner_PowerGood | 实体上下电状态 | 配置传感器实体 | `"<=/Scanner_PowerGood.Value"` | CSR | 软件 |

---

## Entity 类 - 可选属性

| 属性名 | 类型 | 默认值 | 取值范围 | 动态关联 | 描述 | 使用场景 | 举例 | 来源 | 分类 |
|--------|------|--------|----------|----------|------|----------|------|------|------|
| `Slot` | U8 | 255 | U8 | - | 实体所在的槽位 | 配置传感器实体 | `255` | CSR | 软件 |

---

## ThresholdSensor 类 - 必选属性

| 属性名 | 类型 | 默认值 | 取值范围 | 动态关联 | 描述 | 使用场景 | 举例 | 来源 | 分类 |
|--------|------|--------|----------|----------|------|----------|------|------|------|
| `EntityId` | Mixed | - | 关联Entity的Id | Entity_MainBoard | 传感器需要关联实体 | 配置传感器对象 | `"<=/Entity_MainBoard.Id"` | CSR | 软件 |
| `EntityInstance` | Mixed | - | 关联Entity的Instance | Entity_MainBoard | 传感器需要关联实体 | 配置传感器对象 | `"<=/Entity_MainBoard.Instance"` | CSR | 软件 |
| `SensorType` | U8 | - | U8 | - | 传感器类型<br/>具体参照IPMI标准协议规范 | 配置传感器对象 | `1` | CSR | 硬件 |
| `ReadingType` | U8 | 1 | U8 | - | 传感器读值类型 | 配置传感器对象 | `1` | CSR | 硬件 |
| `SensorName` | String | - | String | - | 传感器名称 | 配置传感器对象 | `"CPU Temperature"` | CSR | 硬件 |
| `BaseUnit` | U8 | - | U8 | - | 传感器基本单位<br/>参照IPMI标准协议规范 | 配置传感器对象 | `1` | CSR | 硬件 |

---

## ThresholdSensor 类 - 可选属性

| 属性名 | 类型 | 默认值 | 取值范围 | 动态关联 | 描述 | 使用场景 | 举例 | 来源 | 分类 |
|--------|------|--------|----------|----------|------|----------|------|------|------|
| `UpperCritical` | U8 | 220 | U8 | - | 传感器严重事件上限 | 配置传感器对象 | `220` | CSR | 硬件 |
| `LowerCritical` | U8 | 180 | U8 | - | 传感器严重事件下限 | 配置传感器对象 | `180` | CSR | 硬件 |
| `SensorNumber` | U8 | 255 | U8 | - | 传感器编号定制需求 | 配置传感器对象 | `255` | CSR | 软件 |

---

# 🔗 动态关联机制

## 语法规范

使用 `<=/xxx`、`#/xxx` 与表达式实现动态关联（与现网 Sensor/CPU 等文档一致）：

```yaml
EntityId: "<=/Entity_MainBoard.Id"
PowerState: "<=/Scanner_PowerGood.Value"
Reading: "<=/Scanner_CpuTemp.Value"
```

## 关联说明

- **Entity 关联**：传感器通过 EntityId / EntityInstance 绑定实体。
- **Scanner 关联**：读值类属性常绑定 `<=/Scanner_xxx.Value` 或 `Status`。

---

# 📂 分类标准

## 硬件属性

- **定义**：与硬件特性和物理参数直接相关的属性
- **特点**：通常与IPMI标准协议规范对应，反映硬件特性
- **示例**：`SensorType`, `ReadingType`, `SensorName`, `BaseUnit`, `UpperCritical`, `LowerCritical`

---

## 软件属性  

- **定义**：用于逻辑控制和软件管理的参数
- **特点**：由CSR配置管理，用于传感器逻辑控制
- **示例**：`Id`, `Instance`, `Name`, `Presence`, `PowerState`, `EntityId`, `EntityInstance`, `SensorNumber`

---

# 📝 配置示例

## 温度传感器配置

```json
{
  "Entity": {
    "Id": 7,
    "Instance": 96,
    "Name": "MainBoard",
    "Presence": 1,
    "PowerState": "<=/Scanner_PowerGood.Value"
  },
  "ThresholdSensor": {
    "EntityId": "<=/Entity_MainBoard.Id",
    "EntityInstance": "<=/Entity_MainBoard.Instance",
    "SensorType": 1,
    "ReadingType": 1,
    "SensorName": "CPU Temperature",
    "BaseUnit": 1,
    "UpperCritical": 85,
    "LowerCritical": 0
  }
}
```

---

## 电压传感器配置

```json
{
  "Entity": {
    "Id": 7,
    "Instance": 97,
    "Name": "PowerBoard",
    "Presence": 1
  },
  "ThresholdSensor": {
    "EntityId": "<=/Entity_PowerBoard.Id",
    "EntityInstance": "<=/Entity_PowerBoard.Instance",
    "SensorType": 2,
    "ReadingType": 1,
    "SensorName": "VCC_12V0",
    "BaseUnit": 4,
    "UpperCritical": 220,
    "LowerCritical": 180
  }
}
```

---

# 🔧 使用指南

## 配置步骤

1. **创建实体对象**：首先配置Entity，定义传感器所属的实体
2. **选择传感器类型**：根据需要选择ThresholdSensor或DiscreteSensor
3. **关联实体**：通过EntityId和EntityInstance关联对应的Entity
4. **配置传感器属性**：设置SensorType、ReadingType、SensorName等基本属性
5. **配置单位和范围**：设置BaseUnit、UpperCritical、LowerCritical等

---

## 注意事项

- **IPMI标准遵循**：所有配置必须符合IPMI标准协议规范
- **实体关联**：传感器必须关联对应的Entity对象
- **动态关联语法**：使用 `<=/Entity_xxx.Property` 格式
- **传感器编号**：SensorNumber建议配置为255，由sensor模块自动分配

---

## 性能建议

- **迟滞量**：合理设置 PositiveHysteresis / NegativeHysteresis，减少事件抖动。
- **表达式**：Reading / ReadingStatus 表达式宜保持可验证、避免循环依赖。

---

## 故障排查

- **传感器不显示**：检查Entity关联和基本属性配置
- **读值异常**：检查Reading表达式和数据源关联
- **事件不触发**：检查AssertMask和DeassertMask配置

---