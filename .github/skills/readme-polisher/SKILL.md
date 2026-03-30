---
name: readme-polisher
description: >-
  Create or improve a repository README using verified project details. Use this
  skill when the user asks to polish a repo, add badges, explain setup, improve
  first impressions, or generate a concise project overview with optional
  diagrams. Prefer accurate, evidence-based documentation and skip anything you
  cannot confirm from the codebase.
argument-hint: "project path or repo context"
---

# README Polisher

Build a README that is clear, practical, and tailored to the repository.

## When this skill fits

Use it for requests like:

- "improve my README"
- "make this repo look more professional"
- "add badges and quick start steps"
- "generate a README for this project"

Do **not** use it for:

- API reference generation
- changelog writing
- release notes
- CI/CD setup

## Workflow

### 1. Inspect the project first

Gather facts from files such as `README.md`, `package.json`, `pyproject.toml`,
`Cargo.toml`, `go.mod`, `.github/workflows/*`, and license files.

If shell access is available, run:

```powershell
pwsh -NoProfile -File ./.github/skills/readme-polisher/scripts/scan_project.ps1 <project-path>
```

Use the scan results as a starting point, then sanity-check important details.

### 2. Load the writing guidance

Read `references/readme-guidelines.md` before drafting. It covers section order,
tone, proportionality, and common documentation mistakes.

### 3. Start from the template

Use `assets/readme-template.md` as a scaffold. Replace every placeholder with
real information. Remove any section that does not help this project.

### 4. Add only verifiable badges

Check `assets/badges.json` for badge patterns. Include badges only when the
underlying metadata exists. No fake versions, broken build badges, or guessed
social links.

### 5. Keep it proportional

- Small utility: short overview + usage is enough
- Library: install, example, and API entry points
- App/service: setup, configuration, and run steps
- Monorepo: explain packages and add a diagram only if it helps

### 6. Validate before finishing

Confirm that:

- commands are real
- no placeholders remain
- section titles are relevant
- links resolve or are clearly marked as local
- tone matches the project rather than sounding generic

### 7. Optional diagram

If the repo has multiple moving parts, adapt a Mermaid starter from
`assets/diagram-ideas.md`. Skip diagrams for simple repos.

## Hard rules

- Never invent package names, releases, CI status, or contact links
- Prefer concise and useful wording over hype
- Preserve important existing instructions if the current README already has them
- If details are missing, say less instead of guessing
