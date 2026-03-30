---
name: api-test-scenario-generator
description: Generate comprehensive REST API test scenarios from a method, endpoint, and optional domain hints such as fields, states, transitions, filters, sortable fields, relations, and RBAC context. Covers happy path, validation, security, query behavior, state transitions, idempotency, and error contract checks.
---

# API Test Scenario Generator

Generate API test-scenario specs that stay grounded in the endpoint plus any domain context the user provides. When domain details are missing, the skill should infer conservatively from HTTP semantics and list assumptions as warnings instead of inventing facts.

## What this skill should produce

- a markdown scenario table with clear expected results and HTTP statuses
- explicit **Priority** labels: `High (H) > Medium (M) > Low (L)`
- an optional **dependency graph** when one resource must exist before another action can be tested
- a **Warnings and Assumptions** section for anything not confirmed

## Usage

Use this command format:

```text
/api-test-scenario-generator {METHOD} {ENDPOINT}
  [--fields name:type:constraint,...]
  [--states STATE1,STATE2,...]
  [--transitions FROM:TO,...]
  [--filters name:type,...]
  [--sortable field1,field2,...]
  [--relations resource:policy,...]
  [additional_context]
```

### Context rules

- These hints are optional, but they make the generated scenarios much more accurate.
- If a hint is missing, fall back to common API patterns and built-in HTTP knowledge only.
- Any inferred RBAC rule, state machine, or filter behavior must be called out as an assumption.

### Examples

```text
/api-test-scenario-generator POST /api/users
/api-test-scenario-generator GET /api/users/{id}
/api-test-scenario-generator POST /api/orders \
  --fields amount:number:>=0,status:enum:PENDING|CONFIRMED|CANCELLED \
  --states PENDING,CONFIRMED,SHIPPED,DELIVERED,CANCELLED \
  --transitions PENDING:CONFIRMED,CONFIRMED:SHIPPED,SHIPPED:DELIVERED \
  --filters status:string,createdAt:date \
  --sortable createdAt,totalAmount \
  --relations user:owner-must-exist
```

## Generated Table Format

| Scenario | Test Type | Description | Expected Result | HTTP Status | Priority | Recommended Test Level |
| -------- | --------- | ----------- | --------------- | ----------- | -------- | ---------------------- |
| ...      | ...       | ...         | ...             | ...         | ...      | ...                    |

### Priority rules

- **High (H)** — must-cover scenarios affecting business-critical flow, auth, money, destructive actions, or data integrity
- **Medium (M)** — important validation and common negative cases
- **Low (L)** — optional, exploratory, or rarer operational checks
- The skill assigns the initial priority. A reviewer can always override it.

## Coverage checklist

The generated scenarios should consider, when relevant:

1. **Happy path and CRUD basics**
2. **Validation and boundary cases** — Unicode, unknown fields, zero values, min/max lengths, date limits
3. **Authentication and RBAC** — missing token, invalid token, expired JWT → `401`, refresh flow expectations, Admin vs Customer access to other users' resources
4. **Query behavior** — pagination, filtering, sorting, invalid filter field, invalid sort field, date-range filters
5. **State machines** — explicit state transitions such as `PENDING → CONFIRMED → SHIPPED → DELIVERED`, plus invalid transitions
6. **Idempotency** — duplicate `POST` or replayed `Idempotency-Key` must not create duplicate writes
7. **Referential integrity** — cascade or blocked delete/update behavior when related resources exist
8. **Protocol and reliability errors** — `405`, `415`, `429`, `502`, `503` where applicable
9. **Error response contract** — check fields like `error.code`, `error.message`, `error.requestId`, and validation details
10. **HTTP methods outside CRUD** — `HEAD` and `OPTIONS` when the endpoint contract supports them

## Output Requirements

### File generation

- **Format**: Always save output in `.md` format
- **Location**: `requirements/{main_resource_name}/{method_name}_{resource_path}.md`
  - Example: `requirements/users/GET_users_id.md` for `GET /api/users/{id}`
  - Example: `requirements/orders/PUT_orders_id_status.md` for `PUT /api/orders/{id}/status`
- **Overwrite Check**: If the file already exists, prompt the user before overwriting it
- **File Structure**: Include scenario table, optional dependency graph, then warnings/unknowns

### Dependency graph

Add a dependency graph when the test flow requires prerequisite resources or state transitions.

```json
{
  "nodes": ["create_user", "update_user", "delete_user"],
  "edges": [
    { "from": "create_user", "to": "update_user" },
    { "from": "create_user", "to": "delete_user" }
  ]
}
```

### Warning documentation

- **Location**: List all warnings about unknowns at the end of the document
- **Format**: Use `⚠️` for each warning
- **Content**: Say exactly what was assumed or missing (RBAC, filters, states, relations, error schema, etc.)

### Plan mode behavior

- **No Implementation Questions**: Do not ask about test framework details in Plan mode
- **Focus**: Generate scenarios only; implementation can be handled by another skill

## Test level guidance

Use the testing pyramid as a **heuristic**, not a rigid quota:

- **Unit**: Most validation and pure business-rule checks
- **Integration**: API contracts, auth, RBAC, persistence, service-to-service behavior
- **E2E**: A small set of cross-system critical journeys

Do not force `70/20/10` blindly if the system shape suggests a different balance.

## Configuration

The skill uses configuration files to customize test generation:

- `config/validation-rules.json` — validation, auth, query, error, and protocol rules
- `config/test-types.json` — test classifications, priority legend, and testing-level guidance
- `templates/` — markdown output templates

## Implementation approach

This skill analyzes the provided HTTP method, endpoint, and optional context using:

1. **Pattern recognition** — CRUD, nested resources, pagination, filtering, sorting
2. **Boundary analysis** — lengths, ranges, Unicode, nullability, unknown fields
3. **Security testing** — auth, RBAC, ownership, tenant isolation, token expiry
4. **Lifecycle modeling** — states, transitions, idempotency, referential integrity
5. **Contract verification** — status codes and structured error responses
6. **Operational resilience** — rate limits and upstream failure scenarios

All unknowns must be surfaced explicitly rather than guessed.
