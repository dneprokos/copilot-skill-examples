---
name: git-branch-creator
description: >-
  Create a new Git branch from the latest core branch (`main` or `develop`,
  whichever is available). Use when the user asks to create a new branch, start
  a feature branch, or checkout a working branch. Requires the new branch name;
  if it is missing, return a message asking for it and stop.
argument-hint: "new-branch-name [optional base branch]"
---

# Git Branch Creator

Create and switch to a new Git branch safely.

## When this skill fits

Use it for requests like:

- "create a new branch feature/login-form"
- "start a branch called bugfix/token-refresh"
- "checkout a new branch for this task"

Do **not** use it for:

- merging or rebasing branches
- deleting branches
- opening pull requests

## Workflow

### 1. Require a branch name

Check whether a branch name was supplied after the skill call.

If it is missing, respond with:

```text
A new branch name should be specified for this skill.
```

Then stop the skill execution.

### 2. Ensure the repository is ready

- Confirm the workspace is inside a Git repository.
- Auto-detect the core branch (`main` preferred, then `develop`) unless the user clearly requests another base.
- If not already on the base branch, switch to it first.

### 3. Update the base branch

Run the helper script:

```powershell
pwsh -NoProfile -File ./.github/skills/git-branch-creator/scripts/create-branch.ps1 -BranchName "<new-branch-name>"
```

The script will:

- fetch from `origin`
- check whether the selected base branch is behind `origin/<base>`
- pull with `--ff-only` if updates are needed
- stop if the requested branch already exists

### 4. Create the branch

After the base branch is ready, create and switch to the new branch using the provided branch name.

## Hard rules

- Never invent the branch name.
- If the name is missing, stop immediately.
- Prefer `git switch` semantics for branch creation.
- Use `--ff-only` when updating the base branch.
- Return the exact git result instead of guessing success.
