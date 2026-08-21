# Codex skills 管理库

这个仓库只管理**来源、版本与兼容性证据**；`C:\Users\ROG\.codex\skills` 是当前的全局安装位置。项目专属技能可以位于项目的 `.agents\skills` 根目录。更新流程始终先检查和审查，绝不自动覆盖已安装技能或本地改动。

## 已验证基线（2026-08-21）

- 36 个已安装技能与 `claude-skills` 上游提交 `fcc69cc9` 的 `SKILL.md` 完全相同。
- `ponytail`、`karpathy-skills` 和 `claude-plugins-official` 已与其登记远程同步。
- 全局安装目录中的 39 个直接技能目录均包含有效 YAML 前置元数据。

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

Codex 当前加载了 OpenAI 运行时维护的 `documents`、`presentations`、`spreadsheets` 和 `pdf`（版本 `26.819.11345`）。处理 Word、演示文稿、工作簿或 PDF 时，优先使用这些官方运行时技能；仓库中的 `docx`、`pptx`、`xlsx` 和 `pdf` 快照仅保留作兼容参考，避免两个相似技能同时被当作默认入口。

这些旧快照位于 `archive/office/`，不会由本仓库的安装脚本安装。

`canvas` 与 `json-canvas` 都使用兼容 Obsidian Canvas 的数据模型；为避免重复常驻，`canvas` 已转为按需技能。需要在 Markdown 中输出围栏式 Canvas JSON 时再执行 `pwsh ./scripts/install-managed-skill.ps1 -Skill canvas`；需要创建或编辑真实 `.canvas` 文件时，使用常驻的 `json-canvas`。

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
- `F:\\codex_project\\skyrim\\重命名和排序mod\\AGENTS.md`：`mo2-modlist-sort` 的项目级工作流入口，不作为全局技能安装。

## 重复根目录的处理

已将 `C:\\Users\\ROG\\.agents\\skills` 可恢复地移动到 `C:\\Users\\ROG\\.agents\\skills-archive-20260821`。迁移前按 `SKILL.md` 内容比对，其中 23 个与全局目录完全相同、12 个存在差异；全局 `C:\\Users\\ROG\\.codex\\skills` 现为唯一的共享用户技能根目录，项目可另设隔离的 `.agents\\skills`。

来源、固定提交和本地安装位置见 [sources.json](sources.json)。
