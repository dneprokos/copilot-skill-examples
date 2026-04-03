# Copilot Skill Examples

[![License](https://img.shields.io/github/license/dneprokos/copilot-skill-examples?style=flat-square)](LICENSE)
[![Stars](https://img.shields.io/github/stars/dneprokos/copilot-skill-examples?style=flat-square)](https://github.com/dneprokos/copilot-skill-examples/stargazers)

Example GitHub Copilot skills you can copy into `.github/skills/` and adapt for your own repositories. This repo is focused on reusable patterns, supporting templates, and small helper scripts rather than a published package or app.

![Reusable Copilot skills: modular SKILL.md workflows you copy into .github/skills](docs/assets/skills-hero.svg)

## Overview

Each skill in this repository targets a specific workflow:

| Skill                                                                        | Purpose                                                                            | Contents                                    |
| ---------------------------------------------------------------------------- | ---------------------------------------------------------------------------------- | ------------------------------------------- |
| [`api-test-scenario-generator`](.github/skills/api-test-scenario-generator/) | Generates structured REST API test scenarios with boundary and validation coverage | `SKILL.md`, templates, config, script       |
| [`rest-api-design`](.github/skills/rest-api-design/)                         | Designs and reviews REST APIs: paths, HTTP semantics, pagination, versioning, errors, OpenAPI | `SKILL.md`, README, `references/`           |
| [`git-branch-creator`](.github/skills/git-branch-creator/)                   | Creates a new Git branch after checking that `main` is ready and up to date        | `SKILL.md`, README, script                  |
| [`git-commit-creator`](.github/skills/git-commit-creator/)                   | Creates a commit on the current branch from collected git changes                  | `SKILL.md`, README, references, script      |
| [`git-pr-creator`](.github/skills/git-pr-creator/)                           | Creates a pull request from the current branch and handles ticket-style PR titles  | `SKILL.md`, README, references, script      |
| [`git-push-creator`](.github/skills/git-push-creator/)                       | Pushes the current local branch to `origin` using the same branch name             | `SKILL.md`, README, script                  |
| [`git-workflow-orchestrator`](.github/skills/git-workflow-orchestrator/)     | Phased branch, commit, push, and PR with per-phase status and PR URL               | `SKILL.md`, script                          |
| [`meeting-notes-summarizer`](.github/skills/meeting-notes-summarizer/)       | Turns transcripts or messy notes into a Teams/email-ready structured recap       | `SKILL.md`, references                      |
| [`readme-polisher`](.github/skills/readme-polisher/)                         | Helps draft or improve a repository `README.md` using real project evidence        | `SKILL.md`, references, assets, scan script |
| [`token-usage-reporting`](.github/skills/token-usage-reporting/)             | Produces day/week/month token usage reports in table format                        | `SKILL.md`, config, template, script        |
| [`jira-mcp-assistant`](.github/skills/jira-mcp-assistant/)                   | Jira Cloud JQL and backlog-style lists via Atlassian MCP (read-first; extend for writes) | `SKILL.md`, `references/`              |
| [`skill-creator`](.github/skills/skill-creator/)                             | Create, test, and iteratively improve agent skills (from [anthropics/skills](https://github.com/anthropics/skills); see [skills.sh](https://skills.sh/anthropics/skills/skill-creator)) | `SKILL.md`, `agents/`, `scripts/`, `eval-viewer/`, `assets/`, `references/` |

## Getting Started

1. Clone this repository and open it in VS Code.
2. Browse the skill folders under `.github/skills/`.
3. Copy the skill you want into your own project's `.github/skills/` directory.
4. Prompt Copilot with a request that matches the skill's domain.

### Clone locally

```bash
git clone https://github.com/dneprokos/copilot-skill-examples.git
cd copilot-skill-examples
```

### Example prompts

```text
Improve this repository README using the readme-polisher skill.
Generate API test scenarios for POST /api/users.
Review these REST endpoints using the rest-api-design skill (paste OpenAPI or routes).
Create a new branch named feature/add-login-flow.
Commit the current branch using the git-commit-creator skill.
Push the current branch using the git-push-creator skill.
Create a pull request from this branch using the git-pr-creator skill.
Run the git-workflow-orchestrator to ship my branch (branch, commit, push, PR).
Create a token usage report for this week.
Summarize these meeting notes using the meeting-notes-summarizer skill (paste notes below).
List Jira backlog issues for project SCRUM using the jira-mcp-assistant skill (Atlassian MCP must be connected).
Help me draft and evaluate a new agent skill using the skill-creator skill.
```

> Exact invocation style can vary by Copilot surface, but clear natural-language prompts work well.

This repository also mirrors the same skill folders under [`.cursor/skills/`](.cursor/skills/) for Cursor Agent Skills; copy from either location depending on your editor.

**`skill-creator` (Anthropic):** use [`.github/skills/skill-creator/`](.github/skills/skill-creator/) for Copilot-style layouts and [`.cursor/skills/skill-creator/`](.cursor/skills/skill-creator/) for Cursor; the contents are the same—keep both in sync when you update.

## Jira skills and Atlassian MCP

The [`jira-mcp-assistant`](.github/skills/jira-mcp-assistant/) skill is a **read-first** workflow: resolve `cloudId`, run JQL through the MCP (e.g. `searchJiraIssuesUsingJql`), paginate, and format results. It does not replace MCP setup—you still connect Cursor (or another client) to the [Atlassian Rovo MCP Server](https://support.atlassian.com/rovo/docs/setting-up-ides/) and authenticate (OAuth or API token if your org allows it).

**How to extend without renaming the skill**

1. **Keep the umbrella id** `jira-mcp-assistant` so existing prompts keep working.
2. **Widen the YAML `description`** in `SKILL.md` with new trigger phrases (e.g. “create Jira issue”, “dashboard filter”, “saved filter”) so the agent selects this skill for those requests.
3. **Add sections** to `SKILL.md` for new flows (create issue, transition, comments, dashboard or filter metadata), each with: required inputs, which MCP tool to call, pagination or confirmation rules, and output shape.
4. **Split reference files** under `references/` (e.g. `references/dashboard-filters.md`) when `SKILL.md` grows long; link them from the main instructions.
5. **Add a separate skill only** for a large or high-risk workflow (for example release approvals) that should not share triggers with everyday queries.

After extending, copy the updated folder into your project’s `.github/skills/` or `.cursor/skills/` and re-test MCP tool names against your client’s live schema.

## Typical Skill Layout

```text
.github/skills/{skill-name}/
├── SKILL.md
├── README.md
├── config/        # optional configuration
├── scripts/       # optional helper utilities
├── templates/     # optional output templates
└── references/    # optional guidance material
```

## Repository Map

```text
copilot-skill-examples/
├── docs/
│   └── assets/
│       └── skills-hero.svg
├── .github/
│   └── skills/
│       ├── api-test-scenario-generator/
│       ├── rest-api-design/
│       ├── git-branch-creator/
│       ├── git-commit-creator/
│       ├── git-pr-creator/
│       ├── git-push-creator/
│       ├── git-workflow-orchestrator/
│       ├── meeting-notes-summarizer/
│       ├── readme-polisher/
│       ├── token-usage-reporting/
│       ├── jira-mcp-assistant/
│       └── skill-creator/
├── .cursor/
│   └── skills/    # Cursor Agent copy of the same skills (keep in sync when contributing)
├── README.md
└── LICENSE
```

## Contributing

Contributions are welcome. If you add a new skill, keep it focused, document it clearly, and include any supporting templates or scripts needed to make the workflow reproducible.

## License

Released under the MIT License. See [`LICENSE`](LICENSE) for details.
