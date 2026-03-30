# Git Commit Creator

A GitHub Copilot skill for creating a commit on the current branch from real git changes.

## What it does

- asks whether all unstaged files should be staged first
- collects the current git status and staged diff summary
- writes a commit message using concise best practices
- creates the commit on the active branch

## Suggested prompt

```text
Commit the current branch using the git-commit-creator skill.
```

## Helper script

### Preview the commit state

```powershell
pwsh -NoProfile -File ./.github/skills/git-commit-creator/scripts/create-commit.ps1 -PreviewOnly
```

### Stage all changes and commit

```powershell
pwsh -NoProfile -File ./.github/skills/git-commit-creator/scripts/create-commit.ps1 -StageAll -CommitMessage "docs: add git commit creator skill"
```

## Commit message examples

- `feat: add git commit creator skill`
- `fix: handle empty commit message safely`
- `docs: update README with commit workflow`
- `refactor: simplify git helper script output`

## Notes

- The skill commits on the **current branch**.
- If nothing is staged, it stops instead of guessing.
- `-DryRun` is available for safe verification.
