---
name: defuddle
description: Extract clean markdown content from ordinary web pages with Defuddle CLI, removing clutter and navigation. Use for articles, documentation, blog posts, and other HTML pages; use the session's native URL reader for URLs that already serve Markdown.
---

# Defuddle

Use Defuddle CLI to extract clean readable content from ordinary HTML pages. It removes navigation, ads, and clutter. For a URL ending in `.md`, use the session's native URL reader instead; the source is already Markdown.

If not installed: `npm install -g defuddle`

## Usage

Always use `--md` for markdown output:

```bash
defuddle parse <url> --md
```

Save to file:

```bash
defuddle parse <url> --md -o content.md
```

Extract specific metadata:

```bash
defuddle parse <url> -p title
defuddle parse <url> -p description
defuddle parse <url> -p domain
```

## Output formats

| Flag | Format |
|------|--------|
| `--md` | Markdown (default choice) |
| `--json` | JSON with both HTML and markdown |
| (none) | HTML |
| `-p <name>` | Specific metadata property |
