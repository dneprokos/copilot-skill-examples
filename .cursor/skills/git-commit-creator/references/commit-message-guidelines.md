# Commit Message Guide

Use these rules when generating a commit message from git changes.

## Core rules

- Start with a concise subject line.
- Use imperative mood: `add`, `fix`, `update`, `remove`, `refactor`.
- Describe the actual change, not a vague intention.
- Keep the subject short and easy to scan.
- Add a prefix when it helps clarify the kind of change.

## Useful prefixes

- `feat` — new functionality
- `fix` — bug fix or safety improvement
- `docs` — documentation change
- `refactor` — code cleanup without behavior change
- `test` — test updates
- `chore` — maintenance or housekeeping work

## Good examples

```text
feat: add branch creation skill
fix: handle missing branch name safely
docs: refresh README skill list
refactor: simplify git diff summary output
```

## Avoid

```text
update
changes
misc fixes
work in progress
stuff
```

## Optional body pattern

If the change is large, a short body can follow the subject:

```text
feat: add git commit creator skill

- prompt whether to stage all files
- collect git status and staged diff summary
- create a commit on the active branch
```
