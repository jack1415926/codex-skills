---
name: windows-proxy-install
description: Diagnose Windows, Clash, GitHub, npm, and Codex skill/plugin/MCP installation failures caused by proxy, HTTPS, SSH, or npm-cache permission problems. Use for connection resets, GitHub 443 errors, EPERM, or proxy setup on Windows.
---

# Windows + Clash 安装与连接排障

Use this skill for a failed install, update, clone, or Codex integration on Windows. Diagnose the actual failing layer first; do not assume a common proxy port or change global settings as a first response.

## Check the active proxy

- Inspect Windows proxy settings and the relevant application's configuration, then test the candidate local port with a TCP connection.
- For Bash commands that contact GitHub or a registry, use process-local proxy variables:

  ```bash
  export https_proxy=http://127.0.0.1:<port> http_proxy=http://127.0.0.1:<port>
  ```

- The Windows `curl` build may ignore those variables. Test it explicitly:

  ```powershell
  curl --proxy http://127.0.0.1:<port> https://github.com
  ```

Do not set a global Git proxy: it can break local and intranet repositories.

## Classify the failure

### `EPERM` inside npm cache

Verify the npm cache path and its ACL. An inaccessible cache on a non-system drive is an ACL issue, not a reason to run `npm cache clean --force`. Request approval before changing permissions, then verify a small temporary write/delete at the affected path.

### GitHub `443`, timeout, reset, or TLS connection failure

First confirm the proxy port with `curl --proxy`, then retry the exact Git/npm/Codex command with process-local proxy variables. Use HTTPS remote URLs.

### `Permission denied (publickey)`

An SSH remote was used. Replace it with `https://github.com/<owner>/<repo>.git`; do not try to make Clash carry SSH unless the user specifically wants SSH configured.

## Codex-specific operations

- For a GitHub-hosted skill, use the normal Codex skill installation workflow or clone over HTTPS after connectivity is verified.
- For plugins, use `codex plugin` commands; for MCP registrations, use `codex mcp` commands instead of editing credential-bearing configuration by hand when the CLI supports the operation.
- Keep proxy changes process-local unless the user explicitly requests persistent configuration.

## Report and stop conditions

State the verified failure class, the tested endpoint/port, and the resulting command exit status. If fixing it requires ACL changes, credential changes, persistent proxy settings, or a destructive cache operation, stop and request approval.
