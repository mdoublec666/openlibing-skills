---
name: gitcode
description: GitCode 平台操作技能（OpenUBMC 组织通用）。处理 issues、PR、仓库管理等 API v5 操作。当需要操作 GitCode 仓库、issue、PR 时使用此技能。
metadata:
  author: OpenUBMC Team
  version: 1.0.0
  tags: [gitcode, api, openubmc, pr, issue]
---

# GitCode 操作技能

## ⚠️ 重要：API 版本 (必须先读)

**GitCode 使用 Gitee API v5，不是 GitLab API v4！**

```
正确: https://gitcode.com/api/v5/repos/{owner}/{repo}/pulls/{number}?access_token=${GITCODE_TOKEN}
错误: https://gitcode.com/api/v4/projects/{id}/merge_requests/{iid}?private_token=${GITCODE_TOKEN}
```

认证方式：`?access_token=${GITCODE_TOKEN}` (query 参数)

推荐使用 **query 参数**（`?access_token=xxx`），兼容性更好。
Header 方式（`Authorization: Bearer xxx`）在部分旧版 API 中可能不支持。

> ⚠️ **安全提示**：`access_token` 是个人访问令牌，具有仓库的读写权限。
> - 不要将 token 硬编码在代码或公开仓库中
> - 不要通过 URL 分享包含 token 的链接
> - 建议设置环境变量 `GITCODE_TOKEN` 使用，而不是直接写在命令中
> - 获取 token：GitCode → 设置 → 私人令牌

---

## 核心原则

⚠️ **所有 GitCode 操作必须通过 API 完成，禁止使用浏览器访问网页。**

- ✅ 使用 GitCode API v5
- ❌ 不要使用 browser 工具访问 gitcode.com
- ❌ 不要假设是 GitLab API（即使看起来像）

## API 基础信息

- **基础 URL**: `https://gitcode.com/api/v5`
- **认证方式**: 
  - `access_token` query 参数（推荐）
  - `Authorization: Bearer {token}` header
- **Rate Limit**: 50次/分钟，4000次/小时
- **分页参数**: `page`, `per_page` (默认30，最大100)

## HTTP 状态码

| 状态码 | 说明 | 处理方式 |
|--------|------|----------|
| 200 | 成功 | — |
| 201 | 创建成功 | — |
| 204 | 删除成功 | — |
| 401 | 未认证/Token 无效 | 检查 access_token 是否正确 |
| 403 | 无权限 | 确认账号是否有仓库访问权限 |
| 404 | 资源不存在 | 检查 API 路径和参数 |
| 429 | 请求过于频繁 | 等待后重试 |

---

## 认证

```bash
# 设置环境变量
export GITCODE_TOKEN="your_personal_access_token"

# 验证 Token
curl -s "https://gitcode.com/api/v5/user?access_token=${GITCODE_TOKEN}" | jq '.login'
```

---

# API 端点参考

## 1. 用户 API

### 获取当前用户信息
```bash
GET /user
curl -s "https://gitcode.com/api/v5/user?access_token=${GITCODE_TOKEN}"
```

### 获取用户信息
```bash
GET /users/{username}
curl -s "https://gitcode.com/api/v5/users/{username}?access_token=${GITCODE_TOKEN}"
```

---

## 2. 仓库 API

### 获取仓库信息
```bash
GET /repos/{owner}/{repo}
curl -s "https://gitcode.com/api/v5/repos/{owner}/{repo}?access_token=${GITCODE_TOKEN}"
```

### 获取分支列表
```bash
GET /repos/{owner}/{repo}/branches
curl -s "https://gitcode.com/api/v5/repos/{owner}/{repo}/branches?access_token=${GITCODE_TOKEN}"
```

### 获取文件内容
```bash
GET /repos/{owner}/{repo}/contents/{path}
curl -s "https://gitcode.com/api/v5/repos/{owner}/{repo}/contents/{path}?access_token=${GITCODE_TOKEN}&ref={branch}"
```

### 获取 README
```bash
GET /repos/{owner}/{repo}/readme
curl -s "https://gitcode.com/api/v5/repos/{owner}/{repo}/readme?access_token=${GITCODE_TOKEN}"
```

### Fork 仓库
```bash
POST /repos/{owner}/{repo}/forks
curl -X POST "https://gitcode.com/api/v5/repos/{owner}/{repo}/forks?access_token=${GITCODE_TOKEN}"
```

---

## 3. Issues API

### 获取仓库 Issues
```bash
GET /repos/{owner}/{repo}/issues
curl -s "https://gitcode.com/api/v5/repos/{owner}/{repo}/issues?access_token=${GITCODE_TOKEN}&state=open&page=1&per_page=100"
```

### 获取单个 Issue
```bash
GET /repos/{owner}/{repo}/issues/{number}
curl -s "https://gitcode.com/api/v5/repos/{owner}/{repo}/issues/{number}?access_token=${GITCODE_TOKEN}"
```

### 创建 Issue
```bash
POST /repos/{owner}/{repo}/issues
curl -X POST "https://gitcode.com/api/v5/repos/{owner}/{repo}/issues?access_token=${GITCODE_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{"title": "Issue 标题", "body": "Issue 内容"}'
```

### 更新 Issue
```bash
PATCH /repos/{owner}/{repo}/issues/{number}
curl -X PATCH "https://gitcode.com/api/v5/repos/{owner}/{repo}/issues/{number}?access_token=${GITCODE_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{"title": "新标题", "state": "closed"}'
```

### 关闭 Issue（通过命令评论）
```bash
# openUBMC 项目使用机器人命令关闭 Issue，推荐此方式
POST /repos/{owner}/{repo}/issues/{number}/comments
curl -X POST "https://gitcode.com/api/v5/repos/{owner}/{repo}/issues/{number}/comments?access_token=${GITCODE_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{"body": "/close"}'
```

⚠️ **缺陷类 issue 必须走工作流**，不能直接 `/close`：
```
待修复 → /todo2fixing → 修复中 → /fixing2UAT → 待验收 → /UAT2done → 已修复(closed)
```

⚠️ **机器人执行命令后不会回复评论**，必须通过 API 查 `issue_state` 字段确认状态：
```bash
curl -s "https://gitcode.com/api/v5/repos/{owner}/{repo}/issues/{number}?access_token=${GITCODE_TOKEN}" | jq '{state, issue_state}'
```

⚠️ **最佳实践**：关闭 Issue 前先评论说明原因，再发工作流命令：
```bash
# 1. 先说明原因
curl -X POST "https://gitcode.com/api/v5/repos/{owner}/{repo}/issues/{number}/comments?access_token=${GITCODE_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{"body": "PR #123 已被合入。"}'
# 2. 按工作流推进（根据 issue_state 当前值选择下一步命令）
curl -X POST "https://gitcode.com/api/v5/repos/{owner}/{repo}/issues/{number}/comments?access_token=${GITCODE_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{"body": "/todo2fixing"}'
# 3. 等 5 秒后用 API 查 issue_state 确认，然后继续下一步
```

### 获取 Issue 评论
```bash
GET /repos/{owner}/{repo}/issues/{number}/comments
curl -s "https://gitcode.com/api/v5/repos/{owner}/{repo}/issues/{number}/comments?access_token=${GITCODE_TOKEN}"
```

### 创建 Issue 评论
```bash
POST /repos/{owner}/{repo}/issues/{number}/comments
curl -X POST "https://gitcode.com/api/v5/repos/{owner}/{repo}/issues/{number}/comments?access_token=${GITCODE_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{"body": "评论内容"}'
```

### Issue 标签管理
```bash
# 获取 Issue 标签
GET /repos/{owner}/{repo}/issues/{number}/labels

# 添加标签
POST /repos/{owner}/{repo}/issues/{number}/labels
curl -X POST "https://gitcode.com/api/v5/repos/{owner}/{repo}/issues/{number}/labels?access_token=${GITCODE_TOKEN}" \
  -d '["bug", "help wanted"]'

# 删除标签
DELETE /repos/{owner}/{repo}/issues/{number}/labels/{name}
```

### 关联 Issue 到 PR
**必须用 API 关联**（PR body 中写 `Fixes #N` 不一定会被机器人识别为关联）：

```bash
POST /repos/{owner}/{repo}/pulls/{number}/issues
curl -X POST "https://gitcode.com/api/v5/repos/{owner}/{repo}/pulls/{number}/issues?access_token=${GITCODE_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '[123]'  # 关联的 Issue 编号数组
```

- ✅ **正确**：`POST /repos/{owner}/{repo}/pulls/{number}/issues` + Body `[issue_id]`
- ⚠️ **可用**：PR body 第一行写 `Fixes #N`（某些场景会自动关联，但不保证所有仓库都生效）
- ❌ **错误**：评论中写 `关联 Issue #N`（不会被识别）
- ❌ **废弃**：`PUT /repos/{owner}/{repo}/issues/{number}/related`（旧接口，已不推荐）

**删除关联**：
```bash
DELETE /repos/{owner}/{repo}/pulls/{number}/issues/{issue_number}
curl -X DELETE "https://gitcode.com/api/v5/repos/{owner}/{repo}/pulls/{number}/issues/{issue_number}?access_token=${GITCODE_TOKEN}"
```

⚠️ 关联 issue 后，`needs-issue` 标签可能需要评论 `/check-issue` 才会移除。

---

## 4. Pull Requests API

### 获取 PR 列表
```bash
GET /repos/{owner}/{repo}/pulls
curl -s "https://gitcode.com/api/v5/repos/{owner}/{repo}/pulls?access_token=${GITCODE_TOKEN}&state=open"
```

### 获取 PR 详情
```bash
GET /repos/{owner}/{repo}/pulls/{number}
curl -s "https://gitcode.com/api/v5/repos/{owner}/{repo}/pulls/{number}?access_token=${GITCODE_TOKEN}"
```

### 创建 PR
```bash
POST /repos/{owner}/{repo}/pulls
curl -X POST "https://gitcode.com/api/v5/repos/{owner}/{repo}/pulls?access_token=${GITCODE_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "PR 标题",
    "head": "feature-branch",
    "base": "main",
    "body": "PR 描述"
  }'
```

### 更新 PR
```bash
PATCH /repos/{owner}/{repo}/pulls/{number}
curl -X PATCH "https://gitcode.com/api/v5/repos/{owner}/{repo}/pulls/{number}?access_token=${GITCODE_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{"title": "新标题", "body": "新描述"}'
```

### 合并 PR
```bash
PUT /repos/{owner}/{repo}/pulls/{number}/merge
curl -X PUT "https://gitcode.com/api/v5/repos/{owner}/{repo}/pulls/{number}/merge?access_token=${GITCODE_TOKEN}"
```

**⚠️ openUBMC 项目特殊流程**：

openUBMC 项目**不使用 API 直接合并**，而是通过评论触发机器人合并。

**⚠️ 提交前必须检查 PR 是否可合入**（参见 `openubmc-pr-monitor` skill 中的完整合入流程）：

1. 确认无阻塞标签（`unresolved-reviews`、`stat/needs-squash`、CI 失败等）
2. 确认 `mergeable` 为 true
3. 如有阻塞，先处理再提交

```bash
# 添加 lgtm 标签（需要审核者权限）
POST /repos/{owner}/{repo}/pulls/{number}/comments
curl -X POST "https://gitcode.com/api/v5/repos/{owner}/{repo}/pulls/{number}/comments?access_token=${GITCODE_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{"body": "/lgtm"}'

# 添加 approve 标签（需要审核者权限）
curl -X POST "https://gitcode.com/api/v5/repos/{owner}/{repo}/pulls/{number}/comments?access_token=${GITCODE_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{"body": "/approve"}'
```

**合并条件**：同时有 `lgtm` 和 `approved` 标签后，机器人会自动合并。

**⚠️ 合入后必须确认**：等待 30 秒检查 PR 是否已合入，1 分钟内未合入则评论 `/check-pr` 触发机器人。

**注意**：需要是项目的 reviewer/approver 才能添加这些标签。

### 获取 PR 评论
```bash
# Review comments（代码行评论）
GET /repos/{owner}/{repo}/pulls/{number}/comments
curl -s "https://gitcode.com/api/v5/repos/{owner}/{repo}/pulls/{number}/comments?access_token=${GITCODE_TOKEN}"

# Issue comments（普通评论，CI 结果通常在这里）
GET /repos/{owner}/{repo}/issues/{number}/comments
curl -s "https://gitcode.com/api/v5/repos/{owner}/{repo}/issues/{number}/comments?access_token=${GITCODE_TOKEN}"
```

⚠️ **评论结构注意**：
- Review comments 的**回复**内容在返回的 `reply` 字段中，**不在顶层**
- 获取一条评论及其所有回复时，需遍历列表匹配 `in_reply_to_id`

### 获取 PR Commits
```bash
GET /repos/{owner}/{repo}/pulls/{number}/commits
curl -s "https://gitcode.com/api/v5/repos/{owner}/{repo}/pulls/{number}/commits?access_token=${GITCODE_TOKEN}"
```

### 获取 PR 文件变更
```bash
GET /repos/{owner}/{repo}/pulls/{number}/files
curl -s "https://gitcode.com/api/v5/repos/{owner}/{repo}/pulls/{number}/files?access_token=${GITCODE_TOKEN}"
```

### PR 标签（同 Issue）
```bash
# CI 状态通常在 PR 的 labels 中
curl -s "https://gitcode.com/api/v5/repos/{owner}/{repo}/pulls/{number}?access_token=${GITCODE_TOKEN}" | jq '.labels[].name'
```

---

## 5. PR 审查 API

### 指派审查人
```bash
POST /repos/{owner}/{repo}/pulls/{number}/reviewers
curl -X POST "https://gitcode.com/api/v5/repos/{owner}/{repo}/pulls/{number}/reviewers?access_token=${GITCODE_TOKEN}" \
  -d '{"reviewers": ["username1", "username2"]}'
```

### 获取审查人列表
```bash
GET /repos/{owner}/{repo}/pulls/{number}/reviewers
curl -s "https://gitcode.com/api/v5/repos/{owner}/{repo}/pulls/{number}/reviewers?access_token=${GITCODE_TOKEN}"
```

### 提交审查意见
```bash
POST /repos/{owner}/{repo}/pulls/{number}/reviews
curl -X POST "https://gitcode.com/api/v5/repos/{owner}/{repo}/pulls/{number}/reviews?access_token=${GITCODE_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{"body": "审查意见", "event": "APPROVE"}'  # EVENT: APPROVE, REQUEST_CHANGES, COMMENT
```

### 关闭/解决检视意见
```bash
PUT /repos/{owner}/{repo}/pulls/{number}/comments/{discussion_id}
curl -X PUT "https://gitcode.com/api/v5/repos/{owner}/{repo}/pulls/{number}/comments/{discussion_id}?access_token=${GITCODE_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{"resolved": true}'
```

⚠️ **注意事项**：
- 使用评论返回的 `discussion_id` 字段值（如 `cc7fd351e2e8...`），**不是** `id`
- **必须传 JSON body `{"resolved": true}`**，否则会返回 `PARAMETER_ERROR`
- 如果 discussion 已被归档（Archived），会返回 "Archived note can not be edited"
- API 文档: https://docs.gitcode.com/docs/apis/put-api-v-5-repos-owner-repo-pulls-number-comments-discussions-id

### 编辑 PR 评论
```bash
PATCH /repos/{owner}/{repo}/pulls/comments/{id}
curl -X PATCH "https://gitcode.com/api/v5/repos/{owner}/{repo}/pulls/comments/{id}?access_token=${GITCODE_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{"body": "新的评论内容"}'
```

⚠️ **注意事项**：
- **路径中包含 `pulls/`**：是 `/repos/{owner}/{repo}/pulls/comments/{id}`，**不是** `/repos/{owner}/{repo}/comments/{id}`
- `id` 是评论的数字 ID（从 GET `/repos/{owner}/{repo}/pulls/{number}/comments` 获取）
- 同时适用于 `diff_comment`（代码行评论）和 `pr_comment`（普通 PR 评论）
- 成功返回 204 No Content
- API 文档: https://docs.gitcode.com/docs/apis/patch-api-v-5-repos-owner-repo-pulls-comments-id

### 删除 PR 评论
```bash
DELETE /repos/{owner}/{repo}/pulls/comments/{id}
curl -X DELETE "https://gitcode.com/api/v5/repos/{owner}/{repo}/pulls/comments/{id}?access_token=${GITCODE_TOKEN}"
```

⚠️ 同样注意路径中有 `pulls/`，API 文档: https://docs.gitcode.com/docs/apis/delete-api-v-5-repos-owner-repo-pulls-comments-id

### 回复检视意见
```bash
POST /repos/{owner}/{repo}/pulls/{number}/comments
curl -X POST "https://gitcode.com/api/v5/repos/{owner}/{repo}/pulls/{number}/comments?access_token=${GITCODE_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{"body": "回复内容", "in_reply_to_id": <comment_id>, "path": "<file_path>", "position": <line_number>}'
```

⚠️ **注意事项**：
- 回复检视意见必须使用 `in_reply_to_id` 参数，否则会创建新的 review comment 而非回复
- 不要发到 issue comments（`/repos/{owner}/{repo}/issues/{number}/comments`），那样不会出现在 review 讨论串中

---

## 6. PR 测试 API

### 指派测试人
```bash
POST /repos/{owner}/{repo}/pulls/{number}/testers
curl -X POST "https://gitcode.com/api/v5/repos/{owner}/{repo}/pulls/{number}/testers?access_token=${GITCODE_TOKEN}" \
  -d '{"testers": ["username1"]}'
```

### 获取测试人列表
```bash
GET /repos/{owner}/{repo}/pulls/{number}/testers
curl -s "https://gitcode.com/api/v5/repos/{owner}/{repo}/pulls/{number}/testers?access_token=${GITCODE_TOKEN}"
```

---

## 7. 标签管理 API

### 获取仓库标签列表
```bash
GET /repos/{owner}/{repo}/labels
curl -s "https://gitcode.com/api/v5/repos/{owner}/{repo}/labels?access_token=${GITCODE_TOKEN}"
```

### 创建标签
```bash
POST /repos/{owner}/{repo}/labels
curl -X POST "https://gitcode.com/api/v5/repos/{owner}/{repo}/labels?access_token=${GITCODE_TOKEN}" \
  -d '{"name": "bug", "color": "ff0000"}'
```

---

## 8. Commit API

### 获取 Commit 列表
```bash
GET /repos/{owner}/{repo}/commits
curl -s "https://gitcode.com/api/v5/repos/{owner}/{repo}/commits?access_token=${GITCODE_TOKEN}&sha={branch}"
```

### 获取单个 Commit
```bash
GET /repos/{owner}/{repo}/commits/{sha}
curl -s "https://gitcode.com/api/v5/repos/{owner}/{repo}/commits/{sha}?access_token=${GITCODE_TOKEN}"
```

### 比较 Commits
```bash
GET /repos/{owner}/{repo}/compare/{base}...{head}
curl -s "https://gitcode.com/api/v5/repos/{owner}/{repo}/compare/main...feature?access_token=${GITCODE_TOKEN}"
```

---

## 9. 组织 API

### 获取组织信息
```bash
GET /orgs/{org}
curl -s "https://gitcode.com/api/v5/orgs/{org}?access_token=${GITCODE_TOKEN}"
```

### 获取组织成员
```bash
GET /orgs/{org}/members
curl -s "https://gitcode.com/api/v5/orgs/{org}/members?access_token=${GITCODE_TOKEN}"
```

---

## 常用场景示例

### 检查 PR 状态和 CI
```bash
curl -s "https://gitcode.com/api/v5/repos/{owner}/{repo}/pulls/{number}?access_token=${GITCODE_TOKEN}" | jq '{
  number,
  state,
  title,
  labels: [.labels[].name],
  user: .user.login,
  head_branch: .head.ref,
  base_branch: .base.ref
}'
```

### 获取 CI 错误详情
```bash
curl -s "https://gitcode.com/api/v5/repos/{owner}/{repo}/pulls/{number}/comments?access_token=${GITCODE_TOKEN}&per_page=100" | jq -r '.[] | select(.body | contains("门禁未通过")) | .body'
```

### 筛选自己的 PR
```bash
curl -s "https://gitcode.com/api/v5/repos/{owner}/{repo}/pulls?access_token=${GITCODE_TOKEN}&state=open" | jq '.[] | select(.user.login == "YOUR_USERNAME") | {number, title}'
```

---

## API 文档

- 官方文档: https://docs.gitcode.com/docs/apis/
- Gitee API v5 参考: https://gitee.com/api/v5/swagger (GitCode 兼容)

*最后更新: 2026-03-28*
