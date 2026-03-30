# Pull Request Title Guide

Use these rules when generating a PR title.

## Core rules

- Keep the title concise and specific.
- Prefer describing the result of the branch changes.
- Preserve a ticket or issue prefix when the branch clearly contains one.
- Use a readable sentence after the prefix.
- Avoid vague titles such as `update`, `changes`, `test branch`, or `misc fixes`.

## Ticket prefix format

If the branch starts with a ticket-like prefix, format the title like this:

```text
[TST-2056]: add new git related skills
[2056]: update README and workflow docs
```

## Good examples

```text
[TST-2056]: add new git related skills
[2056]: update README and Git workflow helpers
add readme and git skills
fix PowerShell script parsing issues
```
