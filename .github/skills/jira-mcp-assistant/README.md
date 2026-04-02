# Jira MCP Assistant

A small, read-first workflow for working with **Jira Cloud** via the **Atlassian (Jira) MCP** tools already configured in Cursor.

## What it does

- Resolves the Atlassian `cloudId`
- Runs **JQL searches** (and backlog-style views)
- Returns results as a clean **markdown table** (issue key, summary, type, status, etc.)
- Never fabricates issues - only reports what MCP returns

## Suggested prompt

```text
List backlog issues for project SCRUM using the jira-mcp-assistant skill.
```

You can also ask for custom JQL:

```text
Run this JQL and summarize the results as a table:
project = SCRUM AND issuetype = Bug ORDER BY updated DESC
```

## Prerequisites

- **Atlassian MCP is connected and authenticated** (OAuth or API token, depending on your org's Rovo MCP settings).
- Your authenticated user can **browse** the target Jira project and run JQL.

## Configure Atlassian MCP auth (API token, no helper scripts)

This skill expects the MCP server to receive an HTTP `Authorization` header.

1. Create an **Atlassian API token** for the same Atlassian account that has access to your Jira Cloud site:  
   https://id.atlassian.com/manage-profile/security/api-tokens

2. Build the HTTP Basic auth value:
   - Take: `email:api_token`
   - Encode the combined string as **Base64 (UTF-8)**
   - Prefix with `Basic `  
   Result format: `Basic <base64(email:api_token)>`

3. Set a Windows **user** environment variable:
   - Name: `ATLASSIAN_MCP_AUTHORIZATION`
   - Value: the full `Basic <base64...>` string from step 2

4. Wire it into MCP config (example for `mcp.json`):

```json
{
  "mcpServers": {
    "Atlassian-MCP-Server": {
      "url": "https://mcp.atlassian.com/v1/mcp",
      "headers": {
        "Authorization": "${env:ATLASSIAN_MCP_AUTHORIZATION}"
      }
    }
  }
}
```

Notes:
- Keep `ATLASSIAN_MCP_AUTHORIZATION` out of git. Prefer **user env vars** over committed files.
- If your org/client setup uses OAuth login, you may not need `mcp.json` at all - Cursor can prompt you to sign in.

## OAuth note (optional)

If you configure MCP with OAuth, Cursor typically opens a browser sign-in flow. In that case, you do not need the API-token-based `ATLASSIAN_MCP_AUTHORIZATION` header.

## Helper scripts (optional) - simplify the same steps

If you don't want to do Base64 and env-var setup manually, you can use the repo scripts:

- [`../../../Build-AtlassianMcpAuthorization.ps1`](../../../Build-AtlassianMcpAuthorization.ps1): prompts for email + token and prints `Basic ...`
- [`../../../Set-AtlassianMcpAuthorizationUserEnv.ps1`](../../../Set-AtlassianMcpAuthorizationUserEnv.ps1): prompts for `Basic ...` and sets `ATLASSIAN_MCP_AUTHORIZATION`

Security reminder: do not commit secrets or paste tokens into issues/PRs.

## Usage examples

- Backlog-style ranked list:
  - `List backlog issues for project SCRUM using the jira-mcp-assistant skill.`
- "Backlog column only" (not in any sprint):
  - `List issues in SCRUM where sprint is empty.`
- Custom JQL + table:
  - `Run this JQL and summarize in a table: project = SCRUM ORDER BY Rank ASC`

## Output format

By default, the skill can present a table with (at minimum):
- Issue key
- Summary
- Type
- Status

It can add more fields when needed (priority, sprint, assignee, etc.). If results are large and truncated, the skill should fetch additional pages as appropriate.

## JQL reference

See:
- [`references/jql-snippets.md`](references/jql-snippets.md)

## Extending this skill

To add new Jira workflows without breaking discovery:

1. Keep the umbrella skill id as `jira-mcp-assistant`
2. Update `SKILL.md` description to include new trigger phrases (e.g. "create issue", "dashboard filter")
3. Add implementation guidance as new sections in `SKILL.md`
4. Split large JQL guidance into more files under `references/`

This repo's main README explains the intended extension approach.

