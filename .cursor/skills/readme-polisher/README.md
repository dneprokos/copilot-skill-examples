# README Polisher

A GitHub Copilot skill for drafting or refreshing project `README.md` files from real repository evidence.

## What it does

- inspects the repo for package managers, scripts, licenses, and CI clues
- suggests a practical README structure instead of a one-size-fits-all wall of text
- adds badges only when the underlying metadata is present
- keeps small projects short and complex projects organized
- can add a simple Mermaid diagram when the architecture is worth explaining

## Folder Layout

```text
.github/skills/readme-polisher/
├── SKILL.md
├── README.md
├── assets/
│   ├── badges.json
│   ├── diagram-ideas.md
│   └── readme-template.md
├── evals/
│   └── evals.json
├── references/
│   └── readme-guidelines.md
└── scripts/
    └── scan_project.ps1
```

## Suggested prompt

```text
Improve the README for this project using the readme-polisher skill. Inspect the repo first, keep the output accurate, and do not invent badges or setup steps.
```

## Notes

- The bundled scan script is PowerShell-based, which makes it convenient on Windows.
- The template is meant to be adapted, not pasted blindly.
- The evals file gives a lightweight checklist for judging output quality.
