# Codex skills 管理库

这个仓库管理**来源、版本、兼容性证据和已审阅的个人 Skill 快照**。本机用户级安装根为 `C:\Users\ROG\.codex\skills` 和 `C:\Users\ROG\.agents\skills`；项目专属技能位于项目的 `.agents\skills`。更新流程始终先检查和审查，绝不自动覆盖本地改写。

## 已验证基线（2026-09-29）

- 27 个用户级 Skill 均包含有效 YAML 前置元数据；19 个与登记来源完整匹配，8 个是已登记的本地维护版本。
- 4 个已知项目级 Skill 已纳入审计，其中 3 个与上游匹配，1 个为项目专用。
- 所有登记来源的固定提交均与当前检出一致；houseCARL 的 8 个 Skill 由其独立官方仓库维护，不在本仓库重复 vendoring。

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

## Office 技能的默认选择

Codex 当前加载了 OpenAI 运行时维护的 `documents`、`presentations`、`spreadsheets` 和 `pdf`（版本 `26.909.12148`）。处理 Word、演示文稿、工作簿或 PDF 时，优先使用这些官方运行时技能；仓库中的 `docx`、`pptx`、`xlsx` 和 `pdf` 快照仅保留作兼容参考，避免两个相似技能同时被当作默认入口。

这些旧快照位于 `archive/office/`，不会由本仓库的安装脚本安装。

`canvas` 仅保留为按需源快照；`json-canvas` 已于 2026-09-10 与其余 14 个可视化 Skill 一起移出全局安装目录，并保存在本地可恢复归档中。

## 安装已审阅的受管技能

```powershell
# 首次安装；已安装同名技能时停止，不会覆盖
pwsh ./scripts/install-managed-skill.ps1 -Skill agents-md-improver

# 审阅差异后，自动保留带时间戳的本地备份，再替换安装
pwsh ./scripts/install-managed-skill.ps1 -Skill ponytail-help -Replace
```

## 当前兼容性边界

- 使用 `agents-md-improver` 审计 Codex 的 `AGENTS.md`；原 `claude-md-improver` 已作为 Claude 迁移参考归档。
- `ponytail-help` 已改为本仓库的 Codex 审计与安装流程；不要使用其中上游版本曾要求的 Claude 插件命令。
- `defuddle`、`graphify`、`mcp-builder` 与 `web-design-guidelines` 已改用 Codex 的原生 URL 读取和可写 worker 表述。

## 项目级技能

- `F:\\ObsidianNotes\\.agents\\skills`：`obsidian-cli`、`obsidian-markdown`、`obsidian-bases`。仅在该笔记库中工作时加载。
- `F:\\codex_project\\skyrim\\重命名和排序mod\\.agents\\skills\\mo2-modlist-sort`：项目级工作流，不作为全局 Skill 安装。

## 用户级安装根

- `C:\\Users\\ROG\\.codex\\skills`：19 个本机管理或兼容迁移的用户 Skill；对应的已审阅快照位于本仓库 `skills/`。
- `C:\\Users\\ROG\\.agents\\skills`：8 个 houseCARL Skill；内容由 `Avick3110/houseCARL` 上游维护，本仓库只记录其来源和固定提交。

来源、固定提交和本地安装位置见 [sources.json](sources.json)。
