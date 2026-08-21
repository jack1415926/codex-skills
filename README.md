# Codex skills 管理库

这个仓库只管理**来源、版本与兼容性证据**；`C:\Users\ROG\.codex\skills` 是当前的全局安装位置。更新流程始终先检查和审查，绝不自动覆盖已安装技能或本地改动。

## 已验证基线（2026-08-21）

- 36 个已安装技能与 `claude-skills` 上游提交 `fcc69cc9` 的 `SKILL.md` 完全相同。
- `ponytail`、`karpathy-skills` 和 `claude-plugins-official` 已与其登记远程同步。
- 全局安装目录中的 48 个直接技能目录均包含有效 YAML 前置元数据。

这些是静态和来源验证，不等同于每一种外部工具、账户或 API 都已运行成功。

## 日常操作

```powershell
# 离线：检查来源、安装副本和已知宿主兼容性标记
pwsh ./scripts/audit-skills.ps1

# 联网：先 fetch 各来源，再检查是否有待审查的上游提交
pwsh ./scripts/audit-skills.ps1 -Fetch -Proxy http://127.0.0.1:7890
```

审计脚本不会修改已安装技能。若发现更新，先用 `git log HEAD..@{u}` 和 `git diff` 审查对应技能，再按技能逐项移植到 Codex；带有 Claude 专属工具、命令或路径的技能不得直接覆盖。

```powershell
# 将一个明确选择的上游技能复制到带时间戳的工作区暂存区，供 diff 审查
pwsh ./scripts/stage-update.ps1 -Source claude-skills -Skill graphviz
```

暂存脚本同样不会安装或覆盖全局技能。确认差异兼容 Codex 后，才应请求执行针对该技能的安装更新。

## 当前兼容性边界

- `claude-md-improver` 是针对 `CLAUDE.md` 的 Claude 工作流，需改写为 `AGENTS.md` 工作流后才可作为 Codex 项目规范技能使用。
- `ponytail-help` 的更新说明是 Claude 插件命令；其核心工作流可加载，但更新必须走本仓库的审计流程。
- `qwen-mm-plugins-api` 需要它描述的 Qwen MCP 服务实际可用；仅有技能文件不代表该服务已连接。
- `graphify`、`defuddle`、`web-design-guidelines` 等含旧宿主工具名；使用时必须映射到本会话可用的浏览、命令和协作能力。

来源、固定提交和本地安装位置见 [sources.json](sources.json)。
