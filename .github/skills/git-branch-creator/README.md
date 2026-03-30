# Git Branch Creator

A GitHub Copilot skill for creating a new branch from the latest `main` branch.

## What it does

- checks whether a branch name was provided
- stops with a clear message when the name is missing
- fetches the latest remote changes and updates `main` if needed
- creates and switches to the requested branch

## Suggested prompt

```text
Create a new branch using the git-branch-creator skill: feature/add-branch-skill
```

## Helper script

```powershell
pwsh -NoProfile -File ./.github/skills/git-branch-creator/scripts/create-branch.ps1 -BranchName "feature/add-branch-skill"
```

### Optional parameters

- `-BaseBranch "main"` to use a different starting branch
- `-DryRun` to verify the flow without creating the branch

## Notes

- The script uses `main` as the default base branch.
- If local `main` is behind `origin/main`, it pulls with `--ff-only`.
- If the target branch already exists, the script exits with a clear message.
