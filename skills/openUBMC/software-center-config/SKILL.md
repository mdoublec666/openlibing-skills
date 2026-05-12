---
name: software-center-config
description: software-center-config 仓库维护技能。管理应用配置的版本同步、新增应用、PR 提交流程。
metadata:
  author: OpenUBMC Team
  version: 1.0.0
  tags: [software-center, config, openubmc, manifest]
---

# software-center-config

software-center-config 仓库维护技能。负责将 manifest 仓库的应用版本同步到配置文件，管理应用的新增和更新。

## ⚠️ 强制约束

1. **版本号必须来自 manifest 仓库**，不能手动指定
2. **版本同步前必须检查 upstream 是否已有最新版本**（避免重复工作）
3. **SIG 归属按 manifest 的 subsys 分类**，不能随意指定
4. **单个 PR ≤1000 行 insertions**（OpenUBMC 社区规则）

---

## 触发条件

- 用户要求同步应用版本
- 用户要求新增应用到配置
- 用户询问 software-center-config 状态

---

## 仓库信息

- **仓库**: `openUBMC/software-center-config`
- **路径**: `/home/admin/workspace/software-center-config`
- **远程**: `origin` = `git@gitcode.com:zybwh/software-center-config.git`（fork），`upstream` = `git@gitcode.com:openUBMC/software-center-config.git`
- **结构**: `configs/application/{app}/{version}/software.yml`

---

## 关联仓库

### manifest 仓库
- **路径**: `/home/admin/workspace/manifest`
- **版本信息**: `build/subsys/*.yml` 中包含所有 conan 依赖的版本号
- **SIG 归属**: 每个 app 按 subsys 文件分类（如 `interface.yml`、`security.yml`）

### 获取版本号

```bash
# 从 manifest 提取某个 app 的最新版本
grep -rh "\"{app_name}/" /home/admin/workspace/manifest/build/subsys/*.yml | \
  sed 's/.*"'"${app_name}"'\/\([^@]*\)@.*/\1/' | sort -V | tail -1
```

### 获取 SIG 归属

```bash
# 查找 app 属于哪个 subsys（即 SIG）
grep -rl "\"{app_name}/" /home/admin/workspace/manifest/build/subsys/*.yml | \
  xargs -I{} basename {} .yml
```

**SIG 到邮箱的映射**（已知）：
| SIG | 邮箱 |
|---|---|
| interface | interface@public.openubmc.cn |
| security | security@public.openubmc.cn |
| hardware | hardware@public.openubmc.cn |
| TC | tc@public.openubmc.cn |
| component_drivers | component_drivers@public.openubmc.cn |
| bmc-core | bmc-core@public.openubmc.cn |

---

## software.yml 模板

```yaml
name: {app_name}
maintainer:
  sig: {sig_name}
  email: {sig_email}
  gitcode: https://gitcode.com/openUBMC/{app_name}
description: {中文描述}
description_en: {英文描述}
usage: 
  - |
    使用openUBMC社区Conan仓进行获取，因此需要配置Conan中心仓。
    ```bash
    pip install conan==2.13.0
    conan profile detect --force
    conan remote add openubmc_dev 'https://conan.openubmc.cn/conan_1/' --insecure --force
    conan remote login openubmc_dev 《openUBMC社区用户名》 -p "《openUBMC社区用户密码》"
    ```
  - |
    从Conan中心仓拉取组件。
    ```bash
    conan download {app_name}/{version}@openubmc/stable#latest -r openubmc_dev
    ```
  - |
    如果需要构建特定版本，如`test`选项为`True`的包等，可以使用`conan install`功能。
    ```bash
    conan install --requires='{app_name}/{version}@openubmc/stable' -r openubmc_dev -o */*:test=True -pr profile.dt.ini --build=missing
    ```
  - |
    如果需要进行二次定制，可以通过拉取代码仓后，通过[bingo](https://openubmc.cn/easysoftware/bingo)进行构建。
    ```bash
    git clone git@gitcode.com:openUBMC/{app_name}.git
    cd {app_name}
    bingo build
    ```
usage_en:
  - |
    In order to download from the openUBMC Conan repository, you need to setup Conan first.
    ```bash
    pip install conan==2.13.0
    conan profile detect --force
    conan remote add openubmc_dev 'https://conan.openubmc.cn/conan_1/' --insecure --force
    conan remote login openubmc_dev 《openUBMC username》 -p "《openUBMC password》"
    ```
  - |
    Download from Conan repository
    ```bash
    conan download {app_name}/{version}@openubmc/stable#latest -r openubmc_dev
    ```
  - |
    If you need to build a specific version, use `conan install` instead.
    ```bash
    conan install --requires='{app_name}/{version}@openubmc/stable' -r openubmc_dev -o */*:test=True -pr profile.dt.ini --build=missing
    ```
  - |
    If you need to build from scratch, clone the git repo and build with [`bingo`](https://openubmc.cn/easysoftware/bingo).
    ```bash
    git clone git@gitcode.com:openUBMC/{app_name}.git
    cd {app_name}
    bingo build
    ```
license: Mulan PSL v2
download:
  cmd: conan download {app_name}/{version}@openubmc/stable#latest -r openubmc_dev
type: application
version: {version_tag}   # 如 26.03
app_version: {version}    # 如 1.100.21
```

---

## 操作流程

### 版本同步（已有 app 更新版本）

1. **获取 manifest 最新版本**
   ```bash
   # 批量检查所有已有 app 的版本
   for app_dir in configs/application/*/; do
     app=$(basename "$app_dir")
     yml="$app_dir/25.12/software.yml"
     if [ -f "$yml" ]; then
       old_ver=$(grep "^app_version:" "$yml" | awk '{print $2}')
       new_ver=$(grep -rh "\"$app/" /home/admin/workspace/manifest/build/subsys/*.yml | sed 's/.*"'"$app"'\/\([^@]*\)@.*/\1/' | sort -V | tail -1)
       if [ "$old_ver" != "$new_ver" ]; then
         echo "UPDATE: $app  $old_ver -> $new_ver"
       fi
     fi
   done
   ```

2. **创建新版本目录**：复制上一版本的 `software.yml`，替换版本号
   - `app_version` 更新为新版本
   - `version` 更新为版本标签（如 `26.03`）
   - conan 引用中的版本号同步替换

3. **检查 upstream 是否已有**
   ```bash
   git fetch upstream && git ls-tree --name-only upstream/main | grep "26.03"
   ```

4. **提交 PR**（注意 ≤1000 行限制，超了要拆分）

### 新增应用

1. **确认仓库存在**：通过 GitCode API 检查 `openUBMC/{app_name}` 仓库
2. **获取描述**：从仓库 description 提取，翻译中英文
3. **确定 SIG**：从 manifest subsys 分类
4. **创建 software.yml**：按模板填写
5. **提交 PR**

### 新增应用的 SIG 判断

如果 app 不在 manifest 的 subsys 中，通过 GitCode API 获取仓库描述，根据功能判断：
- Web 界面相关 → interface
- 安全/加密相关 → security
- 硬件监控/传感器相关 → hardware
- 测试/调试工具 → TC
- 底层组件/编译依赖 → bmc-core 或 component_drivers

---

## 底层依赖排除

以下类型的仓库不添加到 application 配置：
- 编译工具链依赖（abseil、grpc、openssl、protobuf 等）
- 纯测试工具（如果没有 conan 包）
- 被其他 app 内部依赖但不独立使用的库

---

## ⚠️ 踩坑记录

### upstream 已有最新版本
2026-03-31：尝试为 28 个 app 创建 26.03 配置，结果 upstream/main 已经有了。必须先 `git fetch upstream` 再检查，不要凭本地缓存判断。

### needs-issue 标签
创建 PR 后，**必须用 API 关联 issue**（POST /repos/{owner}/{repo}/pulls/{number}/issues + Body `[issue_id]`），否则机器人会加 `needs-issue` 标签阻止合入。关联后评论 `/check-issue` 移除标签。

### API 关闭 Issue 失败
`PATCH /repos/{owner}/{repo}/issues/{id}` + `state_event=close` 可能返回 200 但不生效。对于非缺陷类 issue（如任务类），可能需要不同命令或权限。

---

*Created: 2026-03-31*
