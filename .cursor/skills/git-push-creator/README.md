# Git Push Creator

A GitHub Copilot skill for pushing the current local branch to `origin` using the same branch name.

## What it does

- detects the current branch
- blocks pushes from the resolved core branch (`main` preferred, then `develop`)
- pushes to `origin/<same-branch-name>`
- sets upstream automatically when needed

## Suggested prompt

```text
Push the current branch using the git-push-creator skill.
```

## Helper script

```powershell
pwsh -NoProfile -File ./.github/skills/git-push-creator/scripts/push-branch.ps1
```

### Safety behavior

If the current branch is the resolved core branch, the script stops with:

```text
You cannot push to the <core-branch> branch with this skill.
```

## Notes

- The remote branch name always matches the current local branch name.
- The script uses `git push --set-upstream origin <branch>`.
- No force push behavior is included.
