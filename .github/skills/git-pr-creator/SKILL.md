---
name: git-pr-creator
description: >-
  Create a pull request from the current branch to `main`. Use when the user asks
  to open a PR, create a pull request from the current branch, or publish work
  for review. If the branch name contains a ticket-like prefix such as
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
- creating a PR from `main`

## Workflow

### 1. Detect the current branch

Check the current local branch name first.

If the current branch is `main`, stop immediately and return:

```text
You cannot create a pull request from the main branch with this skill.
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

### 4. Create the PR

Run the helper script:

```powershell
pwsh -NoProfile -File ./.github/skills/git-pr-creator/scripts/create-pr.ps1
```

The script will:

- detect the current branch
- block PR creation from `main`
- keep the remote branch name the same as the local one
- generate a title from the branch name or current changes
- check for duplicate ticket-prefix PRs
- create the PR against `main` by default

## Hard rules

- Never create a PR from `main` with this skill.
- If a ticket-like prefix exists, preserve it as `[PREFIX]: ...` in the title.
- If the prefix already exists in an open PR, ask the user before continuing.
- Do not invent a misleading PR title; base it on the branch name and real changes.
- Return the exact GitHub result after creation.
