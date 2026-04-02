---
name: jira-mcp-assistant
description: >-
  Queries Jira Cloud via the Atlassian MCP: JQL search, backlog-style lists, and
  ranked issue views. Resolves cloudId, paginates results, and formats a concise
  table. Use when the user asks for Jira backlog items, project issues, sprint
  scope, or any JQL-driven list. Future sections may cover creating issues and
  dashboard or filter metadata; extend references/ and this description when
  adding those workflows.
---

# Jira MCP Assistant

Use the **Atlassian (Jira) MCP** tools already configured in Cursor (or another MCP client). This skill does not call the REST API directly; it tells the agent **how** to use MCP consistently.

## Prerequisites

- Atlassian MCP is connected and authenticated (OAuth or API token per your org’s [Rovo MCP settings](https://support.atlassian.com/rovo/docs/setting-up-ides/)).
- The authenticated user can **browse** the target project and run JQL.

If tools are missing, complete MCP authentication first; do not guess endpoints or tokens.

## When this skill fits

- List backlog or board issues for a project (e.g. `SCRUM`, `PROJ`).
- Run a user-supplied or template JQL query and return a readable summary.
- Compare “everything on the backlog screen” vs “issues not in a sprint” (see [references/jql-snippets.md](references/jql-snippets.md)).

## Workflow

### 1. Collect inputs

From the user (or context), obtain when relevant:

- **Site** (e.g. `your-site.atlassian.net`) or confirmation that the default accessible site is correct.
- **Project key** (e.g. `SCRUM`).
- **Intent:** full backlog view vs unsprinted backlog only vs custom JQL.

### 2. Resolve `cloudId`

Use the Atlassian MCP tool that lists accessible resources (often named like `getAccessibleAtlassianResources`). Pick the `cloudId` for the site that hosts the project.

If the user only gives a project key, still resolve `cloudId` for their Jira Cloud site before calling Jira tools.

### 3. Search with JQL

Call the MCP tool that searches Jira by JQL (commonly `searchJiraIssuesUsingJql`).

- Build JQL using [references/jql-snippets.md](references/jql-snippets.md) or the user’s query.
- **Always** respect the tool’s **pagination** (`maxResults`, `startAt`, or `nextPageToken`—follow the live schema). If the user wants the full set, page until no more results or a sensible cap they confirm.
- Request fields needed for the summary table at minimum: issue key, summary, type, status; add assignee, sprint, priority if the question requires them.

### 4. Present results

Return a **markdown table** (or bullet list if very small) with the chosen columns. Note approximate **total** if pagination was truncated and offer to fetch the next page.

### 5. Optional deep fetch

If search results omit fields the user needs, use `getJiraIssue` (or equivalent) for specific keys—avoid N+1 calls for large lists unless necessary.

## Guardrails

- Do not fabricate issues or JQL results; only report what MCP returns.
- For **mutating** operations (create, transition, comment), confirm intent explicitly with the user before invoking write tools—even when you add those sections later.

## Extending this skill

See the repository [README.md](../../../README.md) section **Jira skills and Atlassian MCP** for how to add create-issue, dashboard, and filter workflows without renaming the skill.
