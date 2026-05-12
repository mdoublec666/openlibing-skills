---
name: openubmc-mdb-interface-dev
description: 开发 openUBMC 的 MDB/D-Bus 资源协作接口，包括 mdb_interface 接口定义、MDS 数据建模、bingo gen 代码自动生成、RPC 方法实现、跨组件通信和 IPMI 命令开发。Use when user asks to "定义MDB资源协作接口", "model.json配置MDS对象", "service.json跨组件依赖", "bingo gen代码自动生成", "实现RPC方法回调", "IPMI命令开发", "属性订阅与信号监听", "types.json复杂类型定义". Do NOT use for generic D-Bus, OpenBMC phosphor-dbus-interfaces, or sdbusplus YAML workflows.
compatibility: Requires openUBMC 1.0.0+, bingo-cli >= 1.0.0, conan >= 2.0.0, mdb_interface >= 1.0.0, dbus >= 1.12
metadata:
  author: OpenUBMC Team
  version: 1.1.0
  tags: [openubmc, mdb, dbus, mdb_interface, mds, bingo, rpc, ipmi, code-generation, interface]
---

# OpenUBMC MDB 接口开发

## Instructions

### Step 0: 判断接口是否已存在

在编写 `model.json` 之前，**必须先确认**所需接口是否已在 `mdb_interface` 仓库中定义：

```bash
# 方法 1：在组件 temp 中查找（执行过 bingo gen 后可用）
find temp/opt/bmc/apps/mdb_interface/intf -name "*.json" 2>/dev/null | xargs grep -l "接口名关键字"

# 方法 2：克隆 mdb_interface 仓库查找
git clone git@gitcode.com:openUBMC/mdb_interface.git
find mdb_interface/json/intf -name "*.json" | xargs grep -l "接口名关键字"
```

CRITICAL: 如果接口不存在，必须先完成 **Step 1（新增接口定义）** 再继续；禁止在 `model.json` 中引用尚未定义的接口名，否则 `bingo gen` 会直接报 `FileNotFoundError`。

### Step 1: 在 mdb_interface 中新增接口（仅当接口不存在时）

如果 Step 0 确认接口不存在，需要先在 `mdb_interface` 仓库中定义：

#### 1.1 接口定义文件（intf）

在 `json/intf/mdb/bmc/kepler/` 下按功能分目录创建接口 JSON 文件：

```
json/intf/mdb/bmc/kepler/
└── <功能目录>/
    └── I<接口名>.json
```

接口 JSON 文件定义属性类型、默认值、校验规则等：

```json
{
  "properties": {
    "Id": { "baseType": "STRING" },
    "Status": { "baseType": "U8", "default": 0, "minimum": 0, "maximum": 255 }
  }
}
```

#### 1.2 路径定义文件（path）

CRITICAL: path 文件必须放在 **`类名/类名.json`** 子目录中，否则 `bingo gen` 会因路径解析失败报 `FileNotFoundError`。

```
json/path/mdb/bmc/kepler/
└── <功能目录>/
    └── <类名>/              ← 必须创建与类名同名的子目录
        └── <类名>.json      ← 路径定义文件
```

常见错误对照：

```
✅ 正确: json/path/mdb/bmc/kepler/Systems/MyDevice/MyDevice.json
❌ 错误: json/path/mdb/bmc/kepler/Systems/MyDevice.json        ← 缺少子目录
```

可以参照仓库中已有接口（如 `Debug/Performance/Performance.json`）的目录结构。

#### 1.3 构建本地 mdb_interface 包

```bash
cd mdb_interface
bingo build
```

构建完成后记录输出中的本地版本号（形如 `x.y.z@openubmc.dev/dev`），后续 `service.json` 需要用到。

#### 1.4 在组件中指向本地 mdb_interface

修改组件 `mds/service.json`，将 `mdb_interface` 依赖指向本地版本：

```json
{
  "dependencies": {
    "build": [
      { "conan": "mdb_interface/<本地版本号>@openubmc.dev/dev" }
    ]
  }
}
```

验证接口是否已正确安装到本地缓存：

```bash
conan list "mdb_interface/*"
```

#### 1.5 本地验证通过后的收尾

将 `mdb_interface` 的修改提交 PR 合入官方仓库。合入后将 `service.json` 改回正式版本号或移除本地版本依赖。

### Step 2: 收集需求

在编写任何配置之前，先向用户收集以下信息：

- 组件名 `<app-name>` 和目标接口名（`bmc.kepler.xxx`）
- 当前 `mds/model.json` 和 `mds/service.json` 内容
- 需要定义的属性、RPC 方法或 IPMI 命令的详细需求
- 数据是否需要持久化（决定 `model.json` 中的 `tableName`、`primaryKey`、`usage` 配置方式）
- 如果是排查问题，提供 `bingo gen` 或 `bingo build` 失败日志

### Step 3: 定义 MDS 模型

在 `mds/model.json` 中定义资源对象：

- 所有接口名必须以 `bmc.kepler.` 开头，禁止使用 `xyz.openbmc_project.*`
- `model.json` 中引用的接口名必须与 `mdb_interface` 仓库中的定义一致
- 对外属性放 `interfaces.properties`，只需写属性名和 `usage`（如需），类型和校验已在 `mdb_interface` 中定义
- 私有属性放与 `interfaces` 平级的 `properties`，需自行定义 `baseType`、`default`、`minimum`/`maximum` 等

```json
{
  "MyDevice": {
    "path": "/bmc/kepler/Systems/${SystemId}/MyDevice/${Id}",
    "privilege": ["ConfigureSelf"],
    "interfaces": {
      "bmc.kepler.Systems.IMyDevice": {
        "properties": {
          "Id": {},
          "FirmwareVersion": { "usage": ["PoweroffPer"] }
        }
      }
    },
    "properties": {
      "InternalState": { "baseType": "U8", "default": 0 }
    }
  }
}
```

如需跨组件依赖，在 `mds/service.json` 的 `required` 中声明。

如需复杂类型，在 `mds/types.json` 中定义。

#### 持久化配置

CRITICAL: `usage`、`tableName`、`primaryKey` 与持久化机制直接关联。`usage` 字段会触发持久化检查，一旦配置就必须同时配置 `tableName` 和 `primaryKey`，否则 `bingo gen` 会报错。不需要持久化的数据（如实时监控指标、运行时状态）禁止配置这些字段。

涉及持久化配置时，必须先阅读 `references/persistence-mechanisms.md`，了解持久化类型、类级别字段和属性级别字段的完整规则后再进行配置。

### Step 4: 生成代码

运行 `bingo gen` 前，确保 `mdb_interface` 缓存为最新：

```bash
conan remove "mdb_interface/*" -c
bingo gen
```

CRITICAL: 禁止跳过 `bingo gen` 直接手写 `/gen` 目录下的代码。禁止在 Conan 缓存目录（`~/.conan2/p/` 或 `~/.conan/data/`）中直接修改文件。组件目录下的 `temp/` 目录仅用于查看生成产物，禁止直接修改其中任何文件，因执行 `bingo gen` / `bingo build` 后会被完全覆盖。

`bingo gen` 成功后，可通过 `temp/` 目录确认接口是否已正确拉取：

```bash
ls temp/opt/bmc/apps/mdb_interface/intf/mdb/bmc/kepler/<功能目录>/
ls temp/opt/bmc/apps/mdb_interface/path/mdb/bmc/kepler/<功能目录>/<类名>/
```

### Step 5: 实现业务逻辑

在 `src/lualib/<app-name>_app.lua` 中调用生成的 `CreateXxx()` 创建对象实例：

```lua
function app:init()
    app.super.init(self)
    self:CreateMyDevice(1, 'dev_001', function(obj)
        obj.InternalState = 0
    end)
end
```

RPC 方法回调在 `bingo gen` 后注册：

```lua
function app:register_rpc()
    self:ImplMyDeviceIMyDeviceGetPortSpeed(function(obj, ctx, type_val, port_id)
        local speed = self.device_manager:query_port_speed(type_val, port_id)
        return 0, speed
    end)
end
```

回调参数固定为 `(obj, ctx, ...)`：`obj` 是 MDS 对象，`ctx` 是上下文，`...` 是业务参数。

跨组件访问：在 `service.json` 中声明依赖，`bingo gen` 后使用生成的 `client.lua`：

```lua
local client = require '<app_name>.client'

client:ForeachIOtherComponentObjects(function(obj)
    if obj.Id == target_id then result = obj end
end)
```

属性变更订阅：在 `service.json` 中配置 `"State": ["subscribe"]`，`bingo gen` 后监听：

```lua
client:OnIMonitoredPropertiesChanged(function(values, _, _)
    local state = values.State:value()
end)
```

IPMI 命令：在 `mds/ipmi.json` 中配置（netfn、cmd、req、rsp），运行 `bingo gen`，然后注册处理函数：

```lua
local ipmi_struct = require '<app_name>.ipmi.ipmi'
local msg = require '<app_name>.ipmi.ipmi_message'

function app:register_ipmi()
    self.register_ipmi_cmd(ipmi_struct.GetDeviceInfo, function(req, ctx)
        return msg.GetDeviceInfoRsp(0, self.device_manager:get_info(req.DeviceId))
    end)
end
```

### Step 6: 构建与验证

```bash
bingo build --stage=stable
```

验证接口是否生效：

```bash
source /etc/profile
busctl --user tree <bus-name>
busctl --user introspect <bus-name> <object-path>
```

### 关键规则

- CRITICAL: 所有接口名必须使用 `bmc.kepler.` 前缀，禁止使用 `xyz.openbmc_project.*`
- CRITICAL: 禁止虚构不存在于 `mdb_interface` 仓库中的接口名，必须先通过 Step 0 确认接口存在或通过 Step 1 新增
- CRITICAL: 禁止把私有属性放进 `interfaces.properties`，也禁止把接口属性放进平级的 `properties`
- CRITICAL: 禁止在 `model.json` 的接口属性中重复定义类型信息（已在 `mdb_interface` 中定义）
- CRITICAL: 禁止在 `service.json` 的 `required` 中遗漏跨组件依赖的接口
- CRITICAL: 如需修改 `mdb_interface`，必须拉取源码仓库修改并重新构建，禁止编辑 Conan 缓存产物
- CRITICAL: `mdb_interface` 的 path 文件必须放在 `<类名>/<类名>.json` 子目录中，否则会路径解析失败
- CRITICAL: `usage` 字段会触发持久化检查，不需要持久化的数据禁止配置 `usage`、`tableName`、`primaryKey`
- 多接口同名属性必须用 `alias` 别名解决冲突，别名不可随意变更
- 权限采用局部继承全局原则：属性权限 = 属性 + 接口 + 对象路径三级叠加
- `mc.class` 生命周期：`ctor()` -> `pre_init()` -> `init()`

## Examples

### 示例 1：端到端新增 D-Bus 接口（接口已存在）

1. 通过 Step 0 确认接口名已在 `mdb_interface` 中定义
2. 在 `mds/model.json` 中定义 MDS 类、`path`、`interfaces` 和属性
3. 如需跨组件依赖，在 `mds/service.json` 的 `required` 中声明
4. 如需复杂类型，在 `mds/types.json` 中定义
5. 运行 `bingo gen`
6. 在 `src/lualib/<app-name>_app.lua` 中调用 `CreateXxx()` 创建对象
7. 如有 RPC 方法，注册回调实现
8. 运行 `bingo build --stage=stable`
9. 使用 `busctl --user` 验证

### 示例 2：端到端新增 D-Bus 接口（接口不存在，需本地补齐）

1. 通过 Step 0 确认接口不存在
2. 克隆 `mdb_interface` 仓库：

```bash
git clone git@gitcode.com:openUBMC/mdb_interface.git
cd mdb_interface
```

3. 新增接口定义文件（intf）和路径定义文件（path），**注意 path 的 `类名/类名.json` 子目录结构**
4. 在 `mdb_interface` 目录下构建本地包：

```bash
bingo build
```

5. 修改组件 `mds/service.json`，将 `mdb_interface` 依赖指向本地版本
6. 回到组件目录运行 `bingo gen`
7. 在 `src/lualib/<app-name>_app.lua` 中实现业务逻辑
8. 运行 `bingo build --stage=stable` 并验证
9. 验证通过后将 `mdb_interface` 修改提交 PR 合入官方仓库

### 示例 3：新增 IPMI 命令

1. 在 `mds/ipmi.json` 中配置（netfn、cmd、req、rsp）
2. 运行 `bingo gen`
3. 在 `<app-name>_app.lua` 中 `register_ipmi_cmd` 注册处理函数
4. 使用 `ipmitool raw` 验证

## Troubleshooting

### bingo gen 失败排查清单

遇到 `bingo gen` 失败，按以下顺序逐项排查：

**1. 接口是否在 `mdb_interface` 中定义？**

```bash
find temp/opt/bmc/apps/mdb_interface/intf -name "*.json" 2>/dev/null | xargs grep -l "接口名关键字"
```

如果找不到，需要先在 `mdb_interface` 仓库新增接口（见 Step 1）。

**2. path 文件是否在正确的子目录中？**

```
✅ 正确: json/path/mdb/bmc/kepler/<功能目录>/<类名>/<类名>.json
❌ 错误: json/path/mdb/bmc/kepler/<功能目录>/<类名>.json   ← 缺少子目录
```

**3. 是否配置了不必要的持久化字段？**

错误特征：`model.json中类X配置了持久化但是没有配置'tableName'`

- 如果不需要持久化：删除 `tableName`、`primaryKey`，并移除接口属性中的 `usage` 字段
- 如果需要持久化：补齐 `tableName` 和 `primaryKey`

**4. `service.json` 中的 `mdb_interface` 版本是否匹配？**

```bash
conan list "mdb_interface/*"
```

确保 `service.json` 中声明的版本与本地 Conan 缓存中的版本一致。

**5. `temp` 缓存是否需要清理？**

修改 `model.json` 或 `mdb_interface` 后，如果 `bingo gen` 仍报旧错误：

```bash
rm -rf temp && bingo gen
```

### FileNotFoundError: .../path/mdb//...///类名.json

原因：`mdb_interface` 中缺少接口的 intf 或 path 定义文件。

解决方案：

1. 检查接口定义文件是否存在：`json/intf/mdb/bmc/kepler/<功能目录>/I<接口名>.json`
2. 检查路径定义文件是否在正确的子目录中：`json/path/mdb/bmc/kepler/<功能目录>/<类名>/<类名>.json`
3. 如果缺失，按 Step 1 在 `mdb_interface` 仓库中补齐

### 报错 "配置了持久化但是没有配置 tableName"

原因：接口属性中的 `usage` 字段触发了持久化检查，但未配置 `tableName` 和 `primaryKey`。

解决方案：

- 如果不需要持久化：移除该属性的 `usage` 字段，同时移除 `tableName` 和 `primaryKey`
- 如果需要持久化：补齐 `tableName` 和 `primaryKey` 配置

### Unable to find 'mdb_interface/X@Y/Z' in remotes

原因：使用了本地构建的 `mdb_interface` 版本，但 `service.json` 中的版本号与本地缓存不匹配。

解决方案：

```bash
# 查看本地已有版本
conan list "mdb_interface/*"

# 方法 1：修改 service.json 指向正确的本地版本
# 方法 2：清理本地缓存，使用远程正式版本
conan remove "mdb_interface/*" -c
```

### busctl 看不到对象

原因：组件初始化时未创建对象，或服务未成功启动。

解决方案：

1. 确认 `app:init()` 中调用了 `CreateXxx()`
2. 检查服务状态：`systemctl status <service>`
3. 查看日志：`journalctl -u <service> -n 100`
4. 检查 `config:set_start(...)` 和 `config:include_app(...)` 启动配置

### 属性通过 D-Bus 不可见

原因：属性被定义为私有属性而非接口属性。

解决方案：将属性从顶层 `properties` 移入 `model.json` 中对应的 `interfaces.properties` 块。

### RPC 方法回调未被调用

原因：回调未注册，或方法签名不匹配。

解决方案：

1. 确认回调已在 `register_rpc()` 或等效方法中注册
2. 确认生成的方法名格式为 `Impl<ClassName><InterfaceName><MethodName>`
3. 确保参数数量匹配 `(obj, ctx, ...业务参数)`

## Related Skills

- **lua-component** — Lua 组件开发：组件脚手架（`bingo new`）、构建发布（`bingo build`）、`mc.class` 生命周期、整包接入和资源验证

## References

- MDS 数据模型: <https://www.openubmc.cn/docs/zh/development/design_reference/key_feature/MDS.html>
- 代码自动生成: <https://www.openubmc.cn/docs/zh/development/design_reference/key_feature/code_generation.html>
- mdb_interface 仓库: <https://gitcode.com/openUBMC/mdb_interface>
- Lua 开发框架: <https://www.openubmc.cn/docs/zh/development/design_reference/key_feature/lua_sdk.html>
- 扩展对外接口: <https://www.openubmc.cn/docs/zh/development/quick_start/extend_bmc_api.html>
- 持久化机制: [`references/persistence-mechanisms.md`](references/persistence-mechanisms.md)（原始文档: <https://www.openubmc.cn/docs/zh/development/develop_guide/feature_development/persistence_mechanisms_introduction.html>）
