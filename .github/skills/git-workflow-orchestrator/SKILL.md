---
name: git-workflow-orchestrator
description: >-
  Run a phased git workflow: create branch (optional), commit, push, and open a
  GitHub pull request. Reports success or failure per phase and surfaces the PR
  URL when the final phase succeeds. Use when the user wants to ship a feature
  branch end-to-end or wants a single scripted pipeline with phase status.
argument-hint: "branch name, commit message, or 'use orchestrator script'"
---

# Git Workflow Orchestrator

Coordinate **git-branch-creator**, **git-commit-creator**, **git-push-creator**, and **git-pr-creator** as **sequential phases**. After the last phase, return the **pull request URL** when available.

## When this skill fits

Use it for requests like:

- "run the full ship workflow: branch, commit, push, PR"
- "orchestrate git phases and tell me if each step succeeded"
- "create a branch, commit my changes, push, and open a PR"

Do **not** use it for:

- rewriting history, force push, or merge (use explicit user request outside these skills)
- operations on `main` as the branch to push (push-creator blocks `main`)

## GitHub token (non-DryRun)

Opening a PR needs a GitHub token with the **same resolution** as **git-pr-creator**: `GITHUB_TOKEN` or `GH_TOKEN`, then **repo-root** `github-pr.local.json` (preferred for Copilot + Cursor skill layouts), then legacy `.github/skills/git-pr-creator/config/github-pr.local.json`. Details: [git-pr-creator README](../git-pr-creator/README.md).

- **Script-driven:** `run-git-ship-workflow.ps1` checks the token **before** Phase 1 when `-DryRun` is not set, then sets `GH_TOKEN` for subprocesses.

- **Agent-driven:** Confirm a token is configured before Phase 4 (or at workflow start); if missing, stop and point to the git-pr-creator README.

## Two ways to run

### A. Agent-driven (interactive commit)

Run each underlying skill **in order**. After every phase, state **SUCCESS** or **FAILED** and paste relevant script output. **Stop** on first failure.

1. **Phase 1 — Branch** — Follow **git-branch-creator** (staging question N/A; use its script with the requested branch name).  
   - **Success:** `create-branch.ps1` exits 0, or user is already on the intended branch and you document **SKIPPED** with reason.  
   - **Skip:** If the user explicitly says they are already on the correct branch and must not create a new one, mark Phase 1 **SKIPPED**.

2. **Phase 2 — Commit** — Follow **git-commit-creator** (staging prompt, preview, proposed message **OK / Not OK**, then commit).  
   - **Success:** commit completes and working tree has no unintended uncommitted requirement for push (report `git status --short` if ambiguous).  
   - Do **not** use the orchestrator script for this path; preserve message approval.

3. **Phase 3 — Push** — Follow **git-push-creator** (`push-branch.ps1`).  
   - **Success:** exit code 0; capture **exact** git output.

4. **Phase 4 — PR** — Follow **git-pr-creator** (`create-pr.ps1`).  
   - **Success:** exit code 0; capture **exact** output including the **PR URL** (usually printed by `gh pr create`).

### B. Script-driven (non-interactive commit)

When the user supplies a **final commit message** and wants one command, run:

```powershell
pwsh -NoProfile -File ./.github/skills/git-workflow-orchestrator/scripts/run-git-ship-workflow.ps1 `
  -BranchName "<name>" `
  -CommitMessage "<message>" `
  [-SkipBranch] `
  [-BaseBranch main] `
  [-PrBase main] `
  [-ApproveInstall] [-ApproveAuth] `
  [-AllowDuplicatePrefix] `
  [-DryRun]
```

- **`-CommitMessage`** is required (stages all changes and commits in one step).  
- **`-SkipBranch`** omits Phase 1 (use when already on the target branch).  
- Forward **`-ApproveInstall`** / **`-ApproveAuth`** for headless `gh` setup when needed.

Phase banners and subprocess output use the host stream so they stay visible when the script is invoked from tools that assign function output. On success, the script also emits **`PR_URL: <url>`** on the success stream for redirection or piping.

Interpret the script’s **phase lines** and final **`PR_URL:`** line for the user.

## Phase summary template (agent-driven)

After all phases, respond with a compact table:

```text
| Phase | Name   | Status   | Notes |
| ----- | ------ | -------- | ----- |
| 1     | Branch | SUCCESS  | ...   |
| 2     | Commit | SUCCESS  | ...   |
| 3     | Push   | SUCCESS  | ...   |
| 4     | PR     | SUCCESS  | ...   |

PR: <paste URL verbatim from gh output>
```

Use **FAILED** and stop populating later phases if a step errors. Include a short **Notes** reason on failure.

## Hard rules

- Use existing scripts under `.github/skills/*/scripts/`; do not reimplement git operations in the orchestrator narrative.
- Treat **exit code 0** as phase success for scripted steps; non-zero means **FAILED**.
- Return the **PR link exactly** as printed; do not guess URLs.
- Never push from `main` via this workflow (push-creator will refuse; report FAILED if attempted).
