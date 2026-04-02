# API Test Scenario Generator

A GitHub Copilot skill for producing API scenario specs from an HTTP method, endpoint, optional domain hints, and (optionally) an OpenAPI spec.

## Quick Start

```text
/api-test-scenario-generator POST /api/orders \
  --fields amount:number:>=0,status:enum:PENDING|CONFIRMED|CANCELLED \
  --states PENDING,CONFIRMED,SHIPPED,DELIVERED,CANCELLED \
  --transitions PENDING:CONFIRMED,CONFIRMED:SHIPPED,SHIPPED:DELIVERED \
  --filters status:string,createdAt:date \
  --sortable createdAt,totalAmount \
  --relations user:owner-must-exist
```

If you do not supply these hints, the skill falls back to HTTP conventions and common API knowledge, then records any assumptions under warnings.

## What it covers

- ✅ happy path, validation, and edge cases
- ✅ RBAC and auth flows, including expired JWT and refresh expectations
- ✅ filtering, sorting, pagination, and date-range queries
- ✅ state transitions and lifecycle checks
- ✅ idempotency and duplicate-write protection
- ✅ referential integrity and cascade behavior
- ✅ error-response contract verification
- ✅ protocol and operational errors such as `405`, `415`, `429`, `502`, and `503`

## Output

Generated documents include:

- a scenario table with `Priority` and `Recommended Test Level`
- a clear legend: `High (H) > Medium (M) > Low (L)`
- an optional dependency graph when prerequisite resources are required
- a warnings section for unknown or inferred behavior

### Example dependency graph

```json
{
  "nodes": ["create_user", "update_user", "delete_user"],
  "edges": [
    { "from": "create_user", "to": "update_user" },
    { "from": "create_user", "to": "delete_user" }
  ]
}
```

## Priority and test-level guidance

- **High (H)** = business-critical, auth, destructive, money, or data-integrity scenarios
- **Medium (M)** = important validation and common negative checks
- **Low (L)** = optional or rarer operational checks

The skill assigns these priorities as a starting point, and reviewers can override them. The testing pyramid split is also a heuristic, not a hard quota.

## Supported context flags

```text
--fields      name:type:constraint,...
--states      STATE1,STATE2,...
--transitions FROM:TO,...
--filters     name:type,...
--sortable    field1,field2,...
--relations   resource:policy,...
--openapiSpec PATH_OR_JSON_OR_YAML
--openapiOperationId OPERATION_ID
```

Use them when the endpoint depends on domain rules that cannot be safely inferred from the path alone.

## Supported HTTP methods

- `GET`, `POST`, `PUT`, `PATCH`, `DELETE`
- `HEAD`, `OPTIONS` when the contract exposes them

## Files

```text
.github/skills/api-test-scenario-generator/
├── SKILL.md
├── README.md
├── templates/
│   ├── scenario-table.md
│   └── full-report.md
├── config/
│   ├── validation-rules.json
│   └── test-types.json
└── scripts/
    └── generate-scenarios.js
```

## Implementation tips

1. Cover `High (H)` scenarios first.
2. Prefer unit tests for validation rules and pure business logic.
3. Use integration tests for auth, RBAC, state changes, and error contracts.
4. Keep E2E coverage focused on a few cross-system flows.
5. Treat missing context as a warning, not a guess.
