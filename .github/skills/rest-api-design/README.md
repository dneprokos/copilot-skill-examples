# REST API Design

A skill for **designing and reviewing** REST-style HTTP JSON APIs: resource paths, HTTP methods, status codes, pagination, versioning, request/response and error shapes, and OpenAPI/Swagger documentation.

## Sources

- Principles aligned with the public **[rest-api](https://skills.sh/claude-dev-suite/claude-dev-suite/rest-api)** skill from [claude-dev-suite](https://github.com/claude-dev-suite/claude-dev-suite) on [skills.sh](https://skills.sh/).
- Additional conventions (pagination parameters, URL versioning, Swagger checklist, error examples) were synthesized from common REST guideline material and internal team PDFs; **adapt** naming and limits to your org.

To install the upstream skill package directly:

```bash
npx skills add https://github.com/claude-dev-suite/claude-dev-suite --skill rest-api
```

This repository’s copy is **standalone Markdown** (no MCP required).

## Layout

| File | Role |
| ---- | ---- |
| `SKILL.md` | Agent instructions, core tables, review workflow |
| `references/detail.md` | Anti-patterns, troubleshooting, production and OpenAPI checklists |

## Suggested prompt

```text
Review my REST API endpoints for REST best practices using the rest-api-design skill (paste OpenAPI or route list).
```

## Copy into your project

Place the folder under `.github/skills/rest-api-design/` (Copilot) and/or `.cursor/skills/rest-api-design/` (Cursor), matching the rest of this repo’s mirrored skills.
