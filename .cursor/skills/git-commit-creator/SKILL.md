---
name: git-commit-creator
description: >-
  Create a commit on the current Git branch from the collected repository changes.
  Use when the user asks to commit the current branch, save current work, or
  generate a commit message from git diff output. Prompt whether to stage all
  unstaged files before collecting the changes. Confirm the proposed commit
  message with the user before creating the commit.
argument-hint: "optional commit context or preferred commit style"
---

# Git Commit Creator

Create a commit for the current branch using the actual git changes.

## When this skill fits

Use it for requests like:

- "commit the current branch"
- "create a commit for my current changes"
- "write a commit message and commit the work"

Do **not** use it for:

- pushing to remote
- amending or rewriting commit history
- squashing or rebasing commits

## Workflow

### 1. Prompt about staging

Ask the user this question first:

```text
Do you want to stage all unstaged files before creating the commit?
```

Offer exactly these two options:

- `Yes` — stage all unstaged files
- `No` — keep the current staged set and continue

If the ask-questions tool is available, use it.

### 2. Collect git changes

After the staging choice is known, collect the current git state from the active repository.

Use the helper script in preview mode:

```powershell
pwsh -NoProfile -File ./.github/skills/git-commit-creator/scripts/create-commit.ps1 [-StageAll] -PreviewOnly
```

This previews:

- the current branch name
- `git status --short`
- staged file names
- staged diff summary

If there are no staged changes after the chosen flow, stop and return:

```text
No staged changes are available to commit.
```

### 3. Draft, show, and confirm the commit message

#### 3a. Draft

Produce **one** proposed commit message based only on the collected git changes.

Follow these static best-practice rules:

- use a short subject line in imperative mood
- describe **what changed**, not vague intent
- keep the subject concise and specific
- use a helpful prefix when it fits: `feat`, `fix`, `docs`, `refactor`, `test`, `chore`
- avoid messages like `update`, `changes`, `misc fixes`, or `stuff`

Good examples:

```text
feat: add git commit creator skill
fix: handle empty branch names in git helper
docs: update README with git workflow skills
refactor: simplify API scenario priority rules
```

#### 3b. Show and confirm

Display the proposed message prominently: use a short label, then a single fenced block containing only the message (no nested fences), for example:

**Proposed commit message**

```text
<proposed-message>
```

Then ask:

```text
Is this commit message OK to use?
```

Offer exactly these two options:

- `OK` — use the proposed message
- `Not OK` — I will provide my own message

If the ask-questions tool is available, use it.

#### 3c. Branch on the answer

- If **OK** — go to **step 4** using `<proposed-message>` as the final message.
- If **Not OK** — tell the user to send their **exact** commit message in their next reply (one line subject, or subject plus body if they prefer). Do **not** create the commit until they provide it. After they send it, use **that** text as the final message for **step 4**. Do not invent or alter their wording unless they ask you to edit it.

### 4. Create the commit

Run the helper script with the **final** message (proposed after OK, or user-supplied after Not OK):

```powershell
pwsh -NoProfile -File ./.github/skills/git-commit-creator/scripts/create-commit.ps1 [-StageAll] -CommitMessage "<final-message>"
```

Return the exact git result after the commit command completes.

## Hard rules

- Never invent changed files or behaviors.
- Do not commit if there are no staged changes.
- Do not amend, force-push, or rewrite history unless explicitly requested.
- Build the commit message from the real diff, not from assumptions.
- Keep the message clear and professional.
- Do not create the commit until the user chooses **OK** for the proposed message, or **explicitly supplies** their own message after **Not OK**.
