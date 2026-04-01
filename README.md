# Copilot Skill Examples

[![License](https://img.shields.io/github/license/dneprokos/copilot-skill-examples?style=flat-square)](LICENSE)
[![Stars](https://img.shields.io/github/stars/dneprokos/copilot-skill-examples?style=flat-square)](https://github.com/dneprokos/copilot-skill-examples/stargazers)

Example GitHub Copilot skills you can copy into `.github/skills/` and adapt for your own repositories. This repo is focused on reusable patterns, supporting templates, and small helper scripts rather than a published package or app.

## Overview

Each skill in this repository targets a specific workflow:

| Skill                                                                        | Purpose                                                                            | Contents                                    |
| ---------------------------------------------------------------------------- | ---------------------------------------------------------------------------------- | ------------------------------------------- |
| [`api-test-scenario-generator`](.github/skills/api-test-scenario-generator/) | Generates structured REST API test scenarios with boundary and validation coverage | `SKILL.md`, templates, config, script       |
| [`git-branch-creator`](.github/skills/git-branch-creator/)                   | Creates a new Git branch after checking that `main` is ready and up to date        | `SKILL.md`, README, script                  |
| [`git-commit-creator`](.github/skills/git-commit-creator/)                   | Creates a commit on the current branch from collected git changes                  | `SKILL.md`, README, references, script      |
| [`git-pr-creator`](.github/skills/git-pr-creator/)                           | Creates a pull request from the current branch and handles ticket-style PR titles  | `SKILL.md`, README, references, script      |
| [`git-push-creator`](.github/skills/git-push-creator/)                       | Pushes the current local branch to `origin` using the same branch name             | `SKILL.md`, README, script                  |
| [`git-workflow-orchestrator`](.github/skills/git-workflow-orchestrator/)     | Phased branch, commit, push, and PR with per-phase status and PR URL               | `SKILL.md`, script                          |
| [`meeting-notes-summarizer`](.github/skills/meeting-notes-summarizer/)       | Turns transcripts or messy notes into a Teams/email-ready structured recap       | `SKILL.md`, references                      |
| [`readme-polisher`](.github/skills/readme-polisher/)                         | Helps draft or improve a repository `README.md` using real project evidence        | `SKILL.md`, references, assets, scan script |
| [`token-usage-reporting`](.github/skills/token-usage-reporting/)             | Produces day/week/month token usage reports in table format                        | `SKILL.md`, config, template, script        |

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
Create a new branch named feature/add-login-flow.
Commit the current branch using the git-commit-creator skill.
Push the current branch using the git-push-creator skill.
Create a pull request from this branch using the git-pr-creator skill.
Run the git-workflow-orchestrator to ship my branch (branch, commit, push, PR).
Create a token usage report for this week.
Summarize these meeting notes using the meeting-notes-summarizer skill (paste notes below).
```

> Exact invocation style can vary by Copilot surface, but clear natural-language prompts work well.

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
├── .github/
│   └── skills/
│       ├── api-test-scenario-generator/
│       ├── git-branch-creator/
│       ├── git-commit-creator/
│       ├── git-pr-creator/
│       ├── git-push-creator/
│       ├── git-workflow-orchestrator/
│       ├── meeting-notes-summarizer/
│       ├── readme-polisher/
│       └── token-usage-reporting/
├── README.md
└── LICENSE
```

## Contributing

Contributions are welcome. If you add a new skill, keep it focused, document it clearly, and include any supporting templates or scripts needed to make the workflow reproducible.

## License

Released under the MIT License. See [`LICENSE`](LICENSE) for details.
