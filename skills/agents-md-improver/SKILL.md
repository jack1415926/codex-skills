---
name: agents-md-improver
description: Audit and improve AGENTS.md files for Codex projects. Use when the user asks to review, update, shorten, or standardize AGENTS.md project instructions; report findings before changing files.
---

# AGENTS.md Improver

Audit a project's `AGENTS.md` instructions for Codex. Start read-only and present a short, evidence-backed report. Edit only the files the user approves.

## Discover and assess

- Find `AGENTS.md` files with `rg --files -g AGENTS.md` and include applicable parent directories.
- Read each relevant file completely. Do not infer instructions from its filename or location.
- Assess whether it contains project-specific commands, real environment constraints, safety boundaries, and information that changes an agent's decisions.
- Flag stale commands, duplicated instructions, conflicting rules, secrets, and generic advice that duplicates Codex's built-in behavior.

## Report before editing

For each file, identify verified findings with file evidence and propose a minimal patch. Preserve useful project conventions, public interfaces, and user-owned instructions. Do not invent tooling, paths, or workflows.

When editing is approved, change only the selected files and run the listed relevant checks. Summarize exactly what changed and what remains uncertain.
