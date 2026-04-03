---
name: git-push-creator
description: >-
  Push the current local branch to `origin` using the same branch name on the
  remote. Use when the user asks to push the current branch or publish local
  commits. If the current branch is the resolved core branch (`main` or
  `develop`), abort and return a safety message.
argument-hint: "optional push context"
---

# Git Push Creator

Push the current branch to `origin` safely.

## When this skill fits

Use it for requests like:

- "push my current branch"
- "publish this branch to origin"
- "push local commits to remote"

Do **not** use it for:

- pushing the core branch (`main` or `develop`)
- force pushing
- deleting remote branches
- opening pull requests

## Workflow

### 1. Detect the current branch

Check the current local branch name first.

Resolve the core branch first (`main` preferred, then `develop`).

If the branch matches that resolved core branch, stop immediately and return:

```text
You cannot push to the <core-branch> branch with this skill.
```

### 2. Use the same branch name on remote

Push the local branch to `origin` using the same branch name remotely.

Example:

```powershell
pwsh -NoProfile -File ./.github/skills/git-push-creator/scripts/push-branch.ps1
```

The helper script will:

- confirm the workspace is a Git repository
- detect the current branch
- resolve the core branch (`main` then `develop`)
- abort if the current branch matches the resolved core branch
- push to `origin/<same-branch-name>`
- set upstream if needed

### 3. Return the exact git result

Do not guess success. Return the real git output after the push completes.

## Hard rules

- Never push the resolved core branch (`main` or `develop`) with this skill.
- Never rename the remote branch; it must match the local branch name.
- Do not use `--force` or `--force-with-lease` unless the user explicitly requests it.
- Return the exact git result instead of summarizing vaguely.
