---
name: openubmc-interface-mapping
description: 开发 openUBMC 北向接口映射配置（Redfish / Web-backend / CLI / SNMP），涵盖 rackmount 仓库的 mapping_config JSON 编写、Schema 文件配置、ProcessingFlow 资源协作接口映射、Statements 数据处理和 ReqBody/RspBody 配置。Use when user asks to "新增Redfish接口映射配置", "编写mapping_config JSON", "配置ProcessingFlow资源协作接口映射", "编写ReqBody请求体校验", "配置RspBody响应体", "创建Redfish Schema文件", "Statements数据处理转换", "CallIf条件执行和Foreach循环". Do NOT use for hand-writing Redfish interface business code in Lua/C.
compatibility: Requires openUBMC 1.0.0+, bingo-cli >= 1.0.0, mdb_interface >= 1.0.0, rackmount >= 1.0.0
metadata:
  author: OpenUBMC Team
  version: 1.0.0
  tags: [openubmc, redfish, interface-mapping, rackmount, web-backend, cli, snmp, schema, mapping-config, processing-flow, statements]
---

# OpenUBMC 接口映射配置

## Instructions

### Step 1: 收集需求

在编写映射配置之前，先向用户收集以下信息：

- 目标 Redfish Uri 路径（如 `/redfish/v1/MyResource`）
- 资源协作接口名（`bmc.kepler.xxx`）和 MDS 对象路径
- 需要暴露的属性列表及其来源
- 请求体结构（如需 PATCH/POST）
- `mdb_interface` 中对应方法的签名（如有 RPC 调用）

### Step 2: 创建映射配置文件

映射配置文件放在 `interface_config/redfish/mapping_config/` 路径下，一个文件对应一个 Redfish 路径。

通用格式：

```json
{
    "Resources": [
        {
            "Uri": "/redfish/v1/<ResourceName>",
            "Interfaces": [
                {
                    "Type": "GET",
                    "RspBody": { },
                    "ProcessingFlow": [ ]
                }
            ]
        }
    ]
}
```

- `Resources`：Uri 配置对象数组
- `Resources[].Uri`：接口路径，动态参数用 `:paramName`（如 `:id`）
- `Interfaces`：该 Uri 支持的 HTTP 方法集合（GET / PATCH / POST / DELETE）
- `RspBody`：响应体模板，支持 `${}` 数据引用
- `ProcessingFlow`：资源协作接口映射，按数组顺序执行

CRITICAL: `ProcessingFlow` 中的 `Path` 和 `Interface` 必须与 `mdb_interface` / `model.json` 中定义的资源协作接口一致。

### Step 3: 配置 ProcessingFlow

#### Property — 读写属性

获取属性：

```json
{
    "Type": "Property",
    "Path": "/bmc/kepler/Managers/1/EthernetInterfaces/Ipv4",
    "Interface": "bmc.kepler.Managers.EthernetInterfaces.Ipv4",
    "Destination": {
        "IpMode": "IpModeIpv4",
        "IpAddr": "IpAddrIpv4"
    }
}
```

`Destination` 的 key 是资源协作接口上的属性名，value 是自定义别名（避免多接口同名属性冲突）。在 `RspBody` 中通过 `${ProcessingFlow[N]/Destination/别名}` 引用。

设置属性：

```json
{
    "Type": "Property",
    "Path": "/bmc/kepler/Managers/1",
    "Interface": "bmc.kepler.Managers.Ntp",
    "Source": {
        "Preferred": "${ReqBody/PreferredServer}"
    }
}
```

#### Method — 调用 RPC 方法

```json
{
    "Type": "Method",
    "Path": "/bmc/kepler/Systems/Events",
    "Interface": "bmc.kepler.Systems.Events",
    "Name": "GetSelInfo",
    "Params": ["123"],
    "Destination": {
        "Version": "Version",
        "CurrentEventNumber": "CurrentEventNumber"
    }
}
```

#### List — 获取子对象集合

```json
{
    "Type": "List",
    "Path": "/bmc/kepler/Managers/1/NetworkProtocol",
    "Interface": "bmc.kepler.Managers.NetworkProtocol.Protocol",
    "Params": [1],
    "Destination": {
        "Members": "service_table"
    }
}
```

`Params[1]` 表示获取深度，默认 1（子对象）。

#### Task — 异步方法

```json
{
    "Type": "Task",
    "Path": "/bmc/kepler/Managers/1/LogServices",
    "Interface": "bmc.kepler.Managers.LogServices",
    "Name": "Dump",
    "Params": [0],
    "Destination": {
        "TaskId": "TaskId"
    }
}
```

#### CallIf — 条件执行

```json
"CallIf": {
    "${ReqBody/PropA}": "#WITH",
    "${ReqBody/PropB}": "#WITHOUT",
    "${Uri/id}": 1
}
```

所有条件都满足时才执行对应 `ProcessingFlow`。`#WITH` = 数据存在，`#WITHOUT` = 数据不存在。

#### Foreach — 循环调用

```json
{
    "Type": "Property",
    "Path": "/bmc/kepler/EventService/Subscriptions/Snmp/Nmses/${#INDEX}",
    "Interface": "bmc.kepler.EventService.Subscriptions.Snmp.Nms",
    "Source": {
        "Port": "${ReqBody/TrapServer[#INDEX]/TrapServerPort}"
    },
    "Foreach": "${ReqBody/TrapServer}"
}
```

`#INDEX` 会在每次迭代中替换为当前迭代序号。

### Step 4: 配置 ReqBody 校验规则

PATCH/POST 接口需要声明请求体结构和校验规则：

```json
"ReqBody": {
    "Type": "object",
    "Required": true,
    "Properties": {
        "UserName": {
            "Type": "string",
            "Required": true,
            "Validator": [
                { "Type": "Enum", "Formula": ["Administrator", "root"] }
            ]
        },
        "Password": {
            "Type": "string",
            "Sensitive": true
        }
    }
}
```

CRITICAL: 禁止跳过 `ReqBody` 声明直接处理请求体。敏感信息（密码、Token 等）必须配置 `"Sensitive": true`。

Validator 类型：

| Type | 适用类型 | Formula 示例 | 说明 |
|------|----------|-------------|------|
| Enum | string/number/integer | `["val1", "val2"]` | 枚举校验 |
| Length | string | `[1, 16]` | 字符串长度范围（闭区间） |
| Range | integer/number | `[0, 255]` | 数值范围（闭区间） |
| Nonempty | string | 无 | 非空字符串 |
| Regex | string | `"^xx[0-9]"` | 正则匹配 |
| IPFormat | string | 无 | IP 格式校验 |
| Script | any | Lua 脚本 | 自定义校验 |

### Step 5: 配置 Statements 数据处理

在 `RspBody` 中通过 `${Statements/PropName()}` 引用处理结果：

```json
"Statements": {
    "DisplayMode": {
        "Input": "${ProcessingFlow[1]/Destination/ModeValue}",
        "Steps": [
            {
                "Type": "Switch",
                "Formula": [
                    { "Case": 0, "To": "Disabled" },
                    { "Case": 1, "To": "Enabled" },
                    { "To": "Unknown" }
                ]
            }
        ]
    }
}
```

常用 Steps 类型：

| Type | 说明 | Formula |
|------|------|---------|
| Switch | 值映射（类似 switch-case） | `[{"Case": x, "To": y}, ...]` |
| Convert | 类型转换 | `"StringToNumber"` / `"BoolToNumber"` / `"NumberToString"` 等 |
| Count | 数组元素计数 | 无 |
| Prefix-Add | 增加前缀 | 前缀字符串 |
| Prefix-Trim | 删除前缀 | 前缀字符串 |
| Suffix-Add | 增加后缀 | 后缀字符串 |
| Suffix-Trim | 删除后缀 | 后缀字符串 |
| L-Pair | 数组元素转 key-value 对象 | key 字符串（如 `"@odata.id"`） |
| Expand | URI 展开为响应体 | `"1"` |
| DateFormat | 时间戳转日期字符串 | `["%Y-%m-%dT%H:%M:%S", true]` |
| Script | Lua 脚本处理 | Lua 代码或文件名 |
| Plugin | 插件函数调用 | `"file.function(params)"` |

尽量减少 `Script` 和 `Plugin` 的使用，优先使用 `Switch`、`Convert`、`Prefix-Add` 等声明式处理。

### Step 6: 创建 Schema 文件

新增 Redfish 资源时必须同时创建 **4 个 Schema 文件**（文件名全小写）。以 `@odata.type` 为 `#HelloOpenUBMC.v1_0_0.HelloOpenUBMC` 的资源为例：

| # | 路径 | 用途 |
|---|------|------|
| 1 | `static_resource/redfish/v1/schemastore/en/helloopenubmc.json` | 主 Schema 定义（uris、CRUD 能力） |
| 2 | `static_resource/redfish/v1/schemastore/en/helloopenubmc.v1_0_0.json` | 版本化 Schema（属性类型定义） |
| 3 | `static_resource/redfish/v1/jsonschemas/helloopenubmc/index.json` | Schema 索引（指向主 Schema） |
| 4 | `static_resource/redfish/v1/jsonschemas/helloopenubmc.v1_0_0/index.json` | 版本化 Schema 索引 |

文件 1：主 Schema（schemastore/en/helloopenubmc.json）

```json
{
    "$schema": "http://redfish.dmtf.org/schemas/v1/redfish-schema.v1_1_0.json",
    "title": "#HelloOpenUBMC.v1_0_0.HelloOpenUBMC",
    "$ref": "#/definitions/HelloOpenUBMC",
    "definitions": {
        "HelloOpenUBMC": {
            "updatable": false, "insertable": false, "deletable": false,
            "uris": ["/redfish/v1/HelloOpenUBMC"]
        }
    },
    "copyright": "Copyright © Huawei Technologies Co., Ltd. 2021. All rights reserved."
}
```

文件 2：版本化 Schema（schemastore/en/helloopenubmc.v1_0_0.json）

```json
{
    "$schema": "http://redfish.dmtf.org/schemas/v1/redfish-schema.v1_1_0.json",
    "$id": "http://redfish.dmtf.org/schemas/v1/HelloOpenUBMC.v1_0_0.json",
    "definitions": {
        "HelloOpenUBMC": {
            "type": "object",
            "properties": {
                "@odata.id": { "type": "string", "format": "uri" },
                "@odata.type": { "type": "string" },
                "@odata.context": { "type": "string" },
                "Id": { "type": "string" },
                "Name": { "type": "string" },
                "WelcometoOpenUBMC": { "type": "string" }
            }
        }
    }
}
```

文件 3 & 4：Schema 索引（jsonschemas/）

`jsonschemas/helloopenubmc/index.json`（主索引）：

```json
{
    "@odata.context": "/redfish/v1/$metadata#JsonSchemaFile.JsonSchemaFile",
    "@odata.id": "/redfish/v1/JSONSchemas/HelloOpenUBMC",
    "@odata.type": "#JsonSchemaFile.JsonSchemaFile",
    "Id": "HelloOpenUBMC",
    "Name": "HelloOpenUBMC Schema File",
    "Languages": ["en"],
    "Schema": "#HelloOpenUBMC.HelloOpenUBMC",
    "Location": [{ "Language": "en", "Uri": "/redfish/v1/SchemaStore/en/HelloOpenUBMC.json" }]
}
```

`jsonschemas/helloopenubmc.v1_0_0/index.json`（版本化索引）结构相同，`Schema` 改为 `#HelloOpenUBMC.v1_0_0.HelloOpenUBMC`，`Uri` 指向版本化 Schema 文件。

命名规则：`@odata.type` 中 `#` 后第一段即为 Schema 名称，文件名全小写。

### Step 7: 构建与验证

```bash
cd rackmount
bingo build

cd <manifest-dir>
bingo build -sc qemu

python3 build/works/packet/qemu_shells/vemake_1711.py

curl -k https://192.168.0.70:10443/redfish/v1/<ResourceName>
```

### 数据引用符号速查

| 符号 | 说明 | 示例 |
|------|------|------|
| `${...}` | 引用外部数据 | `${Uri/id}`、`${ReqBody/Name}` |
| `[...]` | 数组下标引用 | `${Statements/List()[#INDEX]}` |
| `()` | Statements 调用 | `${Statements/Prop()}` |
| `/` | 下级属性 | `${ProcessingFlow[1]/Destination/Name}` |
| `{{...}}` | 全局配置引用 | `{{OemIdentifier}}` |
| `#WITH` | 数据存在 | 用于 ResourceExist / CallIf |
| `#WITHOUT` | 数据不存在 | 用于 ResourceExist / CallIf |

### LockdownAllow 系统锁定

设置类接口（PATCH/POST/DELETE）默认在系统锁定时被禁止。如需允许：

- 接口级：`"LockdownAllow": true`（在 Interfaces 对象中）
- 属性级：`"LockdownAllow": true`（在 ReqBody Properties 中，可覆盖接口级配置）

### 关键规则

- CRITICAL: 通过 JSON 配置而非手写接口代码实现北向接口
- CRITICAL: `ProcessingFlow` 中的 `Path` 和 `Interface` 必须与 `mdb_interface` / `model.json` 一致
- CRITICAL: 新增 Redfish 接口必须同时配置 4 个 Schema 文件，否则构建报错
- CRITICAL: `@odata.type` 必须与 Schema 文件名匹配
- CRITICAL: 禁止在 `RspBody` 中硬编码应从资源协作接口获取的动态数据
- 映射配置本质是将接口以 JSON 配置方式实现，框架自动解析并映射到资源协作接口
- `ProcessingFlow` 数组按序执行，前一步结果可被后续步骤引用
- PATCH 接口处理前框架会自动调用对应 GET，因此 PATCH 无需配置 `ResourceExist`
- 不同资源协作接口同名属性通过 `Destination` 的 value 别名避免冲突
- Script/Plugin 中可用全局变量：`Uri`、`ReqBody`、`Query`、`Context`、`ProcessingFlow`、`Input` 等
- Schema 文件名必须全小写，且与 `@odata.type` 中的类型名对应

## Examples

### 示例 1：新增 Redfish GET 接口

`mapping_config/HelloOpenUBMC/HelloOpenUBMC.json`：

```json
{
    "Resources": [{
        "Uri": "/redfish/v1/HelloOpenUBMC",
        "Interfaces": [{
            "Type": "GET",
            "RspBody": {
                "@odata.id": "/redfish/v1/HelloOpenUBMC",
                "@odata.type": "#HelloOpenUBMC.v1_0_0.HelloOpenUBMC",
                "@odata.context": "/redfish/v1/$metadata#HelloOpenUBMC.HelloOpenUBMC",
                "Id": "HelloOpenUBMC",
                "Name": "HelloOpenUBMC",
                "WelcometoOpenUBMC": "${ProcessingFlow[1]/Destination/WelcometoOpenUBMC}"
            },
            "ProcessingFlow": [{
                "Type": "Property",
                "Path": "/bmc/kepler/HelloOpenUBMC",
                "Interface": "bmc.kepler.OpenUBMC.Community",
                "Destination": { "WelcometoOpenUBMC": "WelcometoOpenUBMC" }
            }]
        }]
    }]
}
```

### 示例 2：GET + PATCH 组合

```json
{
    "Resources": [{
        "Uri": "/redfish/v1/Managers/:managersid/NetworkProtocol",
        "Interfaces": [
            {
                "Type": "GET",
                "ResourceExist": { "${Uri/managersid}": "1" },
                "RspBody": {
                    "NTP": {
                        "ProtocolEnabled": "${ProcessingFlow[1]/Destination/Enabled}"
                    }
                },
                "ProcessingFlow": [{
                    "Type": "Property",
                    "Path": "/bmc/kepler/Managers/1",
                    "Interface": "bmc.kepler.Managers.Ntp",
                    "Destination": { "Enabled": "Enabled" }
                }]
            },
            {
                "Type": "PATCH",
                "ReqBody": {
                    "Type": "object",
                    "Properties": {
                        "NTP": {
                            "Type": "object",
                            "Properties": {
                                "ProtocolEnabled": { "Type": "boolean" }
                            }
                        }
                    }
                },
                "ProcessingFlow": [{
                    "Type": "Property",
                    "Path": "/bmc/kepler/Managers/1",
                    "Interface": "bmc.kepler.Managers.Ntp",
                    "Source": { "Enabled": "${ReqBody/NTP/ProtocolEnabled}" }
                }]
            }
        ]
    }]
}
```

### 示例 3：集合资源（List + Statements 转 Members 链接）

```json
{
    "ProcessingFlow": [{
        "Type": "List",
        "Path": "/bmc/kepler/AccountService/Accounts",
        "Interface": "bmc.kepler.AccountService.ManagerAccount",
        "Destination": { "Members": "AccountList" }
    }],
    "Statements": {
        "MemberLinks": {
            "Input": "${ProcessingFlow[1]/Destination/AccountList}",
            "Steps": [
                { "Type": "Prefix-Trim", "Formula": "/bmc/kepler" },
                { "Type": "Prefix-Add", "Formula": "/redfish/v1" },
                { "Type": "L-Pair", "Formula": "@odata.id" }
            ]
        }
    },
    "RspBody": {
        "Members": "${Statements/MemberLinks()}"
    }
}
```

## Troubleshooting

### 构建报错：找不到 Schema 文件

原因：新增 Redfish 资源时遗漏了 Schema 文件。

解决方案：确认 4 个 Schema 文件都已创建，且文件名全小写，与 `@odata.type` 匹配。

### GET 接口返回空数据

原因：`ProcessingFlow` 中的 `Path` 或 `Interface` 与实际资源不匹配。

解决方案：

1. 确认 `Path` 与 `model.json` 中的 `path` 一致
2. 确认 `Interface` 与 `mdb_interface` 中的定义一致
3. 使用 `busctl --user introspect` 验证资源是否存在

### PATCH 接口不生效

原因：`Source` 字段引用的 `ReqBody` 路径不正确，或系统锁定未配置 `LockdownAllow`。

解决方案：

1. 检查 `${ReqBody/...}` 路径与 `ReqBody` 声明的属性路径一致
2. 如系统处于锁定状态，确认 `LockdownAllow` 已配置

### @odata.type 与 Schema 不匹配

原因：`RspBody` 中的 `@odata.type` 字符串与 Schema 文件命名不对应。

解决方案：`@odata.type` 中 `#` 后第一段即为 Schema 名称，Schema 文件名必须全小写。

## Related Skills

- **lua-component** — Lua 组件开发：组件脚手架、MDS 建模、构建发布
- **mdb-interface-dev** — MDB/D-Bus 接口开发：`mdb_interface` 接口定义、RPC 方法实现（映射配置中的 `Path` 和 `Interface` 来源于此）

## References

- 接口映射配置: <https://www.openubmc.cn/docs/zh/development/design_reference/key_feature/interface_mapping.html>
- Redfish 接口映射教程: <https://discuss.openubmc.cn/t/topic/2963>
- rackmount 仓库: <https://gitcode.com/openUBMC/rackmount>
- 扩展对外接口: <https://www.openubmc.cn/docs/zh/development/quick_start/extend_bmc_api.html>
- MDS 数据模型: <https://www.openubmc.cn/docs/zh/development/design_reference/key_feature/MDS.html>
