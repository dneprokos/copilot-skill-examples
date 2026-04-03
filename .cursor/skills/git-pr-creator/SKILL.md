---
name: git-pr-creator
description: >-
  Create a pull request from the current branch to the core branch (`main` or
  `develop`, whichever exists on `origin`). Use when the user asks to open a
  PR, create a pull request from the current branch, or publish work for
  review. If the branch name contains a ticket-like prefix such as
  `TST-2056_*` or `2056_*`, start the PR title with that prefix in square
  brackets. If a PR with the same prefix already exists, ask whether to continue.
argument-hint: "optional PR context or base branch"
---

# Git PR Creator

Create a pull request from the current branch safely.

## When this skill fits

Use it for requests like:

- "create a pull request from this branch"
- "open a PR for the current branch"
- "publish this branch for review"

Do **not** use it for:

- force pushing
- merging PRs
- reviewing PR comments
- creating a PR from the resolved core branch (`main` or `develop`)

## Workflow

### 1. Detect the current branch

Check the current local branch name first.

Resolve the core base branch first (`main` preferred, then `develop`).

If the current branch matches the resolved base branch, stop immediately and return:

```text
You cannot create a pull request from the <base-branch> branch with this skill.
```

### 2. Build the PR title

If the branch name starts with a ticket-like prefix followed by `_` or `-`, use that prefix in square brackets at the start of the PR title.

Examples:

```text
TST-2056_testBranch -> [TST-2056]: added new git related skills
2056_testBranch     -> [2056]: added new git related skills
```

Rules:

- If the postfix branch name is already meaningful, convert it into readable text.
- If the postfix is vague like `testBranch`, `work`, or `changes`, summarize the branch from commit messages and changed files.
- Decide whether the branch name is proper; do not blindly trust it.

### 3. Check for an existing PR with the same prefix

If a ticket-like prefix was found, check open PRs for the same prefix.

If one already exists, ask the user:

```text
A pull request with prefix [TST-2056] already exists. Do you want to create an additional PR?
```

Offer exactly these options:

- `Yes` — continue and create another PR
- `No` — stop the skill

If the answer is `No`, stop immediately.

### 4. GitHub token precondition (non-DryRun)

Before running the helper script **without** `-DryRun`, verify a GitHub token is available from this order:

1. Environment variable **`GITHUB_TOKEN`** or **`GH_TOKEN`** (non-empty),
2. SecretManagement secret **`GitHubToken`** stored in the SecretManagement/SecretStore vault,
3. If secret is missing and session is interactive: prompt user for token (masked) and save it as **`GitHubToken`**, then use it immediately,
4. Legacy fallback: **`github-pr.local.json`** at the **repository root** with string property **`github_token`**,
5. Legacy fallback: **`.github/skills/git-pr-creator/config/github-pr.local.json`** with the same property.

If SecretManagement is not installed, use the setup skill:

```powershell
pwsh -NoProfile -File ./.github/skills/windows-secretmanagement-setup/scripts/install-secretmanagement.ps1
```

If no source provides a token for a real PR run, **stop** and tell the user to follow [README.md](README.md). **Never** commit `github-pr.local.json` or paste tokens into chat.

`-DryRun` does **not** require a token (local preview only). Duplicate-prefix checks during DryRun may still need an authenticated `gh` if they call the API.

### 5. Ensure GitHub CLI is ready

Ensure `gh` is installed. If `gh` is missing, the script can ask for approval before auto-installing (`winget`, `choco`, or `scoop`); pre-approve with `-ApproveInstall`.

When a token is set (step 4), the script sets **`GH_TOKEN`** for `gh` and skips interactive `gh auth login`. If `GH_TOKEN` is **not** set (DryRun-only paths or edge cases), the script may still prompt for `gh auth login --web` unless pre-approved with `-ApproveAuth`.

```powershell
pwsh -NoProfile -File ./.github/skills/git-pr-creator/scripts/create-pr.ps1 -ApproveInstall -ApproveAuth
```

If installation fails or `gh` cannot authenticate with the token, stop and return the exact error.

### 6. Create the PR

Run the helper script:

```powershell
pwsh -NoProfile -File ./.github/skills/git-pr-creator/scripts/create-pr.ps1
```

The script will:

- detect the current branch
- resolve the core base branch (`main` then `develop`) when `-BaseBranch` is omitted
- block PR creation from that resolved base branch
- require a GitHub token for non-DryRun runs (env, SecretManagement `GitHubToken`, interactive prompt-and-save, then legacy JSON fallback)
- ask approval before auto-installing `gh` when needed
- keep the remote branch name the same as the local one
- generate a title from the branch name or current changes
- build the PR description from **commit subjects** on this branch versus the base (oldest first), not generic skill boilerplate
- check for duplicate ticket-prefix PRs
- create the PR against the resolved core base branch by default

## Hard rules

- Never create a PR from the resolved core branch (`main` or `develop`) with this skill.
- For non-DryRun runs, never proceed without a configured token (`GITHUB_TOKEN`, `GH_TOKEN`, SecretManagement `GitHubToken`, or legacy fallback JSON paths).
- Never commit `github-pr.local.json` or expose tokens in logs or commits.
- If a ticket-like prefix exists, preserve it as `[PREFIX]: ...` in the title.
- If the prefix already exists in an open PR, ask the user before continuing.
- Do not invent a misleading PR title; base it on the branch name and real changes.
- Never use force push or rename the branch for PR creation.
- Return the exact GitHub result after creation.
- Base the PR body on real commits (`git log` vs base); do not replace that with invented narrative unless the user asks.
