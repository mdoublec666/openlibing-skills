---
name: openubmc-lua-component
description: 创建和实现 openUBMC Lua 组件，涵盖脚手架、MDS 建模、代码生成、Lua SDK、UT/IT 测试、构建发布和资源验证的完整开发流程。Use when user asks to "创建Lua组件", "bingo new新建组件", "实现MDB接口", "bingo gen代码生成", "Lua SDK对象生命周期", "组件UT和IT测试", "编写单元测试", "编写集成测试", "Conan2和CMake构建发布", "bingo build构建". Do NOT use for generic Lua service templates or OpenBMC component workflows.
compatibility: Requires openUBMC 1.0.0+, bingo-cli >= 1.0.0, conan >= 2.0.0, cmake >= 3.14
metadata:
  author: OpenUBMC Team
  version: 2.1.0
  tags: [openubmc, lua, mds, microcomponent, bingo, mdb, lua-sdk, conan, cmake, testing, unit-test, integration-test]
---

# OpenUBMC Lua 组件开发

openUBMC 的组件结构、工具链和 API 与通用 Lua 服务或 OpenBMC 完全不同。如果套用通用模板（如 `meson.build`、`src/main.lua`、`require "logger"`），bingo 工具链将无法识别组件，导致构建失败。本 Skill 确保你始终使用 openUBMC 的标准流程。

## Step 1: 收集需求

在创建组件之前，向用户收集以下信息：

- **必须**：组件名 `<app-name>`
- **必须**：目标资源模型或接口设计（接口名、属性列表）
- **按需**：`mds/model.json` 内容（如已有）
- **按需**：生成或构建失败的具体日志（如排查问题）
- **按需**：`manifest.yml` 或产品依赖信息（如需整包构建）

## Step 2: 创建组件脚手架

```bash
cd /home/workspace
bingo new -n <app-name> -t application -l lua -conan 2.0
cd /home/workspace/<app-name>
git init .
```

`-conan 2.0` 参数指定使用 Conan2 包管理器，省略此参数会进入交互式选择导致脚本卡住。`-t application` 指定组件类型，`-l lua` 指定语言为 Lua。这三个参数缺一不可。

## Step 3: 开发流程决策

```
需要定义 MDB 接口？
├─ 是 → 需要新的接口（mdb_interface 中不存在）？
│   ├─ 是 → 先完成 mdb-interface-dev Skill 的 Step 0 ~ Step 1（新增接口定义并本地构建）
│   └─ 否 → 直接进入 Step 4 配置 model.json
├─ 否 → 直接进入 Step 5 实现纯 Lua 业务逻辑
```

涉及 MDB 接口开发、MDS 建模或 `mdb_interface` 相关实现时，**必须同时加载并遵循 `mdb-interface-dev` Skill 的指引**。该 Skill 包含接口定义的完整规则（如 path 文件的 `类名/类名.json` 子目录结构），本 Skill 不展开这些细节。

## Step 4: 定义 MDS 模型

在 `mds/model.json` 中定义资源对象。以下是一个完整的模板：

```json
{
    "Fan": {
        "path": "/bmc/kepler/Chassis/${ChassisId}/Thermal/Fan/${Id}",
        "privilege": ["ConfigureSelf"],
        "interfaces": {
            "bmc.kepler.Thermal.IFan": {
                "properties": {
                    "Id": {},
                    "Speed": {},
                    "Status": {}
                }
            }
        },
        "properties": {
            "InternalState": {
                "baseType": "U8",
                "default": 0
            }
        }
    }
}
```

**关键规则说明：**

- `interfaces.properties` 中的属性是对外可见的（通过 D-Bus/mdbctl 可查询）。只需写属性名和空对象 `{}`，因为类型、校验规则已在 `mdb_interface` 的 intf 文件中定义。如果在这里重复写 `baseType`，会导致与 `mdb_interface` 定义冲突。
- 与 `interfaces` 平级的 `properties` 是组件私有属性，外部不可见，需要自行定义 `baseType`、`default` 等。
- 如果属性需要持久化（掉电保存），需要在属性上配置 `usage` 字段（如 `"usage": ["PoweroffPer"]`），并在类级别配置 `tableName`。配置了 `usage` 就必须同时配置 `tableName` 和 `primaryKey`，否则 `bingo gen` 会报错。不需要持久化的属性（如实时监控数据）不要配置这些字段。
- 涉及持久化配置时，参考 `mdb-interface-dev` Skill 中的 `references/persistence-mechanisms.md` 了解完整规则。

如需跨组件依赖，在 `mds/service.json` 的 `required` 中声明。如需复杂类型，在 `mds/types.json` 中定义。

## Step 5: 生成代码并实现业务逻辑

```bash
bingo gen
```

`bingo gen` 基于 `mds/model.json` 生成辅助代码到 `gen/` 目录，包括组件基类 `<app-name>.service` 和对象创建方法 `CreateXxx()`。这些生成代码是后续业务逻辑的基础，跳过此步直接编写依赖生成代码的逻辑会导致 require 失败。

### _app.lua 标准结构

在 `src/lualib/<app-name>_app.lua` 中编写业务逻辑。以下是标准模板：

```lua
local class = require 'mc.class'
local c_service = require '<app_name>.service'
local log = require 'mc.logging'

local app = class(c_service)

function app:ctor()
end

function app:pre_init()
end

function app:init()
    app.super.init(self)
    -- 创建 MDS 对象实例
    self.my_obj = self:CreateXxx(1, function(obj)
        obj.ObjectName = "MyObj_1"
        obj.SomeProperty = "initial_value"
    end)
end

return app
```

**生命周期顺序**：`ctor()` → `pre_init()` → `init()`。`init()` 中必须先调用 `app.super.init(self)` 初始化基类。

### 日志 API

openUBMC 使用 `mc.logging` 模块，不要使用 `require "logger"` 或 `require "log"` — 这些模块在 openUBMC 中不存在。

```lua
local log = require 'mc.logging'

log:debug('value: %s', value)
log:info('started')
log:notice('important event: %s', event_name)
log:warning('threshold exceeded: %s', metric)
log:error('operation failed: %s', err_msg)
```

日志默认只输出 Notice 及以上级别。频繁输出日志会影响 flash 寿命，在高频场景下谨慎使用 Info 以上级别。

### IPMI 命令注册

如需注册 IPMI 命令，先在 `mds/ipmi.json` 中配置（netfn、cmd、req、rsp），运行 `bingo gen`，然后在 `_app.lua` 中注册：

```lua
local ipmi_struct = require '<app_name>.ipmi.ipmi'
local ipmi_msg = require '<app_name>.ipmi.ipmi_message'
local ipmi = require 'ipmi'

function app:init()
    app.super.init(self)
    self.my_obj = self:CreateXxx(1, function(obj)
        obj.SomeProperty = default_value
    end)
    self:register_ipmi()
end

function app:register_ipmi()
    self:register_ipmi_cmd(ipmi_struct.GetInfo, function(req, ctx, ...)
        return ipmi_msg.GetInfoRsp.new(ipmi.types.Cc.Success, self.my_obj.SomeProperty)
    end)
end
```

### 持久化数据库操作

对于配置了持久化的属性，`bingo gen` 会在 `gen/` 目录生成 `db.lua`。可通过 Statement API 操作数据库：

```lua
-- 查询
local record = db:select(db.MyTable):where(db.MyTable.Id:eq(1)):first()
-- 插入
db:insert(db.MyTable):value({Id = 1, Name = 'test'}):exec()
-- 更新
db:update(db.MyTable):value({Name = 'new'}):where({Id = 1}):exec()
-- 删除
db:delete(db.MyTable):where({Id = 1}):exec()
```

## Step 6: 构建

```bash
bingo build --stage=stable
```

如需整包构建，在 `manifest.yml` 的 `dependencies:` 下添加组件后执行 `bingo build`。

## Step 7: 编写 UT/IT 测试

构建通过后，**必须编写 UT 和 IT 测试**再进行验证。跳过测试直接验证会导致问题在后期才暴露，修复成本更高。

> **完整的测试编写指南参考 `openubmc-dt-testing` Skill**，以下为快速入门。

### 单元测试（UT）

1. 确认被测模块的导出函数（`local` 函数不可直接测试）
2. 在 `test/unit/test_<module>.lua` 编写 LuaUnit 用例
3. 在 `test/unit/test.lua` 中 `require 'test_<module>'`

```lua
local lu = require 'luaunit'

TestMyModule = {}

function TestMyModule:test_basic_property()
    lu.assertEquals(obj.SomeProperty, expected_value)
end

function TestMyModule:test_edge_case()
    lu.assertNotNil(result)
end

os.exit(lu.LuaUnit.run())
```

运行：

```bash
bingo test -ut
```

### 集成测试（IT）

1. 在 `test/integration/` 下创建 `test_<app>.conf` 和 `test_<app>.lua`
2. 在 `service.json` 中声明测试依赖
3. 确认配置包含 `config:set_start(...)`、`test_common.dbus_launch()`、`skynet.uniqueservice('main')`

运行：

```bash
bingo test -it
```

### 覆盖率

```bash
bingo test -ut -cov
```

结果查看 `temp/coverage/luacov.report.html` 和 `dt_result.json`。

**测试编写的详细规则、断言 API、Troubleshooting 参考 `openubmc-dt-testing` Skill。**

## Step 8: 验证

验证资源是否生效：

```bash
source /etc/profile
busctl --user tree <bus-name>
busctl --user introspect <bus-name> <object-path>
mdbctl lsprop <ObjectName>
```

## 关键约束

以下约束源于 openUBMC 工具链的实际限制，违反会导致构建失败或运行异常：

- openUBMC 组件使用 `CMake + Conan2` 构建，不使用 `meson.build`。`bingo new` 生成的目录结构中没有 `src/main.lua`，入口文件是 `src/lualib/<app-name>_app.lua`。
- 日志模块是 `require 'mc.logging'`，不是 `require "logger"` 或 `require "log"`。
- `bingo gen` 生成的 `temp/` 和 `gen/` 目录会在每次执行时被覆盖，不要手动修改其中的文件。
- 只有在 `interfaces.properties` 中定义的属性才能通过 D-Bus 被外部访问。私有属性放在与 `interfaces` 平级的 `properties` 中。
- CRITICAL: 构建通过后必须编写 UT/IT 测试，禁止跳过测试直接交付。测试命令为 `bingo test -ut` 和 `bingo test -it`，禁止使用 `bingo test --unit` 等非官方写法。

## Examples

### 示例 1：创建一个新 Lua 组件（接口已存在）

```bash
cd /home/workspace
bingo new -n my_app -t application -l lua -conan 2.0
cd /home/workspace/my_app
git init .
```

编辑 `mds/model.json`：

```json
{
    "MyMDSModel": {
        "path": "/bmc/demo/MyMDSModel/${id}",
        "interfaces": {
            "bmc.demo.OpenUBMC.Community": {
                "properties": {
                    "WelcomeMessage": {}
                }
            }
        },
        "properties": {
            "SecretNumber": {
                "baseType": "U32"
            }
        }
    }
}
```

生成代码并实现业务逻辑：

```bash
bingo gen
```

编辑 `src/lualib/my_app_app.lua`：

```lua
local class = require 'mc.class'
local c_service = require 'my_app.service'

local app = class(c_service)

function app:ctor()
end

function app:init()
    app.super.init(self)
    self.my_mds_model = self:CreateMyMDSModel(1, function(object)
        object.ObjectName = "MyMDSModel_1"
        object.WelcomeMessage = "Hello OpenUBMC!"
        object.SecretNumber = 330
    end)
end

return app
```

构建并验证：

```bash
bingo build --stage=stable
source /etc/profile
busctl --user tree bmc.kepler.my_app
busctl --user introspect bmc.kepler.my_app /bmc/demo/MyMDSModel/1
```

### 示例 2：完整开发流程（需要新接口 + 持久化）

1. `bingo new -n <app-name> -t application -l lua -conan 2.0`
2. 确认接口是否已在 `mdb_interface` 中存在（`mdb-interface-dev` Skill 的 Step 0）
3. 如不存在：在 `mdb_interface` 仓库新增接口定义并本地构建（`mdb-interface-dev` Skill 的 Step 1）
4. 在 `mds/model.json` 定义模型，配置 `usage`、`tableName`、`primaryKey`（**具体写法参考 `mdb-interface-dev` Skill**）
5. `bingo gen`
6. 在 `src/lualib/<app-name>_app.lua` 创建对象实例并实现业务逻辑
7. `bingo build --stage=stable`
8. 编写 UT：在 `test/unit/` 下为导出函数编写 LuaUnit 用例，`bingo test -ut` 验证
9. 编写 IT：在 `test/integration/` 下编写集成测试，`bingo test -it` 验证（**详细规则参考 `openubmc-dt-testing` Skill**）
10. 如需整包，更新 `manifest.yml` 后执行 `bingo build`
11. 用 `busctl --user` / `mdbctl` 验证资源是否生效

## Troubleshooting

### bingo new 创建组件时卡住等待输入

原因：未指定 `-conan` 参数，进入了交互式选择。

解决：始终使用完整参数：`bingo new -n <app-name> -t application -l lua -conan 2.0`

### bingo gen 失败

与 MDB 接口、MDS 模型或 `mdb_interface` 相关的问题（接口不存在、path 文件目录结构错误、持久化配置不完整等），**参考 `mdb-interface-dev` Skill 的 Troubleshooting 小节**，其中包含完整的排查清单。

### bingo build 构建失败

1. 检查 `service.json` 中的依赖声明
2. 查看构建日志中的具体错误信息
3. 确认 Conan 和 CMake 版本满足最低要求

### busctl / mdbctl 查不到资源

1. 确认 `app:init()` 中调用了 `CreateXxx()` 并且先调用了 `app.super.init(self)`
2. 检查服务状态：`systemctl status <service>`
3. 查看日志：`journalctl -u <service> -n 100`
4. 如果是接口或属性不可见，确认属性定义在 `interfaces.properties` 中而非私有 `properties` 中

### bingo test -ut / -it 失败

测试相关的 Troubleshooting 参考 **`openubmc-dt-testing` Skill** 的 Troubleshooting 小节，包含：测试文件找不到、IT 超时卡住、覆盖率为空、断言失败无详情等常见问题。

## Related Skills

- **mdb-interface-dev** — MDB/D-Bus 接口开发：MDS 数据建模详解、`mdb_interface` 接口定义与新增、持久化配置规则、`bingo gen` 代码自动生成产物、RPC 方法实现、跨组件通信、IPMI 命令开发
- **openubmc-dt-testing** — UT/IT 测试编写：LuaUnit 断言 API、UT 目录结构与入口文件、IT 配置与依赖声明、覆盖率分析、测试用例设计指导。**Step 7 的完整指南在此 Skill 中**
- **openubmc-qemu-testing** — QEMU 仿真测试：QEMU 环境启动、冒烟验证、skynet coredump 排查。适用于需要在仿真环境中进行端到端验证的场景

## References

- 新增一个组件: <https://www.openubmc.cn/docs/zh/development/quick_start/create_an_app.html>
- Lua 开发框架: <https://www.openubmc.cn/docs/zh/development/design_reference/key_feature/lua_sdk.html>
- 组件的构建与发布: <https://www.openubmc.cn/docs/zh/development/develop_guide/app_development/build_process.html>
- 扩展对外接口: <https://www.openubmc.cn/docs/zh/development/quick_start/extend_bmc_api.html>
