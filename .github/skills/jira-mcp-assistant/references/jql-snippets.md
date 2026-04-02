# JQL snippets for Jira MCP Assistant

Replace `PROJ` with the user’s project key. Adjust issue types or statuses as needed.

## Ranked project issues (backlog screen: sprint + backlog column)

Often matches what users see on a Scrum backlog view ordered by rank:

```jql
project = PROJ ORDER BY Rank ASC
```

## Issues not in any sprint (“backlog” section only)

```jql
project = PROJ AND sprint IS EMPTY ORDER BY Rank ASC
```

## Open work in a project

```jql
project = PROJ AND statusCategory != "Done" ORDER BY updated DESC
```

## Assigned to current user (example)

```jql
assignee = currentUser() AND resolution = Unresolved ORDER BY updated DESC
```

## Notes

- **Sprint** field behavior can vary with team-managed vs company-managed projects; if results look wrong, narrow with `board` or saved filter tools when MCP exposes them.
- Prefer `ORDER BY Rank ASC` when the user cares about backlog order.
