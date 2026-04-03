# Git Branch Creator

A GitHub Copilot skill for creating a new branch from the latest core branch (`main` or `develop`, whichever is available).

## What it does

- checks whether a branch name was provided
- stops with a clear message when the name is missing
- fetches the latest remote changes and updates the selected base branch if needed
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

- `-BaseBranch "<branch>"` to use a specific starting branch
- `-DryRun` to verify the flow without creating the branch

## Notes

- If `-BaseBranch` is omitted, the script resolves the core branch (`main` first, then `develop`).
- If local base branch is behind `origin/<base>`, it pulls with `--ff-only`.
- If the target branch already exists, the script exits with a clear message.
