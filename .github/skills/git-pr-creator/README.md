# Git PR Creator

A GitHub Copilot skill for creating a pull request from the current branch to `main`.

## What it does

- detects the current local branch
- blocks PR creation from `main`
- keeps the same local and remote branch name
- generates a PR title from a ticket prefix, branch suffix, or commit changes
- checks for an existing PR with the same ticket prefix before continuing

## Suggested prompt

```text
Create a pull request from this branch using the git-pr-creator skill.
```

## Helper script

```powershell
pwsh -NoProfile -File ./.github/skills/git-pr-creator/scripts/create-pr.ps1 -DryRun
```

## Title examples

- `TST-2056_testBranch` → `[TST-2056]: added new git related skills`
- `2056_testBranch` → `[2056]: added new git related skills`
- `readme_and_git_skills` → `add readme and git skills`

## Notes

- The default base branch is `main`.
- If the remote branch does not exist yet, the helper can publish it using the same name.
- Duplicate ticket-prefix PRs require explicit user confirmation.
