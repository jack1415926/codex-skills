# Codex Skills 维护规则

本仓库是本机 Codex Skills 的唯一来源、版本和兼容性维护库。全局安装目录为 `C:\Users\ROG\.codex\skills`；已知项目级 Skills 记录在 `sources.json` 的 `project_bindings` 中。

## 检查

- 先读取 `sources.json`，再运行 `scripts/audit-skills.ps1`。
- 离线审计：`& 'C:\Program Files\PowerShell\7\pwsh.exe' -NoLogo -NoProfile -ExecutionPolicy Bypass -File '.\scripts\audit-skills.ps1'`。
- 联网上游审计：在上述命令后添加 `-Fetch -Proxy 'http://127.0.0.1:7890'`。
- 必须检查退出码。审计应覆盖每个直接安装的 Skill、登记的本地改写及项目绑定；不得把仓库同步等同于安装副本已更新。

## 更新

- 对落后的来源先查看 `git log HEAD..@{u}` 和相关目录的 `git diff`，确认 Codex 兼容性后再更新。
- 比较整个 Skill 目录，保留本地新增文件和 `agents/openai.yaml` 调用策略。
- 覆盖安装前创建可恢复备份；不要修改归档内容或用户无关改动。
- 插件、MCP、Skill 文件和运行时可用性分别验证。配置或缓存存在不等于已经启用或可调用。
- 常规维护只保留本地修改；除非用户明确要求，不提交、不推送，也不安装可选插件或注册新的 MCP 服务。

## 验证

- 更新后重新运行审计，要求来源覆盖与项目绑定均无未解释问题，退出码为 0。
- 解析修改过的 JSON/TOML，并针对伴随 CLI 运行版本或诊断命令。
- 报告已验证事实、保留的本地差异、未能执行的检查，以及是否需要重启或新会话。
