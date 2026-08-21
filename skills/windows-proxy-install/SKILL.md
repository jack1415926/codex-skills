---
name: windows-proxy-install
description: Diagnose and fix Windows + proxy failures when installing Claude Code skills via npx or git. Use when the user encounters EPERM npm cache errors, git Connection reset, Failed to connect to github.com port 443, SSH Permission denied during plugin install, or any proxy-related failure behind Clash/V2Ray. Also trigger on npm cache permission issues on non-system drives, or when the user asks how to install skills behind a proxy.
---

# Windows + 代理环境 Skill 安装排障

Three root causes cover almost all installation failures on Windows behind a proxy.

## 诊断决策树

```
npx skills add 报错 → 看错误类型
  ├── EPERM: open 'npm_cache\_cacache\tmp\***' → 问题 1
  ├── Failed to connect to github.com port 443 → 问题 2
  ├── Connection reset / Recv failure → 问题 2
  ├── Permission denied (publickey) → 问题 3
  └── Device or resource busy (删除时) → 已知无害
```

---

## 问题 1: npm 缓存权限不足 (EPERM)

**症状:**
```
npm error code EPERM
npm error path F:\Node_js\npm_cache\_cacache\tmp\***
npm error EPERM: operation not permitted, open '...'
```

**根因:** Node.js 装在非系统盘，`_cacache` 目录只有 Administrators 有写权限。

**验证:**
```bash
powershell -Command "Get-Acl '<npm缓存路径>\_cacache' | Format-List"
# Users 只有 ReadAndExecute → 确认是权限问题
```

**修复 (管理员 PowerShell):**
```powershell
icacls "F:\Node_js\npm_cache" /grant "ROG:(OI)(CI)M" /T
```
`(OI)(CI)M` = Object Inherit + Container Inherit + Modify (read+write+delete).

**验证修复:**
```bash
echo "test" > "F:\Node_js\npm_cache\_cacache\tmp\test-permission" && rm "F:\Node_js\npm_cache\_cacache\tmp\test-permission" && echo "OK"
```

---

## 问题 2: Git 不从代理继承

**症状:** npm 正常但 `npx skills add` 内部 git clone 报:
```
fatal: unable to access 'https://github.com/...': Failed to connect to github.com port 443
或: Recv failure: Connection was reset
```

**根因:** `npx skills add` 调 git clone 时，git 只认环境变量 `http_proxy`/`https_proxy`，不认 `git -c http.proxy=...` 参数，也不读 Git 全局配置。

**定位 Clash 端口:**
```bash
for port in 7890 7891 1080 10809; do
  curl -s --max-time 2 -o /dev/null -w "Port $port: %{http_code}\n" \
    https://github.com --proxy http://127.0.0.1:$port
done
# 返回 200 的就是正确端口
```

**修复——安装前设环境变量:**
```bash
export https_proxy=http://127.0.0.1:7890
export http_proxy=http://127.0.0.1:7890
# 然后再执行 npx skills add
npx skills add <repo>
```

> 如果 curl 检查端口 200 但 git clone 仍超时，用 `export` + `env` 方式而非 `-c` 参数。Git for Windows 某些版本 `-c` 参数在子进程中有 bug。

---

## 问题 3: SSH 被代理阻断

**症状:**
```
git@github.com: Permission denied (publickey)
fatal: Could not read from remote repository
```

**根因:** `claude plugins marketplace add` 默认 `git@github.com:user/repo.git` (SSH)，Clash 不转发 SSH 协议。

**修复方案 (选一):**

A) Git 全局强制 HTTPS:
```bash
git config --global url."https://github.com/".insteadOf git@github.com:
```

B) 每次 clone 手动换 HTTPS:
```bash
git clone https://github.com/user/repo.git
```

---

## 安装 Skill 的正确优先级

| 优先级 | 方法 | 前提条件 |
|---|---|---|
| 1 | `export https_proxy=... && npx skills add <repo>` | npm 权限 OK + 代理 env var |
| 2 | git clone + 运行 install.sh | Git 代理 OK |
| 3 | `claude plugin marketplace add` + `plugin install` | SSH 密钥 或 Git HTTPS 映射 |

---

## 补充

- **目录被占用:** skill 安装后如被 Claude Code 进程加载，`rm -rf` 报 `Device or resource busy` 是正常现象。`npx skills add` 可直接覆盖安装，无需手动删除。
- **npm cache clean --force:** 遇到 EPERM 时这个命令本身也会报错（因为同样无法写入），权限问题解决后缓存自然可用，不需要单独清理。
- **全局 Git 代理慎配:** `git config --global http.proxy` 会让所有仓库走代理（包括本地/内网），建议只配 GitHub 或每次 `export`。
