# README Writing Guide

Use this guide when creating or upgrading a repository README.

## 1. Core principles

A good README should:
- explain the project's purpose in one or two plain sentences
- help a new contributor or user get started quickly
- stay faithful to what the repository actually contains
- scale its length to the size of the project

## 2. Recommended section flow

A practical order for most repositories is:

1. **Title + summary** — what the project is and why it exists
2. **Badges** — only if they communicate something real
3. **Overview** — a short description of the project or problem space
4. **Getting Started** — install and run instructions
5. **Usage or examples** — the most common workflow
6. **Project Map** — useful when the repo has several folders or packages
7. **Contributing** — include only when contributions are welcome
8. **License** — short and direct

## 3. Tone guidance

Prefer writing that is:
- concrete
- calm
- easy to skim
- free of marketing fluff

| Prefer | Avoid |
|---|---|
| "Runs a local dev server for previewing content." | "A revolutionary next-gen preview experience." |
| "Use `npm run dev` to start the app." | "Simply fire it up with your favorite command." |
| "Requires Python 3.11+." | "Works great everywhere." |

## 4. Adjust to the project type

### Library or framework
Focus on installation, a minimal example, and public entry points.

### App or service
Explain configuration, environment variables, and how to launch it locally.

### Small utility or script
Keep the README compact. A short overview and one usage block may be enough.

### Monorepo
Add a directory map and explain where each package or app lives.

### Docs or learning repository
Emphasize navigation and what readers should open first.

## 5. Badge advice

- Two to five badges is usually enough
- Use a consistent visual style
- Skip badges that do not help a reader decide what this repo is
- Never guess build, release, or package status

## 6. Common mistakes

Avoid these issues:
- leftover placeholders like `{{TODO}}`
- install commands that are not present in the repo
- badges for workflows or registries that do not exist
- giant READMEs for tiny repositories
- sections with headings but no useful content underneath
