# 持久化机制介绍

> 来源：<https://www.openubmc.cn/docs/zh/development/develop_guide/feature_development/persistence_mechanisms_introduction.html>

在 openUBMC 固件中，数据持久化机制是指将关键的配置、状态及监控数据从易失性内存写入非易失性存储介质的过程。该机制主要基于 SQLite 数据库实现。

组件的持久化配置以 MDS 模型中 `model.json` 定义的类为基本单位。每个类在数据库中映射为一张独立的数据表，而类中声明为持久化的属性则对应表中的字段。

---

## 持久化模式

通过 MDS 模型中类定义的 `tableLocation` 字段配置，支持两种管理模式：

- **本地持久化模式**：数据存储在以组件名称命名的专属持久化数据库中，组件直接对本地持久化数据库执行读写操作。
- **远程持久化模式**（默认）：组件启动时创建内存数据库作为临时工作区，框架通过钩子机制自动捕获变更事件，通过 RPC 转发至 persistence 服务统一写入持久化数据库。

## 持久化类型

通过类定义的 `tableType` 字段或属性定义的 `usage` 字段设置：

| 类型 | 标识 | 存储介质 | 生存期 |
|------|------|----------|--------|
| 不持久化 | Memory | 内存数据库 | 进程重启后丢失 |
| 临时持久化 | TemporaryPer | tmpfs 虚拟内存文件系统 | BMC 复位后清除 |
| 复位持久化 | ResetPer | pram 文件系统 | BMC 掉电后清除 |
| 掉电持久化 | PoweroffPer | nandflash 文件系统 | BMC 深度还原/恢复出厂后清除 |
| 永久持久化 | PermanentPer | 字符设备（非数据库） | 深度还原/恢复出厂后仍保留 |

---

## MDS 持久化配置方式（model.json）

### 类级别字段

| 字段 | 说明 |
|------|------|
| `tableName` | 该类通过 ORM 映射的数据库表名 |
| `tableLocation` | 持久化方式。值为 `Local` 表示本地持久化；不配或其他值为远程持久化 |
| `tableType` | 该类所有属性的持久化类型（如 `PoweroffPer`） |
| `tableMaxRows` | 数据库表中最多允许存储多少条数据 |

### 属性级别字段

| 字段 | 说明 |
|------|------|
| `usage` | 数组，指定属性的持久化类型（如 `["PoweroffPer"]`） |
| `primaryKey` | `true` 表示该属性是数据库表主键；多个属性为主键时组合值必须唯一 |
| `uniquekey` | `true` 表示唯一键；主键属性自动具备唯一键约束 |
| `baseType` | 数据类型：`U8`、`U16`、`U32`、`U64`、`S8`、`S16`、`S32`、`S64`、`String` 等 |
| `default` | 默认值，插入新数据行未赋值时自动使用 |
| `notAllowNull` | `true` 表示不允许为 NULL；主键默认不允许为空 |
| `sensitive` | `true` 表示敏感数据，一键收集/导出时替换为 `*****` |
| `critical` | `true` 表示关键数据，掉电持久化时每次更新同步写入备份数据库 |

---

## 关键注意事项

- **永久持久化不支持本地模式**
- **永久持久化总可用空间仅 2MB**，仅适用于数量小、内容稳定的关键数据（如 MAC 地址）
- **掉电持久化需评估写入量与频率**，避免影响 Flash 存储介质寿命
- **本地持久化**仅支持通过 `tableType` 配置整表持久化类型，属性级别的 `usage` 无效
- **本地持久化**未配置 `tableType` 时默认采用 `PoweroffPer`
- **远程持久化**中 `tableType` 与属性 `usage` 同时配置时，优先采用属性级别的持久化类型
- **远程持久化**未配置任何持久化类型时，数据仅存在于内存数据库中，不会被持久化

---

## 自动生成代码与持久化的对应关系

| 生成文件 | 依据 | 说明 |
|----------|------|------|
| `gen/<App名>/db.lua` | model.json | 远程持久化内存数据库表格创建和操作函数 |
| `gen/<App名>/local_db.lua` | model.json | 本地持久化数据库表格创建和操作函数（`tableLocation: Local`） |
| `gen/<App名>/orm_classes.lua` | model.json | 为配置了远程持久化的每个类初始化 ORM 对象 |
| `gen/<App名>/datas.lua` | datas.yaml | 持久化数据库初始化加载的默认数据 |

---

## 持久化数据库路径

### 远程持久化

| 类型 | 路径 |
|------|------|
| TemporaryPer | `/run/persistence/per_temporary.db` |
| ResetPer | `/opt/bmc/pram/persistence/per_reset.db` |
| PoweroffPer | `/data/trust/persistence/per_poweroff.db` |
| PermanentPer | `/dev/mmcblk0p8` |

### 本地持久化（`tableLocation: Local`）

| 类型 | 路径 |
|------|------|
| TemporaryPer | `/dev/shm/persistence.local/*.db` |
| ResetPer | `/opt/bmc/pram/persistence.local/*.db` |
| PoweroffPer（非最小系统组件） | `/data/opt/bmc/persistence.local/*.db` |
| PoweroffPer（最小系统组件） | `/data/trust/persistence.local/*.db` |

可通过 `/opt/bmc/trust/mini_system.json` 查看最小系统组件清单。

---

## 持久化问题定位

### 命令行查询

```bash
# 远程持久化 - 掉电持久化查询
/usr/sbin/sqlite3 /data/trust/persistence/per_poweroff.db \
  "SELECT * FROM persist_table WHERE table_name = '<表名>';"

# 本地持久化查询（数据库文件以组件名命名）
/usr/sbin/sqlite3 /data/opt/bmc/persistence.local/<组件名>.db \
  "SELECT * FROM <表名>;"
```

### 删除数据

**远程持久化**（删除后需重启组件所在进程）：

```bash
# 删除整表
/usr/sbin/sqlite3 /data/trust/persistence/per_poweroff.db \
  "DELETE FROM persist_table WHERE table_name = '<表名>';"

# 删除单条记录
/usr/sbin/sqlite3 /data/trust/persistence/per_poweroff.db \
  "DELETE FROM persist_table WHERE table_name = '<表名>' AND prime_key = '<主键字段>:<值>';"
```

**本地持久化**（删除后立即生效，无需重启）：

```bash
/usr/sbin/sqlite3 /data/opt/bmc/persistence.local/<组件名>.db \
  "DELETE FROM <表名>;"
```

注意：对于存在新增字段的本地持久化数据表，删除时需使用 `_v_<表名>` 视图名，否则扩展表会有数据残留。

### 恢复 datas.yaml 预置数据

远程持久化删除过的数据在 `deleted_data_table` 中保留主键值记录，阻止 datas.yaml 预置数据重新加载。如需恢复：

```bash
/usr/sbin/sqlite3 /data/trust/persistence/per_poweroff.db \
  "DELETE FROM deleted_data_table WHERE table_name = '<表名>';"
# 然后重启组件所在进程
```

### 内存数据库查看（代码注入）

需要 skynet 进程开启 debug_console：

```lua
local c_object_manage = require 'mc.orm.object_manage'
local cjson = require 'cjson'
local sqlite3 = require 'lsqlite3'
local db = c_object_manage.get_instance().db.db
local vm = db:prepare('SELECT * FROM <表名>')
while vm:step() ~= sqlite3.DONE do
    print(cjson.encode(vm:get_named_values()))
end
vm:finalize()
```

通过 `telnet <IP> <debug_console端口>` 连接后，执行 `list` 找到服务地址，再 `inject <服务地址> <lua文件路径>` 注入执行。
