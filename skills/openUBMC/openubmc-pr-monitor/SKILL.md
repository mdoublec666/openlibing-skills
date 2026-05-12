---
name: openubmc-pr-monitor
description: OpenUBMC 组织通用 PR 监控与审核技能。包含 Issue 操作规范、PR 审核规范、提交规范、合并流程。适用于 OpenUBMC 组织下所有仓库。
metadata:
  author: OpenUBMC Team
  version: 1.0.0
  tags: [pr, issue, review, openubmc, ci]
---

# openubmc-pr-monitor

OpenUBMC 组织通用 PR 监控与审核技能。

## ⚠️ 强制约束

1. **必须用 GitCode API v5**，禁止浏览器访问 gitcode.com
2. **发现 CI 失败后主动修复**，不等人工指令
3. **执行此 skill 前先读** `gitcode/SKILL.md`

---

## 触发条件

- Cron 定时触发
- 用户询问 PR 状态时

---

## 执行结束时的自主判断

**每次执行结束前，必须判断是否还需要继续监控：**

1. 检查当前 open PR 数量和状态
2. 如果所有 PR 都已合并/关闭，或长期无活动（>7天），判断是否还需要继续监控
3. **不需要继续监控时**：
   ```bash
   openclaw cron disable <cron-job-id>
   ```
   并通知用户："所有 PR 已处理完毕，已暂停 PR 监控。需要时告诉我重新开启。"

4. **需要继续监控时**：正常结束，等待下次触发

**判断标准**：
- 有 open PR 且有待处理问题 → 继续监控
- 所有 PR 已合并/关闭 → 暂停监控
- PR 长期无活动且无待处理问题 → 暂停监控

---

## 执行流程

### Step 1: 获取你自己的 PR 列表

**只监控你自己提交的 PR，忽略其他人的 PR：**

```bash
# 获取所有 open PR，过滤出自己的（替换 YOUR_USERNAME 和仓库路径）
curl -s "https://gitcode.com/api/v5/repos/{owner}/{repo}/pulls?access_token=${GITCODE_TOKEN}&state=open" | jq '.[] | select(.user.login == "YOUR_USERNAME") | {number, title, labels: [.labels[].name]}'
```

如果返回空，说明没有你的 PR 需要监控，执行结束判断。

### Step 2: 检查每个 PR 的 CI 状态

```bash
curl -s "https://gitcode.com/api/v5/repos/{owner}/{repo}/pulls/{number}?access_token=${GITCODE_TOKEN}" | jq '{
  number,
  state,
  labels: [.labels[].name]
}'
```

CI 标签由各仓库自行定义，具体标签名见仓库级 skill。

### Step 3: 如果有 CI 失败，执行自动修复

```bash
# 获取 PR 评论中的错误详情（关键词视仓库而定）
curl -s "https://gitcode.com/api/v5/repos/{owner}/{repo}/pulls/{number}/comments?access_token=${GITCODE_TOKEN}" | jq '.[] | select(.body | contains("门禁未通过")) | .body'
```

解析错误后：
1. 确定需要修复的文件和具体错误
2. 启动 subagent 修复（设置 5 分钟超时）
3. 修复完成后推送并等待 CI 结果

### Step 4: PR 合入后关闭关联 Issue

**当 PR 合入后，必须关闭关联的 Issue。**

⚠️ **缺陷类 issue 必须走工作流**，不能直接 `/close`：
```
待修复 → /todo2fixing → 修复中 → /fixing2UAT → 待验收 → /UAT2done → 已修复(closed)
```

**机器人执行命令后不会回复评论**，必须通过 API 查 `issue_state` 字段确认状态：
```bash
# 查询 issue 工作流状态
curl -s "https://gitcode.com/api/v5/repos/{owner}/{repo}/issues/{issue_number}?access_token=${GITCODE_TOKEN}" | jq '{state, issue_state}'
```

**关闭缺陷类 Issue 的正确流程**：
```bash
# 1. 先评论说明 PR 已合入
curl -X POST "https://gitcode.com/api/v5/repos/{owner}/{repo}/issues/{issue_number}/comments?access_token=${GITCODE_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{"body": "PR #{pr_number} 已被合入。"}'

# 2. 按工作流逐步推进（每步间隔 5 秒，用 API 查 issue_state 确认）
# 根据当前状态选择下一步命令：
#   待修复 → /todo2fixing
#   修复中 → /fixing2UAT
#   待验收 → /UAT2done
curl -X POST "https://gitcode.com/api/v5/repos/{owner}/{repo}/issues/{issue_number}/comments?access_token=${GITCODE_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{"body": "/todo2fixing"}'

# 3. 确认状态变更
sleep 5
curl -s "https://gitcode.com/api/v5/repos/{owner}/{repo}/issues/{issue_number}?access_token=${GITCODE_TOKEN}" | jq '.issue_state'

# 4. 继续下一步，直到 issue_state 变为 "已修复"
```

**需求类 issue 的关闭流程可能不同，待确认。**

### API 调用错误处理

如果 API 调用返回错误，按以下方式处理：

| 状态码 | 说明 | 处理方式 |
|--------|------|----------|
| 401 | Token 无效或过期 | 检查 `GITCODE_TOKEN` 环境变量 |
| 403 | 无权限 | 确认账号有该仓库的 issue 管理权限 |
| 405 | 方法不支持 | 检查 API 路径和 HTTP 方法是否正确 |
| 429 | 请求过于频繁 | 等待后重试（Rate Limit: 50次/分钟） |

---

## ⚠️ PR Review 规范

### 检视评论位置
- ✅ **正确**：在具体代码行上评论（PR review comments）
  ```bash
  POST /repos/{owner}/{repo}/pulls/{number}/comments
  参数: body, path, position（position 是文件实际行号）
  ```
- ❌ **错误**：发到普通评论（issue comments），那样不会出现在 review 讨论串中
  ```bash
  ❌ POST /repos/{owner}/{repo}/issues/{number}/comments
  ```

### 回复检视意见
- 必须使用 `in_reply_to_id` 参数在 review comment 下回复
- 收到检视意见后，修复并回复说明，**不能只修改不回复**

### 编辑检视评论
如需修改已有的 review comment（如补充 AI 署名），使用：
```bash
PATCH /repos/{owner}/{repo}/pulls/comments/{id}
curl -X PATCH "https://gitcode.com/api/v5/repos/{owner}/{repo}/pulls/comments/{id}?access_token=${GITCODE_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{"body": "新的评论内容"}'
```
⚠️ **注意路径中有 `pulls/`**，不是 `/repos/{owner}/{repo}/comments/{id}`。

### AI 评论尾标
所有 PR 检视评论必须添加 AI 签名：
```
---
*此评论由 AI (OpenClaw + GLM-5-turbo) 完成*
```
⚠️ 模型名必须完整（如 `GLM-5-turbo`），不能省略后缀。

**PR 描述同样必须署名**：创建 PR 和编辑 PR 描述时，末尾均需加上：
```
---
*此 PR 由 AI (OpenClaw + GLM-5-turbo) 完成*
```

### 自己提的 PR 不能自己合并
即使 CI 通过也要等待他人审核，不能自己 lgtm + approve 自己的 PR。

### 单个 PR 行数 ≤1000
OpenUBMC 社区规则：**单个 PR 的 insertions 不能超过 1000 行**（`git diff --shortstat` 中的 `insertion` 数字）。

**拆分策略**：
1. 先计算总行数：`git diff upstream/main --shortstat`
2. 如果超过 1000 行，按功能/模块拆分为多个 PR
3. 每个独立功能一个 PR，不要把不相关的改动混在一起
4. 新增文件（`new file`）和修改文件可以分 PR

### PR 描述必须关联 Issue
**必须用 API 关联**（不能只在 PR body 中写 `Fixes #N`）：

```bash
# PR 创建后，用 API 关联 issue
curl -X POST "https://gitcode.com/api/v5/repos/{owner}/{repo}/pulls/{number}/issues?access_token=${GITCODE_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '[8]'  # issue 编号数组
```

如果机器人已添加 `needs-issue` 标签，关联后评论 `/check-issue` 移除标签。

⚠️ **错误做法**：
- 评论中写 `关联 Issue #N`（不被机器人识别）
- 只在 PR body 中写 `Fixes #N`（不一定生效）

### PR 描述必须完整
- ✅ 完整描述变更内容
- ❌ 不能只写"请查看 commit 记录"，即使与 commit 内容重复也要完整描述

### 合并流程

openUBMC 项目**不使用 API 直接合并**，通过评论触发机器人：

**Step 1: 检查 PR 是否可合入**

在提交 `/lgtm` 和 `/approve` 之前，必须先确认 PR 状态满足所有条件：

```bash
curl -s "https://gitcode.com/api/v5/repos/{owner}/{repo}/pulls/{number}?access_token=${GITCODE_TOKEN}" | jq '{
  state,
  mergeable,
  labels: [.labels[].name]
}'
```

**必须满足以下全部条件才能继续：**
- ✅ CI 通过（有 `ci-successful` 或仓库特定的 CI 成功标签）
- ✅ CLA 通过（有 `openUBMC-cla/yes` 标签）
- ✅ 无 `unresolved-reviews` 标签
- ✅ 无 `stat/needs-squash` 标签
- ✅ `mergeable` 为 true

**如果存在阻塞条件，先处理：**
| 阻塞 | 处理方式 |
|------|----------|
| `unresolved-reviews` | 先 resolve 所有检视意见（PUT 评论 + `{"resolved": true}`），然后评论 `/check-pr` |
| `stat/needs-squash` | 执行 git amend 合并 commits，force push |
| CI 失败 | 修复代码后等待 CI 重新通过 |

**Step 2: 提交审核**

```bash
# 添加 lgtm
curl -X POST "https://gitcode.com/api/v5/repos/{owner}/{repo}/pulls/{number}/comments?access_token=${GITCODE_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{"body": "/lgtm"}'

# 添加 approve
curl -X POST "https://gitcode.com/api/v5/repos/{owner}/{repo}/pulls/{number}/comments?access_token=${GITCODE_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{"body": "/approve"}'
```

**Step 3: 等待并确认合入**

提交后等待约 30 秒，然后检查 PR 状态：

```bash
curl -s "https://gitcode.com/api/v5/repos/{owner}/{repo}/pulls/{number}?access_token=${GITCODE_TOKEN}" | jq '{state, merged_at: .merged_at}'
```

- ✅ `state` 变为 `closed` 且有 `merged_at` → 合入成功，流程结束
- ❌ 1 分钟内仍为 `open` → 评论 `/check-pr` 手动触发机器人，再等待 30 秒重新检查

**如果 `/check-pr` 后仍未合入**：检查 PR 是否出现了新的阻塞标签（如 CI 重跑失败），处理后再评论 `/check-pr`。

**⚠️ 完整合入流程总结：检查状态 → 处理阻塞 → /lgtm + /approve → 等待 30s → 确认合入 → 必要时 /check-pr → 再次确认**

---

## ⚠️ Git 提交规范

### 修复 PR 必须用 amend
**永远用 `--amend`，不要创建新 commit**，否则会触发 `stat/needs-squash` 标签。

```bash
# 正确流程
git add <file>
git commit --amend --no-edit    # ← 修改原始 commit
git push -f origin <branch>     # ← 必须强制推送
```

```bash
# 如果已经错误地创建了新 commit，先回退
git reset --soft HEAD~1         # 回退，保留修改
git commit --amend --no-edit    # 修改原始 commit
git push -f origin <branch>     # 强制推送
```

### 必须配置正确的 git config
<!-- openUBMC 社区 CLA 要求：提交 author 必须与 CLA 签署人一致。以下为示例，实际使用时请替换为你自己的信息。 -->
提交 author 必须与你的 CLA 签署信息一致，否则 CLA 验证失败：
```bash
git config user.name "<YOUR_NAME>"
git config user.email "<YOUR_EMAIL>"
```

### 修复分支必须基于 upstream/main
❌ 禁止基于 origin/main 创建 PR 分支
✅ 必须 `git reset --hard upstream/main`

---

## ⚠️ Issue 修复规范

### 修复前必须检查（避免重复工作）
1. ✅ 搜索是否有已合入的 PR 修复了该 Issue
2. ✅ 检查是否有进行中的 PR
3. ✅ 检查 Issue 评论中的状态标记：
   - `/fixing2UAT` = 待验收，**不需要修复**
   - `/fixing` = 有人正在修复
4. ❌ 不要只看 open/close 状态

### 不由我修复的 Issue
- 超出当前仓库范围的 Issue → 关闭并说明原因

---

## Fork 仓库修复流程

PR 分支基于你的 fork，但提交到 upstream（`{owner}/{repo}`）。

**⚠️ 修复时必须基于 upstream/main：**

```bash
# 添加 upstream（如果不存在）
git remote add upstream git@gitcode.com:{owner}/{repo}.git

# 获取最新 upstream
git fetch upstream main

# 基于 upstream 创建/重置分支
git checkout fix-xxx
git reset --hard upstream/main

# 配置 git（替换为你自己的 CLA 签署信息）
git config user.name "<YOUR_NAME>"
git config user.email "<YOUR_EMAIL>"

# 应用修复
# ... 修改文件 ...

# 提交（用 amend！）
git add .
git commit --amend --no-edit
git push origin fix-xxx --force
```

---

## 配置

- `GITCODE_TOKEN` 环境变量（需要在 `~/.bashrc` 或 `~/.zshrc` 中配置）
- 工作目录: `{repo_path}`（各仓库自行定义）

## 相关 Skills

- **gitcode**: `gitcode/SKILL.md` — GitCode API v5 详细文档

---

*Updated: 2026-03-27*
